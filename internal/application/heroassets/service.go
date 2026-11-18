// Package heroassets settles the I9-11A skill-point purchase (MID 99) and the
// skill-point item (MID 90). Every accepted command is one transaction on the
// LEAD_SEAMS_I9-11 V2 money path: fence, player root, rank-450 daily counter,
// then one I5 exchange for the crystal or stack debit and the temporal grant.
package heroassets

import (
	"context"
	"encoding/json"
	"strconv"
	"time"

	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	d "gxb.local/backend/v2/internal/domain/heroassets"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	// ReceiptClass is the LEAD_SEAMS_I9-11 V2 section 5 receipt class.
	ReceiptClass = "I9_11A_HERO_ASSETS"
	// ResultSchema is the stored reply schema of every 11A receipt.
	ResultSchema = "gxb.hero_assets.command.v1"
)

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	DailyBuyInputsTx(context.Context, tx.Queryer, string) (itemsenergy.Catalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

type Counters interface {
	LockBuyTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (appconsume.LockedCounters, appconsume.BuyCounters, error)
	AdvanceBuyTx(context.Context, tx.Tx, identity.PlayerID, appconsume.LockedCounters, int64, int64) (appconsume.BuyCounters, error)
}

type Balances interface {
	ReadTemporalTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.TemporalState, bool, error)
	ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error)
	ReadStackTx(context.Context, tx.Queryer, identity.PlayerID, int64) (economy.StackState, bool, error)
}

type Privileges interface {
	SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (appi5.PrivilegeSnapshot, error)
}

type Receipts interface {
	FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error)
	PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error)
}

// Service is the I9-11A command owner. Route registration and composition are
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
	Receipts    Receipts
	ReceiptRead receipt.Reader
}

func Profile() tx.Profile {
	return tx.Profile{Name: "hero-assets", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

func (s Service) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Content != nil &&
		s.Fence != nil && s.Players != nil && s.Counters != nil && s.Exchange != nil && s.Balances != nil &&
		s.Privileges != nil && s.Receipts != nil && s.ReceiptRead != nil
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

// execute pins content, opens the command transaction and writes its outer
// semantic receipt in the same commit. body owns the per-command decisions.
func (s Service) execute(c context.Context, a identity.ActorContext, op operation.Context, name string, request any, body func(context.Context, gen.TimedScope, itemsenergy.Catalog) (map[string]any, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	if !a.PlayerID.Valid() {
		return nil, d.ErrInvalid
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "hero-assets", Operation: name, SemanticKey: op.ID.String()}
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

func (s Service) day(sc gen.TimedScope) int64 {
	return modes.Day(sc.Operation.DecisionAt())
}

func (s Service) requireStack(c context.Context, sc gen.TimedScope, pid identity.PlayerID, itemID, amount int64) error {
	state, exists, err := s.Balances.ReadStackTx(c, sc.Tx, pid, itemID)
	if err != nil {
		return err
	}
	if !exists || state.Quantity < amount {
		return d.ErrStaleState
	}
	return nil
}

func (s Service) skillPoint(c context.Context, q tx.Queryer, pid identity.PlayerID) (int64, int64, error) {
	state, exists, err := s.Balances.ReadTemporalTx(c, q, pid, "skill_point")
	if err != nil {
		return 0, 0, err
	}
	if !exists {
		return 0, 0, economy.ErrUnknownResource
	}
	skillTime := int64(0)
	if state.RegenAnchorAt != nil {
		skillTime = state.RegenAnchorAt.UTC().Unix()
	}
	return state.StoredAmount, skillTime, nil
}

func (s Service) scalar(c context.Context, q tx.Queryer, pid identity.PlayerID, key string) (int64, error) {
	state, exists, err := s.Balances.ReadScalarTx(c, q, pid, key)
	if err != nil {
		return 0, err
	}
	if !exists {
		return 0, nil
	}
	return state.Amount, nil
}

// recordBalances asks the decorator to carry the post-commit values this
// command changed. Values are read back, never recomputed from the request.
func recordBalances(c context.Context, crystal, skillPoint int64) {
	changes.Balance(c, "crystal", crystal)
	changes.Balance(c, "skill_point", skillPoint)
}

func rewardPlan(pid identity.PlayerID, name string, op operation.Context, amount int64) grant.Plan {
	return grant.Plan{PlayerID: pid, Source: grant.SourceIdentity{Domain: "hero-assets", Operation: name, BusinessKey: op.ID.String(), Occurrence: op.ID.String(), PolicyVersion: d.PolicyID}, Lines: []grant.Line{{Kind: grant.Temporal, ResourceKey: "skill_point", Amount: amount}}}
}
