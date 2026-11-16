package commerceprivilege

import (
	"context"
	"encoding/json"
	"math"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/directorysync"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	tapOperationClass = "I9_10G_CHARGE_TAP"
	tapResultSchema   = "gxb.commerce.charge-tap.v1"
	tapIssuer         = "player-tap"
	tapReason         = "recharge tap, PRIVATE_POLICY D455"
	rechargeEventMID  = 36857
	maxIntentLength   = 64
)

type ChargeStore interface {
	Store
	ReadPurchaseCountTx(context.Context, tx.Queryer, identity.PlayerID, int64) (int64, error)
	SavePurchaseTx(context.Context, tx.Tx, identity.PlayerID, int64, int64) error
	LockCardsTx(context.Context, tx.Queryer, identity.PlayerID) (d.Cards, error)
	SaveCardsTx(context.Context, tx.Tx, identity.PlayerID, d.Cards, time.Time) error
	ChargeTuningTx(context.Context, tx.Queryer) (d.ChargeTuning, bool, error)
	ReadPurchasesTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Purchase, error)
	ClaimVIPAwardTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (bool, error)
}

type ChargeContent interface {
	ManualContent
	ChargeCatalogTx(context.Context, tx.Queryer, string) (d.ChargeCatalog, error)
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type Facts interface {
	PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error)
}

type Grants interface {
	SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error)
	CrystalBalanceTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (int64, error)
}

// Charge owns the recharge tap (I9_COMMERCE_CHARGE_V1 C8).
type Charge struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Fence       Fence
	Facts       Facts
	Store       ChargeStore
	Content     ChargeContent
	Grants      Grants
	Effects     i5.PrivilegeTransitionPort
	Directory   directorysync.VIPProjectionPort
	Receipts    receipt.Store
	ReceiptRead receipt.Reader
}

type TapRequest struct {
	ChargeID int64  `json:"charge_id"`
	IntentID string `json:"intent_id"`
}

func (q TapRequest) valid() bool {
	if q.ChargeID <= 0 || q.IntentID == "" || len(q.IntentID) > maxIntentLength {
		return false
	}
	for _, r := range q.IntentID {
		if r < '!' || r > '~' {
			return false
		}
	}
	return true
}

func (s Charge) ready() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Fence != nil && s.Facts != nil && s.Store != nil && s.Content != nil && s.Grants != nil && s.Effects != nil && s.Directory != nil && s.Receipts != nil && s.ReceiptRead != nil
}

func tapProfile() tx.Profile {
	return tx.Profile{Name: "charge-tap", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 45 * time.Second}
}

func tapRetry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 6, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

type timedReceipt struct{ receipt.Resolver }

func (r timedReceipt) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation(), CommitError: q.CommitError, Attempt: q.Attempt})
}

func (s Charge) pin(c context.Context, op operation.Context) (operation.Context, string, error) {
	if revision, bound := op.Policies.Get("content"); bound {
		return op, revision, nil
	}
	revision, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return op, "", e
	}
	op.Policies, e = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})...)
	return op, revision, e
}

