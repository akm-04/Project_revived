// Package itemsenergy settles the stock item-use, sell, energy-buy, golden-hand
// and exchange-code commands. Every accepted command is one transaction on the
// LEAD_SEAMS_I9-11 V2 money path: fence, player root, roster, daily counter,
// then one I5 exchange for the whole debit/restoration union.
package itemsenergy

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	// ReceiptClass is the LEAD_SEAMS_I9-11 V2 section 5 receipt class.
	ReceiptClass = "I9_11B_ITEMS_ENERGY"
	// ResultSchema is the stored reply schema of every 11B receipt.
	ResultSchema = "gxb.items_energy.command.v1"
)

var (
	ErrEnergyCap = errors.New("items-energy: energy at cap")
)

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	DailyBuyInputsTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

type Counters interface {
	ReadBuyTx(context.Context, tx.Queryer, identity.PlayerID, int64) (appconsume.BuyCounters, error)
	IncrementBuyTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, time.Time) (appconsume.BuyCounters, error)
	IncrementDailyTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, time.Time) (int64, error)
}

type Privileges interface {
	SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (appi5.PrivilegeSnapshot, error)
}

type Progression interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}

// Balances is the I5-owned read seam used for the locked energy-cap read and
// the post-commit economy projection.
type Balances interface {
	ReadTemporalTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.TemporalState, bool, error)
	ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error)
}

type Heroes interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
	AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error)
	OwnsOriginTx(context.Context, tx.Tx, identity.PlayerID, int64) (bool, error)
}

// HeroFragments is the summon owner's duplicate conversion for an owned hero.
type HeroFragments interface {
	Fragments(int64) ([2]int64, error)
}

type HeroWire func(character.Hero) (map[string]any, error)

type Receipts interface {
	FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error)
	PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error)
}

// Service is the I9-11B command owner. Route registration and composition are
// lead work at merge; this constructor and its registration test are the leaf's
// part.
type Service struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Content     Content
	Fence       Fence
	Players     Players
	Counters    Counters
	Exchange    appi5.TxItemsEnergyExchange
	Balances    Balances
	Privileges  Privileges
	Progression Progression
	Facts       appi5.ObjectiveFacts
	Heroes      Heroes
	Fragments   HeroFragments
	HeroWire    HeroWire
	Receipts    Receipts
	ReceiptRead receipt.Reader
}

func Profile() tx.Profile {
	return tx.Profile{Name: "items-energy", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

func (s Service) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Content != nil &&
		s.Fence != nil && s.Players != nil && s.Counters != nil && s.Exchange != nil && s.Balances != nil &&
		s.Privileges != nil && s.Progression != nil && s.Receipts != nil && s.ReceiptRead != nil
}

func (s Service) pin(c context.Context, op operation.Context) (operation.Context, error) {
	if !s.ready() {
		return op, d.ErrUnavailable
	}
	if _, bound := op.Policies.Get("content"); bound {
		return op, nil
	}
	revision, err := s.Content.ActiveRevision(c, s.Fresh)
	if err != nil {
		return op, err
	}
	op.Policies, err = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return op, err
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

// execute pins content, opens the command's transaction and writes its outer
// semantic receipt in the same commit. body owns the per-command decisions.
func (s Service) execute(c context.Context, a identity.ActorContext, op operation.Context, name string, request any, body func(context.Context, gen.TimedScope, d.Catalog) (map[string]any, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	if !a.PlayerID.Valid() {
		return nil, d.ErrInvalid
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "items-energy", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	_, result, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, a, at); err != nil {
			return err
		}
		if _, err := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); err != nil {
			return err
		}
		stored, found, err := s.Receipts.FindTx(c, sc.Tx, id)
		if err != nil {
			return err
		}
		if found {
			if stored.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(stored.ResultPayload, &out)
		}
		revision, _ := sc.Operation.Operation().Policies.Get("content")
		catalog, err := s.Content.DailyBuyInputsTx(c, sc.Tx, revision)
		if err != nil {
			return err
		}
		out, err = body(c, sc, catalog)
		if err != nil {
			return err
		}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		entry, err := receipt.New(sc.Operation.Operation(), id, ReceiptClass, ResultSchema, raw, fingerprint)
		if err != nil {
			return err
		}
		entry.PolicyVersion, entry.ActorAccountUID, entry.ContextID = d.PolicyID, string(a.AccountUID), a.ContextID.UUID()
		_, err = s.Receipts.PutTx(c, sc.Tx, entry)
		return err
	})
	if err == nil && result.Reconciled {
		stored, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, d.ErrUnavailable
		}
		err = json.Unmarshal(stored.ResultPayload, &out)
	}
	if err != nil {
		return nil, err
	}
	return out, nil
}

