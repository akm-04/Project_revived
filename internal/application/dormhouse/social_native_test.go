//go:build postgres

package dormhouse_test

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/application/generation"
	i5dom "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const socialRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

type socialFence struct{}

func (socialFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type socialPlayers struct{}

func (socialPlayers) LockPlayerRootsTx(_ context.Context, _ tx.Tx, server identity.LogicalServerID, players []identity.PlayerID) ([]playerroot.Root, error) {
	out := make([]playerroot.Root, 0, len(players))
	for _, player := range players {
		out = append(out, playerroot.Root{PlayerID: player, LogicalServerID: server})
	}
	return out, nil
}

type socialValues struct{}

func (socialValues) ReadDormPlayerStateTx(_ context.Context, _ tx.Queryer, player identity.PlayerID, at time.Time) (i5dom.DormPlayerState, error) {
	return i5dom.DormPlayerState{Player: player, Level: 10, LevelVersion: 1, UpdatedAt: at, Functions: map[int64]i5dom.DormFunctionFact{71: {FunctionID: 71, StateVersion: 1, OpenedAt: at}}}, nil
}

func (socialValues) LockDormPlayerStateTx(ctx context.Context, q tx.Tx, player identity.PlayerID, at time.Time) (i5dom.DormPlayerState, error) {
	return socialValues{}.ReadDormPlayerStateTx(ctx, q, player, at)
}

func (socialValues) ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error) {
	return nil, nil
}

type socialHeroes struct{}

func (socialHeroes) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error) {
	return character.HeroRoot{}, nil
}
func (socialHeroes) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error) {
	return character.HeroRoot{}, nil
}
func (socialHeroes) ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error) {
	return character.Hero{}, nil
}
func (socialHeroes) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	return character.Hero{}, nil
}
func (socialHeroes) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	return nil, nil
}

type socialContent struct{}

func (socialContent) DormCatalogTx(context.Context, tx.Queryer, string) (dorm.Catalog, error) {
	return dorm.Catalog{}, nil
}
func (socialContent) HeroTemplateProgressionTx(context.Context, tx.Queryer, string, int64) (character.HeroTemplateProgression, error) {
	return character.HeroTemplateProgression{}, nil
}
func (socialContent) DormInputsActive(context.Context) (string, bool, error) {
	return socialRevision, true, nil
}
func (socialContent) DormInputsRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return true, nil
}

type socialDirectory struct{}

func (socialDirectory) ProfileTx(_ context.Context, _ tx.Tx, player identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{PlayerID: player, Name: "P" + playerString(player), Level: 10, AvatarID: 1, AvatarFrameID: 0}, true, nil
}
func (socialDirectory) ProfilesByExactNameTx(context.Context, tx.Tx, string, int) ([]playerdirectory.Profile, error) {
	return nil, nil
}
func (socialDirectory) PlayerIDBoundsTx(context.Context, tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error) {
	return 100001, 199999, true, nil
}
func (socialDirectory) ProfilesAfterTx(_ context.Context, _ tx.Tx, after identity.PlayerID, limit int) ([]playerdirectory.Profile, error) {
	if limit != 256 {
		return nil, errors.New("unexpected limit")
	}
	out := []playerdirectory.Profile{}
	for _, player := range []identity.PlayerID{126701, 126702, 126703} {
		if player > after {
			out = append(out, playerdirectory.Profile{PlayerID: player, Name: "P" + playerString(player), Level: 10, AvatarID: 1})
		}
	}
	return out, nil
}

func playerString(player identity.PlayerID) string {
	return string([]byte{byte('0' + int64(player)%10)})
}

