//go:build postgres

package librarystore_test

import (
	"context"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

func TestLibraryNativeFacetPersistenceRollbackBackfill(t *testing.T) {
	dsn := os.Getenv("GXB_I7C2B_DSN")
	if dsn == "" {
		t.Skip("GXB_I7C2B_DSN required")
	}
	ctx := context.Background()
	p, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i7c2b-core-work"})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	s := librarystore.Store{}
	pid := identity.PlayerID(777301)
	ref := character.HeroRef{PlayerID: pid, PartnerID: 1}
	now := time.Now().UTC().Truncate(time.Microsecond)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = s.EnsurePlayerRootTx(ctx, tr, pid, now); e != nil {
		t.Fatal(e)
	}
	if e = s.InitFreshHeroTx(ctx, tr, ref, now); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	f, e := s.ReadHeroTx(ctx, p, ref)
	if e != nil || f.StateVersion != 1 || f.Favor != 0 || f.Pending != nil || f.Applied != (library.FeedAttrs{}) {
		t.Fatal(f, e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = s.LockRootTx(ctx, tr, pid); e != nil {
		t.Fatal(e)
	}
	f, e = s.LockHeroTx(ctx, tr, ref)
	if e != nil {
		t.Fatal(e)
	}
	original := f.StateVersion
	f.Favor = 2000
	f.Married = true
	f.StateVersion++
	f.UpdatedAt = now.Add(time.Second)
	if e = s.SaveHeroTx(ctx, tr, f, original); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	f, e = s.ReadHeroTx(ctx, p, ref)
	if e != nil || !f.Married {
		t.Fatal(f, e)
	}
	id, _ := ids.ParseUUID("12345678-1234-4234-8234-123456789012")
	candidate := library.Candidate{OperationID: id, Revision: f.StateVersion + 1, PolicyVersion: library.FeedPolicyV1, ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Base: f.Applied, Proposed: library.FeedAttrs{60, 5, 5, 2, 2, 2}, Delta: library.FeedAttrs{60, 5, 5, 2, 2, 2}, CreatedAt: now.Add(2 * time.Second)}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = s.LockRootTx(ctx, tr, pid); e != nil {
		t.Fatal(e)
	}
	f, e = s.LockHeroTx(ctx, tr, ref)
	if e != nil {
		t.Fatal(e)
	}
	original = f.StateVersion
	preview, e := f.WithPreview(candidate, candidate.CreatedAt)
	if e != nil {
		t.Fatal(e)
	}
	if e = s.SaveHeroTx(ctx, tr, preview, original); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	f, e = s.ReadHeroTx(ctx, p, ref)
	if e != nil || f.Pending == nil || f.Pending.Proposed != candidate.Proposed || f.Applied != candidate.Base {
		t.Fatal("preview/applied roundtrip", f, e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = s.LockRootTx(ctx, tr, pid); e != nil {
		t.Fatal(e)
	}
	f, e = s.LockHeroTx(ctx, tr, ref)
	if e != nil {
		t.Fatal(e)
	}
	original = f.StateVersion
	applied, _, e := f.SaveCurrent(now.Add(3 * time.Second))
	if e != nil {
		t.Fatal(e)
	}
	if e = s.SaveHeroTx(ctx, tr, applied, original); e != nil {
		t.Fatal(e)
	}
	if e = tr.Rollback(ctx); e != nil {
		t.Fatal(e)
	}
	still, e := s.ReadHeroTx(ctx, p, ref)
	if e != nil || still.Pending == nil || still.Applied != candidate.Base {
		t.Fatal("rolled-back SAVE changed durable applied facts", still, e)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	added, e := s.BackfillMissingHeroTx(ctx, tr, ref, now.Add(4*time.Second))
	if e != nil || added {
		t.Fatal("backfill overwrote explicit paid facts", added, e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	retained, e := s.ReadHeroTx(ctx, p, ref)
	if e != nil || retained.StateVersion != still.StateVersion || retained.Pending == nil || retained.Pending.OperationID != id {
		t.Fatal(retained, e)
	}
}
