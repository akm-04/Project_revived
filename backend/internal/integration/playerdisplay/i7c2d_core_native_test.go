//go:build postgres

package playerdisplay_test

import (
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

// New owner foundation only: does not qualify commands, API, economic effects or process recovery.
func TestI7C2DBookCoreSourceRoundtripRollbackPreserve(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	c, e := (contentstore.Store{Queryer: p}).BookCatalogTx(ctx, p, rev)
	if e != nil || len(c.Buildings) != 112 || len(c.Skills) != 399 {
		t.Fatal("source binder", e)
	}
	if c.Books[130001020].PieceCount != 40 || c.Books[130001021].PieceCount != 45 {
		t.Fatal("qualified anomaly policy")
	}
	store := bookstore.Store{}
	at := time.Now().UTC().Add(-time.Hour)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = store.EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	root, e := store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.Facts.Validate(c) != nil || root.Version != 1 || root.Facts.Buildings[4].Level != 1 || len(root.Facts.Skills) != 0 {
		t.Fatal(root, e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	locked, e := store.LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	b := locked.Facts.Buildings[4]
	b.Level = 50
	locked.Facts.Buildings[4] = b
	locked.Version++
	locked.UpdatedAt = at.Add(time.Second)
	if e = store.SaveRootTx(ctx, tr, locked, 1); e != nil {
		t.Fatal(e)
	}
	if e = tr.Rollback(ctx); e != nil {
		t.Fatal(e)
	}
	root, e = store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.Facts.Buildings[4].Level != 1 {
		t.Fatal("rollback", root, e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	locked, e = store.LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	b = locked.Facts.Buildings[4]
	b.Level = 50
	locked.Facts.Buildings[4] = b
	locked.Version++
	locked.UpdatedAt = at.Add(time.Second)
	if e = store.SaveRootTx(ctx, tr, locked, 1); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = store.EnsureRootTx(ctx, tr, a.PlayerID, rev, time.Now().UTC()); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	root, e = store.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.Facts.Buildings[4].Level != 50 || root.Version != 2 || root.Facts.Validate(c) != nil {
		t.Fatal("preserve explicit", root, e)
	}
}

func TestI7C2DBookCostScalarProfileRequired(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	store := contentstore.Store{}
	for _, key := range []string{"magic_dust", "magic_liquid", "magic_energy", "magic_exp"} {
		_, e := store.ResolveResourceTx(ctx, p, rev, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: 1})
		if e != nil {
			t.Fatalf("required Book cost %s unresolved: %v", key, e)
		}
	}
}
