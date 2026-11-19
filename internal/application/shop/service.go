// Package shop owns the I9-11C core-shop commands. Every write is one
// transaction on the LEAD_SEAMS_I9-11 V2 money path: fence, player root 315,
// shop row 460, the I5 exchange suffix, then the state save and receipt.
package shop

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	achd "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ResultSchema is the stored reply schema of every 11C receipt.
const ResultSchema = "gxb.shop.command.v1"

type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ShopCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

type Store interface {
	LockShopTx(context.Context, tx.Tx, identity.PlayerID, int64) (d.Row, bool, error)
	InsertShopTx(context.Context, tx.Tx, d.Row) error
	SaveShopTx(context.Context, tx.Tx, d.Row) error
	TuningTx(context.Context, tx.Queryer) (d.Tuning, bool, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

type Exchange interface {
	PrepareItemsEnergyExchangeTx(context.Context, tx.Tx, identity.ActorContext, appi5.ItemsEnergyExchangeRequest, operation.Context) (*appi5.PreparedItemsEnergyExchange, error)
	ApplyItemsEnergyExchangeTx(context.Context, tx.Tx, *appi5.PreparedItemsEnergyExchange) (appi5.ItemsEnergyExchangeResult, error)
}

// Debiter is the I5-owned debit-only seam a paid refresh uses: a refresh grants
// no item, so the exchange pair would need a fabricated restoration.
type Debiter interface {
	PrepareMaterialDebitTx(context.Context, tx.Tx, identity.PlayerID, appi5.MaterialCost, operation.Context) (*appi5.PreparedMaterialDebit, error)
	ApplyMaterialDebitTx(context.Context, tx.Tx, *appi5.PreparedMaterialDebit) (appi5.MaterialDebitResult, error)
}

// Achievements is the 11E C7 typed port; a purchase calls it once inside the
// settling transaction and it writes only achievement rows.
type Achievements interface {
	ObserveShopPurchaseTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error
}

// ObjectiveFacts is the objective-fact port; a purchase that debits crystal
// reports one SHOP_PURCHASE fact inside the settling transaction (C4).
type ObjectiveFacts interface {
	RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error
}

type Balances interface {
	ReadStackTx(context.Context, tx.Queryer, identity.PlayerID, int64) (economy.StackState, bool, error)
	ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error)
}

type Privileges interface {
	SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (appi5.PrivilegeSnapshot, error)
}

type Progression interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}

type Functions interface {
	ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error)
}

// TeamShops is the guild campaign's team-shop availability rule: the chapter
// that owns the shop is open, at chapter_version 2, and the member joined
// before the run started (11C C3/C12).
type TeamShops interface {
	TeamShopEligibleTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error)
}

type Receipts interface {
	FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error)
	PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error)
}

// Service is the I9-11C command owner.
type Service struct {
	Timed        gen.TimedRunner
	Fresh        tx.Queryer
	Content      Content
	Store        Store
	Fence        Fence
	Players      Players
	Exchange     Exchange
	Debiter      Debiter
	Balances     Balances
	Privileges   Privileges
	Progression  Progression
	Functions    Functions
	TeamShops    TeamShops
	Achievements Achievements
	Facts        ObjectiveFacts
	Receipts     Receipts
	ReceiptRead  receipt.Reader
}