// Tap settles one purchase. Replaying an intent returns the stored reply; the
// same intent with another product is a receipt conflict. Lock ranks ascend:
// fence 315, commerce rows, grant 700 and 720, transition 721 and 730, directory 740.
func (s Charge) Tap(c context.Context, a identity.ActorContext, q TapRequest, op operation.Context) (map[string]any, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	if !q.valid() {
		return nil, d.ErrChargeRefused
	}
	op, revision, e := s.pin(c, op)
	if e != nil {
		return nil, e
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "commerce-charge", Operation: "tap", SemanticKey: q.IntentID}
	fingerprint, e := receipt.FingerprintRequest(struct {
		Player identity.PlayerID
		Server identity.LogicalServerID
		Charge int64
	}{a.PlayerID, a.LogicalServerID, q.ChargeID})
	if e != nil {
		return nil, e
	}
	var out map[string]any
	_, result, e := s.Timed.Run(c, op, tapProfile(), tx.Options{Isolation: tx.Serializable}, tapRetry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		stored, found, e := s.Receipts.FindTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if found {
			if stored.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(stored.ResultPayload, &out)
		}
		out, e = s.settle(c, sc, a, q, revision, at)
		if e != nil {
			return e
		}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		r, e := receipt.New(sc.Operation.Operation(), id, tapOperationClass, tapResultSchema, raw, fingerprint)
		if e != nil {
			return e
		}
		r.PolicyVersion, r.ActorAccountUID, r.ContextID = d.TapPolicy, string(a.AccountUID), a.ContextID.UUID()
		_, e = s.Receipts.PutTx(c, sc.Tx, r)
		return e
	})
	if e == nil && result.Reconciled {
		stored, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, d.ErrUnavailable
		}
		e = json.Unmarshal(stored.ResultPayload, &out)
	}
	return out, e
}

func (s Charge) settle(c context.Context, sc gen.TimedScope, a identity.ActorContext, q TapRequest, revision string, at time.Time) (map[string]any, error) {
	catalog, e := s.Content.ChargeCatalogTx(c, sc.Tx, revision)
	if e != nil {
		return nil, e
	}
	product, ok := catalog.Product(q.ChargeID)
	if !ok {
		return nil, d.ErrChargeRefused
	}
	root, rooted, e := s.Store.ReadPrivilegeTx(c, sc.Tx, a.PlayerID, true)
	if e != nil {
		return nil, e
	}
	prior, e := s.Store.ReadPurchaseCountTx(c, sc.Tx, a.PlayerID, q.ChargeID)
	if e != nil {
		return nil, e
	}
	cards, e := s.Store.LockCardsTx(c, sc.Tx, a.PlayerID)
	if e != nil {
		return nil, e
	}
	c, e = s.Facts.PrepareTx(c, sc.Tx, a.PlayerID, sc.Operation)
	if e != nil {
		return nil, e
	}
	tuning, tuned, e := s.Store.ChargeTuningTx(c, sc.Tx)
	if e != nil {
		return nil, e
	}
	decided, e := d.DecideGrant(product, prior, tuning, tuned)
	if e != nil {
		return nil, e
	}
	next, oldCap, newCap, e := s.transition(c, sc.Tx, a, root, rooted, decided.VIPXP, revision, at)
	if e != nil {
		return nil, e
	}
	now := at.Unix()
	nextCards := cards.Extended(decided.Card, decided.CardDays, now)
	if cards.PrivilegeActive(now) {
		oldCap += catalog.PrivilegeSkillMax
	}
	if nextCards.PrivilegeActive(now) {
		newCap += catalog.PrivilegeSkillMax
	}
	if decided.Crystal > 0 {
		current := sc.Operation.Operation()
		plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "commerce-charge", Operation: "tap", BusinessKey: q.IntentID, Occurrence: current.ID.String(), PolicyVersion: d.TapPolicy}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: decided.Crystal}}}
		if _, e = s.Grants.SettleGrantTx(c, sc.Tx, a, plan, current, i5.GrantTxOptions{}); e != nil {
			return nil, e
		}
	}
	total, e := s.Grants.CrystalBalanceTx(c, sc.Tx, a.PlayerID, at)
	if e != nil {
		return nil, e
	}
	effect, e := s.Effects.PreparePrivilegeTransitionTx(c, sc.Tx, a.PlayerID, oldCap, newCap, next.VIPLevel, at)
	if e != nil {
		return nil, e
	}
	directory, e := s.Directory.PrepareVIPProjectionTx(c, sc.Tx, a.PlayerID, next.VIPLevel, at)
	if e != nil {
		return nil, e
	}
	if e = s.Store.SavePrivilegeTx(c, sc.Tx, next.StateVersion-1, next); e != nil {
		return nil, e
	}
	if e = s.Store.SavePurchaseTx(c, sc.Tx, a.PlayerID, q.ChargeID, now); e != nil {
		return nil, e
	}
	if e = s.Store.SaveCardsTx(c, sc.Tx, a.PlayerID, nextCards, at); e != nil {
		return nil, e
	}
	if e = effect.Apply(c, sc.Tx); e != nil {
		return nil, e
	}
	if e = directory.Apply(c, sc.Tx); e != nil {
		return nil, e
	}
	balances, functions := changes.Recorded(c)
	body := map[string]any{"recharge_event": map[string]any{"mid": rechargeEventMID, "params": tapParams(q, decided, next, nextCards, total, balances, now)}}
	changes.WriteEconomy(body, balances)
	changes.WriteFunctions(body, functions)
	return body, nil
}

