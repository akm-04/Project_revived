package summon

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type refusingCosts struct{ err error }

func (c refusingCosts) DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error) {
	return i5.MaterialDebitResult{}, c.err
}

func TestDebitPreservesNamedBalance(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	timed, err := generation.NewTimedOperation(operation.Context{ID: ids.UUID{1}, StartedAt: at}, at)
	if err != nil {
		t.Fatal(err)
	}
	scope := generation.TimedScope{Operation: timed}
	for _, tc := range []struct {
		button   d.Button
		resource string
	}{{d.Button{Mana: 100}, "mana"}, {d.Button{Crystal: 288}, "crystal"}} {
		mode := Mode{Costs: refusingCosts{err: economy.InsufficientBalance(tc.resource)}}
		got := mode.debit(context.Background(), scope, identity.PlayerID(1), tc.button)
		var balance *economy.InsufficientBalanceError
		if !errors.Is(got, economy.ErrInsufficientBalance) || !errors.As(got, &balance) || balance.ResourceKey != tc.resource {
			t.Fatalf("%s debit lost the named balance: %v", tc.resource, got)
		}
	}
}
