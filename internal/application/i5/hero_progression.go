package i5

import (
	"context"
	"errors"
	"fmt"
	"sort"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroExpItemDebit is an exact requested stack debit for MID55/MID63.
type HeroExpItemDebit struct {
	ItemID int64
	Count  int64
}

type HeroExpDebitResult struct {
	PlayerLevel int64
	Stacks      []economy.StackState
}

// TxHeroProgressionDebiter is the CA2-2 caller-owned-transaction seam into I5.
// Character never reaches I5 tables directly. Implementations structurally lock
// Economy(700) -> Progression(710) -> sorted Stack(722).
type TxHeroProgressionDebiter interface {
	DebitHeroExpItemsTx(context.Context, tx.Tx, identity.PlayerID, []HeroExpItemDebit, operation.Context) (HeroExpDebitResult, error)
	DebitHeroEvolutionTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, operation.Context) (MaterialDebitResult, error)
}

type HeroProgressionStore interface {
	MaterialCostStore
	LockProgressionTx(context.Context, tx.Tx, identity.PlayerID) (player.Progression, error)
}

type HeroProgressionDebiter struct {
	Store   HeroProgressionStore
	Content ContentRuntime
}

var _ TxHeroProgressionDebiter = HeroProgressionDebiter{}

func (d HeroProgressionDebiter) DebitHeroExpItemsTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, requested []HeroExpItemDebit, op operation.Context) (HeroExpDebitResult, error) {
	if d.Store == nil || d.Content == nil || t == nil || !pid.Valid() || len(requested) == 0 || len(requested) > 5 || op.StartedAt.IsZero() {
		return HeroExpDebitResult{}, errors.New("i5 Hero EXP debit: invalid input")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return HeroExpDebitResult{}, err
	}
	items := append([]HeroExpItemDebit(nil), requested...)
	seen := make(map[int64]struct{}, len(items))
	for _, x := range items {
		if x.ItemID <= 0 || x.Count <= 0 {
			return HeroExpDebitResult{}, errors.New("i5 Hero EXP debit: invalid item")
		}
		if _, ok := seen[x.ItemID]; ok {
			return HeroExpDebitResult{}, fmt.Errorf("i5 Hero EXP debit: duplicate item %d", x.ItemID)
		}
		seen[x.ItemID] = struct{}{}
		p, err := d.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.StackItem, ItemID: x.ItemID, Amount: x.Count})
		if err != nil {
			return HeroExpDebitResult{}, err
		}
		if p.Kind != grant.StackItem || p.Stack == nil || p.Stack.ItemID != x.ItemID {
			return HeroExpDebitResult{}, economy.ErrUnknownResource
		}
	}
	// Canonical same-rank ordering follows decimal item identity, matching I5 Grant/material debit.
	sort.Slice(items, func(i, j int) bool { return fmt.Sprintf("%d", items[i].ItemID) < fmt.Sprintf("%d", items[j].ItemID) })

	if err := d.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return HeroExpDebitResult{}, err
	}
	progression, err := d.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return HeroExpDebitResult{}, err
	}
	if progression.Level <= 0 {
		return HeroExpDebitResult{}, errors.New("i5 Hero EXP debit: invalid canonical player level")
	}

	now := op.StartedAt.UTC()
	next := make([]economy.StackState, 0, len(items))
	for _, x := range items {
		st, exists, err := d.Store.LockStackTx(ctx, t, pid, x.ItemID, now)
		if err != nil {
			return HeroExpDebitResult{}, err
		}
		if !exists {
			return HeroExpDebitResult{}, economy.ErrUnknownResource
		}
		adjusted, err := st.Adjust(-x.Count, now)
		if err != nil {
			return HeroExpDebitResult{}, err
		}
		next = append(next, adjusted.State)
	}
	// All balances were locked and planned before the first write.
	for _, st := range next {
		if st.Quantity == 0 {
			if err := d.Store.DeleteStackTx(ctx, t, st); err != nil {
				return HeroExpDebitResult{}, err
			}
		} else if err := d.Store.SaveStackTx(ctx, t, st, true); err != nil {
			return HeroExpDebitResult{}, err
		}
	}
	return HeroExpDebitResult{PlayerLevel: progression.Level, Stacks: next}, nil
}

func (d HeroProgressionDebiter) DebitHeroEvolutionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, mana, fragmentItemID, fragmentCount int64, op operation.Context) (MaterialDebitResult, error) {
	if d.Store == nil || d.Content == nil || t == nil || !pid.Valid() || mana < 0 || fragmentItemID < 0 || fragmentCount < 0 {
		return MaterialDebitResult{}, errors.New("i5 Hero evolution debit: invalid input")
	}
	if (fragmentCount == 0) != (fragmentItemID == 0) {
		return MaterialDebitResult{}, errors.New("i5 Hero evolution debit: fragment id/count mismatch")
	}
	cost := MaterialCost{}
	if mana > 0 {
		cost.Scalars = append(cost.Scalars, ScalarMaterialCost{ResourceKey: "mana", Amount: mana})
	}
	if fragmentCount > 0 {
		cost.Stacks = append(cost.Stacks, StackMaterialCost{ItemID: fragmentItemID, Amount: fragmentCount})
	}
	if len(cost.Scalars) == 0 && len(cost.Stacks) == 0 {
		return MaterialDebitResult{}, nil
	}
	return (MaterialCostDebiter{Store: d.Store, Content: d.Content}).DebitMaterialCostTx(ctx, t, pid, cost, op)
}
