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
	ErrStrictRestorationAlreadySettled = errors.New("strict restoration grant already settled")
	ErrHeroPromotionResourceCollision  = errors.New("Hero promotion debit/restoration resource collision")
)

// StrictRestorationRequest is the reusable CA4 strict nested-Grant seam. Unlike
// SettleGrantTx, an already-terminal nested receipt is an inconsistent outer
// transition state and therefore fails closed instead of replaying.
type StrictRestorationRequest struct {
	Plan              grant.Plan
	AllowOverflowMail bool
}

type PreparedStrictRestoration struct {
	actor            identity.ActorContext
	op               operation.Context
	plan             grant.Plan
	allowOverflow    bool
	contentRevision  string
	grantPreflight   grantPreflight
	grantIdentity    receipt.Identity
	grantFingerprint [32]byte
	applied          bool
}

type TxStrictRestorationSettler interface {
	PrepareStrictRestorationTx(context.Context, tx.Tx, identity.ActorContext, StrictRestorationRequest, operation.Context) (*PreparedStrictRestoration, error)
	ApplyStrictRestorationTx(context.Context, tx.Tx, *PreparedStrictRestoration) (GrantResult, error)
}

func cloneGrantPlan(in grant.Plan) grant.Plan {
	out := in
	out.Lines = append([]grant.Line(nil), in.Lines...)
	return out
}

func (s Service) preflightStrictRestorationTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, req StrictRestorationRequest, op operation.Context) (*PreparedStrictRestoration, error) {
	if err := s.validate(); err != nil {
		return nil, err
	}
	if t == nil || !actor.PlayerID.Valid() || req.Plan.PlayerID != actor.PlayerID {
		return nil, errors.New("strict restoration transaction/actor required")
	}
	plan := cloneGrantPlan(req.Plan)
	if err := validateStackOnlyRestoration(plan); err != nil {
		return nil, err
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return nil, err
	}
	now := op.StartedAt.UTC()
	if now.IsZero() {
		return nil, errors.New("strict restoration requires operation time")
	}
	id, _, err := plan.ReceiptIdentities()
	if err != nil {
		return nil, err
	}
	fp, err := receiptFingerprintForGrant(plan)
	if err != nil {
		return nil, err
	}
	if _, ok, err := s.findGrantReceiptTx(ctx, t, plan, fp); err != nil {
		return nil, err
	} else if ok {
		return nil, ErrStrictRestorationAlreadySettled
	}
	pf, err := s.preflightGrantTx(ctx, t, plan, revision, grantPreflightOptions{AllowOverflowMail: req.AllowOverflowMail}, now)
	if err != nil {
		return nil, err
	}
	return &PreparedStrictRestoration{
		actor: actor, op: op, plan: plan, allowOverflow: req.AllowOverflowMail,
		contentRevision: revision, grantPreflight: pf, grantIdentity: id, grantFingerprint: fp,
	}, nil
}

func (s Service) PrepareStrictRestorationTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, req StrictRestorationRequest, op operation.Context) (*PreparedStrictRestoration, error) {
	prepared, err := s.preflightStrictRestorationTx(ctx, t, actor, req, op)
	if err != nil {
		return nil, err
	}
	if err := s.acquireGrantLocksTx(ctx, t, actor.PlayerID, prepared.grantPreflight, op.StartedAt.UTC()); err != nil {
		return nil, err
	}
	if _, ok, err := s.findGrantReceiptTx(ctx, t, prepared.plan, prepared.grantFingerprint); err != nil {
		return nil, err
	} else if ok {
		return nil, ErrStrictRestorationAlreadySettled
	}
	return prepared, nil
}

func (s Service) ApplyStrictRestorationTx(ctx context.Context, t tx.Tx, prepared *PreparedStrictRestoration) (GrantResult, error) {
	if err := s.validate(); err != nil {
		return GrantResult{}, err
	}
	if t == nil || prepared == nil || prepared.applied || !prepared.actor.PlayerID.Valid() {
		return GrantResult{}, errors.New("prepared strict restoration required")
	}
	if _, ok, err := s.findGrantReceiptTx(ctx, t, prepared.plan, prepared.grantFingerprint); err != nil {
		return GrantResult{}, err
	} else if ok {
		return GrantResult{}, ErrStrictRestorationAlreadySettled
	}
	out, err := s.applyPreparedGrantTx(ctx, t, prepared.actor, prepared.plan, prepared.op, prepared.allowOverflow, prepared.contentRevision, prepared.grantPreflight, prepared.grantIdentity, prepared.grantFingerprint)
	if err != nil {
		return GrantResult{}, err
	}
	prepared.applied = true
	return out, nil
}

