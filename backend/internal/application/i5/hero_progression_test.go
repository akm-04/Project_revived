package i5

import (
	"context"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/policy"
)

func TestHeroExpDebitLocksEconomyThenProgressionThenStack(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	st := &testStore{
		progression: player.Progression{PlayerID: identity.PlayerID(7), Level: 20, Exp: 100, StateVersion: 1, UpdatedAt: now},
		stack:       economy.StackState{PlayerID: identity.PlayerID(7), ItemID: 50001001, Quantity: 3, StateVersion: 1, AcquiredAt: now, UpdatedAt: now},
		stackExists: true,
	}
	content := &testContent{policies: map[grant.LineKind]ResourcePolicy{
		grant.StackItem: {Kind: grant.StackItem, Stack: &economy.StackDefinition{ItemID: 50001001, StackCap: 999, OverflowToMail: true}},
	}}
	op := testOperation(90)
	set, err := policy.NewSet(policy.Ref{Name: "content", Version: testContentRevisionA})
	if err != nil {
		t.Fatal(err)
	}
	op.Policies = set
	got, err := (HeroProgressionDebiter{Store: st, Content: content}).DebitHeroExpItemsTx(context.Background(), &testTx{}, identity.PlayerID(7), []HeroExpItemDebit{{ItemID: 50001001, Count: 2}}, op)
	if err != nil {
		t.Fatal(err)
	}
	if got.PlayerLevel != 20 || len(got.Stacks) != 1 || got.Stacks[0].Quantity != 1 {
		t.Fatalf("got=%+v", got)
	}
	if want := []string{"economy-owner", "progression", "stack:50001001"}; !reflect.DeepEqual(st.lockTrace, want) {
		t.Fatalf("lock trace=%v want=%v", st.lockTrace, want)
	}
}
