//go:build postgres

package playerdisplay_test

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestExtensionBuildingPinStoragePreservesCreationAndRollback(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := actor(t, database)
	owner := bookstore.Store{}
	at := time.Now().UTC().Add(-time.Hour)
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err := owner.EnsureRootTx(ctx, transaction, player.PlayerID, revision, at); err != nil {
		t.Fatal(err)
	}
	root, err := owner.LockRootTx(ctx, transaction, player.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	pin := strings.Repeat("b", 64)
	root.Facts.Buildings[2] = book.Building{Level: 1, CatalogRevision: pin}
	root.Version++
	root.UpdatedAt = at.Add(time.Second)
	if err := owner.SaveRootTx(ctx, transaction, root, 1); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	stored, err := owner.ReadRootTx(ctx, database, player.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if stored.Revision != revision || stored.Facts.Buildings[2].CatalogRevision != pin || stored.Version != 2 {
		t.Fatal("stored pin or creation revision changed", stored)
	}
	transaction, err = database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	root, err = owner.LockRootTx(ctx, transaction, player.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	root.Facts.Buildings[2] = book.Building{Level: 2, CatalogRevision: strings.Repeat("c", 64)}
	root.Version++
	root.UpdatedAt = at.Add(2 * time.Second)
	if err := owner.SaveRootTx(ctx, transaction, root, 2); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	stored, err = owner.ReadRootTx(ctx, database, player.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if stored.Facts.Buildings[2].Level != 1 || stored.Facts.Buildings[2].CatalogRevision != pin || stored.Version != 2 || stored.Revision != revision {
		t.Fatal("rollback changed durable pin", stored)
	}
}
