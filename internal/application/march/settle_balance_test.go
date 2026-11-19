package march

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type typedBalanceCosts struct{ err error }

func (c typedBalanceCosts) DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error) {
	return i5.MaterialDebitResult{}, c.err
}

func TestExtraPreservesTypedBalanceRefusal(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	run := startChoiceRun()
	run.Passed = 9
	store := &startChoiceStore{run: run}
	mode := startChoiceMode(at, store, &startChoiceCombat{})
	mode.Costs = typedBalanceCosts{err: economy.InsufficientBalance("crystal")}
	_, err := mode.Extra(context.Background(), actor, startChoiceOperation(t, ids.UUID{1}, at))
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("Extra refusal = %v, want the typed balance error", err)
	}
	var balance *economy.InsufficientBalanceError
	if !errors.As(err, &balance) || balance.ResourceKey != "crystal" {
		t.Fatalf("Extra refusal lost the resource key: %v", err)
	}
	if store.run.Extra {
		t.Fatal("a refused Extra marked the Mystic chest claimed")
	}
}
