package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LevelStackDebitRequest describes one immutable-content-qualified stack debit
// guarded by canonical player progression. CA6 ticket use supplies its bound
// ticket item/count and the bound Practice unlock level through this typed seam.
type LevelStackDebitRequest struct {
	ItemID         int64
	Count          int64
	MinPlayerLevel int64
}

// PreparedLevelStackDebit is deliberately opaque. Prepare acquires every I5
// owner lock and computes the one next stack state without writing; Apply may
// persist only this frozen state and may not acquire another lock.
type PreparedLevelStackDebit struct {
	playerID    identity.PlayerID
	playerLevel int64
	effectAt    time.Time
	nextStack   economy.StackState
}

func (p PreparedLevelStackDebit) PlayerLevel() int64 { return p.playerLevel }

func (p PreparedLevelStackDebit) valid() bool {
	return p.playerID.Valid() && p.playerLevel > 0 && !p.effectAt.IsZero() && p.nextStack.Validate() == nil && p.nextStack.PlayerID == p.playerID && p.nextStack.UpdatedAt.Equal(p.effectAt)
}

type LevelStackDebitResult struct {
	PlayerLevel int64
	Stack       economy.StackState
}

// TxLevelAndStackDebiter is the I5-owned CA6 caller-transaction seam. Prepare
// structurally locks Economy(700) -> Progression(710) -> Stack(722), qualifies
// the stack item against the operation's immutable content revision, enforces
// the canonical level requirement, and performs no writes. Apply acquires no
// locks and writes only the state prepared by Prepare.
type TxLevelAndStackDebiter interface {
	PrepareLevelAndStackDebitTx(context.Context, tx.Tx, identity.PlayerID, LevelStackDebitRequest, operation.Context) (PreparedLevelStackDebit, error)
	ApplyLevelAndStackDebitTx(context.Context, tx.Tx, PreparedLevelStackDebit) (LevelStackDebitResult, error)
}

type LevelAndStackDebiter struct {
	Store   HeroProgressionStore
	Content ContentRuntime
}

var _ TxLevelAndStackDebiter = LevelAndStackDebiter{}

func (d LevelAndStackDebiter) PrepareLevelAndStackDebitTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, req LevelStackDebitRequest, op operation.Context) (PreparedLevelStackDebit, error) {
	if d.Store == nil || d.Content == nil || t == nil || !pid.Valid() || req.ItemID <= 0 || req.Count <= 0 || req.MinPlayerLevel <= 0 || op.StartedAt.IsZero() {
		return PreparedLevelStackDebit{}, errors.New("i5 level+stack prepare: invalid input")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return PreparedLevelStackDebit{}, err
	}
	resource, err := d.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.StackItem, ItemID: req.ItemID, Amount: req.Count})
	if err != nil {
		return PreparedLevelStackDebit{}, err
	}
	if resource.Kind != grant.StackItem || resource.Stack == nil || resource.Stack.ItemID != req.ItemID {
		return PreparedLevelStackDebit{}, economy.ErrUnknownResource
	}

	if err := d.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return PreparedLevelStackDebit{}, err
	}
	progression, err := d.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return PreparedLevelStackDebit{}, err
	}
	if progression.Level <= 0 {
		return PreparedLevelStackDebit{}, errors.New("i5 level+stack prepare: invalid canonical player level")
	}
	if progression.Level < req.MinPlayerLevel {
		return PreparedLevelStackDebit{}, ErrLevelRequirement
	}

	now := op.StartedAt.UTC()
	stack, exists, err := d.Store.LockStackTx(ctx, t, pid, req.ItemID, now)
	if err != nil {
		return PreparedLevelStackDebit{}, err
	}
	if !exists {
		return PreparedLevelStackDebit{}, economy.ErrUnknownResource
	}
	adjusted, err := stack.Adjust(-req.Count, now)
	if err != nil {
		return PreparedLevelStackDebit{}, err
	}
	plan := PreparedLevelStackDebit{playerID: pid, playerLevel: progression.Level, effectAt: now, nextStack: adjusted.State}
	if !plan.valid() {
		return PreparedLevelStackDebit{}, errors.New("i5 level+stack prepare: invalid prepared state")
	}
	return plan, nil
}

func (d LevelAndStackDebiter) ApplyLevelAndStackDebitTx(ctx context.Context, t tx.Tx, plan PreparedLevelStackDebit) (LevelStackDebitResult, error) {
	if d.Store == nil || t == nil || !plan.valid() {
		return LevelStackDebitResult{}, errors.New("i5 level+stack apply: invalid plan")
	}
	// No lock/read is allowed here. All I5 locks and debit arithmetic belong to
	// Prepare so an outer CharacterPractice transaction can validate its domain
	// before the first I5 write without changing lock order.
	if plan.nextStack.Quantity == 0 {
		if err := d.Store.DeleteStackTx(ctx, t, plan.nextStack); err != nil {
			return LevelStackDebitResult{}, err
		}
	} else if err := d.Store.SaveStackTx(ctx, t, plan.nextStack, true); err != nil {
		return LevelStackDebitResult{}, err
	}
	return LevelStackDebitResult{PlayerLevel: plan.playerLevel, Stack: plan.nextStack}, nil
}
