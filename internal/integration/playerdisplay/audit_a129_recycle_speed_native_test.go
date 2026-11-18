//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/eventcentrestore"
	app "gxb.local/backend/v2/internal/application/bookskill"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

func a129SeedRecycle(t *testing.T, database *pg.Pool, actor identity.ActorContext, revision string, energy int64) time.Time {
	t.Helper()
	anchored := time.Now().UTC()
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	owner := eventcentrestore.Store{}
	if err = owner.EnsureRootTx(ctx, transaction, actor.PlayerID, revision, anchored); err != nil {
		t.Fatal(err)
	}
	root, exists, err := owner.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil || !exists {
		t.Fatal("recycle root", exists, err)
	}
	root.Facts.Recycle = ec.RecycleState{Energy: energy, EnergyAt: anchored}
	root.Version++
	root.UpdatedAt = anchored
	if err = owner.SaveRootTx(ctx, transaction, root, root.Version-1); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return anchored
}

// The stock RecycleWindow callback reads reply.trash_info after a paid type-3
// speed-up. The success must carry the committed snapshot, cap it at the new
// level's limit without inventing zero, and replay the same result without a
// second crystal debit.
func TestA129RecycleSpeedNativeCarriesCommittedSnapshot(t *testing.T) {
	database := pool(t)
	actor, revision, books := bookFixture(t, database)
	eventCentre := eventCentreService(database, books)
	finishBuilding(t, books, actor, 1)

	before, err := eventCentre.Read(ctx, actor, 1072, op())
	if err != nil {
		t.Fatal(err)
	}
	oldLimit := number(t, before["energy_limit"])
	if oldLimit <= 0 || number(t, before["energy"]) != oldLimit {
		t.Fatalf("fresh recycle read = %#v", before)
	}

	anchored := a129SeedRecycle(t, database, actor, revision, oldLimit-1)
	bookCmd(t, books, actor, app.Command{Family: app.Start, Type: 3})

	speed := op()
	result, err := books.Command(ctx, actor, app.Command{Family: app.Speed, Type: 3}, speed)
	if err != nil {
		t.Fatal(err)
	}
	crystalAfterFirst := libraryAmount(t, database, actor, "crystal")
	if number(t, result.Body["lev"]) != 2 || number(t, result.Body["type"]) != 3 {
		t.Fatalf("speed building fields = %#v", result.Body)
	}
	for _, field := range []string{"start_time", "need_time", "new_evolve"} {
		if _, present := result.Body[field]; !present {
			t.Fatalf("speed reply lacks %s: %#v", field, result.Body)
		}
	}
	replyconformance.Check(t, 1077, result.Body)
	trash, ok := result.Body["trash_info"].(map[string]any)
	if !ok {
		t.Fatalf("type-3 speed success lacks trash_info: %#v", result.Body)
	}
	if number(t, trash["energy"]) != oldLimit-1 || number(t, trash["energy_time"]) != anchored.Unix() {
		t.Fatalf("near-saturated snapshot = %#v", trash)
	}

	replayed, err := books.Command(ctx, actor, app.Command{Family: app.Speed, Type: 3}, speed)
	if err != nil {
		t.Fatal(err)
	}
	firstJSON, _ := json.Marshal(result.Body)
	replayJSON, _ := json.Marshal(replayed.Body)
	if !bytes.Equal(firstJSON, replayJSON) {
		t.Fatalf("replay changed the stored result:\nfirst %s\nreplay %s", firstJSON, replayJSON)
	}
	if crystalAfter := libraryAmount(t, database, actor, "crystal"); crystalAfter != crystalAfterFirst {
		t.Fatalf("replay debited again: first %d replay %d", crystalAfterFirst, crystalAfter)
	}

	after, err := eventCentre.Read(ctx, actor, 1072, op())
	if err != nil {
		t.Fatal(err)
	}
	if newLimit := number(t, after["energy_limit"]); newLimit != oldLimit {
		t.Fatalf("level changed the saturation cap: %#v", after)
	}
	if number(t, after["energy"]) != oldLimit-1 || number(t, after["energy_time"]) != anchored.Unix() {
		t.Fatalf("read disagrees with the speed snapshot: %#v", after)
	}
}
