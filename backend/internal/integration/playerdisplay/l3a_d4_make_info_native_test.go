//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/eventcentrestore"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func seedEventCentreMake(t *testing.T, database *pg.Pool, actor identity.ActorContext, revision string, apply func(*ec.Root)) {
	t.Helper()
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	owner := eventcentrestore.Store{}
	now := time.Now().UTC()
	if err = owner.EnsureRootTx(ctx, transaction, actor.PlayerID, revision, now); err != nil {
		t.Fatal(err)
	}
	root, exists, err := owner.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil || !exists {
		t.Fatalf("event centre root %v %v", exists, err)
	}
	apply(&root)
	previousVersion := root.Version
	root.Version++
	root.UpdatedAt = now
	if err = owner.SaveRootTx(ctx, transaction, root, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func makeField(t *testing.T, body map[string]any, key string, want int64) {
	t.Helper()
	got, ok := body[key].(int64)
	if !ok {
		small, isInt := body[key].(int)
		got, ok = int64(small), isInt
	}
	if !ok || got != want {
		t.Fatalf("%s = %#v, want %d", key, body[key], want)
	}
}

func TestL3AD4MakeInfoNative(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)

	list, err := books.Read(ctx, actor, 1056, op())
	if err != nil {
		t.Fatal(err)
	}
	desk, ok := list["desk_info"].(map[string]any)
	if !ok {
		t.Fatalf("1056 desk_info = %#v", list["desk_info"])
	}
	for key, want := range map[string]int64{"is_making": 0, "make_need_time": 0, "make_start_time": 0, "make_item": 0} {
		makeField(t, desk, key, want)
	}
	pet, ok := list["pet_cabin_info"].(map[string]any)
	if !ok {
		t.Fatalf("1056 pet_cabin_info = %#v", list["pet_cabin_info"])
	}
	makeField(t, pet, "pet_id", int64(0))
	makeField(t, pet, "is_making", int64(0))

	itemID := int64(130001001)
	startedAt := time.Now().UTC().Add(-100 * time.Second).Truncate(time.Second)
	seedEventCentreMake(t, database, actor, revision, func(root *ec.Root) {
		root.Facts.Desk.Job = &ec.MakeJob{Occurrence: "l3a-d4", ItemID: itemID, StartedAt: startedAt, Duration: 3600, Cost: []ec.ResourceAmount{{ID: 13, Amount: 2}}}
	})
	list, err = books.Read(ctx, actor, 1056, op())
	if err != nil {
		t.Fatal(err)
	}
	desk = list["desk_info"].(map[string]any)
	makeField(t, desk, "is_making", int64(1))
	makeField(t, desk, "making_item", itemID)
	makeField(t, desk, "make_need_time", int64(3600))
	makeField(t, desk, "make_start_time", startedAt.Unix())
	makeField(t, desk, "make_item", int64(0))

	detail, err := eventCentreService(database, books).Read(ctx, actor, 1074, op())
	if err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"is_making", "make_item", "making_item", "make_need_time", "make_start_time"} {
		if detail[key] != desk[key] {
			t.Fatalf("1074 %s = %#v, 1056 = %#v", key, detail[key], desk[key])
		}
	}

	seedEventCentreMake(t, database, actor, revision, func(root *ec.Root) {
		root.Facts.Desk.Job = &ec.MakeJob{Occurrence: "l3a-d4-done", ItemID: itemID, StartedAt: startedAt.Add(-2 * time.Hour), Duration: 3600, Cost: []ec.ResourceAmount{{ID: 13, Amount: 2}}}
	})
	list, err = books.Read(ctx, actor, 1056, op())
	if err != nil {
		t.Fatal(err)
	}
	desk = list["desk_info"].(map[string]any)
	makeField(t, desk, "is_making", int64(0))
	makeField(t, desk, "make_item", itemID)
	makeField(t, desk, "make_need_time", int64(0))
	makeField(t, desk, "make_start_time", int64(0))
	stored, found, err := eventcentrestore.Store{}.ReadRootTx(ctx, database, actor.PlayerID)
	if err != nil || !found || stored.Facts.Desk.Job == nil {
		t.Fatalf("1056 saved the settled clone: found %v err %v", found, err)
	}
}
