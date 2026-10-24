package i5

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

func levelStackOperation(t *testing.T, now time.Time) operation.Context {
	t.Helper()
	set, err := policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("a", 64)})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{StartedAt: now.UTC(), Policies: set}
}

func TestLevelAndStackPrepareLocks700710722WithoutWritingAndApplyOnlyWrites(t *testing.T) {
	now := time.Unix(9000, 321).UTC()
	pid := identity.PlayerID(7)
	const ticketID int64 = 50001181
	store := &petExpTestStore{
		progression: player.Progression{PlayerID: pid, Level: 90},
		stacks: map[int64]economy.StackState{
			ticketID: {PlayerID: pid, ItemID: ticketID, Quantity: 1, StateVersion: 3, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour)},
		},
	}
	d := LevelAndStackDebiter{Store: store, Content: petExpTestContent{}}
	plan, err := d.PrepareLevelAndStackDebitTx(context.Background(), petExpTestTx{}, pid, LevelStackDebitRequest{ItemID: ticketID, Count: 1, MinPlayerLevel: 90}, levelStackOperation(t, now))
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"lock:economy", "lock:progression", "lock:stack:50001181"}
	if fmt.Sprint(store.events) != fmt.Sprint(want) {
		t.Fatalf("prepare events=%v want=%v", store.events, want)
	}
	if plan.PlayerLevel() != 90 {
		t.Fatalf("player level=%d", plan.PlayerLevel())
	}
	if store.stacks[ticketID].Quantity != 1 {
		t.Fatalf("Prepare wrote stack: %+v", store.stacks[ticketID])
	}

	before := len(store.events)
	res, err := d.ApplyLevelAndStackDebitTx(context.Background(), petExpTestTx{}, plan)
	if err != nil {
		t.Fatal(err)
	}
	if res.PlayerLevel != 90 || res.Stack.Quantity != 0 {
		t.Fatalf("result=%+v", res)
	}
	for _, ev := range store.events[before:] {
		if strings.HasPrefix(ev, "lock:") {
			t.Fatalf("Apply acquired lock: %v", store.events)
		}
	}
	if _, exists := store.stacks[ticketID]; exists {
		t.Fatalf("zero ticket stack was not deleted: %+v", store.stacks)
	}
}

func TestLevelAndStackPrepareFailsClosedBelowCanonicalLevelBeforeStackLock(t *testing.T) {
	now := time.Unix(9100, 0).UTC()
	pid := identity.PlayerID(7)
	store := &petExpTestStore{
		progression: player.Progression{PlayerID: pid, Level: 89},
		stacks: map[int64]economy.StackState{
			50001181: {PlayerID: pid, ItemID: 50001181, Quantity: 2, StateVersion: 1, AcquiredAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour)},
		},
	}
	d := LevelAndStackDebiter{Store: store, Content: petExpTestContent{}}
	_, err := d.PrepareLevelAndStackDebitTx(context.Background(), petExpTestTx{}, pid, LevelStackDebitRequest{ItemID: 50001181, Count: 1, MinPlayerLevel: 90}, levelStackOperation(t, now))
	if !errors.Is(err, ErrLevelRequirement) {
		t.Fatalf("err=%v want ErrLevelRequirement", err)
	}
	want := []string{"lock:economy", "lock:progression"}
	if fmt.Sprint(store.events) != fmt.Sprint(want) {
		t.Fatalf("events=%v want=%v", store.events, want)
	}
	if store.stacks[50001181].Quantity != 2 {
		t.Fatal("failed Prepare mutated stack")
	}
}