var _ TxStrictRestorationSettler = Service{}

// HeroPromotionResourceRequest closes the complete bounded potential debit
// identity set before Character chooses the exact all-or-nothing MID57 plan.
// Restoration is optional because the collect-only branch creates no refund.
type HeroPromotionResourceRequest struct {
	PotentialStackItemIDs []int64
	Restoration           *grant.Plan
	AllowOverflowMail     bool
}

type PreparedHeroPromotionResources struct {
	actor             identity.ActorContext
	op                operation.Context
	contentRevision   string
	playerLevel       int64
	effectAt          time.Time
	mana              economy.ScalarBalance
	manaExists        bool
	stackIDs          []int64
	stacks            map[int64]preparedHeroEquipmentStack
	restoration       *PreparedStrictRestoration
	combinedGrantPlan grantPreflight
	applied           bool
}

func (p *PreparedHeroPromotionResources) PlayerLevel() int64 {
	if p == nil {
		return 0
	}
	return p.playerLevel
}
func (p *PreparedHeroPromotionResources) Mana() int64 {
	if p == nil || !p.manaExists {
		return 0
	}
	return p.mana.Amount
}
func (p *PreparedHeroPromotionResources) StackQuantity(itemID int64) (int64, bool) {
	if p == nil {
		return 0, false
	}
	st, ok := p.stacks[itemID]
	if !ok {
		return 0, false
	}
	if !st.exists {
		return 0, true
	}
	return st.state.Quantity, true
}
func (p *PreparedHeroPromotionResources) PreparedStackItemIDs() []int64 {
	if p == nil {
		return nil
	}
	return append([]int64(nil), p.stackIDs...)
}
func (p *PreparedHeroPromotionResources) HasRestoration() bool {
	return p != nil && p.restoration != nil
}

type HeroPromotionResourceResult struct {
	Debit       HeroEquipmentResourceResult
	Restoration *GrantResult
}

type TxHeroPromotionResourceSettler interface {
	PrepareHeroPromotionResourcesTx(context.Context, tx.Tx, identity.ActorContext, HeroPromotionResourceRequest, operation.Context) (*PreparedHeroPromotionResources, error)
	ApplyHeroPromotionResourcesTx(context.Context, tx.Tx, *PreparedHeroPromotionResources, HeroEquipmentResourceDebit) (HeroPromotionResourceResult, error)
}

func promotionPotentialCollision(ids []int64, plan *grant.Plan) error {
	if plan == nil {
		return nil
	}
	set := make(map[int64]struct{}, len(ids))
	for _, id := range ids {
		set[id] = struct{}{}
	}
	for _, line := range plan.Lines {
		if _, ok := set[line.ItemID]; ok {
			return fmt.Errorf("%w: stack item %d", ErrHeroPromotionResourceCollision, line.ItemID)
		}
	}
	return nil
}

func appendPromotionBaseLocks(reqs *[]grantLockRequirement, pid identity.PlayerID, ids []int64) error {
	if err := appendGrantLock(reqs, grantLockRankEconomyOwner, "i5.economy-owner", lockkey.Int64(int64(pid)), grantLockEconomyOwner, "", 0, 0); err != nil {
		return err
	}
	if err := appendGrantLock(reqs, grantLockRankProgression, "i5.progression", lockkey.Int64(int64(pid)), grantLockProgression, "", 0, 0); err != nil {
		return err
	}
	if err := appendGrantLock(reqs, grantLockRankScalar, "i5.scalar", grantChildIdentity(pid, "mana"), grantLockScalar, "mana", 0, 0); err != nil {
		return err
	}
	for _, itemID := range ids {
		if err := appendGrantLock(reqs, grantLockRankStack, "i5.stack", grantChildIdentity(pid, fmt.Sprintf("%d", itemID)), grantLockStack, "", itemID, 0); err != nil {
			return err
		}
	}
	return nil
}

func (s Service) PrepareHeroPromotionResourcesTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, req HeroPromotionResourceRequest, op operation.Context) (*PreparedHeroPromotionResources, error) {
	if err := s.validate(); err != nil {
		return nil, err
	}
	if t == nil || !actor.PlayerID.Valid() || op.StartedAt.IsZero() || s.Content == nil {
		return nil, errors.New("i5 Hero promotion prepare: invalid input")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return nil, err
	}
	ids, err := canonicalHeroEquipmentStackIDs(req.PotentialStackItemIDs)
	if err != nil {
		return nil, err
	}
	if err := promotionPotentialCollision(ids, req.Restoration); err != nil {
		return nil, err
	}
	for _, itemID := range ids {
		rp, err := s.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: 1})
		if err != nil {
			return nil, err
		}
		if rp.Kind != grant.StackItem || rp.Stack == nil || rp.Stack.ItemID != itemID {
			return nil, economy.ErrUnknownResource
		}
	}
	manaPolicy, err := s.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 1})
	if err != nil {
		return nil, err
	}
	if manaPolicy.Kind != grant.ScalarCurrency {
		return nil, economy.ErrUnknownResource
	}

	var strict *PreparedStrictRestoration
	if req.Restoration != nil {
		plan := cloneGrantPlan(*req.Restoration)
		strict, err = s.preflightStrictRestorationTx(ctx, t, actor, StrictRestorationRequest{Plan: plan, AllowOverflowMail: req.AllowOverflowMail}, op)
		if err != nil {
			return nil, err
		}
	}
	reqs := make([]grantLockRequirement, 0, 3+len(ids)+8)
	if err := appendPromotionBaseLocks(&reqs, actor.PlayerID, ids); err != nil {
		return nil, err
	}
	if strict != nil {
		reqs = append(reqs, strict.grantPreflight.Locks...)
	}
	union, err := canonicalGrantLockRequirements(reqs)
	if err != nil {
		return nil, err
	}
	combined := grantPreflight{Locks: union}
	if strict != nil {
		combined.Lines = strict.grantPreflight.Lines
		combined.ProgressionPolicy = strict.grantPreflight.ProgressionPolicy
		combined.FunctionPolicy = strict.grantPreflight.FunctionPolicy
		combined.EnergyDescriptor = strict.grantPreflight.EnergyDescriptor
		combined.PetStarterPolicy = strict.grantPreflight.PetStarterPolicy
		combined.Partner = strict.grantPreflight.Partner
		strict.grantPreflight.Locks = union
	}
	if err := s.acquireGrantLocksTx(ctx, t, actor.PlayerID, combined, op.StartedAt.UTC()); err != nil {
		return nil, err
	}
	if strict != nil {
		if _, ok, err := s.findGrantReceiptTx(ctx, t, strict.plan, strict.grantFingerprint); err != nil {
			return nil, err
		} else if ok {
			return nil, ErrStrictRestorationAlreadySettled
		}
	}
	// Re-locking only identities already closed by the union is permitted by the
	// accepted I5 Prepare/Apply doctrine and captures the bounded planner view.
	progression, err := s.Store.LockProgressionTx(ctx, t, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	if progression.Level <= 0 {
		return nil, errors.New("i5 Hero promotion prepare: invalid canonical player level")
	}
	now := op.StartedAt.UTC()
	mana, exists, err := s.Store.LockScalarTx(ctx, t, actor.PlayerID, "mana", now)
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, economy.ErrUnknownResource
	}
	if err := mana.Validate(); err != nil {
		return nil, err
	}
	stacks := make(map[int64]preparedHeroEquipmentStack, len(ids))
	for _, itemID := range ids {
		st, exists, err := s.Store.LockStackTx(ctx, t, actor.PlayerID, itemID, now)
		if err != nil {
			return nil, err
		}
		if exists {
			if err := st.Validate(); err != nil {
				return nil, err
			}
			if st.PlayerID != actor.PlayerID || st.ItemID != itemID {
				return nil, errors.New("i5 Hero promotion prepare: corrupt stack identity")
			}
		}
		stacks[itemID] = preparedHeroEquipmentStack{state: st, exists: exists}
	}
	return &PreparedHeroPromotionResources{
		actor: actor, op: op, contentRevision: revision, playerLevel: progression.Level,
		effectAt: now, mana: mana, manaExists: true, stackIDs: ids, stacks: stacks,
		restoration: strict, combinedGrantPlan: combined,
	}, nil
}

