package i5

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroEquipmentResourceRequest names the complete bounded I5 stack identity
// closure that a caller may consume while planning one Normal-Hero MID62
// operation. It contains identities only; canonical quantities remain owned and
// read by I5 during Prepare.
type HeroEquipmentResourceRequest struct {
	PotentialStackItemIDs []int64
}

// HeroEquipmentStackDebit is one exact stack debit selected by the caller's
// deterministic planner after Prepare. ItemID must have appeared in the
// prepared request closure.
type HeroEquipmentStackDebit struct {
	ItemID int64
	Count  int64
}

// HeroEquipmentResourceDebit is the final exact I5 debit chosen from one
// prepared snapshot. Mana may be zero and Stacks may be empty for a valid
// no-work operation.
type HeroEquipmentResourceDebit struct {
	Mana   int64
	Stacks []HeroEquipmentStackDebit
}

type preparedHeroEquipmentStack struct {
	state  economy.StackState
	exists bool
}

// PreparedHeroEquipmentResources is intentionally opaque outside I5. Prepare
// acquires the complete I5 lock suffix and records canonical owner state. A
// Character caller may inspect only the bounded read-only planning snapshot
// exposed by the methods below; Apply consumes the private locked state.
type PreparedHeroEquipmentResources struct {
	playerID    identity.PlayerID
	playerLevel int64
	effectAt    time.Time
	mana        economy.ScalarBalance
	manaExists  bool
	stackIDs    []int64
	stacks      map[int64]preparedHeroEquipmentStack
	applied     bool
}

func (p *PreparedHeroEquipmentResources) PlayerLevel() int64 {
	if p == nil {
		return 0
	}
	return p.playerLevel
}

func (p *PreparedHeroEquipmentResources) Mana() int64 {
	if p == nil || !p.manaExists {
		return 0
	}
	return p.mana.Amount
}

// StackQuantity reports the canonical quantity captured for one prepared
// identity. The boolean reports closure membership, not row existence: an
// absent but prepared stack returns (0,true).
func (p *PreparedHeroEquipmentResources) StackQuantity(itemID int64) (int64, bool) {
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

// PreparedStackItemIDs returns a defensive copy in canonical lock order.
func (p *PreparedHeroEquipmentResources) PreparedStackItemIDs() []int64 {
	if p == nil {
		return nil
	}
	return append([]int64(nil), p.stackIDs...)
}

type HeroEquipmentResourceResult struct {
	PlayerLevel int64
	Mana        economy.ScalarBalance
	Stacks      []economy.StackState
}

// TxHeroEquipmentResourceDebiter is the CA4-2B I5-owned Prepare/Apply seam.
// The caller must already hold the lower-ranked Hero owner lock. Prepare then
// acquires Economy(700) -> Progression(710) -> Mana(720) -> sorted Stack(722)
// and performs no writes. Apply performs no content lookup, reads, or locks.
type TxHeroEquipmentResourceDebiter interface {
	PrepareHeroEquipmentResourcesTx(context.Context, tx.Tx, identity.PlayerID, HeroEquipmentResourceRequest, operation.Context) (*PreparedHeroEquipmentResources, error)
	ApplyHeroEquipmentResourceDebitTx(context.Context, tx.Tx, *PreparedHeroEquipmentResources, HeroEquipmentResourceDebit) (HeroEquipmentResourceResult, error)
}

// HeroEquipmentResourceDebiter uses the already-qualified I5 store and content
// authority. Store is HeroProgressionStore because its LockProgressionTx result
// is the canonical player.Progression value used elsewhere in I5.
type HeroEquipmentResourceDebiter struct {
	Store   HeroProgressionStore
	Content ContentRuntime
}

var _ TxHeroEquipmentResourceDebiter = HeroEquipmentResourceDebiter{}

func canonicalHeroEquipmentStackIDs(ids []int64) ([]int64, error) {
	if len(ids) == 0 {
		return nil, errors.New("i5 Hero equipment prepare: empty stack closure")
	}
	out := append([]int64(nil), ids...)
	seen := make(map[int64]struct{}, len(out))
	for _, id := range out {
		if id <= 0 {
			return nil, errors.New("i5 Hero equipment prepare: invalid stack identity")
		}
		if _, ok := seen[id]; ok {
			return nil, fmt.Errorf("i5 Hero equipment prepare: duplicate stack identity %d", id)
		}
		seen[id] = struct{}{}
	}
	// Match the accepted I5 same-rank identity ordering used by Grant and the
	// material debit seams: canonical decimal identity order.
	sort.Slice(out, func(i, j int) bool { return fmt.Sprintf("%d", out[i]) < fmt.Sprintf("%d", out[j]) })
	return out, nil
}

func (d HeroEquipmentResourceDebiter) PrepareHeroEquipmentResourcesTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, req HeroEquipmentResourceRequest, op operation.Context) (*PreparedHeroEquipmentResources, error) {
	if d.Store == nil || d.Content == nil || t == nil || !pid.Valid() || op.StartedAt.IsZero() {
		return nil, errors.New("i5 Hero equipment prepare: invalid input")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return nil, err
	}
	ids, err := canonicalHeroEquipmentStackIDs(req.PotentialStackItemIDs)
	if err != nil {
		return nil, err
	}

	// Qualify the complete potential stack closure against the caller-pinned
	// immutable revision before acquiring canonical owner locks. This does not
	// read or mutate player balances.
	for _, itemID := range ids {
		rp, err := d.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: 1})
		if err != nil {
			return nil, err
		}
		if rp.Kind != grant.StackItem || rp.Stack == nil || rp.Stack.ItemID != itemID {
			return nil, economy.ErrUnknownResource
		}
	}
	manaPolicy, err := d.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 1})
	if err != nil {
		return nil, err
	}
	if manaPolicy.Kind != grant.ScalarCurrency {
		return nil, economy.ErrUnknownResource
	}

	if err := d.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return nil, err
	}
	progression, err := d.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return nil, err
	}
	if progression.Level <= 0 {
		return nil, errors.New("i5 Hero equipment prepare: invalid canonical player level")
	}
	now := op.StartedAt.UTC()
	mana, exists, err := d.Store.LockScalarTx(ctx, t, pid, "mana", now)
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
		st, exists, err := d.Store.LockStackTx(ctx, t, pid, itemID, now)
		if err != nil {
			return nil, err
		}
		if exists {
			if err := st.Validate(); err != nil {
				return nil, err
			}
			if st.PlayerID != pid || st.ItemID != itemID {
				return nil, errors.New("i5 Hero equipment prepare: corrupt stack identity")
			}
		}
		stacks[itemID] = preparedHeroEquipmentStack{state: st, exists: exists}
	}
	return &PreparedHeroEquipmentResources{
		playerID: pid, playerLevel: progression.Level, effectAt: now,
		mana: mana, manaExists: true, stackIDs: ids, stacks: stacks,
	}, nil
}

