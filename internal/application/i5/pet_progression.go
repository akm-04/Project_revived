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

// PetExpItemDebit is one exact stack debit requested by stock MID787/MID134.
type PetExpItemDebit struct {
	ItemID int64
	Count  int64
}

// PetExpDebitPlan is intentionally opaque outside I5. Prepare locks and
// computes every I5-owned next state without writing; CharacterPet may inspect
// only canonical PlayerLevel before asking I5 to apply the already-planned
// stack mutations.
type PetExpDebitPlan struct {
	playerID    identity.PlayerID
	playerLevel int64
	effectAt    time.Time
	nextStacks  []economy.StackState
}

func (p PetExpDebitPlan) PlayerLevel() int64 { return p.playerLevel }

func (p PetExpDebitPlan) valid() bool {
	return p.playerID.Valid() && p.playerLevel > 0 && !p.effectAt.IsZero() && len(p.nextStacks) > 0 && len(p.nextStacks) <= 3
}

type PetExpDebitResult struct {
	PlayerLevel int64
	Stacks      []economy.StackState
}

// TxPetExpDebiter is the CA3-3 caller-owned transaction seam. Prepare acquires
// Economy(700) -> Progression(710) -> sorted Stack(722) and performs no writes.
// Apply acquires no locks and writes only states produced by Prepare.
type TxPetExpDebiter interface {
	PreparePetExpDebitTx(context.Context, tx.Tx, identity.PlayerID, []PetExpItemDebit, operation.Context) (PetExpDebitPlan, error)
	ApplyPetExpDebitTx(context.Context, tx.Tx, PetExpDebitPlan) (PetExpDebitResult, error)
}

type PetExpDebiter struct {
	Store   HeroProgressionStore
	Content ContentRuntime
}

var _ TxPetExpDebiter = PetExpDebiter{}

func (d PetExpDebiter) PreparePetExpDebitTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, requested []PetExpItemDebit, op operation.Context) (PetExpDebitPlan, error) {
	if d.Store == nil || d.Content == nil || t == nil || !pid.Valid() || len(requested) == 0 || len(requested) > 3 || op.StartedAt.IsZero() {
		return PetExpDebitPlan{}, errors.New("i5 Pet EXP prepare: invalid input")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return PetExpDebitPlan{}, err
	}
	items := append([]PetExpItemDebit(nil), requested...)
	seen := make(map[int64]struct{}, len(items))
	for _, x := range items {
		if x.ItemID <= 0 || x.Count <= 0 {
			return PetExpDebitPlan{}, errors.New("i5 Pet EXP prepare: invalid item")
		}
		if _, ok := seen[x.ItemID]; ok {
			return PetExpDebitPlan{}, fmt.Errorf("i5 Pet EXP prepare: duplicate item %d", x.ItemID)
		}
		seen[x.ItemID] = struct{}{}
		rp, err := d.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.StackItem, ItemID: x.ItemID, Amount: x.Count})
		if err != nil {
			return PetExpDebitPlan{}, err
		}
		if rp.Kind != grant.StackItem || rp.Stack == nil || rp.Stack.ItemID != x.ItemID {
			return PetExpDebitPlan{}, economy.ErrUnknownResource
		}
	}
	sort.Slice(items, func(i, j int) bool { return fmt.Sprintf("%d", items[i].ItemID) < fmt.Sprintf("%d", items[j].ItemID) })

	if err := d.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return PetExpDebitPlan{}, err
	}
	progression, err := d.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return PetExpDebitPlan{}, err
	}
	if progression.Level <= 0 {
		return PetExpDebitPlan{}, errors.New("i5 Pet EXP prepare: invalid canonical player level")
	}
	now := op.StartedAt.UTC()
	next := make([]economy.StackState, 0, len(items))
	for _, x := range items {
		st, exists, err := d.Store.LockStackTx(ctx, t, pid, x.ItemID, now)
		if err != nil {
			return PetExpDebitPlan{}, err
		}
		if !exists {
			return PetExpDebitPlan{}, economy.ErrUnknownResource
		}
		adjusted, err := st.Adjust(-x.Count, now)
		if err != nil {
			return PetExpDebitPlan{}, err
		}
		next = append(next, adjusted.State)
	}
	return PetExpDebitPlan{playerID: pid, playerLevel: progression.Level, effectAt: now, nextStacks: next}, nil
}

func (d PetExpDebiter) ApplyPetExpDebitTx(ctx context.Context, t tx.Tx, plan PetExpDebitPlan) (PetExpDebitResult, error) {
	if d.Store == nil || t == nil || !plan.valid() {
		return PetExpDebitResult{}, errors.New("i5 Pet EXP apply: invalid plan")
	}
	// No lock/read call is permitted here. All owner locks and next-state
	// arithmetic were completed by Prepare before CharacterPet validation.
	for _, st := range plan.nextStacks {
		if st.PlayerID != plan.playerID || !st.UpdatedAt.Equal(plan.effectAt) {
			return PetExpDebitResult{}, errors.New("i5 Pet EXP apply: corrupt plan")
		}
		if st.Quantity == 0 {
			if err := d.Store.DeleteStackTx(ctx, t, st); err != nil {
				return PetExpDebitResult{}, err
			}
			continue
		}
		if err := d.Store.SaveStackTx(ctx, t, st, true); err != nil {
			return PetExpDebitResult{}, err
		}
	}
	return PetExpDebitResult{PlayerLevel: plan.playerLevel, Stacks: append([]economy.StackState(nil), plan.nextStacks...)}, nil
}