// exchangePlan is one command's validated debit and restoration before the I5
// exchange closes the lock union.
type exchangePlan struct {
	cost        appi5.MaterialCost
	restoration grant.Plan
}

func (s Service) settle(c context.Context, sc gen.TimedScope, a identity.ActorContext, plan exchangePlan, allowOverflow bool) (appi5.ItemsEnergyExchangeResult, error) {
	prepared, err := s.Exchange.PrepareItemsEnergyExchangeTx(c, sc.Tx, a, appi5.ItemsEnergyExchangeRequest{Cost: plan.cost, Restoration: plan.restoration, AllowOverflowMail: allowOverflow}, sc.Operation.Operation())
	if err != nil {
		return appi5.ItemsEnergyExchangeResult{}, err
	}
	applied, err := s.Exchange.ApplyItemsEnergyExchangeTx(c, sc.Tx, prepared)
	if err != nil {
		return applied, err
	}
	recordDebit(c, applied.Debit)
	return applied, s.recordRestoration(c, sc, a.PlayerID, applied.Restoration)
}

func recordDebit(c context.Context, debit appi5.MaterialDebitResult) {
	for _, balance := range debit.Scalars {
		changes.Balance(c, balance.ResourceKey, balance.Amount)
	}
}

func (s Service) recordRestoration(c context.Context, sc gen.TimedScope, pid identity.PlayerID, result appi5.GrantResult) error {
	keys := map[string]struct{}{}
	if result.Effects != nil {
		for _, effect := range result.Effects.Temporal {
			changes.Balance(c, effect.ResourceKey, effect.AfterAmount)
		}
		for _, progression := range result.Effects.Progression {
			changes.Balance(c, "lev", progression.AfterLevel)
			changes.Balance(c, "exp", progression.AfterExp)
		}
	}
	for _, award := range result.Awards {
		if award.ResourceKey == "" || award.ResourceKey == "exp" {
			continue
		}
		keys[award.ResourceKey] = struct{}{}
	}
	for key := range keys {
		state, exists, err := s.Balances.ReadScalarTx(c, sc.Tx, pid, key)
		if err != nil {
			return err
		}
		if !exists {
			continue
		}
		changes.Balance(c, key, state.Amount)
	}
	return nil
}

func (s Service) day(sc gen.TimedScope) int64 {
	return modes.Day(sc.Operation.DecisionAt())
}

func (s Service) snapshot(c context.Context, sc gen.TimedScope, pid identity.PlayerID, at time.Time) (appi5.PrivilegeSnapshot, error) {
	return s.Privileges.SnapshotTx(c, sc.Tx, pid, at)
}

func (s Service) level(c context.Context, sc gen.TimedScope, pid identity.PlayerID) (int64, error) {
	progression, err := s.Progression.ReadProgressionTx(c, sc.Tx, pid)
	if err != nil {
		return 0, err
	}
	return progression.Level, nil
}

func (s Service) temporal(c context.Context, sc gen.TimedScope, pid identity.PlayerID, key string) (int64, error) {
	state, exists, err := s.Balances.ReadTemporalTx(c, sc.Tx, pid, key)
	if err != nil {
		return 0, err
	}
	if !exists {
		return 0, nil
	}
	return state.StoredAmount, nil
}

func (s Service) scalar(c context.Context, sc gen.TimedScope, pid identity.PlayerID, key string) (int64, error) {
	state, exists, err := s.Balances.ReadScalarTx(c, sc.Tx, pid, key)
	if err != nil {
		return 0, err
	}
	if !exists {
		return 0, nil
	}
	return state.Amount, nil
}

func rewardPlan(pid identity.PlayerID, name string, op operation.Context, lines []grant.Line) grant.Plan {
	return grant.Plan{PlayerID: pid, Source: grant.SourceIdentity{Domain: "items-energy", Operation: name, BusinessKey: op.ID.String(), Occurrence: op.ID.String(), PolicyVersion: d.PolicyID}, Lines: lines}
}
