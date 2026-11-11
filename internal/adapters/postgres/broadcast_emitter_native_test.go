//go:build postgres

package postgres

import (
	"context"
	"os"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/broadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type broadcastDropMetrics struct {
	counters map[string]uint64
}

func (m *broadcastDropMetrics) Counter(name string, _ observability.Labels, delta uint64) {
	m.counters[name] += delta
}
func (m *broadcastDropMetrics) Observe(string, observability.Labels, time.Duration) {}
func (m *broadcastDropMetrics) count(name string) uint64                            { return m.counters[name] }

func repairR2Pool(t *testing.T) *Pool {
	t.Helper()
	dsn := os.Getenv("GXB_REPAIR_R2_DSN")
	if dsn == "" {
		t.Skip("GXB_REPAIR_R2_DSN required")
	}
	p, err := Open(context.Background(), dsn, PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func repairR2Player(t *testing.T, p *Pool, server identity.LogicalServerID) identity.PlayerID {
	t.Helper()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(context.Background(), tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(context.Background())
	var playerID int64
	if err = tr.QueryRow(context.Background(), `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=$1 RETURNING next_player_id-1`, int64(server)).Scan(&playerID); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(context.Background(), `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(context.Background(), `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'repair-r2')`, playerID, account.String(), int64(server)); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
	return identity.PlayerID(playerID)
}

// TestBroadcastEmitterDropsInvalidAnnouncementAndCommitsGameplay (D1): an
// announcement that fails its own validation is not inserted, is counted once,
// and the gameplay in the same transaction still commits.
func TestBroadcastEmitterDropsInvalidAnnouncementAndCommitsGameplay(t *testing.T) {
	ctx := context.Background()
	p := repairR2Pool(t)
	metrics := &broadcastDropMetrics{counters: map[string]uint64{}}
	player := repairR2Player(t, p, 1)
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-committed' WHERE player_id=$1`, int64(player)); err != nil {
		t.Fatal(err)
	}
	invalid := app.Message{MID: app.SystemMID, MsgType: app.ConquerSchool, Server: 1, Player: player,
		Fields: app.Fields{Region: 0, ConquerLoopID: 1, ConquerLev: 1}}
	if err = (BroadcastEmitter{Metrics: metrics}).EmitTx(ctx, tr, invalid); err != nil {
		t.Fatalf("invalid announcement cancelled gameplay: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if got := metrics.count("broadcast_announcement_dropped"); got != 1 {
		t.Fatalf("dropped counter=%d want 1", got)
	}
	var outbox int64
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM broadcast_outbox WHERE player_id=$1`, int64(player)).Scan(&outbox); err != nil {
		t.Fatal(err)
	}
	if outbox != 0 {
		t.Fatalf("outbox rows=%d want 0", outbox)
	}
	var committed string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(player)).Scan(&committed); err != nil {
		t.Fatal(err)
	}
	if committed != "repair-r2-committed" {
		t.Fatalf("gameplay write rolled back: %q", committed)
	}
}

// TestBroadcastEmitterDatabaseErrorRollsBackGameplay (D1): a real database
// error in the optional outbox write stays fatal and rolls the gameplay back.
func TestBroadcastEmitterDatabaseErrorRollsBackGameplay(t *testing.T) {
	ctx := context.Background()
	p := repairR2Pool(t)
	player := repairR2Player(t, p, 1)
	if _, err := p.Raw().Exec(ctx, `ALTER TABLE broadcast_outbox RENAME TO broadcast_outbox_repair_r2`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if _, err := p.Raw().Exec(context.Background(), `ALTER TABLE broadcast_outbox_repair_r2 RENAME TO broadcast_outbox`); err != nil {
			t.Errorf("restore broadcast_outbox: %v", err)
		}
	})
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-must-roll-back' WHERE player_id=$1`, int64(player)); err != nil {
		t.Fatal(err)
	}
	valid := app.Message{MID: app.SystemMID, MsgType: app.ConquerSchool, Server: 1, Player: player,
		Fields: app.Fields{Region: 1, ConquerLoopID: 1, ConquerLev: 1}}
	if err = (BroadcastEmitter{Metrics: &broadcastDropMetrics{counters: map[string]uint64{}}}).EmitTx(ctx, tr, valid); err == nil {
		t.Fatal("database error in the outbox was not returned")
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var version string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(player)).Scan(&version); err != nil {
		t.Fatal(err)
	}
	if version == "repair-r2-must-roll-back" {
		t.Fatal("gameplay write committed despite the fatal outbox error")
	}
}
