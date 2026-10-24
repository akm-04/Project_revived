//go:build postgres && river

package riveradapter

import (
	"context"
	"github.com/riverqueue/river/riverdriver/riverpgxv5"
	"github.com/riverqueue/river/rivermigrate"
	"gxb.local/backend/v2/internal/adapters/postgres"
	gb "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

func TestRealGuildInsertOnlyRollbackAndCommit(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8_WORKING_DSN")
	if dsn == "" {
		t.Skip("explicit scoped working-copy real PostgreSQL/River DSN required")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 3, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	// Explicit test/deployment migration; producer constructors never migrate.
	m, e := rivermigrate.New(riverpgxv5.New(p.Raw()), nil)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = m.Migrate(c, rivermigrate.DirectionUp, nil); e != nil {
		t.Fatal(e)
	}
	valid, e := m.Validate(c, nil)
	if e != nil || !valid.OK {
		t.Fatal(valid, e)
	}
	queue, e := NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	id, _ := ids.NewUUID()
	o, e := gb.MailObligation(id, 100001, time.Date(2026, 10, 9, 9, 0, 0, 0, time.UTC))
	if e != nil {
		t.Fatal(e)
	}
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	if e = queue.InsertTx(c, x, o); e != nil {
		t.Fatal(e)
	}
	var count int64
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key'=$1`, o.SemanticKey).Scan(&count); e != nil || count != 0 {
		t.Fatal("uncommitted job visible", count, e)
	}
	if e = x.Rollback(c); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key'=$1`, o.SemanticKey).Scan(&count); e != nil || count != 0 {
		t.Fatal("rollback retained job", count, e)
	}
	x, e = p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	if e = queue.InsertTx(c, x, o); e != nil {
		t.Fatal(e)
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key'=$1 AND state='scheduled' AND queue='guild_materialization' AND scheduled_at=$2 AND args->>'queue'='guild.materialization'`, o.SemanticKey, o.DueAt).Scan(&count); e != nil || count != 1 {
		t.Fatal("committed insertion missing", count, e)
	}
	o.Profile = "forged"
	x, e = p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	if e = queue.InsertTx(c, x, o); e == nil {
		t.Fatal("invalid profile inserted")
	}
	x.Rollback(c)
	t.Log("Real pinned River insert-only: source transaction visibility/rollback/commit and profile rejection; production worker/crash/recovery NOT_RUN")
}
