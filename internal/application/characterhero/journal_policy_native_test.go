//go:build postgres

package characterhero

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type journalDropMetrics struct {
	counters map[string]uint64
}

func (m *journalDropMetrics) Counter(name string, _ observability.Labels, delta uint64) {
	m.counters[name] += delta
}
func (m *journalDropMetrics) Observe(string, observability.Labels, time.Duration) {}
func (m *journalDropMetrics) count(name string) uint64                            { return m.counters[name] }

func journalPool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_REPAIR_R2_DSN")
	if dsn == "" {
		t.Skip("GXB_REPAIR_R2_DSN required")
	}
	p, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func journalPlayer(t *testing.T, p *postgres.Pool) identity.PlayerID {
	t.Helper()
	ctx := context.Background()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	var playerID int64
	if err = tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&playerID); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'repair-r2')`, playerID, account.String()); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return identity.PlayerID(playerID)
}

// TestHeroJournalDropsInvalidDiaryRowAndKeepsMilestone (D1): a Girls Log row
// that fails its own validation is dropped and counted once, and the star,
// promotion or awakening milestone in the same transaction commits.
func TestHeroJournalDropsInvalidDiaryRowAndKeepsMilestone(t *testing.T) {
	ctx := context.Background()
	p := journalPool(t)
	player := journalPlayer(t, p)
	metrics := &journalDropMetrics{counters: map[string]uint64{}}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-committed' WHERE player_id=$1`, int64(player)); err != nil {
		t.Fatal(err)
	}
	service := Service{Journals: librarystore.Store{}, Metrics: metrics}
	if err = service.recordHeroJournalTx(ctx, tr, player, 0, lib.LogAwakened, time.Now().UTC()); err != nil {
		t.Fatalf("invalid diary row cancelled the milestone: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if got := metrics.count("girls_log_dropped"); got != 1 {
		t.Fatalf("dropped counter=%d want 1", got)
	}
	var rows int64
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM player_library_hero_logs WHERE player_id=$1`, int64(player)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("diary rows=%d want 0", rows)
	}
	var committed string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(player)).Scan(&committed); err != nil {
		t.Fatal(err)
	}
	if committed != "repair-r2-committed" {
		t.Fatalf("milestone rolled back: %q", committed)
	}
}

// TestHeroJournalDatabaseErrorRollsBackMilestone (D1): a database error in the
// optional diary insert stays fatal and rolls the milestone back.
func TestHeroJournalDatabaseErrorRollsBackMilestone(t *testing.T) {
	ctx := context.Background()
	p := journalPool(t)
	player := journalPlayer(t, p)
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	// A column-less temp table shadows player_library_hero_logs for this session only, so the
	// write fails without touching the table other packages share.
	if _, err = tr.Exec(ctx, `CREATE TEMP TABLE player_library_hero_logs () ON COMMIT DROP`); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-must-roll-back' WHERE player_id=$1`, int64(player)); err != nil {
		t.Fatal(err)
	}
	service := Service{Journals: librarystore.Store{}, Metrics: &journalDropMetrics{counters: map[string]uint64{}}}
	err = service.recordHeroJournalTx(ctx, tr, player, 1, lib.LogAwakened, time.Now().UTC())
	if err == nil || errors.Is(err, lib.ErrInvalidFacts) {
		t.Fatalf("database error not surfaced: %v", err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var version string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(player)).Scan(&version); err != nil {
		t.Fatal(err)
	}
	if version == "repair-r2-must-roll-back" {
		t.Fatal("milestone committed despite the fatal diary error")
	}
}
