package i5

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ScalarMaterialCost and StackMaterialCost are deliberately narrow. CA1 does
// not make Temporal, PlayerExp, PartnerEntity or SpecializedDomain debit-able
// by generic Character callers.
type ScalarMaterialCost struct {
	ResourceKey string
	Amount      int64
}

type StackMaterialCost struct {
	ItemID int64
	Amount int64
}

type MaterialCost struct {
	Scalars []ScalarMaterialCost
	Stacks  []StackMaterialCost
}

func (c MaterialCost) validate() error {
	if len(c.Scalars) == 0 && len(c.Stacks) == 0 {
		return errors.New("material cost is empty")
	}
	seenScalar := make(map[string]struct{}, len(c.Scalars))
	for _, x := range c.Scalars {
		if strings.TrimSpace(x.ResourceKey) == "" || x.Amount <= 0 {
			return errors.New("invalid scalar material cost")
		}
		if _, exists := seenScalar[x.ResourceKey]; exists {
			return fmt.Errorf("duplicate scalar material cost %q", x.ResourceKey)
		}
		seenScalar[x.ResourceKey] = struct{}{}
	}
	seenStack := make(map[int64]struct{}, len(c.Stacks))
	for _, x := range c.Stacks {
		if x.ItemID <= 0 || x.Amount <= 0 {
			return errors.New("invalid stack material cost")
		}
		if _, exists := seenStack[x.ItemID]; exists {
			return fmt.Errorf("duplicate stack material cost %d", x.ItemID)
		}
		seenStack[x.ItemID] = struct{}{}
	}
	return nil
}

type MaterialDebitResult struct {
	Scalars []economy.ScalarBalance
	Stacks  []economy.StackState
}

// TxMaterialCostDebiter is the shared I5-owned debit-only composition seam.
// The caller owns the transaction and semantic receipt. It acquires only
// canonical I5 owner/resource locks and never begins, commits or retries a tx.
type TxMaterialCostDebiter interface {
	DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, MaterialCost, operation.Context) (MaterialDebitResult, error)
}

// MaterialCostStore is intentionally narrower than the full I5 Store so later
// Character domains cannot reach foreign-owner SQL through this seam.
type MaterialCostStore interface {
	LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error
	LockScalarTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) (economy.ScalarBalance, bool, error)
	SaveScalarTx(context.Context, tx.Tx, economy.ScalarBalance, bool) error
	LockStackTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (economy.StackState, bool, error)
	SaveStackTx(context.Context, tx.Tx, economy.StackState, bool) error
	DeleteStackTx(context.Context, tx.Tx, economy.StackState) error
}

// MaterialCostDebiter composes immutable I5 content qualification with canonical
// Economy/Scalar/Stack ownership. CA4-1 refactors its planning into a no-write
// preflight so the mixed material-exchange seam can union the same lock identities
// with Grant before any canonical mutation.
type MaterialCostDebiter struct {
	Store   MaterialCostStore
	Content ContentRuntime
}

var _ TxMaterialCostDebiter = MaterialCostDebiter{}

type preparedScalarDebit struct {
	Cost   ScalarMaterialCost
	Policy ResourcePolicy
}

type preparedStackDebit struct {
	Cost   StackMaterialCost
	Policy ResourcePolicy
}

type materialCostPreflight struct {
	Scalars []preparedScalarDebit
	Stacks  []preparedStackDebit
	Locks   []grantLockRequirement
	Now     time.Time
}