func validateHeroEquipmentResourceDebit(prepared *PreparedHeroEquipmentResources, debit HeroEquipmentResourceDebit) error {
	if prepared == nil || !prepared.playerID.Valid() || prepared.playerLevel <= 0 || prepared.effectAt.IsZero() || !prepared.manaExists || prepared.applied {
		return errors.New("i5 Hero equipment apply: invalid prepared plan")
	}
	if debit.Mana < 0 {
		return errors.New("i5 Hero equipment apply: negative Mana debit")
	}
	seen := make(map[int64]struct{}, len(debit.Stacks))
	for _, x := range debit.Stacks {
		if x.ItemID <= 0 || x.Count <= 0 {
			return errors.New("i5 Hero equipment apply: invalid stack debit")
		}
		if _, ok := seen[x.ItemID]; ok {
			return fmt.Errorf("i5 Hero equipment apply: duplicate stack debit %d", x.ItemID)
		}
		seen[x.ItemID] = struct{}{}
		if _, ok := prepared.stacks[x.ItemID]; !ok {
			return fmt.Errorf("i5 Hero equipment apply: stack %d outside prepared closure", x.ItemID)
		}
	}
	return nil
}

func (d HeroEquipmentResourceDebiter) ApplyHeroEquipmentResourceDebitTx(ctx context.Context, t tx.Tx, prepared *PreparedHeroEquipmentResources, debit HeroEquipmentResourceDebit) (HeroEquipmentResourceResult, error) {
	if d.Store == nil || t == nil {
		return HeroEquipmentResourceResult{}, errors.New("i5 Hero equipment apply: invalid ports")
	}
	if err := validateHeroEquipmentResourceDebit(prepared, debit); err != nil {
		return HeroEquipmentResourceResult{}, err
	}

	nextMana := prepared.mana
	var err error
	if debit.Mana > 0 {
		nextMana, err = prepared.mana.Debit(debit.Mana, prepared.effectAt)
		if err != nil {
			return HeroEquipmentResourceResult{}, err
		}
	}

	stackDebits := append([]HeroEquipmentStackDebit(nil), debit.Stacks...)
	sort.Slice(stackDebits, func(i, j int) bool {
		return fmt.Sprintf("%d", stackDebits[i].ItemID) < fmt.Sprintf("%d", stackDebits[j].ItemID)
	})
	nextStacks := make([]economy.StackState, 0, len(stackDebits))
	for _, x := range stackDebits {
		locked := prepared.stacks[x.ItemID]
		if !locked.exists {
			return HeroEquipmentResourceResult{}, economy.ErrInsufficientBalance
		}
		adjusted, err := locked.state.Adjust(-x.Count, prepared.effectAt)
		if err != nil {
			return HeroEquipmentResourceResult{}, err
		}
		nextStacks = append(nextStacks, adjusted.State)
	}

	// From this point onward Apply performs writes only. It discovers no new
	// identity and performs no content resolution, canonical read, or lock.
	if debit.Mana > 0 {
		if err := d.Store.SaveScalarTx(ctx, t, nextMana, true); err != nil {
			return HeroEquipmentResourceResult{}, err
		}
	}
	for _, next := range nextStacks {
		if next.Quantity == 0 {
			if err := d.Store.DeleteStackTx(ctx, t, next); err != nil {
				return HeroEquipmentResourceResult{}, err
			}
		} else if err := d.Store.SaveStackTx(ctx, t, next, true); err != nil {
			return HeroEquipmentResourceResult{}, err
		}
	}
	prepared.applied = true
	return HeroEquipmentResourceResult{PlayerLevel: prepared.playerLevel, Mana: nextMana, Stacks: nextStacks}, nil
}
