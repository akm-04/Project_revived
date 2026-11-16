//go:build postgres

package playerdisplay_test

import (
	"context"
	"reflect"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fixedBookReadTime struct{ at time.Time }

func (f fixedBookReadTime) Now(context.Context) (time.Time, error) { return f.at, nil }

type gatedBookContent struct {
	appbook.ContentPort
	entered chan int64
	release chan struct{}
	once    sync.Once
}

func (g *gatedBookContent) BookCatalogTx(ctx context.Context, q tx.Queryer, revision string) (book.Catalog, error) {
	g.once.Do(func() {
		var pid int64
		if err := q.QueryRow(ctx, "SELECT pg_backend_pid()").Scan(&pid); err != nil {
			g.entered <- -1
			return
		}
		g.entered <- pid
		<-g.release
	})
	return g.ContentPort.BookCatalogTx(ctx, q, revision)
}

func activeBookRevision(t *testing.T, service appbook.Service) string {
	t.Helper()
	revision, on, err := service.Content.BookInputsActive(ctx)
	if err != nil || !on {
		t.Fatalf("active book inputs: %q %v %v", revision, on, err)
	}
	return revision
}

func seedIdleBookRoot(t *testing.T, database *pg.Pool, actor identity.ActorContext, revision string) {
	t.Helper()
	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = (bookstore.Store{}).EnsureRootTx(ctx, transaction, actor.PlayerID, revision, time.Now().UTC().Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestL3D5IdleBookReadTakesNoRootLockOrWrite(t *testing.T) {
	database := pool(t)
	actor, _, service := bookFixture(t, database)
	seedIdleBookRoot(t, database, actor, activeBookRevision(t, service))
	before := bookRoot(t, database, actor)

	gated := &gatedBookContent{ContentPort: service.Content, entered: make(chan int64, 1), release: make(chan struct{})}
	service.Content = gated
	readErr := make(chan error, 1)
	go func() {
		_, err := service.Read(ctx, actor, 1056, op())
		readErr <- err
	}()

	var pid int64
	select {
	case pid = <-gated.entered:
	case <-time.After(10 * time.Second):
		close(gated.release)
		t.Fatal("idle read never reached its catalog read")
	}
	if pid <= 0 {
		close(gated.release)
		t.Fatalf("catalog read transaction did not report a backend pid: %d", pid)
	}
	var locked int64
	lockErr := database.QueryRow(ctx, `SELECT count(*) FROM pg_locks WHERE pid=$1 AND relation='player_book_roots'::regclass AND mode <> 'AccessShareLock'`, pid).Scan(&locked)
	close(gated.release)
	if err := <-readErr; err != nil {
		t.Fatal(err)
	}
	if lockErr != nil {
		t.Fatal(lockErr)
	}
	if locked != 0 {
		t.Fatalf("idle read held %d non-AccessShare locks on player_book_roots", locked)
	}
	after := bookRoot(t, database, actor)
	if after.Version != before.Version {
		t.Fatalf("idle read advanced state_version: %d -> %d", before.Version, after.Version)
	}
}

func TestL3D5BookReadSnapshotAndSettledPathsAgree(t *testing.T) {
	database := pool(t)
	actor, _, service := bookFixture(t, database)
	revision := activeBookRevision(t, service)
	store := bookstore.Store{}

	transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	root, err := store.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	root.Facts.Buildings[1] = book.Building{Level: 1, Job: &book.Job{Occurrence: "l3a-d5", Revision: revision, StartedAt: root.CreatedAt.Add(-time.Hour), Duration: 60, Target: 2, Subject: 1}}
	oldVersion := root.Version
	root.Version++
	root.UpdatedAt = root.CreatedAt
	if err = store.SaveRootTx(ctx, transaction, root, oldVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	settlingRootVersion := root.Version
	at := time.Now().UTC()

	service.Timed.Binder.Time = fixedBookReadTime{at: at}
	settled, err := service.Read(ctx, actor, 1056, op())
	if err != nil {
		t.Fatal(err)
	}
	idle, err := service.Read(ctx, actor, 1056, op())
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(settled, idle) {
		t.Fatalf("settled and snapshot bodies differ:\nsettled %#v\nidle    %#v", settled, idle)
	}
	stored := bookRoot(t, database, actor)
	if stored.Version != settlingRootVersion+1 {
		t.Fatalf("state versions: stored %d, want one settle write from %d", stored.Version, settlingRootVersion)
	}
}
