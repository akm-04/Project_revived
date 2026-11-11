//go:build postgres

package guildcampaign

import (
	"context"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type campaignDropMetrics struct {
	counters map[string]uint64
}

func (m *campaignDropMetrics) Counter(name string, _ observability.Labels, delta uint64) {
	m.counters[name] += delta
}
func (m *campaignDropMetrics) Observe(string, observability.Labels, time.Duration) {}
func (m *campaignDropMetrics) count(name string) uint64                            { return m.counters[name] }

func campaignPool(t *testing.T) *postgres.Pool {
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

func campaignPlayer(t *testing.T, p *postgres.Pool) identity.PlayerID {
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

func noticeService(metrics observability.Metrics) Service {
	return Service{Mail: i5.SettlementMail{Store: i5store.Store{}}, Metrics: metrics,
		Notice: NoticeMail{Enabled: true, OpenTitle: "Open", OpenBody: "Body", ResetTitle: "Reset", ResetBody: "Body", Sender: "Guild"}}
}

// TestGuildCampaignNoticeDropsInvalidRecipientAndKeepsChapterWrite (D1): a
// notice request that fails its own validation is dropped and counted once,
// and the chapter open or reset in the same transaction commits.
func TestGuildCampaignNoticeDropsInvalidRecipientAndKeepsChapterWrite(t *testing.T) {
	ctx := context.Background()
	p := campaignPool(t)
	player := campaignPlayer(t, p)
	metrics := &campaignDropMetrics{counters: map[string]uint64{}}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-committed' WHERE player_id=$1`, int64(player)); err != nil {
		t.Fatal(err)
	}
	if err = noticeService(metrics).noticeTx(ctx, tr, d.Chapter{GuildID: 1, ChapterID: 1, Run: 1}, false, []identity.PlayerID{0}, time.Now().UTC()); err != nil {
		t.Fatalf("invalid notice cancelled the chapter: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if got := metrics.count("guild_campaign_notice_dropped"); got != 1 {
		t.Fatalf("dropped counter=%d want 1", got)
	}
	var rows int64
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE source_kind=$1`, noticeSource).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("notice rows=%d want 0", rows)
	}
	var committed string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(player)).Scan(&committed); err != nil {
		t.Fatal(err)
	}
	if committed != "repair-r2-committed" {
		t.Fatalf("chapter write rolled back: %q", committed)
	}
}

// TestGuildCampaignNoticeDatabaseErrorRollsBackChapter (D1): a database error
// in the optional notice write stays fatal and rolls the chapter write back.
func TestGuildCampaignNoticeDatabaseErrorRollsBackChapter(t *testing.T) {
	ctx := context.Background()
	p := campaignPool(t)
	member := campaignPlayer(t, p)
	if _, err := p.Raw().Exec(ctx, `ALTER TABLE mail_records RENAME TO mail_records_repair_r2`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if _, err := p.Raw().Exec(context.Background(), `ALTER TABLE mail_records_repair_r2 RENAME TO mail_records`); err != nil {
			t.Errorf("restore mail_records: %v", err)
		}
	})
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-must-roll-back' WHERE player_id=$1`, int64(member)); err != nil {
		t.Fatal(err)
	}
	err = noticeService(&campaignDropMetrics{counters: map[string]uint64{}}).noticeTx(ctx, tr, d.Chapter{GuildID: 1, ChapterID: 1, Run: 1}, false, []identity.PlayerID{member}, time.Now().UTC())
	if err == nil {
		t.Fatal("database error in the notice write was not returned")
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var version string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(member)).Scan(&version); err != nil {
		t.Fatal(err)
	}
	if version == "repair-r2-must-roll-back" {
		t.Fatal("chapter write committed despite the fatal notice error")
	}
}

// TestGuildCampaignRewardMailDatabaseErrorRollsBackChapter (D1): the mandatory
// attachment mail keeps the fatal path, so a database error rolls back the
// chapter write that produced the reward.
func TestGuildCampaignRewardMailDatabaseErrorRollsBackChapter(t *testing.T) {
	ctx := context.Background()
	p := campaignPool(t)
	member := campaignPlayer(t, p)
	if _, err := p.Raw().Exec(ctx, `ALTER TABLE mail_attachments RENAME TO mail_attachments_repair_r2`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if _, err := p.Raw().Exec(context.Background(), `ALTER TABLE mail_attachments_repair_r2 RENAME TO mail_attachments`); err != nil {
			t.Errorf("restore mail_attachments: %v", err)
		}
	})
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE players SET bootstrap_profile_version='repair-r2-must-roll-back' WHERE player_id=$1`, int64(member)); err != nil {
		t.Fatal(err)
	}
	request := i5.SettlementMailRequest{Recipient: member, SourceKind: "REPAIR_R2_REWARD", SourceKey: "1", Title: "Reward",
		Sender: "Guild", Body: "Body", PolicyVersion: policyVersion, At: time.Now().UTC(),
		Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "dungeon_coin", Amount: 5}}}
	_, _, err = i5.SettlementMail{Store: i5store.Store{}}.DeliverTx(ctx, tr, request)
	if err == nil {
		t.Fatal("database error in the mandatory reward mail was not returned")
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var version string
	if err = p.Raw().QueryRow(ctx, `SELECT bootstrap_profile_version FROM players WHERE player_id=$1`, int64(member)).Scan(&version); err != nil {
		t.Fatal(err)
	}
	if version == "repair-r2-must-roll-back" {
		t.Fatal("chapter write committed despite the fatal reward-mail error")
	}
}
