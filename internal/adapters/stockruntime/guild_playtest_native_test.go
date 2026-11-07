//go:build postgres

package stockruntime

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/i5"
	dcombat "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type playtestCampaignContent struct{}

func (playtestCampaignContent) ChapterInfo(int64) (app.ChapterInfo, bool) {
	return app.ChapterInfo{}, false
}
func (playtestCampaignContent) CopyInfo(int64, int64) (app.CopyInfo, bool) {
	return app.CopyInfo{}, false
}
func (playtestCampaignContent) ChapterOfCopy(int64) (int64, bool) { return 0, false }
func (playtestCampaignContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return "i9-10-playtest-content", nil
}

type playtestCampaignCombat struct{}

func (playtestCampaignCombat) StartTx(context.Context, tx.Tx, ca.CoherentReadScope, combat.StartRequest) (combat.Started, error) {
	return combat.Started{}, nil
}
func (playtestCampaignCombat) AttestSummaryTx(context.Context, tx.Tx, combat.SummaryRequest) (combat.SummaryAttested, error) {
	return combat.SummaryAttested{}, nil
}
func (playtestCampaignCombat) BorrowedTx(context.Context, tx.Tx, dcombat.Locator) (bool, error) {
	return false, nil
}

type playtestCampaignGrants struct{}

func (playtestCampaignGrants) SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error) {
	return i5.GrantResult{}, nil
}

type playtestCampaignFacts struct{}

func (playtestCampaignFacts) PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error) {
	return context.Background(), nil
}
func (playtestCampaignFacts) RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error {
	return nil
}

type playtestCampaignMail struct{}

func (playtestCampaignMail) DeliverTx(context.Context, tx.Tx, i5.SettlementMailRequest) (mail.Record, bool, error) {
	return mail.Record{}, false, nil
}

type playtestCampaignFence struct{}

