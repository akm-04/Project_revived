//go:build postgres

package dormhouse_test

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/characterasset"
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
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

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

type socialAwakening struct{}

func (socialAwakening) RawAwakeningTx(context.Context, characterasset.CoherentReadScope, character.HeroRef) (characterasset.HeroRawAwakeningObservation, error) {
	return characterasset.HeroRawAwakeningObservation{}, character.ErrRawAwakeningUnavailable
}

type socialContent struct{ revision string }

func (socialContent) DormCatalogTx(context.Context, tx.Queryer, string) (dorm.Catalog, error) {
	return dorm.Catalog{}, nil
}
func (socialContent) HeroTemplateProgressionTx(context.Context, tx.Queryer, string, int64) (character.HeroTemplateProgression, error) {
	return character.HeroTemplateProgression{}, nil
}
func (c socialContent) DormInputsActive(context.Context) (string, bool, error) {
	return c.revision, true, nil
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
func (socialDirectory) ProfilesByRecentActivityTx(_ context.Context, _ tx.Tx, server identity.LogicalServerID, exclude identity.PlayerID, limit int) ([]playerdirectory.Profile, error) {
	if server != 1 || limit != 256 {
		return nil, errors.New("unexpected recent-activity read")
	}
	out := []playerdirectory.Profile{}
	for _, player := range []identity.PlayerID{126701, 126702, 126703} {
		if player != exclude {
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
	players := []identity.PlayerID{126701, 126702, 126703}
	for _, player := range players {
		accountUID := "dormhouse-social-" + strconv.FormatInt(int64(player), 10)
		if _, err = pool.Raw().Exec(context.Background(), `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES(gen_random_uuid(),$1,'ACTIVE',$2) ON CONFLICT (account_uid) DO NOTHING`, accountUID, now); err != nil {
			t.Fatal(err)
		}
		if _, err = pool.Raw().Exec(context.Background(), `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) SELECT $1,account_id,1,$2,'dormhouse-social-native' FROM accounts WHERE account_uid=$3 ON CONFLICT (player_id) DO NOTHING`, int64(player), now, accountUID); err != nil {
			t.Fatal(err)
		}
	}
	for _, player := range players {
		if _, err = pool.Raw().Exec(context.Background(), `INSERT INTO player_dorm_roots(player_id,next_house_id,state_version,created_at,updated_at) VALUES($1,2,1,$2,$2) ON CONFLICT DO NOTHING`, int64(player), now); err != nil {
			t.Fatal(err)
		}
		if _, err = pool.Raw().Exec(context.Background(), `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,created_at,updated_at) VALUES($1,1,1000001,1,repeat('a',64),1,1,0,0,1,'{}',$2,$2) ON CONFLICT DO NOTHING`, int64(player), now); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		for _, player := range players {
			for _, statement := range []string{
				`DELETE FROM player_dorm_admissions WHERE player_id=$1`,
				`DELETE FROM player_dorm_comment_reactions WHERE player_id=$1`,
				`DELETE FROM player_dorm_comments WHERE player_id=$1`,
				`DELETE FROM player_dorm_praises WHERE player_id=$1`,
				`DELETE FROM player_dorm_room_social WHERE player_id=$1`,
				`DELETE FROM player_dorm_rooms WHERE player_id=$1`,
				`DELETE FROM player_dorm_roots WHERE player_id=$1`,
				`DELETE FROM players WHERE player_id=$1`,
			} {
				if _, err = pool.Raw().Exec(context.Background(), statement, int64(player)); err != nil {
					t.Error(err)
				}
			}
		}
		if _, err = pool.Raw().Exec(context.Background(), `DELETE FROM accounts WHERE account_uid LIKE 'dormhouse-social-%'`); err != nil {
			t.Error(err)
		}
	})
	runner := tx.Runner{DB: pool}
	revision, err := (contentstore.Store{Queryer: pool}).ActiveRevision(context.Background(), pool)
	if err != nil {
		t.Fatal(err)
	}
	service := app.Service{
		Timed:      generation.TimedRunner{Binder: generation.Binder{Time: pgAuthoritativeTime{pool}}, Runner: runner},
		Reads:      runner,
		Heroes:     socialHeroes{},
		Awakening:  socialAwakening{},
		Owner:      dormstore.Store{},
		Content:    socialContent{revision: revision},
		Players:    socialPlayers{},
		Fence:      socialFence{},
		Values:     socialValues{},
		Receipts:   kernelstore.Store{},
		Social:     dormstore.Store{},
		Directory:  socialDirectory{},
		Moderation: contentstore.Store{Queryer: pool},
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

func (h socialHarness) commandError(actor identity.ActorContext, command app.Command) error {
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		return err
	}
	_, err = h.service.Command(context.Background(), actor, command, op)
	return err
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

func TestDormSocialModerationUsesPublishedProfileCorpus(t *testing.T) {
	h := newSocialHarness(t)

	if body := h.command(t, h.owner, app.Command{Family: app.ChangeName, HouseID: 1, HouseName: "Fuck"}); len(body) != 0 {
		t.Fatalf("change name reply %v", body)
	}
	var name string
	if err := h.pool.QueryRow(context.Background(), `SELECT house_name FROM player_dorm_room_social WHERE player_id=126701 AND house_id=1`).Scan(&name); err != nil || name != "****" {
		t.Fatalf("blocked name stored %q %v", name, err)
	}
	hide := h.command(t, h.owner, app.Command{Family: app.HideHouse, HouseID: 1})
	if info, _ := hide["house_info"].(map[string]any); info == nil || info["house_name"] != "****" {
		t.Fatalf("masked name read %v", hide)
	}
	h.command(t, h.owner, app.Command{Family: app.HideHouse, HouseID: 1})

	commentBody := h.command(t, h.viewer, app.Command{Family: app.CommentHouse, HostID: 126701, HouseID: 1, Content: "hello Fuck"})
	if contents := commentContents(commentBody); commentBody["comment_num"] != int64(1) || len(contents) != 1 || contents[0] != "hello*****" {
		t.Fatalf("blocked comment reply %v", commentBody)
	}
	list, err := h.socialRead(t, h.viewer, 2524, 126701, 1, 0, 20)
	if err != nil || list["comment_num"] != int64(1) || !containsComment(list, "hello*****") {
		t.Fatalf("blocked comment read %v %v", list, err)
	}

	clean := strings.Repeat("a", 50)
	cleanBody := h.command(t, h.viewer, app.Command{Family: app.CommentHouse, HostID: 126701, HouseID: 1, Content: clean})
	if cleanBody["comment_num"] != int64(2) || !containsComment(cleanBody, clean) {
		t.Fatalf("clean comment changed or refused: %v", cleanBody)
	}
	h.command(t, h.owner, app.Command{Family: app.ChangeName, HouseID: 1, HouseName: "hall"})
	if err := h.pool.QueryRow(context.Background(), `SELECT house_name FROM player_dorm_room_social WHERE player_id=126701 AND house_id=1`).Scan(&name); err != nil || name != "hall" {
		t.Fatalf("clean name changed: %q %v", name, err)
	}
	if body := h.command(t, h.owner, app.Command{Family: app.ChangeName, HouseID: 1, HouseName: ""}); len(body) != 0 {
		t.Fatalf("empty name reply %v", body)
	}
	if err := h.pool.QueryRow(context.Background(), `SELECT house_name FROM player_dorm_room_social WHERE player_id=126701 AND house_id=1`).Scan(&name); err != nil || name != "" {
		t.Fatalf("empty name did not restore the default: %q %v", name, err)
	}
	var rawRefs string
	if err := h.pool.QueryRow(context.Background(), `SELECT operation_policy_refs::text FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='dorm-house' AND operation=$2 ORDER BY recorded_at DESC LIMIT 1`, "126701", app.ChangeName).Scan(&rawRefs); err != nil {
		t.Fatal(err)
	}
	refs := []struct{ Name, Version string }{}
	if err := json.Unmarshal([]byte(rawRefs), &refs); err != nil {
		t.Fatal(err)
	}
	moderationRef := ""
	for _, ref := range refs {
		if ref.Name == "profile-moderation" {
			moderationRef = ref.Version
		}
	}
	if moderationRef != "PROFILE_SCALAR_CASE_SENSITIVE_SPACE_MASK_V1" {
		t.Fatalf("receipt moderation ref %q in %s", moderationRef, rawRefs)
	}
}

func TestDormRandomVisitUses256MostRecentActivePlayers(t *testing.T) {
	h := newSocialHarness(t)
	h.service.Directory = i4store.TransactionDiscoveryReader{}
	const (
		firstPlayer = identity.PlayerID(110001)
		firstRecent = identity.PlayerID(110045)
		lastPlayer  = identity.PlayerID(110300)
		hidden      = identity.PlayerID(110046)
	)
	seedRecentActivityPlayers(t, h.pool, firstPlayer, firstRecent, lastPlayer, hidden)
	viewer := socialActor(firstRecent)
	operationContext := func(seed uint64) operation.Context {
		id, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		var entropy [32]byte
		for index := 0; index < 8; index++ {
			entropy[7-index] = byte(seed >> (8 * index))
		}
		return operation.Context{ID: id, StartedAt: time.Now().UTC(), EntropySeed: entropy}
	}
	visit := func(op operation.Context) identity.PlayerID {
		body, err := h.service.SocialRead(context.Background(), viewer, op, 2519, 0, 0, 0, 1)
		if err != nil {
			t.Fatal(err)
		}
		info, ok := body["host_info"].(map[string]any)
		if !ok {
			t.Fatalf("random visit reply %v", body)
		}
		target, ok := info["player_id"].(int64)
		if !ok {
			t.Fatalf("random visit host %v", info)
		}
		return identity.PlayerID(target)
	}

	if target := visit(operationContext(260)); target < firstRecent || target > lastPlayer {
		t.Fatalf("visit target %d outside the 256 most recently active players", target)
	}
	replay := operationContext(260)
	if first, second := visit(replay), visit(replay); first != second {
		t.Fatalf("replayed operation changed target %d to %d", first, second)
	}
	if target := visit(operationContext(0)); target == viewer.PlayerID || target == hidden {
		t.Fatalf("visit selected excluded player %d", target)
	}
}

// seedRecentActivityPlayers creates first..last as same-server directory,
// dorm and login-activity rows. firstRecent starts the most recent 256 by
// login time; earlier players are older than every recent one.
func seedRecentActivityPlayers(t *testing.T, pool *pg.Pool, first, firstRecent, last, hidden identity.PlayerID) {
	t.Helper()
	ctx := context.Background()
	now := time.Now().UTC()
	count := int(last - first + 1)
	t.Cleanup(func() {
		for _, statement := range []string{
			`DELETE FROM player_dorm_room_social WHERE player_id BETWEEN $1 AND $2`,
			`DELETE FROM player_dorm_heroes WHERE player_id BETWEEN $1 AND $2`,
			`DELETE FROM player_dorm_rooms WHERE player_id BETWEEN $1 AND $2`,
			`DELETE FROM player_dorm_roots WHERE player_id BETWEEN $1 AND $2`,
			`DELETE FROM player_directory_profiles WHERE player_id BETWEEN $1 AND $2`,
			`DELETE FROM player_login_observations WHERE player_id BETWEEN $1 AND $2`,
			`DELETE FROM players WHERE player_id BETWEEN $1 AND $2`,
		} {
			if _, err := pool.Raw().Exec(context.Background(), statement, int64(first), int64(last)); err != nil {
				t.Error(err)
			}
		}
		if _, err := pool.Raw().Exec(context.Background(), `DELETE FROM accounts WHERE account_uid LIKE 'dormvisit-%'`); err != nil {
			t.Error(err)
		}
	})
	if _, err := pool.Raw().Exec(ctx, `
WITH created AS (
  INSERT INTO accounts(account_id,account_uid,status,created_at)
  SELECT gen_random_uuid(),'dormvisit-'||g,'ACTIVE',$1 FROM generate_series(1,$2::int) g
  RETURNING account_id,account_uid
)
INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)
SELECT $3::bigint+split_part(account_uid,'-',2)::bigint,account_id,1,$1,'dormvisit-native'
FROM created`, now, count, int64(first)-1); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `
INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at)
SELECT player_id,'Recent'||player_id,10,$1,$1 FROM players WHERE player_id BETWEEN $2 AND $3`, now, int64(first), int64(last)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `
INSERT INTO player_dorm_roots(player_id,next_house_id,state_version,created_at,updated_at)
SELECT player_id,2,1,$1,$1 FROM players WHERE player_id BETWEEN $2 AND $3`, now, int64(first), int64(last)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `
INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,created_at,updated_at)
SELECT player_id,1,1000001,1,repeat('a',64),1,1,0,0,1,'{}',$1,$1 FROM players WHERE player_id BETWEEN $2 AND $3`, now, int64(first), int64(last)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_dorm_room_social(player_id,house_id,house_name,is_hidden,state_version,updated_at) VALUES($1,1,'',true,1,$2)`, int64(hidden), now); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `
INSERT INTO player_login_observations(player_id,logical_server_id,last_login_at,source_operation_id,state_version)
SELECT player_id,1,CASE WHEN player_id<$2 THEN $1::timestamptz-interval '30 days' ELSE $1::timestamptz-make_interval(secs=>player_id-$2) END,gen_random_uuid(),1
FROM players WHERE player_id BETWEEN $3 AND $4`, now, int64(firstRecent), int64(first), int64(last)); err != nil {
		t.Fatal(err)
	}
}

func commentContents(body map[string]any) []string {
	out := []string{}
	for _, key := range []string{"best_comments", "comment_list"} {
		rows, _ := body[key].([]any)
		for _, raw := range rows {
			if row, ok := raw.(map[string]any); ok {
				out = append(out, row["content"].(string))
			}
		}
	}
	return out
}

func containsComment(body map[string]any, want string) bool {
	for _, content := range commentContents(body) {
		if content == want {
			return true
		}
	}
	return false
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

func (h socialHarness) commandWithOperation(t *testing.T, actor identity.ActorContext, command app.Command, op operation.Context) map[string]any {
	t.Helper()
	result, err := h.service.Command(context.Background(), actor, command, op)
	if err != nil {
		t.Fatal(err)
	}
	return result.Body
}

func (h socialHarness) fixedOperation(t *testing.T) operation.Context {
	t.Helper()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	return op
}

func dormReceiptCount(t *testing.T, p *pg.Pool, player identity.PlayerID, family string, op operation.Context) int64 {
	t.Helper()
	var count int64
	if err := p.QueryRow(context.Background(), `SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='dorm-house' AND operation=$2 AND semantic_key=$3`, strconv.FormatInt(int64(player), 10), family, op.ID.String()).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func sameSocialReply(t *testing.T, mid uint16, first, replay map[string]any) {
	t.Helper()
	encodedFirst, err := json.Marshal(first)
	if err != nil {
		t.Fatal(err)
	}
	encodedReplay, err := json.Marshal(replay)
	if err != nil {
		t.Fatal(err)
	}
	if string(encodedFirst) != string(encodedReplay) {
		t.Fatalf("MID %d exact-operation replay drifted: %s vs %s", mid, encodedFirst, encodedReplay)
	}
}

func TestDormSocialExactOperationRetryReceipts(t *testing.T) {
	h := newSocialHarness(t)

	t.Run("2518 change name", func(t *testing.T) {
		op := h.fixedOperation(t)
		command := app.Command{Family: app.ChangeName, HouseID: 1, HouseName: "retry-name"}
		first := h.commandWithOperation(t, h.owner, command, op)
		replay := h.commandWithOperation(t, h.owner, command, op)
		sameSocialReply(t, 2518, first, replay)
		if count := dormReceiptCount(t, h.pool, h.owner.PlayerID, app.ChangeName, op); count != 1 {
			t.Fatalf("change-name receipts=%d", count)
		}
		var name string
		if err := h.pool.QueryRow(context.Background(), `SELECT house_name FROM player_dorm_room_social WHERE player_id=$1 AND house_id=1`, int64(h.owner.PlayerID)).Scan(&name); err != nil || name != "retry-name" {
			t.Fatalf("stored name=%q err=%v", name, err)
		}
	})

	t.Run("2520 hide house", func(t *testing.T) {
		op := h.fixedOperation(t)
		command := app.Command{Family: app.HideHouse, HouseID: 1}
		first := h.commandWithOperation(t, h.owner, command, op)
		replay := h.commandWithOperation(t, h.owner, command, op)
		sameSocialReply(t, 2520, first, replay)
		if count := dormReceiptCount(t, h.pool, h.owner.PlayerID, app.HideHouse, op); count != 1 {
			t.Fatalf("hide receipts=%d", count)
		}
		info, _ := replay["house_info"].(map[string]any)
		if info == nil || (info["is_hide"] != int64(1) && info["is_hide"] != float64(1)) {
			t.Fatalf("hide replay toggled twice: %v", replay)
		}
		h.commandWithOperation(t, h.owner, command, h.fixedOperation(t))
	})

	t.Run("2523 comment house", func(t *testing.T) {
		op := h.fixedOperation(t)
		command := app.Command{Family: app.CommentHouse, HostID: int64(h.owner.PlayerID), HouseID: 1, Content: "retry-comment"}
		first := h.commandWithOperation(t, h.viewer, command, op)
		replay := h.commandWithOperation(t, h.viewer, command, op)
		sameSocialReply(t, 2523, first, replay)
		if count := dormReceiptCount(t, h.pool, h.viewer.PlayerID, app.CommentHouse, op); count != 1 {
			t.Fatalf("comment receipts=%d", count)
		}
		var comments int64
		if err := h.pool.QueryRow(context.Background(), `SELECT count(*) FROM player_dorm_comments WHERE player_id=$1 AND house_id=1 AND content='retry-comment' AND deleted_at IS NULL`, int64(h.owner.PlayerID)).Scan(&comments); err != nil || comments != 1 {
			t.Fatalf("comments=%d err=%v", comments, err)
		}
	})

	t.Run("2526 delete comment", func(t *testing.T) {
		body := h.command(t, h.viewer, app.Command{Family: app.CommentHouse, HostID: int64(h.owner.PlayerID), HouseID: 1, Content: "retry-delete"})
		commentID := body["best_comments"].([]any)[0].(map[string]any)["comment_id"].(int64)
		op := h.fixedOperation(t)
		command := app.Command{Family: app.DeleteComment, HouseID: 1, CommentID: commentID}
		first := h.commandWithOperation(t, h.owner, command, op)
		replay := h.commandWithOperation(t, h.owner, command, op)
		sameSocialReply(t, 2526, first, replay)
		if count := dormReceiptCount(t, h.pool, h.owner.PlayerID, app.DeleteComment, op); count != 1 {
			t.Fatalf("delete receipts=%d", count)
		}
		var deleted bool
		if err := h.pool.QueryRow(context.Background(), `SELECT deleted_at IS NOT NULL FROM player_dorm_comments WHERE comment_id=$1`, commentID).Scan(&deleted); err != nil || !deleted {
			t.Fatalf("comment deleted=%v err=%v", deleted, err)
		}
	})
}

type socialDispatchAuthority struct{ actor identity.ActorContext }

func (a socialDispatchAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func socialDispatchRequest(t *testing.T, actor identity.ActorContext, mid uint16, params map[string]any) httpedge.DispatchRequest {
	t.Helper()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	params["token"] = "bearer"
	params["region"] = int64(actor.LogicalServerID)
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op, MID: mid, ReceivedAt: op.StartedAt, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: int64(actor.LogicalServerID)}}}
}

func TestDormDeleteCommentHostOnlyThroughDispatcher(t *testing.T) {
	h := newSocialHarness(t)
	body := h.command(t, h.viewer, app.Command{Family: app.CommentHouse, HostID: int64(h.owner.PlayerID), HouseID: 1, Content: "host-only"})
	commentID := body["best_comments"].([]any)[0].(map[string]any)["comment_id"].(int64)

	nonHost := stockruntime.DormDispatcher{Authority: socialDispatchAuthority{actor: h.author}, Service: h.service}
	refusal := nonHost.Dispatch(context.Background(), socialDispatchRequest(t, h.author, 2526, map[string]any{"house_id": int64(1), "comment_id": commentID}))
	if refusal.HTTPStatus != 409 || refusal.Body["error_code"] != int64(35028) {
		t.Fatalf("non-host delete status=%d body=%v", refusal.HTTPStatus, refusal.Body)
	}
	page, err := h.socialRead(t, h.viewer, 2524, int64(h.owner.PlayerID), 1, 0, 20)
	if err != nil || page["comment_num"] != int64(1) {
		t.Fatalf("non-host delete removed the comment: %v %v", page, err)
	}

	host := stockruntime.DormDispatcher{Authority: socialDispatchAuthority{actor: h.owner}, Service: h.service}
	accepted := host.Dispatch(context.Background(), socialDispatchRequest(t, h.owner, 2526, map[string]any{"house_id": int64(1), "comment_id": commentID}))
	if accepted.HTTPStatus != 200 {
		t.Fatalf("host delete status=%d body=%v", accepted.HTTPStatus, accepted.Body)
	}
	page, err = h.socialRead(t, h.viewer, 2524, int64(h.owner.PlayerID), 1, 0, 20)
	if err != nil || page["comment_num"] != int64(0) {
		t.Fatalf("host delete left the comment: %v %v", page, err)
	}
}