func socialActor(player identity.PlayerID) identity.ActorContext {
	mk := func(b byte) ids.UUID { var u ids.UUID; u[15] = b; return u }
	account, _ := identity.AccountIDFrom(mk(1))
	session, _ := identity.SessionIDFrom(mk(2))
	contextID, _ := identity.ContextIDFrom(mk(3))
	return identity.ActorContext{AccountID: account, AccountUID: identity.AccountUID("20000007"), SessionID: session, ContextID: contextID, LogicalServerID: 1, PlayerID: player, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

type socialHarness struct {
	service app.Service
	pool    *pg.Pool
	owner   identity.ActorContext
	viewer  identity.ActorContext
	author  identity.ActorContext
}

func newSocialHarness(t *testing.T) socialHarness {
	t.Helper()
	dsn := os.Getenv("GXB_C10S_DSN")
	if dsn == "" {
		t.Skip("GXB_C10S_DSN requires a migrated c10s database")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "i9-10c-social-app"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	now := time.Now().UTC().Truncate(time.Microsecond)
	for _, player := range []identity.PlayerID{126701, 126702, 126703} {
		if _, err = pool.Raw().Exec(context.Background(), `INSERT INTO player_dorm_roots(player_id,next_house_id,state_version,created_at,updated_at) VALUES($1,2,1,$2,$2) ON CONFLICT DO NOTHING`, int64(player), now); err != nil {
			t.Fatal(err)
		}
		if _, err = pool.Raw().Exec(context.Background(), `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,created_at,updated_at) VALUES($1,1,1000001,1,repeat('a',64),1,1,0,0,1,'{}',$2,$2) ON CONFLICT DO NOTHING`, int64(player), now); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		for _, player := range []identity.PlayerID{126701, 126702, 126703} {
			for _, statement := range []string{
				`DELETE FROM player_dorm_comment_reactions WHERE player_id=$1`,
				`DELETE FROM player_dorm_comments WHERE player_id=$1`,
				`DELETE FROM player_dorm_praises WHERE player_id=$1`,
				`DELETE FROM player_dorm_room_social WHERE player_id=$1`,
				`DELETE FROM player_dorm_rooms WHERE player_id=$1`,
				`DELETE FROM player_dorm_roots WHERE player_id=$1`,
			} {
				if _, err = pool.Raw().Exec(context.Background(), statement, int64(player)); err != nil {
					t.Error(err)
				}
			}
		}
	})
	runner := tx.Runner{DB: pool}
	service := app.Service{
		Timed:     generation.TimedRunner{Binder: generation.Binder{Time: pgAuthoritativeTime{pool}}, Runner: runner},
		Reads:     runner,
		Heroes:    socialHeroes{},
		Owner:     dormstore.Store{},
		Content:   socialContent{},
		Players:   socialPlayers{},
		Fence:     socialFence{},
		Values:    socialValues{},
		Receipts:  kernelstore.Store{},
		Social:    dormstore.Store{},
		Directory: socialDirectory{},
	}
	return socialHarness{service: service, pool: pool, owner: socialActor(126701), viewer: socialActor(126702), author: socialActor(126703)}
}

type pgAuthoritativeTime struct{ pool *pg.Pool }

func (a pgAuthoritativeTime) Now(ctx context.Context) (time.Time, error) {
	var now time.Time
	if err := a.pool.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&now); err != nil {
		return time.Time{}, err
	}
	return now.UTC(), nil
}

func (h socialHarness) command(t *testing.T, actor identity.ActorContext, command app.Command) map[string]any {
	t.Helper()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	result, err := h.service.Command(context.Background(), actor, command, op)
	if err != nil {
		t.Fatal(err)
	}
	return result.Body
}

func (h socialHarness) socialRead(t *testing.T, actor identity.ActorContext, mid uint16, host, house, start, offset int64) (map[string]any, error) {
	t.Helper()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	return h.service.SocialRead(context.Background(), actor, op, mid, host, house, start, offset)
}

func TestDormSocialCommandMIDsThroughProductionPath(t *testing.T) {
	h := newSocialHarness(t)
	body := h.command(t, h.owner, app.Command{Family: app.ChangeName, HouseID: 1, HouseName: "hall"})
	if len(body) != 0 {
		t.Fatalf("change name reply %v", body)
	}
	var name string
	if err := h.pool.QueryRow(context.Background(), `SELECT house_name FROM player_dorm_room_social WHERE player_id=126701 AND house_id=1`).Scan(&name); err != nil || name != "hall" {
		t.Fatal(name, err)
	}
	body = h.command(t, h.owner, app.Command{Family: app.HideHouse, HouseID: 1})
	info, _ := body["house_info"].(map[string]any)
	if info == nil || info["is_hide"] != int64(1) || info["house_type"] != int64(1) {
		t.Fatalf("hide reply %v", body)
	}
	if _, err := h.socialRead(t, h.viewer, 2524, 126701, 1, 0, 20); !errors.Is(err, dorm.ErrHidden) {
		t.Fatalf("hidden foreign comment list: %v", err)
	}
	h.command(t, h.owner, app.Command{Family: app.HideHouse, HouseID: 1})

	praise := h.command(t, h.viewer, app.Command{Family: app.PraiseHouse, HostID: 126701, HouseID: 1})
	if praise["praise_num"] != int64(1) || praise["is_has_praise"] != int64(1) {
		t.Fatal(praise)
	}
	repeat := h.command(t, h.viewer, app.Command{Family: app.PraiseHouse, HostID: 126701, HouseID: 1})
	if repeat["praise_num"] != int64(1) {
		t.Fatalf("duplicate praise not idempotent: %v", repeat)
	}
	page, err := h.socialRead(t, h.owner, 2522, 0, 1, 0, 20)
	if err != nil || page["total_num"] != int64(1) {
		t.Fatal(page, err)
	}
	if _, err = h.socialRead(t, h.owner, 2522, 0, 1, 2, 20); err == nil {
		t.Fatal("praise start past total accepted")
	}

	commentBody := h.command(t, h.viewer, app.Command{Family: app.CommentHouse, HostID: 126701, HouseID: 1, Content: "hello"})
	if commentBody["comment_num"] != int64(1) {
		t.Fatal(commentBody)
	}
	best, ok := commentBody["best_comments"].([]any)
	if !ok || len(best) != 1 {
		t.Fatalf("best comments missing: %v", commentBody)
	}
	row := best[0].(map[string]any)
	commentID := row["comment_id"].(int64)
	if row["from_player_info"].(map[string]any)["player_name"] == nil || row["content"] != "hello" || row["is_has_praise"] != int64(0) {
		t.Fatalf("comment row %v", row)
	}
	commentPage, err := h.socialRead(t, h.viewer, 2524, 126701, 1, 0, 20)
	if err != nil || commentPage["comment_num"] != int64(1) {
		t.Fatal(commentPage, err)
	}
	if _, err = h.socialRead(t, h.viewer, 2524, 126701, 1, 203, 20); err == nil {
		t.Fatal("comment start above the stale-page bound accepted")
	}

	reaction := h.command(t, h.author, app.Command{Family: app.PraiseComment, HostID: 126701, HouseID: 1, CommentID: commentID})
	info, _ = reaction["comment_info"].(map[string]any)
	if info == nil || info["comment_id"] != commentID || info["is_has_praise"] != int64(1) || info["content"] != "hello" {
		t.Fatalf("reaction reply %v", reaction)
	}
	repeat = h.command(t, h.author, app.Command{Family: app.PraiseComment, HostID: 126701, HouseID: 1, CommentID: commentID})
	if repeat["comment_info"].(map[string]any)["is_has_praise"] != int64(1) {
		t.Fatalf("duplicate reaction: %v", repeat)
	}
	if likes, err := (dormstore.Store{}).CommentLikesTx(context.Background(), h.pool, dorm.RoomTarget{Server: 1, Owner: 126701, HouseID: 1}, commentID); err != nil || likes != 1 {
		t.Fatal(likes, err)
	}
	deleteBody := h.command(t, h.owner, app.Command{Family: app.DeleteComment, HouseID: 1, CommentID: commentID})
	if len(deleteBody) != 0 {
		t.Fatal(deleteBody)
	}
	commentPage, err = h.socialRead(t, h.viewer, 2524, 126701, 1, 0, 20)
	if err != nil || commentPage["comment_num"] != int64(0) || len(commentPage["comment_list"].([]any)) != 0 {
		t.Fatal(commentPage, err)
	}
	if likes, err := (dormstore.Store{}).CommentLikesTx(context.Background(), h.pool, dorm.RoomTarget{Server: 1, Owner: 126701, HouseID: 1}, commentID); err != nil || likes != 0 {
		t.Fatal("reactions survived comment delete", likes, err)
	}

	random, err := h.socialRead(t, h.viewer, 2519, 0, 0, 0, 1)
	if err != nil {
		t.Fatal(err)
	}
	hostInfo, _ := random["host_info"].(map[string]any)
	houseInfos, _ := random["house_infos"].(map[string]any)
	if hostInfo == nil || hostInfo["player_id"] == nil || houseInfos == nil || houseInfos["house_list"] == nil {
		t.Fatalf("random visit reply %v", random)
	}
}

func TestDormSocialRefusalsThroughProductionPath(t *testing.T) {
	h := newSocialHarness(t)
	command := func(actor identity.ActorContext, value app.Command) error {
		op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
		if err != nil {
			t.Fatal(err)
		}
		_, err = h.service.Command(context.Background(), actor, value, op)
		return err
	}
	if err := command(h.viewer, app.Command{Family: app.PraiseHouse, HostID: 126702, HouseID: 1}); !errors.Is(err, app.ErrRejected) {
		t.Fatalf("self praise: %v", err)
	}
	if err := command(h.owner, app.Command{Family: app.ChangeName, HouseID: 1, HouseName: "1234567890123"}); !errors.Is(err, app.ErrRejected) {
		t.Fatalf("long name: %v", err)
	}
	if err := command(h.viewer, app.Command{Family: app.CommentHouse, HostID: 126701, HouseID: 1, Content: "1234567890123456789012345678901234567890123456789012345678901"}); !errors.Is(err, app.ErrRejected) {
		t.Fatalf("long comment: %v", err)
	}
	if err := command(h.owner, app.Command{Family: app.PraiseComment, HostID: 126701, HouseID: 1, CommentID: 999}); !errors.Is(err, app.ErrRejected) {
		t.Fatalf("missing comment reaction: %v", err)
	}
	if err := command(h.owner, app.Command{Family: app.DeleteComment, HouseID: 1, CommentID: 999}); !errors.Is(err, app.ErrRejected) {
		t.Fatalf("missing comment delete: %v", err)
	}
}
