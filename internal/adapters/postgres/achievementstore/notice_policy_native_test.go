//go:build postgres

package achievementstore_test

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	app "gxb.local/backend/v2/internal/application/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type noticeDropMetrics struct {
	counters map[string]uint64
}

func (m *noticeDropMetrics) Counter(name string, _ observability.Labels, delta uint64) {
	m.counters[name] += delta
}
func (m *noticeDropMetrics) Observe(string, observability.Labels, time.Duration) {}
func (m *noticeDropMetrics) count(name string) uint64                            { return m.counters[name] }

func noticePool(t *testing.T) *postgres.Pool {
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

func noticePlayer(t *testing.T, p *postgres.Pool) identity.PlayerID {
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
	var revision string
	if err = tr.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions LIMIT 1`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(ctx, `INSERT INTO achievement_roots(player_id,content_revision,policy_id,progress,complete_times,state_version,created_at,updated_at)VALUES($1,$2,'C4B_MARRIED_POPULATION_TIER_FACTS_V1',0,'[null,null,null]'::jsonb,1,clock_timestamp(),clock_timestamp())`, playerID, revision); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return identity.PlayerID(playerID)
}

// TestAchievementNoticeDropsInvalidAndKeepsEarnedFact (D1): an out-of-range
// notice is not inserted and is counted once, while the earned tier fact and
// the other writes in the transaction commit.
func TestAchievementNoticeDropsInvalidAndKeepsEarnedFact(t *testing.T) {
	ctx := context.Background()
	p := noticePool(t)
	player := noticePlayer(t, p)
	metrics := &noticeDropMetrics{counters: map[string]uint64{}}
	at := time.Now().UTC()
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-committed' WHERE player_id=$1`, int64(player)); err != nil {
		t.Fatal(err)
	}
	notices := []app.Notice{
		{Player: player, AchievementID: 100033, Tier: 3, CompleteTime: at},
		{Player: player, AchievementID: 100034, Tier: 1, CompleteTime: at},
		{Player: player, AchievementID: 100014, Tier: 4, CompleteTime: at},
	}
	if err = (achievementstore.Store{Metrics: metrics}).PutNoticesTx(ctx, tr, notices); err != nil {
		t.Fatalf("invalid notice cancelled the transaction: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if got := metrics.count("achievement_notice_dropped"); got != 2 {
		t.Fatalf("dropped counter=%d want 2", got)
	}
	var stored int64
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM achievement_notices WHERE player_id=$1`, int64(player)).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if stored != 1 {
		t.Fatalf("notice rows=%d want 1", stored)
	}
	var committed string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(player)).Scan(&committed); err != nil {
		t.Fatal(err)
	}
	if committed != "repair-r2-committed" {
		t.Fatalf("earned-fact transaction rolled back: %q", committed)
	}
}

// TestAchievementNoticeDatabaseErrorRollsBackEarnedFact (D1): a database error
// in the optional notice insert stays fatal and rolls the earned fact back.
func TestAchievementNoticeDatabaseErrorRollsBackEarnedFact(t *testing.T) {
	ctx := context.Background()
	p := noticePool(t)
	player := noticePlayer(t, p)
	if _, err := p.Raw().Exec(ctx, `ALTER TABLE achievement_notices RENAME TO achievement_notices_repair_r2`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if _, err := p.Raw().Exec(context.Background(), `ALTER TABLE achievement_notices_repair_r2 RENAME TO achievement_notices`); err != nil {
			t.Errorf("restore achievement_notices: %v", err)
		}
	})
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE achievement_roots SET progress=500 WHERE player_id=$1`, int64(player)); err != nil {
		t.Fatal(err)
	}
	notice := []app.Notice{{Player: player, AchievementID: 100033, Tier: 3, CompleteTime: time.Now().UTC()}}
	err = (achievementstore.Store{}).PutNoticesTx(ctx, tr, notice)
	if err == nil || errors.Is(err, app.ErrInvalidNotice) {
		t.Fatalf("database error not surfaced: %v", err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var progress int64
	if err = p.Raw().QueryRow(ctx, `SELECT progress FROM achievement_roots WHERE player_id=$1`, int64(player)).Scan(&progress); err != nil {
		t.Fatal(err)
	}
	if progress == 500 {
		t.Fatal("earned fact committed despite the fatal notice error")
	}
}