func Profile() tx.Profile {
	return tx.Profile{Name: "shop", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

func (s Service) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Content != nil &&
		s.Store != nil && s.Fence != nil && s.Players != nil && s.Exchange != nil && s.Debiter != nil && s.Achievements != nil && s.Facts != nil && s.Balances != nil &&
		s.Privileges != nil && s.Progression != nil && s.Functions != nil && s.Receipts != nil && s.ReceiptRead != nil
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

// execute is the receipted write path. The receipt carries the stored reply so
// an R6 replay and a receipt retry return the committed answer.
func (s Service) execute(c context.Context, a identity.ActorContext, op operation.Context, name string, request any, body func(context.Context, gen.TimedScope, d.Catalog) (map[string]any, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	if !a.PlayerID.Valid() || s.ReceiptRead == nil {
		return nil, d.ErrInvalid
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "shop", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	var overlay policy.Ref
	var hasOverlay bool
	_, result, err := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.ReadCommitted}, retry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		if err := s.begin(c, sc, a); err != nil {
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
		catalog, err := s.catalog(c, sc)
		if err != nil {
			return err
		}
		if catalog.Tuning.Revision != "" {
			overlay, hasOverlay = policy.Ref{Name: "shop-overlay", Version: catalog.Tuning.Revision + ":" + catalog.Tuning.Digest}, true
		}
		out, err = body(c, sc, catalog)
		if err != nil {
			return err
		}
		raw, err := json.Marshal(out)
		if err != nil {
			return err
		}
		entry, err := receipt.New(sc.Operation.Operation(), id, d.ReceiptClass, ResultSchema, raw, fingerprint)
		if err != nil {
			return err
		}
		entry.PolicyVersion, entry.ActorAccountUID, entry.ContextID = d.PolicyID, string(a.AccountUID), a.ContextID.UUID()
		if hasOverlay {
			entry.OperationPolicyRefs, err = policy.NewSet(append(entry.OperationPolicyRefs.Refs(), overlay)...)
			if err != nil {
				return err
			}
		}
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

// run executes a non-receipted command (MID 32 may write the first generation).
func (s Service) run(c context.Context, a identity.ActorContext, op operation.Context, readOnly bool, body func(context.Context, gen.TimedScope, d.Catalog) (map[string]any, error)) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	if !a.PlayerID.Valid() {
		return nil, d.ErrInvalid
	}
	// C1-3: a handler that writes nothing runs one REPEATABLE READ READ ONLY snapshot.
	isolation := tx.ReadCommitted
	if readOnly {
		isolation = tx.RepeatableRead
	}
	var out map[string]any
	_, _, err = s.Timed.Run(c, op, Profile(), tx.Options{Isolation: isolation, ReadOnly: readOnly}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		if !readOnly {
			if err := s.begin(c, sc, a); err != nil {
				return err
			}
		}
		catalog, err := s.catalog(c, sc)
		if err != nil {
			return err
		}
		out, err = body(c, sc, catalog)
		return err
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (s Service) begin(c context.Context, sc gen.TimedScope, a identity.ActorContext) error {
	if err := s.Fence.FenceActorTx(c, sc.Tx, a, sc.Operation.DecisionAt()); err != nil {
		return err
	}
	_, err := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
	return err
}

// catalog loads the pinned catalog and applies a valid D476 overlay. An absent
// or invalid overlay keeps the source catalog in force.
func (s Service) catalog(c context.Context, sc gen.TimedScope) (d.Catalog, error) {
	revision, ok := sc.Operation.Operation().Policies.Get("content")
	if !ok {
		return d.Catalog{}, d.ErrUnavailable
	}
	catalog, err := s.Content.ShopCatalogTx(c, sc.Tx, revision)
	if err != nil {
		return d.Catalog{}, err
	}
	tuning, found, err := s.Store.TuningTx(c, sc.Tx)
	if err != nil || !found {
		return catalog, nil
	}
	if err = d.ValidateTuning(catalog, tuning); err != nil {
		return catalog, nil
	}
	catalog.Tuning = tuning
	return catalog, nil
}

func (s Service) day(sc gen.TimedScope) int64 {
	return modes.Day(sc.Operation.DecisionAt())
}

// available revalidates the function gate. A team shop is listed and served
// only while the guild campaign's team predicate agrees, on every read.
func (s Service) available(c context.Context, sc gen.TimedScope, pid identity.PlayerID, shop d.Shop) (bool, error) {
	if shop.Team {
		if s.TeamShops == nil {
			return false, nil
		}
		return s.TeamShops.TeamShopEligibleTx(c, sc.Tx, pid, shop.HomologousID)
	}
	if shop.FunctionID <= 0 {
		return true, nil
	}
	_, eligible, err := s.Functions.ReadFunctionEligibilityTx(c, sc.Tx, pid, shop.FunctionID)
	if err != nil {
		return false, err
	}
	return eligible, nil
}

func (s Service) level(c context.Context, sc gen.TimedScope, pid identity.PlayerID) (int64, error) {
	progression, err := s.Progression.ReadProgressionTx(c, sc.Tx, pid)
	if err != nil {
		return 0, err
	}
	return progression.Level, nil
}

func (s Service) monthCard(c context.Context, sc gen.TimedScope, pid identity.PlayerID, shopType int64) (bool, error) {
	if shopType != 4 && shopType != 5 {
		return false, nil
	}
	snapshot, err := s.Privileges.SnapshotTx(c, sc.Tx, pid, sc.Operation.DecisionAt())
	if err != nil {
		return false, err
	}
	return snapshot.MonthCardActive, nil
}

// state loads and, when needed, generates this player's stock generation. The
// player root lock taken by begin serialises concurrent first generations.
func (s Service) state(c context.Context, sc gen.TimedScope, catalog d.Catalog, shop d.Shop, pid identity.PlayerID) (d.Row, bool, bool, error) {
	now := sc.Operation.DecisionAt()
	day := s.day(sc)
	row, found, err := s.Store.LockShopTx(c, sc.Tx, pid, shop.Type)
	if err != nil {
		return d.Row{}, false, false, err
	}
	if !found {
		row = d.Row{PlayerID: pid, ShopType: shop.Type, StateVersion: 1, UpdatedAt: now.UTC()}
		if err = s.regenerate(c, sc, catalog, shop, &row, 1); err != nil {
			return d.Row{}, false, false, err
		}
		return row, true, true, nil
	}
	changed := row.NormaliseDay(day)
	if d.NeedsScheduledReroll(shop, row.Stock, now) {
		if err = s.regenerate(c, sc, catalog, shop, &row, row.Generation+1); err != nil {
			return d.Row{}, false, false, err
		}
		changed = true
	}
	return row, false, changed, nil
}

// currentState loads the player's frozen generation without generating one. A
// purchase never generates stock (A-139): a missing row or a generation that a
// source mark or game-day change would replace refuses as stale so the client
// reloads MID 32. The player root lock taken by begin serialises the check.
func (s Service) currentState(c context.Context, sc gen.TimedScope, shop d.Shop, pid identity.PlayerID) (d.Row, error) {
	row, found, err := s.Store.LockShopTx(c, sc.Tx, pid, shop.Type)
	if err != nil {
		return d.Row{}, err
	}
	if !found || d.NeedsScheduledReroll(shop, row.Stock, sc.Operation.DecisionAt()) {
		return d.Row{}, d.ErrStaleState
	}
	return row, nil
}

func (s Service) save(c context.Context, sc gen.TimedScope, row d.Row, insert bool) error {
	row.UpdatedAt = sc.Operation.DecisionAt().UTC()
	if insert {
		return s.Store.InsertShopTx(c, sc.Tx, row)
	}
	return s.Store.SaveShopTx(c, sc.Tx, row)
}

// regenerate freezes one generation from Operation.Derive("shop.stock/v1", generation).
func (s Service) regenerate(c context.Context, sc gen.TimedScope, catalog d.Catalog, shop d.Shop, row *d.Row, generation int64) error {
	level, err := s.level(c, sc, row.PlayerID)
	if err != nil {
		return err
	}
	stream := combat.NewStream(sc.Operation.Operation().Derive(d.EntropyLabel, uint64(generation)))
	slots, err := catalog.Generate(shop, level, stream)
	if err != nil {
		return err
	}
	day, mark := d.ScheduledMark(shop, sc.Operation.DecisionAt())
	row.Generation = generation
	row.Stock = d.Stock{ScheduleDay: day, ScheduleMark: mark, Slots: slots}
	return nil
}

func (s Service) observePurchase(c context.Context, sc gen.TimedScope, pid identity.PlayerID, crystal int64) error {
	revision, ok := sc.Operation.Operation().Policies.Get("content")
	if !ok {
		return d.ErrUnavailable
	}
	// The receipt guard runs this body once per operation, so a replay, a
	// refusal and a coin-only purchase record no fact. The fact is written
	// before the achievement rows, which lock last (LEAD_SEAMS_I9-11 V2 §2).
	if crystal > 0 {
		op := sc.Operation.Operation()
		fact := objective.Fact{PlayerID: pid, SourceDomain: "shop", SourceBusinessKey: op.ID.String(), Kind: objective.ShopPurchaseKind, Delta: crystal}
		if err := s.Facts.RecordTx(c, sc.Tx, op, fact); err != nil {
			return err
		}
	}
	err := s.Achievements.ObserveShopPurchaseTx(c, sc.Tx, pid, revision, sc.Operation.DecisionAt())
	// A purchase overtaken by a newer accepted one lost the race; the client
	// reloads. Every other achievement fault stays visible as a defect.
	if errors.Is(err, achd.ErrOvertaken) {
		return d.ErrStaleState
	}
	return err
}

func (s Service) record(c context.Context, sc gen.TimedScope, pid identity.PlayerID, applied appi5.ItemsEnergyExchangeResult) error {
	for _, balance := range applied.Debit.Scalars {
		changes.Balance(c, balance.ResourceKey, balance.Amount)
	}
	keys := map[string]struct{}{}
	for _, award := range applied.Restoration.Awards {
		if award.ResourceKey == "" {
			continue
		}
		keys[award.ResourceKey] = struct{}{}
	}
	for key := range keys {
		state, exists, err := s.Balances.ReadScalarTx(c, sc.Tx, pid, key)
		if err != nil {
			return err
		}
		if exists {
			changes.Balance(c, key, state.Amount)
		}
	}
	return nil
}

func recordDebit(c context.Context, debit appi5.MaterialDebitResult) {
	for _, balance := range debit.Scalars {
		changes.Balance(c, balance.ResourceKey, balance.Amount)
	}
}

func (s Service) rewardPlan(pid identity.PlayerID, name string, op operation.Context, lines []grant.Line) grant.Plan {
	return grant.Plan{
		PlayerID: pid,
		Source: grant.SourceIdentity{
			Domain: "shop", Operation: name, BusinessKey: op.ID.String(),
			Occurrence: op.ID.String(), PolicyVersion: d.PolicyID,
		},
		Lines: lines,
	}
}

func (s Service) stack(c context.Context, sc gen.TimedScope, pid identity.PlayerID, itemID int64) (int64, error) {
	state, exists, err := s.Balances.ReadStackTx(c, sc.Tx, pid, itemID)
	if err != nil {
		return 0, err
	}
	if !exists {
		return 0, nil
	}
	return state.Quantity, nil
}
