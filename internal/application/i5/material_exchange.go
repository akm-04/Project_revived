package i5

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	// ErrMaterialExchangeResourceCollision is fail-closed. The currently
	// qualified CA4 promotion sources never require debit/credit netting of the
	// same I5 identity, so silently inventing net semantics would exceed source
	// authority.
	ErrMaterialExchangeResourceCollision = errors.New("material exchange debit/restoration resource collision")
	// ErrMaterialExchangeGrantAlreadySettled means the inner restoration
	// entitlement already has terminal receipt evidence while the caller is
	// trying to prepare/apply a fresh outer Character transition. Debiting in
	// this state would destroy exactly-once composition, so the seam fails.
	ErrMaterialExchangeGrantAlreadySettled = errors.New("material exchange restoration grant already settled")
)

// MaterialExchangeRequest is the narrow CA4-1 mixed I5 composition surface.
// Restoration is deliberately restricted to stack-item Grant lines. Character
// owners keep durable transition authority; I5 owns all fungible debit/credit
// truth and overflow-to-Mail behavior.
// MaterialCredit is an I5-owned named-scalar credit paid in the same union as a
// material cost when immutable content defines no resource row for it (the Tea
// Party friend_medal reward, I9_GUILD_ACTIVITY_V1 C14). The amount is the
// caller's policy, never content.
type MaterialCredit struct {
	ResourceKey string
	Amount      int64
}

type preparedMaterialCredit struct {
	next   economy.ScalarBalance
	exists bool
}

type MaterialExchangeRequest struct {
	Cost              MaterialCost
	Restoration       grant.Plan
	Credits           []MaterialCredit
	AllowOverflowMail bool
}

// MaterialExchangeResult contains only I5-owned effects. The caller persists
// its Character mutation and outer semantic receipt in the same transaction.
type MaterialExchangeResult struct {
	Debit       MaterialDebitResult
	Restoration GrantResult
}

// PreparedMaterialExchange is intentionally opaque outside package i5. It is a
// closed D01 plan: Apply must not discover a new lock identity.
type PreparedMaterialExchange struct {
	playerID         identity.PlayerID
	actor            identity.ActorContext
	op               operation.Context
	request          MaterialExchangeRequest
	contentRevision  string
	grantPreflight   grantPreflight
	grantIdentity    receipt.Identity
	grantFingerprint [32]byte
	preparedDebit    MaterialDebitResult
	preparedCredits  []preparedMaterialCredit
}

// TxMaterialExchange is the I5-owned Prepare/Apply seam introduced by CA4-1.
// It never begins/commits/retries a transaction and exposes no Store/SQL/raw
// lock key to Character callers.
type TxMaterialExchange interface {
	PrepareMaterialExchangeTx(context.Context, tx.Tx, identity.ActorContext, MaterialExchangeRequest, operation.Context) (*PreparedMaterialExchange, error)
	ApplyMaterialExchangeTx(context.Context, tx.Tx, *PreparedMaterialExchange) (MaterialExchangeResult, error)
}

var _ TxMaterialExchange = Service{}

func validateStackOnlyRestoration(plan grant.Plan) error {
	if err := plan.Validate(); err != nil {
		return err
	}
	for i, line := range plan.Lines {
		if line.Kind != grant.StackItem {
			return fmt.Errorf("material exchange restoration line %d is not stack item", i)
		}
	}
	return nil
}

// validateExchangeRestoration keeps the CA4-1 stack-only shape and adds the
// scalar credits a caller-owned mixed cost needs (I9-9A Tea Party pays a
// friend-medal scalar for a stack debit). Other destinations stay refused.
func validateExchangeRestoration(plan grant.Plan) error {
	if err := plan.Validate(); err != nil {
		return err
	}
	for i, line := range plan.Lines {
		if line.Kind != grant.StackItem && line.Kind != grant.ScalarCurrency {
			return fmt.Errorf("material exchange restoration line %d is not a supported credit", i)
		}
	}
	return nil
}

func validateMaterialCredits(credits []MaterialCredit) error {
	seen := make(map[string]struct{}, len(credits))
	for _, credit := range credits {
		if credit.ResourceKey == "" || credit.Amount <= 0 {
			return errors.New("invalid material credit")
		}
		if _, exists := seen[credit.ResourceKey]; exists {
			return errors.New("duplicate material credit")
		}
		seen[credit.ResourceKey] = struct{}{}
	}
	return nil
}

