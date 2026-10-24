package tx

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/foundation/changes"
)

func TestAbortedAttemptChangesAreDropped(t *testing.T) {
	ctx, request := changes.Track(context.Background())
	calls := 0
	_, err := Runner{DB: &fakeDB{txs: []*fakeTx{{}, {}}}}.Run(ctx, opctx(), profile(), Options{Isolation: Serializable}, RetryPolicy{MaxAttempts: 2, RetryDefiniteAbort: true}, nil, func(c context.Context, _ Scope) error {
		calls++
		if calls == 1 {
			changes.Balance(c, "crystal", 1)
			changes.FunctionOpened(c, 9)
			return stateErr("40001")
		}
		changes.Balance(c, "mana", 5)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if got := request.Balances(); len(got) != 1 || got["mana"] != 5 || len(request.Functions()) != 0 {
		t.Fatalf("balances %v functions %v", got, request.Functions())
	}
}