func (playtestCampaignFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

func playtestGuildLogMode(p *pg.Pool) app.Mode {
	return app.Mode{
		Service:   app.Service{Runner: tx.Runner{DB: p}, Guilds: guildstore.Store{Queryer: p}, Fence: playtestCampaignFence{}, Players: i4store.PlayerRootLocker{}},
		ModeStore: guildcampaignstore.Store{}, Content: playtestCampaignContent{},
		Settings: app.Settings{RetentionDays: 30},
		Combat:   playtestCampaignCombat{}, Grants: playtestCampaignGrants{}, Facts: playtestCampaignFacts{},
		Directory: i4store.PlayerDirectoryReader{Queryer: p}, Mail: playtestCampaignMail{},
		Fresh: p, Revisions: playtestCampaignContent{},
	}
}

func seedPlaytestProfiles(t *testing.T, c context.Context, p *pg.Pool, actors []identity.ActorContext) {
	t.Helper()
	for _, actor := range actors {
		if _, err := p.Raw().Exec(c, `INSERT INTO player_directory_profiles(player_id,name,lev,vip,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id,state_version,created_at,updated_at)
			VALUES($1,$2,1,0,110001001,0,0,1,1,clock_timestamp(),clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`,
			int64(actor.PlayerID), fmt.Sprintf("p%d", actor.PlayerID)); err != nil {
			t.Fatal(err)
		}
	}
}

func playtestGuildPool(t *testing.T) (*pg.Pool, []identity.ActorContext, guildcore.Service, context.Context) {
	t.Helper()
	dsn := os.Getenv("GXB_GUILD_NOTICE_DSN")
	if dsn == "" {
		t.Skip("GXB_GUILD_NOTICE_DSN with a migrated disposable database is required")
	}
	c, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	t.Cleanup(cancel)
	pool, err := pg.Open(c, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	actors := seedApplyNoticePlayers(t, c, pool)
	seedPlaytestProfiles(t, c, pool, actors)
	return pool, actors, applyNoticeGuildService(t, pool), c
}

func playtestJoin(t *testing.T, c context.Context, core guildcore.Service, leader identity.ActorContext, target identity.ActorContext, gid guild.ID, refs policy.Set) {
	t.Helper()
	if _, err := core.ApplyOrJoin(c, target, gid, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	if _, err := core.AcceptApplication(c, leader, target.PlayerID, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
}

func TestPlaytestGuildKickThenReapplyAnswers409AndWritesNoApplication(t *testing.T) {
	pool, actors, core, c := playtestGuildPool(t)
	leader, target := actors[0], actors[1]
	refs := policy.Set{}
	created, err := core.Create(c, leader, guildcore.CreateRequest{Name: fmt.Sprintf("K%d", leader.PlayerID), Icon: core.Policy.Policy.GuildIcons[0]}, applyNoticeOps(t, refs))
	if err != nil {
		t.Fatal(err)
	}
	gid := guild.ID(created.GuildID)
	playtestJoin(t, c, core, leader, target, gid, refs)

	now := time.Now().UTC()
	kick := env(587, nil, now)
	kick.Envelope.Operation = applyNoticeOps(t, refs)
	kick.Envelope.Params["member_id"] = int64(target.PlayerID)
	response := GuildDispatcher{Authority: httpAuthority{leader}, Core: core, View: fakeGuildView{}}.Dispatch(c, kick)
	if response.HTTPStatus != 200 {
		t.Fatalf("kick: %+v", response)
	}
	reapply := env(580, nil, now)
	reapply.Envelope.Operation = applyNoticeOps(t, refs)
	reapply.Envelope.Params["guild_id"] = int64(gid)
	response = GuildDispatcher{Authority: httpAuthority{target}, Core: core, View: fakeGuildView{}}.Dispatch(c, reapply)
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(30011) {
		t.Fatalf("reapply: %+v", response)
	}
	if _, exists := response.Body["time"]; exists {
		t.Fatalf("30011 invented time: %+v", response.Body)
	}
	var applications int64
	if err := pool.QueryRow(c, `SELECT count(*) FROM guild_applications WHERE guild_id=$1 AND player_id=$2`, int64(gid), int64(target.PlayerID)).Scan(&applications); err != nil {
		t.Fatal(err)
	}
	if applications != 0 {
		t.Fatalf("refused reapply wrote %d application rows", applications)
	}
}

// Bug 29: the stock weighted length allows 20 half-width characters; the table check once refused more than 10.
func TestPlaytestGuildCreateAcceptsLongHalfWidthName(t *testing.T) {
	_, actors, core, c := playtestGuildPool(t)
	if _, err := core.Create(c, actors[0], guildcore.CreateRequest{Name: fmt.Sprintf("Guildless %d", actors[0].PlayerID), Icon: core.Policy.Policy.GuildIcons[0]}, applyNoticeOps(t, policy.Set{})); err != nil {
		t.Fatal(err)
	}
}

func TestPlaytestGuildLogMergesMembershipEvents(t *testing.T) {
	pool, actors, core, c := playtestGuildPool(t)
	leader, applicant := actors[0], actors[1]
	refs := policy.Set{}
	created, err := core.Create(c, leader, guildcore.CreateRequest{Name: fmt.Sprintf("L%d", leader.PlayerID), Icon: core.Policy.Policy.GuildIcons[0]}, applyNoticeOps(t, refs))
	if err != nil {
		t.Fatal(err)
	}
	gid := guild.ID(created.GuildID)
	playtestJoin(t, c, core, leader, applicant, gid, refs)
	if _, err = core.SetRole(c, leader, guildcore.RoleRequest{MemberID: applicant.PlayerID, Role: guild.Deputy}, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	if _, err = core.Kick(c, leader, applicant.PlayerID, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}

	response := GuildCampaignDispatcher{Authority: httpAuthority{leader}, Service: playtestGuildLogMode(pool)}.Dispatch(c, env(609, nil, time.Now().UTC()))
	if response.HTTPStatus != 200 {
		t.Fatalf("609: %+v", response)
	}
	rows, ok := response.Body["guild_log"].([]any)
	if !ok || len(rows) < 3 {
		t.Fatalf("609 rows: %+v", response.Body)
	}
	seen := map[int64]bool{}
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			t.Fatalf("609 row: %T", raw)
		}
		kind, _ := row["type"].(int64)
		switch kind {
		case 3, 5, 12:
			name, _ := row["member_name"].(string)
			if name == "" {
				t.Fatalf("type %d lost member_name: %+v", kind, row)
			}
			seen[kind] = true
		}
		if kind == 10 || kind == 14 {
			t.Fatalf("unexpected log type %d: %+v", kind, row)
		}
	}
	for _, kind := range []int64{5, 12, 3} {
		if !seen[kind] {
			t.Fatalf("609 missing type %d: %+v", kind, rows)
		}
	}
}