func (d MaterialCostDebiter) preflightMaterialCostTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, cost MaterialCost, op operation.Context) (materialCostPreflight, error) {
	if d.Store == nil || d.Content == nil || t == nil || !pid.Valid() {
		return materialCostPreflight{}, errors.New("i5 material debit ports/input incomplete")
	}
	if err := cost.validate(); err != nil {
		return materialCostPreflight{}, err
	}
	contentRevision, err := requireContentRevision(op)
	if err != nil {
		return materialCostPreflight{}, err
	}
	now := op.StartedAt.UTC()
	if now.IsZero() {
		return materialCostPreflight{}, errors.New("i5 material debit requires operation time")
	}

	pf := materialCostPreflight{Now: now}
	pf.Scalars = make([]preparedScalarDebit, 0, len(cost.Scalars))
	for _, x := range cost.Scalars {
		line := grant.Line{Kind: grant.ScalarCurrency, ResourceKey: x.ResourceKey, Amount: x.Amount}
		p, err := d.Content.ResolveResourceTx(ctx, t, contentRevision, line)
		if err != nil {
			return materialCostPreflight{}, err
		}
		if p.Kind != grant.ScalarCurrency {
			return materialCostPreflight{}, economy.ErrUnknownResource
		}
		pf.Scalars = append(pf.Scalars, preparedScalarDebit{Cost: x, Policy: p})
	}
	pf.Stacks = make([]preparedStackDebit, 0, len(cost.Stacks))
	for _, x := range cost.Stacks {
		line := grant.Line{Kind: grant.StackItem, ItemID: x.ItemID, Amount: x.Amount}
		p, err := d.Content.ResolveResourceTx(ctx, t, contentRevision, line)
		if err != nil {
			return materialCostPreflight{}, err
		}
		if p.Kind != grant.StackItem || p.Stack == nil || p.Stack.ItemID != x.ItemID {
			return materialCostPreflight{}, economy.ErrUnknownResource
		}
		pf.Stacks = append(pf.Stacks, preparedStackDebit{Cost: x, Policy: p})
	}

	// Preserve the historical deterministic result order while lock ordering is
	// now derived from the canonical D01 keys below.
	sort.Slice(pf.Scalars, func(i, j int) bool { return pf.Scalars[i].Cost.ResourceKey < pf.Scalars[j].Cost.ResourceKey })
	sort.Slice(pf.Stacks, func(i, j int) bool {
		return fmt.Sprintf("%d", pf.Stacks[i].Cost.ItemID) < fmt.Sprintf("%d", pf.Stacks[j].Cost.ItemID)
	})

	reqs := make([]grantLockRequirement, 0, 1+len(pf.Scalars)+len(pf.Stacks))
	if err := appendGrantLock(&reqs, grantLockRankEconomyOwner, "i5.economy-owner", lockkey.Int64(int64(pid)), grantLockEconomyOwner, "", 0, 0); err != nil {
		return materialCostPreflight{}, err
	}
	for _, x := range pf.Scalars {
		if err := appendGrantLock(&reqs, grantLockRankScalar, "i5.scalar", grantChildIdentity(pid, x.Cost.ResourceKey), grantLockScalar, x.Cost.ResourceKey, 0, 0); err != nil {
			return materialCostPreflight{}, err
		}
	}
	for _, x := range pf.Stacks {
		if err := appendGrantLock(&reqs, grantLockRankStack, "i5.stack", grantChildIdentity(pid, fmt.Sprintf("%d", x.Cost.ItemID)), grantLockStack, "", x.Cost.ItemID, 0); err != nil {
			return materialCostPreflight{}, err
		}
	}
	pf.Locks, err = canonicalGrantLockRequirements(reqs)
	if err != nil {
		return materialCostPreflight{}, err
	}
	return pf, nil
}

func (d MaterialCostDebiter) acquireMaterialCostLocksTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, pf materialCostPreflight) error {
	for _, r := range pf.Locks {
		switch r.Kind {
		case grantLockEconomyOwner:
			if err := d.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
				return err
			}
		case grantLockScalar:
			if _, exists, err := d.Store.LockScalarTx(ctx, t, pid, r.ResourceKey, pf.Now); err != nil {
				return err
			} else if !exists {
				return economy.ErrUnknownResource
			}
		case grantLockStack:
			if _, exists, err := d.Store.LockStackTx(ctx, t, pid, r.ItemID, pf.Now); err != nil {
				return err
			} else if !exists {
				return economy.ErrUnknownResource
			}
		default:
			return errors.New("material cost contains non-material lock requirement")
		}
	}
	return nil
}