func rejectMaterialExchangeCollisions(cost MaterialCost, plan grant.Plan) error {
	debits := make(map[int64]struct{}, len(cost.Stacks))
	for _, x := range cost.Stacks {
		debits[x.ItemID] = struct{}{}
	}
	for _, line := range plan.Lines {
		if _, exists := debits[line.ItemID]; exists {
			return fmt.Errorf("%w: stack item %d", ErrMaterialExchangeResourceCollision, line.ItemID)
		}
	}
	return nil
}

// PrepareMaterialExchangeTx closes and acquires the complete I5 lock union
// before any canonical mutation. Re-locking an identity already represented in
// the opaque plan is allowed; discovering a new identity later is not.
func (s Service) PrepareMaterialExchangeTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, req MaterialExchangeRequest, op operation.Context) (*PreparedMaterialExchange, error) {
	if err := s.validate(); err != nil {
		return nil, err
	}
	if t == nil || !actor.PlayerID.Valid() {
		return nil, errors.New("material exchange transaction/actor required")
	}
	if req.Restoration.PlayerID != 0 && req.Restoration.PlayerID != actor.PlayerID {
		return nil, errors.New("material exchange actor/player mismatch")
	}
	if err := req.Cost.validate(); err != nil {
		return nil, err
	}
	if err := validateMaterialCredits(req.Credits); err != nil {
		return nil, err
	}
	hasRestoration := req.Restoration.PlayerID != 0
	if !hasRestoration && len(req.Credits) == 0 {
		return nil, errors.New("material exchange has no restoration or credit")
	}
	if hasRestoration {
		if err := validateExchangeRestoration(req.Restoration); err != nil {
			return nil, err
		}
		if err := rejectMaterialExchangeCollisions(req.Cost, req.Restoration); err != nil {
			return nil, err
		}
	}

	contentRevision, err := requireContentRevision(op)
	if err != nil {
		return nil, err
	}
	now := op.StartedAt.UTC()
	if now.IsZero() {
		return nil, errors.New("material exchange requires operation time")
	}

	var grantID receipt.Identity
	var grantFP [32]byte
	if hasRestoration {
		grantID, _, err = req.Restoration.ReceiptIdentities()
		if err != nil {
			return nil, err
		}
		grantFP, err = receiptFingerprintForGrant(req.Restoration)
		if err != nil {
			return nil, err
		}
		// Fail before acquiring debit locks when the nested entitlement already has
		// terminal evidence. I5 must never "skip grant but still debit".
		if _, ok, err := s.findGrantReceiptTx(ctx, t, req.Restoration, grantFP); err != nil {
			return nil, err
		} else if ok {
			return nil, ErrMaterialExchangeGrantAlreadySettled
		}
	}

	debiter := MaterialCostDebiter{Store: s.Store, Content: s.Content}
	costPF, err := debiter.preflightMaterialCostTx(ctx, t, actor.PlayerID, req.Cost, op)
	if err != nil {
		return nil, err
	}
	var grantPF grantPreflight
	if hasRestoration {
		grantPF, err = s.preflightGrantTx(ctx, t, req.Restoration, contentRevision, grantPreflightOptions{AllowOverflowMail: req.AllowOverflowMail}, now)
		if err != nil {
			return nil, err
		}
	}
	union := make([]grantLockRequirement, 0, len(costPF.Locks)+len(grantPF.Locks)+len(req.Credits)+1)
	union = append(union, costPF.Locks...)
	union = append(union, grantPF.Locks...)
	if len(req.Credits) > 0 {
		if err := appendGrantLock(&union, grantLockRankEconomyOwner, "i5.economy-owner", lockkey.Int64(int64(actor.PlayerID)), grantLockEconomyOwner, "", 0, 0); err != nil {
			return nil, err
		}
		for _, credit := range req.Credits {
			if err := appendGrantLock(&union, grantLockRankScalar, "i5.scalar", grantChildIdentity(actor.PlayerID, credit.ResourceKey), grantLockScalar, credit.ResourceKey, 0, 0); err != nil {
				return nil, err
			}
		}
	}
	union, err = canonicalGrantLockRequirements(union)
	if err != nil {
		return nil, err
	}
	grantPF.Locks = union

	// acquireGrantLocksTx understands the complete I5 D01 lock vocabulary. Debit
	// existence/amount is checked below while those already-planned locks remain
	// held.
	if err := s.acquireGrantLocksTx(ctx, t, actor.PlayerID, grantPF, now); err != nil {
		return nil, err
	}
	// A waiter may have observed no receipt before blocking and resume after a
	// winning transaction commits. Recheck while the complete union is held.
	if hasRestoration {
		if _, ok, err := s.findGrantReceiptTx(ctx, t, req.Restoration, grantFP); err != nil {
			return nil, err
		} else if ok {
			return nil, ErrMaterialExchangeGrantAlreadySettled
		}
	}
	preparedDebit, err := debiter.prepareMaterialDebitStateTx(ctx, t, actor.PlayerID, costPF)
	if err != nil {
		return nil, err
	}
	preparedCredits, err := s.prepareMaterialCreditsTx(ctx, t, actor.PlayerID, req.Credits, now)
	if err != nil {
		return nil, err
	}

	return &PreparedMaterialExchange{
		playerID:         actor.PlayerID,
		actor:            actor,
		op:               op,
		request:          req,
		contentRevision:  contentRevision,
		grantPreflight:   grantPF,
		grantIdentity:    grantID,
		grantFingerprint: grantFP,
		preparedDebit:    preparedDebit,
		preparedCredits:  preparedCredits,
	}, nil
}

