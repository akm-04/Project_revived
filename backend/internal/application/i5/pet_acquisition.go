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

type PetAcquisitionDebitResult struct {
	ItemID            int64
	Count             int64
	UsedEgg           bool
	RemainingQuantity int64
}

type TxPetAcquisitionDebiter interface {
	DebitPetAcquisitionTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, operation.Context) (PetAcquisitionDebitResult, error)
}

// TxTimedPetAcquisitionDebiter is the authoritative-time CA3 seam. The
// operation context retains transport/receipt StartedAt; effectAt is the
// database-authoritative instant used for Economy/Stack owner state.
type TxTimedPetAcquisitionDebiter interface {
	DebitPetAcquisitionAtTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, operation.Context, time.Time) (PetAcquisitionDebitResult, error)
}

type PetAcquisitionDebiter struct {
	Store   MaterialCostStore
	Content ContentRuntime
}

var _ TxPetAcquisitionDebiter = PetAcquisitionDebiter{}

func (d PetAcquisitionDebiter) DebitPetAcquisitionTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, eggItemID, essenceItemID, fragmentCount int64, op operation.Context) (PetAcquisitionDebitResult, error) {
	return d.DebitPetAcquisitionAtTx(ctx, t, pid, eggItemID, essenceItemID, fragmentCount, op, op.StartedAt)
}

func (d PetAcquisitionDebiter) DebitPetAcquisitionAtTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, eggItemID, essenceItemID, fragmentCount int64, op operation.Context, effectAt time.Time) (PetAcquisitionDebitResult, error) {
	if d.Store == nil || d.Content == nil || t == nil || !pid.Valid() || eggItemID <= 0 || essenceItemID <= 0 || eggItemID == essenceItemID || fragmentCount <= 0 || op.StartedAt.IsZero() || effectAt.IsZero() {
		return PetAcquisitionDebitResult{}, errors.New("i5 Pet acquisition debit: invalid input")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return PetAcquisitionDebitResult{}, err
	}
	ids := []int64{eggItemID, essenceItemID}
	policies := map[int64]economy.StackDefinition{}
	for _, id := range ids {
		rp, err := d.Content.ResolveResourceTx(ctx, t, revision, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: 1})
		if err != nil {
			return PetAcquisitionDebitResult{}, err
		}
		if rp.Stack == nil || rp.Stack.ItemID != id {
			return PetAcquisitionDebitResult{}, economy.ErrUnknownResource
		}
		policies[id] = *rp.Stack
	}
	_ = policies // qualification is intentional even though debit does not need cap arithmetic.
	sort.Slice(ids, func(i, j int) bool { return fmt.Sprintf("%d", ids[i]) < fmt.Sprintf("%d", ids[j]) })
	if err := d.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return PetAcquisitionDebitResult{}, err
	}
	type locked struct {
		st     economy.StackState
		exists bool
	}
	states := map[int64]locked{}
	now := effectAt.UTC()
	for _, id := range ids {
		st, exists, err := d.Store.LockStackTx(ctx, t, pid, id, now)
		if err != nil {
			return PetAcquisitionDebitResult{}, err
		}
		states[id] = locked{st: st, exists: exists}
	}
	consumeID, count, usedEgg := essenceItemID, fragmentCount, false
	if x := states[eggItemID]; x.exists && x.st.Quantity > 0 {
		consumeID, count, usedEgg = eggItemID, 1, true
	}
	chosen := states[consumeID]
	if !chosen.exists {
		return PetAcquisitionDebitResult{}, economy.ErrInsufficientBalance
	}
	adjusted, err := chosen.st.Adjust(-count, now)
	if err != nil {
		return PetAcquisitionDebitResult{}, err
	}
	if adjusted.State.Quantity == 0 {
		if err := d.Store.DeleteStackTx(ctx, t, adjusted.State); err != nil {
			return PetAcquisitionDebitResult{}, err
		}
	} else if err := d.Store.SaveStackTx(ctx, t, adjusted.State, true); err != nil {
		return PetAcquisitionDebitResult{}, err
	}
	return PetAcquisitionDebitResult{ItemID: consumeID, Count: count, UsedEgg: usedEgg, RemainingQuantity: adjusted.State.Quantity}, nil
}