// transition derives the next root and the VIP skill caps on either side of it;
// the old root keeps its own content revision (a new revision cannot reinterpret it).
func (s Charge) transition(c context.Context, q tx.Queryer, a identity.ActorContext, old d.State, rooted bool, xp int64, revision string, at time.Time) (d.State, int64, int64, error) {
	catalog, e := s.Content.PrivilegeCatalogTx(c, q, revision)
	if e != nil {
		return d.State{}, 0, 0, e
	}
	next := d.State{PlayerID: a.PlayerID, LogicalServerID: a.LogicalServerID, Charge: xp, MonthlyState: d.MonthlyAbsent, ContentRevision: revision, PolicyVersion: d.TapPolicy, OriginClass: d.TapClass, Issuer: tapIssuer, Reason: tapReason, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	oldCap := int64(10)
	if rooted {
		oldCatalog, e := s.Content.PrivilegeCatalogTx(c, q, old.ContentRevision)
		if e != nil {
			return d.State{}, 0, 0, e
		}
		tooLarge := old.Charge > math.MaxInt64-xp || old.StateVersion == math.MaxInt64
		// The root row is locked, so a later UpdatedAt is a concurrent winner's
		// write, not a future fact: keep timestamps monotone instead of refusing.
		if old.Validate() != nil || old.ValidateCatalog(oldCatalog) != nil || old.LogicalServerID != a.LogicalServerID || tooLarge {
			return d.State{}, 0, 0, d.ErrConflict
		}
		if old.UpdatedAt.After(next.UpdatedAt) {
			next.UpdatedAt = old.UpdatedAt
		}
		if oldCap, e = oldCatalog.SkillCap(old.VIPLevel); e != nil {
			return d.State{}, 0, 0, e
		}
		next.Charge, next.CreatedAt, next.StateVersion = old.Charge+xp, old.CreatedAt, old.StateVersion+1
	}
	if next.VIPLevel, e = catalog.Derive(next.Charge); e != nil {
		return d.State{}, 0, 0, e
	}
	newCap, e := catalog.SkillCap(next.VIPLevel)
	if e != nil {
		return d.State{}, 0, 0, e
	}
	return next, oldCap, newCap, nil
}

// tapParams are the fields stock onRecharge_ reads (SelfPlayer.lua:2826-2932);
// nil items makes it open RECHARGE_SUC with delta.
func tapParams(q TapRequest, g d.ChargeGrant, s d.State, cards d.Cards, total int64, balances map[string]int64, now int64) map[string]any {
	return map[string]any{"charge_id": q.ChargeID, "delta": g.Crystal, "total": total, "vip": s.VIPLevel, "charge": s.Charge, "economy": balances,
		"left_card_day": d.LeftDays(cards.MonthCardEnd, now), "left_week_card_day": int64(0), "left_month_tili_day": int64(0),
		"privilege_left_card_day": d.LeftDays(cards.PrivilegeCardEnd, now), "privilege_month_card_end": cards.PrivilegeCardEnd,
		"month_card_start": cards.MonthCardStart, "month_card_end": cards.MonthCardEnd}
}