// prepareMaterialDebitStateTx computes all next states while the already-planned
// locks are held. Re-locking an already-planned identity is allowed; discovering
// a new identity here is not.
func (d MaterialCostDebiter) prepareMaterialDebitStateTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, pf materialCostPreflight) (MaterialDebitResult, error) {
	nextScalars := make([]economy.ScalarBalance, 0, len(pf.Scalars))
	for _, x := range pf.Scalars {
		b, exists, err := d.Store.LockScalarTx(ctx, t, pid, x.Cost.ResourceKey, pf.Now)
		if err != nil {
			return MaterialDebitResult{}, err
		}
		if !exists {
			return MaterialDebitResult{}, economy.ErrUnknownResource
		}
		next, err := b.Debit(x.Cost.Amount, pf.Now)
		if err != nil {
			return MaterialDebitResult{}, err
		}
		nextScalars = append(nextScalars, next)
	}
	nextStacks := make([]economy.StackState, 0, len(pf.Stacks))
	for _, x := range pf.Stacks {
		st, exists, err := d.Store.LockStackTx(ctx, t, pid, x.Cost.ItemID, pf.Now)
		if err != nil {
			return MaterialDebitResult{}, err
		}
		if !exists {
			return MaterialDebitResult{}, economy.ErrUnknownResource
		}
		adjusted, err := st.Adjust(-x.Cost.Amount, pf.Now)
		if err != nil {
			return MaterialDebitResult{}, err
		}
		nextStacks = append(nextStacks, adjusted.State)
	}
	return MaterialDebitResult{Scalars: nextScalars, Stacks: nextStacks}, nil
}

func (d MaterialCostDebiter) applyPreparedMaterialDebitTx(ctx context.Context, t tx.Tx, prepared MaterialDebitResult) error {
	for _, next := range prepared.Scalars {
		if err := d.Store.SaveScalarTx(ctx, t, next, true); err != nil {
			return err
		}
	}
	for _, next := range prepared.Stacks {
		if next.Quantity == 0 {
			if err := d.Store.DeleteStackTx(ctx, t, next); err != nil {
				return err
			}
			continue
		}
		if err := d.Store.SaveStackTx(ctx, t, next, true); err != nil {
			return err
		}
	}
	return nil
}

func (d MaterialCostDebiter) DebitMaterialCostTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, cost MaterialCost, op operation.Context) (MaterialDebitResult, error) {
	pf, err := d.preflightMaterialCostTx(ctx, t, pid, cost, op)
	if err != nil {
		return MaterialDebitResult{}, err
	}
	if err := d.acquireMaterialCostLocksTx(ctx, t, pid, pf); err != nil {
		return MaterialDebitResult{}, err
	}
	prepared, err := d.prepareMaterialDebitStateTx(ctx, t, pid, pf)
	if err != nil {
		return MaterialDebitResult{}, err
	}
	if err := d.applyPreparedMaterialDebitTx(ctx, t, prepared); err != nil {
		return MaterialDebitResult{}, err
	}
	return prepared, nil
}

// PreparedMaterialDebit closes the existing debit plan before a caller mutates
// another owner. It is opaque and valid only in the caller's current transaction.
type PreparedMaterialDebit struct{ result MaterialDebitResult }

func (d MaterialCostDebiter) PrepareMaterialDebitTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, cost MaterialCost, op operation.Context) (*PreparedMaterialDebit, error) {
	pf, e := d.preflightMaterialCostTx(ctx, t, pid, cost, op)
	if e != nil {
		return nil, e
	}
	if e = d.acquireMaterialCostLocksTx(ctx, t, pid, pf); e != nil {
		return nil, e
	}
	result, e := d.prepareMaterialDebitStateTx(ctx, t, pid, pf)
	if e != nil {
		return nil, e
	}
	return &PreparedMaterialDebit{result}, nil
}
func (d MaterialCostDebiter) ApplyMaterialDebitTx(ctx context.Context, t tx.Tx, p *PreparedMaterialDebit) (MaterialDebitResult, error) {
	if p == nil || t == nil {
		return MaterialDebitResult{}, errors.New("i5: prepared debit required")
	}
	if e := d.applyPreparedMaterialDebitTx(ctx, t, p.result); e != nil {
		return MaterialDebitResult{}, e
	}
	return p.result, nil
}