// prepareMaterialCreditsTx computes named-scalar credits on locks already held
// by Prepare; it writes nothing and acquires nothing.
func (s Service) prepareMaterialCreditsTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, credits []MaterialCredit, now time.Time) ([]preparedMaterialCredit, error) {
	out := make([]preparedMaterialCredit, 0, len(credits))
	for _, credit := range credits {
		current, exists, err := s.Store.LockScalarTx(ctx, t, pid, credit.ResourceKey, now)
		if err != nil {
			return nil, err
		}
		if !exists {
			current = economy.ScalarBalance{PlayerID: pid, ResourceKey: credit.ResourceKey, Amount: credit.Amount, StateVersion: 1, UpdatedAt: now}
			if err := current.Validate(); err != nil {
				return nil, err
			}
			out = append(out, preparedMaterialCredit{next: current, exists: false})
			continue
		}
		next, err := current.Credit(credit.Amount, now)
		if err != nil {
			return nil, err
		}
		out = append(out, preparedMaterialCredit{next: next, exists: true})
	}
	return out, nil
}

// ApplyMaterialExchangeTx applies only the identities/effects closed by
// Prepare. Transaction rollback remains the atomicity boundary if any write or
// receipt persistence fails.
func (s Service) ApplyMaterialExchangeTx(ctx context.Context, t tx.Tx, prepared *PreparedMaterialExchange) (MaterialExchangeResult, error) {
	if err := s.validate(); err != nil {
		return MaterialExchangeResult{}, err
	}
	if t == nil || prepared == nil || !prepared.playerID.Valid() {
		return MaterialExchangeResult{}, errors.New("prepared material exchange required")
	}
	if prepared.request.Restoration.PlayerID != 0 {
		// Defensive same-transaction replay check before the first write.
		if _, ok, err := s.findGrantReceiptTx(ctx, t, prepared.request.Restoration, prepared.grantFingerprint); err != nil {
			return MaterialExchangeResult{}, err
		} else if ok {
			return MaterialExchangeResult{}, ErrMaterialExchangeGrantAlreadySettled
		}
	}

	debiter := MaterialCostDebiter{Store: s.Store, Content: s.Content}
	if err := debiter.applyPreparedMaterialDebitTx(ctx, t, prepared.preparedDebit); err != nil {
		return MaterialExchangeResult{}, err
	}
	var gr GrantResult
	if prepared.request.Restoration.PlayerID != 0 {
		var err error
		gr, err = s.applyPreparedGrantTx(ctx, t, prepared.actor, prepared.request.Restoration, prepared.op, GrantTxOptions{AllowOverflowMail: prepared.request.AllowOverflowMail}, prepared.contentRevision, prepared.grantPreflight, prepared.grantIdentity, prepared.grantFingerprint)
		if err != nil {
			return MaterialExchangeResult{}, err
		}
	}
	// Named-scalar credits are prepared under the union locks; Apply only saves
	// the frozen states and acquires nothing.
	for _, credit := range prepared.preparedCredits {
		if err := s.Store.SaveScalarTx(ctx, t, credit.next, credit.exists); err != nil {
			return MaterialExchangeResult{}, err
		}
	}
	return MaterialExchangeResult{Debit: prepared.preparedDebit, Restoration: gr}, nil
}