func validateHeroPromotionDebit(p *PreparedHeroPromotionResources, debit HeroEquipmentResourceDebit) error {
	if p == nil || p.applied {
		return errors.New("i5 Hero promotion apply: invalid prepared plan")
	}
	shadow := &PreparedHeroEquipmentResources{playerID: p.actor.PlayerID, playerLevel: p.playerLevel, effectAt: p.effectAt, mana: p.mana, manaExists: p.manaExists, stackIDs: p.stackIDs, stacks: p.stacks}
	return validateHeroEquipmentResourceDebit(shadow, debit)
}

func (s Service) ApplyHeroPromotionResourcesTx(ctx context.Context, t tx.Tx, prepared *PreparedHeroPromotionResources, debit HeroEquipmentResourceDebit) (HeroPromotionResourceResult, error) {
	if err := s.validate(); err != nil {
		return HeroPromotionResourceResult{}, err
	}
	if t == nil {
		return HeroPromotionResourceResult{}, errors.New("i5 Hero promotion apply: transaction required")
	}
	if err := validateHeroPromotionDebit(prepared, debit); err != nil {
		return HeroPromotionResourceResult{}, err
	}
	if prepared.restoration != nil {
		if prepared.restoration.applied {
			return HeroPromotionResourceResult{}, errors.New("i5 Hero promotion apply: restoration already applied in memory")
		}
		if _, ok, err := s.findGrantReceiptTx(ctx, t, prepared.restoration.plan, prepared.restoration.grantFingerprint); err != nil {
			return HeroPromotionResourceResult{}, err
		} else if ok {
			return HeroPromotionResourceResult{}, ErrStrictRestorationAlreadySettled
		}
	}
	shadow := &PreparedHeroEquipmentResources{playerID: prepared.actor.PlayerID, playerLevel: prepared.playerLevel, effectAt: prepared.effectAt, mana: prepared.mana, manaExists: prepared.manaExists, stackIDs: prepared.stackIDs, stacks: prepared.stacks}
	debiter := HeroEquipmentResourceDebiter{Store: s.Store, Content: s.Content}
	debitResult, err := debiter.ApplyHeroEquipmentResourceDebitTx(ctx, t, shadow, debit)
	if err != nil {
		return HeroPromotionResourceResult{}, err
	}
	out := HeroPromotionResourceResult{Debit: debitResult}
	if prepared.restoration != nil {
		gr, err := s.applyPreparedGrantTx(ctx, t, prepared.restoration.actor, prepared.restoration.plan, prepared.restoration.op, prepared.restoration.allowOverflow, prepared.restoration.contentRevision, prepared.restoration.grantPreflight, prepared.restoration.grantIdentity, prepared.restoration.grantFingerprint)
		if err != nil {
			return HeroPromotionResourceResult{}, err
		}
		prepared.restoration.applied = true
		out.Restoration = &gr
	}
	prepared.applied = true
	return out, nil
}

var _ TxHeroPromotionResourceSettler = Service{}

// Family-neutral aliases over the accepted promotion-resource transaction
// shape. Hero names remain source-compatible; Pet promotion reuses the same
// owner/lock suffix without depending on CharacterHero authority.
type PromotionResourceRequest = HeroPromotionResourceRequest
type PreparedPromotionResources = PreparedHeroPromotionResources
type PromotionResourceResult = HeroPromotionResourceResult
type PromotionResourceDebit = EquipmentResourceDebit

type TxPromotionResourceSettler interface {
	PreparePromotionResourcesTx(context.Context, tx.Tx, identity.ActorContext, PromotionResourceRequest, operation.Context) (*PreparedPromotionResources, error)
	ApplyPromotionResourcesTx(context.Context, tx.Tx, *PreparedPromotionResources, PromotionResourceDebit) (PromotionResourceResult, error)
}

func (s Service) PreparePromotionResourcesTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, req PromotionResourceRequest, op operation.Context) (*PreparedPromotionResources, error) {
	return s.PrepareHeroPromotionResourcesTx(ctx, t, actor, req, op)
}
func (s Service) ApplyPromotionResourcesTx(ctx context.Context, t tx.Tx, prepared *PreparedPromotionResources, debit PromotionResourceDebit) (PromotionResourceResult, error) {
	return s.ApplyHeroPromotionResourcesTx(ctx, t, prepared, debit)
}
