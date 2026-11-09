//go:build postgres

package socialinvitestore_test

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"strconv"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinvitestore"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func openInvitePool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_SOCIAL_INVITE_DSN")
	if dsn == "" {
		t.Skip("explicit own migrated PostgreSQL database required; skip is not native proof")
	}
	pool, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func mustInviteUUID(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}

type invitePlayer struct {
	PlayerID identity.PlayerID
	Account  ids.UUID
	Session  ids.UUID
	Context  ids.UUID
	Name     string
	Level    int64
	Charge   int64
	Heroes   []int64
}

var fixturePlayerIDs = []identity.PlayerID{131001, 131002, 131003, 131004, 132001, 132002, 132003, 133001, 133002, 134001, 134002}

func newInvitePlayer(t *testing.T, player identity.PlayerID, name string, level int64) invitePlayer {
	t.Helper()
	return invitePlayer{PlayerID: player, Account: mustInviteUUID(t), Session: mustInviteUUID(t), Context: mustInviteUUID(t), Name: name, Level: level}
}

type inviteWorld struct {
	pool      *postgres.Pool
	revision  string
	content   contentstore.Store
	store     socialinvitestore.Store
	facts     socialinvitestore.FactsReader
	reader    socialinvitestore.Reader
	bind      socialinvite.BindService
	claim     socialinvite.ClaimService
	read      socialinvite.ReadService
	privilege commerceprivilege.Provider
}

func clearInviteWorld(t *testing.T, pool *postgres.Pool, players []identity.PlayerID) {
	t.Helper()
	ctx := context.Background()
	values := make([]int64, 0, len(players))
	keys := make([]string, 0, len(players))
	for _, player := range players {
		values = append(values, int64(player))
		keys = append(keys, strconv.FormatInt(int64(player), 10))
	}
	statements := []string{
		`DELETE FROM social_invite_mission_claims WHERE player_id=ANY($1)`,
		`DELETE FROM social_invite_bindings WHERE invitee_player_id=ANY($1) OR inviter_player_id=ANY($1)`,
		`DELETE FROM player_currency_balances WHERE player_id=ANY($1)`,
		`DELETE FROM commerce_privilege_roots WHERE player_id=ANY($1)`,
		`DELETE FROM player_heroes WHERE player_id=ANY($1)`,
		`DELETE FROM player_hero_roots WHERE player_id=ANY($1)`,
		`DELETE FROM player_directory_profiles WHERE player_id=ANY($1)`,
		`DELETE FROM player_progression WHERE player_id=ANY($1)`,
		`DELETE FROM gameplay_contexts WHERE player_id=ANY($1)`,
		`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE player_id=ANY($1))`,
		`DELETE FROM players WHERE player_id=ANY($1)`,
	}
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM gxb_operation_receipts WHERE owner_key=ANY($1)`, keys); err != nil {
		t.Fatalf("clear invite receipts: %v", err)
	}
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM social_invite_tuning`); err != nil {
		t.Fatalf("clear invite tuning: %v", err)
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement, values); err != nil {
			t.Fatalf("clear invite fixture: %v: %v", err, statement)
		}
	}
	rows, err := pool.Raw().Query(ctx, `SELECT account_id::text FROM accounts WHERE account_uid LIKE 'invite-native-%'`)
	if err == nil {
		var accounts []string
		for rows.Next() {
			var account string
			if rows.Scan(&account) == nil {
				accounts = append(accounts, account)
			}
		}
		rows.Close()
		if len(accounts) > 0 {
			if _, err := pool.Raw().Exec(ctx, `DELETE FROM accounts WHERE account_id::text=ANY($1)`, accounts); err != nil {
				t.Fatalf("clear invite accounts: %v", err)
			}
		}
	}
}

func seedInviteWorld(t *testing.T, pool *postgres.Pool, players []invitePlayer) *inviteWorld {
	t.Helper()
	ctx := context.Background()
	playerIDs := fixturePlayerIDs
	clearInviteWorld(t, pool, playerIDs)
	now := time.Now().UTC()
	content := contentstore.Store{Queryer: pool}
	revision, err := content.ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	for _, player := range players {
		if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',$3)`, player.Account.String(), "invite-native-"+player.Account.String(), now.Add(-24*time.Hour)); err != nil {
			t.Fatalf("invite account fixture: %v", err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,$3,$4,'invite-native')`, int64(player.PlayerID), player.Account.String(), int64(player.PlayerID)/100000, now.Add(-24*time.Hour)); err != nil {
			t.Fatalf("invite player fixture: %v", err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, player.Session.String(), player.Account.String(), now.Add(-time.Hour)); err != nil {
			t.Fatalf("invite session fixture: %v", err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at) VALUES($1,$2,$3,$4,$5,1,$6)`, player.Context.String(), player.Session.String(), player.Account.String(), int64(player.PlayerID)/100000, int64(player.PlayerID), now.Add(-time.Hour)); err != nil {
			t.Fatalf("invite context fixture: %v", err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO player_economy_owners(player_id,state_version,created_at) VALUES($1,1,$2)`, int64(player.PlayerID), now.Add(-time.Hour)); err != nil {
			t.Fatalf("invite economy owner fixture: %v", err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO player_progression(player_id,level,exp,state_version,updated_at) VALUES($1,$2,0,1,$3)`, int64(player.PlayerID), player.Level, now.Add(-time.Hour)); err != nil {
			t.Fatalf("invite progression fixture: %v", err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,$2,$3,$4,$4)`, int64(player.PlayerID), player.Name, player.Level, now.Add(-time.Hour)); err != nil {
			t.Fatalf("invite profile fixture: %v", err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at) VALUES($1,$2,$3,0,'QUALIFIED_ABSENT',$4,'C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1','MANUAL_PRESERVATION','invite-native','invite-native',1,$5,$5)`, int64(player.PlayerID), int64(player.PlayerID)/100000, player.Charge, revision, now.Add(-time.Hour)); err != nil {
			t.Fatalf("invite privilege fixture: %v", err)
		}
		if len(player.Heroes) == 0 {
			continue
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at) VALUES($1,$2,0,1,$3,$3)`, int64(player.PlayerID), len(player.Heroes)+1, now.Add(-time.Hour)); err != nil {
			t.Fatalf("invite hero root fixture: %v", err)
		}
		for index, level := range player.Heroes {
			partner := int64(index + 1)
			table := int64(11001 + index)
			if _, err := transaction.Exec(ctx, `INSERT INTO player_heroes(player_id,partner_id,table_id,origin_table_id,star,level,exp,color,raw_skill_1,raw_skill_2,raw_skill_3,raw_skill_4,raw_skill_5,raw_skill_6,raw_skill_id_1,raw_skill_id_2,raw_skill_id_3,raw_skill_id_4,raw_skill_id_5,raw_skill_id_6,skill_seed_policy_id,creation_content_revision,state_version,created_at,updated_at) VALUES($1,$2,$3,$3,1,$4,0,1,1,1,1,1,1,1,0,0,0,0,0,0,'I7C2A_V1_RAW_SKILL_SEED_V1',$5,1,$6,$6)`, int64(player.PlayerID), partner, table, level, revision, now.Add(-time.Hour)); err != nil {
				t.Fatalf("invite hero fixture: %v", err)
			}
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	progression := i5store.Store{Queryer: pool}
	privileges := commerceprivilege.Provider{Store: ps.Store{}, Content: content}
	store := socialinvitestore.Store{}
	facts := socialinvitestore.FactsReader{Directory: i4store.TransactionDiscoveryReader{}, Accounts: i4store.PlayerAccounts{}, Progression: progression, Heroes: characterstore.HeroLevelReader{Store: characterstore.Store{Queryer: pool}}, Privilege: privileges, Servers: i4store.ServerNames{}}
	reader := socialinvitestore.Reader{Owner: store, Facts: facts}
	timed := generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: tx.Runner{DB: pool}}
	i5svc := appi5.Service{Runner: tx.Runner{DB: pool}, Store: progression, Content: content, Privileges: privileges, Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: progression, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}}
	return &inviteWorld{
		pool: pool, revision: revision, content: content, store: store, facts: facts, reader: reader, privilege: privileges,
		bind:  socialinvite.BindService{Timed: timed, Fence: progression, Players: i4store.PlayerRootLocker{}, Owner: store, Facts: facts, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}},
		claim: socialinvite.ClaimService{Timed: timed, Fence: progression, Players: i4store.PlayerRootLocker{}, Content: content, Owner: store, Reader: reader, Grants: i5svc, Settings: store, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}},
		read:  socialinvite.ReadService{Timed: timed, Content: content, Reader: reader},
	}
}

func inviteActor(t *testing.T, player invitePlayer) identity.ActorContext {
	t.Helper()
	account, err := identity.AccountIDFrom(player.Account)
	if err != nil {
		t.Fatal(err)
	}
	session, err := identity.SessionIDFrom(player.Session)
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(player.Context)
	if err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{AccountID: account, AccountUID: identity.AccountUID("invite-native-" + player.Account.String()), SessionID: session, ContextID: contextID, LogicalServerID: identity.LogicalServerID(player.PlayerID / 100000), PlayerID: player.PlayerID, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

func inviteOperation(t *testing.T) operation.Context {
	t.Helper()
	seed := [32]byte{}
	for index := range seed {
		seed[index] = byte(index + 7)
	}
	return operation.Context{ID: mustInviteUUID(t), StartedAt: time.Now().UTC(), EntropySeed: seed, Policies: policy.Set{}}
}

func inviteCode(t *testing.T, player identity.PlayerID) string {
	t.Helper()
	code, err := domain.EncodeCode(player)
	if err != nil {
		t.Fatal(err)
	}
	return code
}

func crystalBalance(t *testing.T, world *inviteWorld, player identity.PlayerID) int64 {
	t.Helper()
	var amount int64
	err := world.pool.Raw().QueryRow(context.Background(), `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'),0)`, int64(player)).Scan(&amount)
	if err != nil {
		t.Fatal(err)
	}
	return amount
}

func TestInviteBindingEligibilityAndReplay(t *testing.T) {
	pool := openInvitePool(t)
	inviter := newInvitePlayer(t, 131001, "Inviter131001", 60)
	invitee := newInvitePlayer(t, 131002, "Invitee131002", 49)
	highLevel := newInvitePlayer(t, 131003, "High131003", 50)
	sameAccountInvitee := newInvitePlayer(t, 131004, "SameAccount131004", 20)
	world := seedInviteWorld(t, pool, []invitePlayer{inviter, invitee, highLevel, sameAccountInvitee})

	current := inviteOperation(t)
	body, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), inviteCode(t, inviter.PlayerID), current)
	if err != nil {
		t.Fatal(err)
	}
	if body["invitor_id"] != int64(inviter.PlayerID) || body["invitor_name"] != inviter.Name {
		t.Fatalf("binding reply = %+v", body)
	}
	replay, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), inviteCode(t, inviter.PlayerID), current)
	if err != nil || replay["invitor_id"] != body["invitor_id"] {
		t.Fatalf("receipt replay = %+v, %v", replay, err)
	}
	var bindings int
	if err := pool.Raw().QueryRow(context.Background(), `SELECT count(*) FROM social_invite_bindings WHERE invitee_player_id=$1`, int64(invitee.PlayerID)).Scan(&bindings); err != nil || bindings != 1 {
		t.Fatalf("bindings=%d err=%v", bindings, err)
	}
	if _, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), inviteCode(t, inviter.PlayerID), inviteOperation(t)); !errors.Is(err, socialinvite.ErrBindRefused) && !isConflict(err) {
		t.Fatalf("duplicate binding accepted: %v", err)
	}
	if _, err := world.bind.Bind(context.Background(), inviteActor(t, highLevel), inviteCode(t, inviter.PlayerID), inviteOperation(t)); !errors.Is(err, socialinvite.ErrBindRefused) {
		t.Fatalf("level-50 invitee bound: %v", err)
	}
	if _, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), inviteCode(t, invitee.PlayerID), inviteOperation(t)); !errors.Is(err, socialinvite.ErrBindRefused) {
		t.Fatalf("self binding accepted: %v", err)
	}
	if _, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), inviteCode(t, 300001), inviteOperation(t)); !errors.Is(err, socialinvite.ErrBindRefused) {
		t.Fatalf("cross-server binding accepted: %v", err)
	}
	for _, malformed := range []string{"", "0001", "not a code"} {
		if _, err := world.bind.Bind(context.Background(), inviteActor(t, highLevel), malformed, inviteOperation(t)); !errors.Is(err, socialinvite.ErrBindRefused) {
			t.Fatalf("malformed code accepted: %q %v", malformed, err)
		}
	}

	forced := sameAccountFacts{FactsReader: world.facts, account: sameAccountInvitee.Account}
	sameAccount := world.bind
	sameAccount.Facts = forced
	if _, err := sameAccount.Bind(context.Background(), inviteActor(t, sameAccountInvitee), inviteCode(t, inviter.PlayerID), inviteOperation(t)); !errors.Is(err, domain.ErrSameAccount) {
		t.Fatalf("same-account binding accepted: %v", err)
	}
}

type sameAccountFacts struct {
	socialinvitestore.FactsReader
	account ids.UUID
}

func (facts sameAccountFacts) ReadAccountTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID) (identity.AccountID, error) {
	return identity.AccountIDFrom(facts.account)
}

func TestInviteConcurrentBindingTwoInvitersOneInvitee(t *testing.T) {
	pool := openInvitePool(t)
	first := newInvitePlayer(t, 132001, "First132001", 60)
	second := newInvitePlayer(t, 132002, "Second132002", 60)
	invitee := newInvitePlayer(t, 132003, "Invitee132003", 20)
	world := seedInviteWorld(t, pool, []invitePlayer{first, second, invitee})

	start := make(chan struct{})
	var wait sync.WaitGroup
	results := make(chan error, 2)
	for _, code := range []string{inviteCode(t, first.PlayerID), inviteCode(t, second.PlayerID)} {
		code := code
		wait.Add(1)
		go func() {
			defer wait.Done()
			<-start
			_, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), code, inviteOperation(t))
			results <- err
		}()
	}
	close(start)
	wait.Wait()
	close(results)
	successes, refusals := 0, 0
	for err := range results {
		switch {
		case err == nil:
			successes++
		case errors.Is(err, socialinvite.ErrBindRefused) || isConflict(err):
			refusals++
		default:
			t.Fatalf("unexpected concurrent binding result: %v", err)
		}
	}
	if successes != 1 || refusals != 1 {
		t.Fatalf("concurrent bind successes=%d refusals=%d", successes, refusals)
	}
	var bindings int
	if err := pool.Raw().QueryRow(context.Background(), `SELECT count(*) FROM social_invite_bindings WHERE invitee_player_id=$1`, int64(invitee.PlayerID)).Scan(&bindings); err != nil || bindings != 1 {
		t.Fatalf("bindings=%d err=%v", bindings, err)
	}
}

func TestInviteReadTypeThreeAndOnceOnlyClaim(t *testing.T) {
	pool := openInvitePool(t)
	inviter := newInvitePlayer(t, 133001, "Inviter133001", 60)
	invitee := newInvitePlayer(t, 133002, "Invitee133002", 49)
	invitee.Heroes = []int64{50, 20}
	world := seedInviteWorld(t, pool, []invitePlayer{inviter, invitee})

	if _, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), inviteCode(t, inviter.PlayerID), inviteOperation(t)); err != nil {
		t.Fatal(err)
	}
	actor := inviteActor(t, inviter)
	read, err := world.read.Read(context.Background(), actor, inviteOperation(t))
	if err != nil {
		t.Fatal(err)
	}
	players := read["invite_players"].([]any)
	if len(players) != 1 || players[0].(map[string]any)["lev"] != int64(50) || players[0].(map[string]any)["partner_num"] != int64(2) {
		t.Fatalf("invite_players = %+v", players)
	}
	if !missionAwardable(read["missions"].([]any), 100016) {
		t.Fatal("type-3 mission not claimable at hero level 50")
	}

	claimOperation := inviteOperation(t)
	body, err := world.claim.Claim(context.Background(), actor, 100016, claimOperation)
	if err != nil {
		t.Fatal(err)
	}
	if !hasAward(body, 90) || missionAwardable(body["new_missions"].([]any), 100016) {
		t.Fatalf("claim body = %+v", body)
	}
	newInfos := body["new_infos"].(map[string]any)
	if !missionAwardableFalse(newInfos["missions"].([]any), 100016) {
		t.Fatalf("reload fragment not updated: %+v", newInfos)
	}
	if balance := crystalBalance(t, world, inviter.PlayerID); balance != 90 {
		t.Fatalf("crystal balance = %d", balance)
	}
	replay, err := world.claim.Claim(context.Background(), actor, 100016, claimOperation)
	if err != nil || !hasAward(replay, 90) {
		t.Fatalf("claim receipt replay = %+v, %v", replay, err)
	}
	if _, err := world.claim.Claim(context.Background(), actor, 100016, inviteOperation(t)); !errors.Is(err, socialinvite.ErrClaimRefused) {
		t.Fatalf("second claim accepted: %v", err)
	}
	if balance := crystalBalance(t, world, inviter.PlayerID); balance != 90 {
		t.Fatalf("second claim paid crystal: %d", balance)
	}
}

func TestInviteConcurrentClaimPaysOnce(t *testing.T) {
	pool := openInvitePool(t)
	inviter := newInvitePlayer(t, 134001, "Inviter134001", 60)
	invitee := newInvitePlayer(t, 134002, "Invitee134002", 49)
	invitee.Heroes = []int64{60}
	world := seedInviteWorld(t, pool, []invitePlayer{inviter, invitee})
	if _, err := world.bind.Bind(context.Background(), inviteActor(t, invitee), inviteCode(t, inviter.PlayerID), inviteOperation(t)); err != nil {
		t.Fatal(err)
	}
	actor := inviteActor(t, inviter)
	start := make(chan struct{})
	var wait sync.WaitGroup
	results := make(chan error, 2)
	for index := 0; index < 2; index++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			<-start
			_, err := world.claim.Claim(context.Background(), actor, 100016, inviteOperation(t))
			results <- err
		}()
	}
	close(start)
	wait.Wait()
	close(results)
	successes, refusals := 0, 0
	for err := range results {
		switch {
		case err == nil:
			successes++
		case errors.Is(err, socialinvite.ErrClaimRefused) || isConflict(err):
			refusals++
		default:
			t.Fatalf("unexpected concurrent claim result: %v", err)
		}
	}
	if successes != 1 || refusals != 1 {
		t.Fatalf("concurrent claim successes=%d refusals=%d", successes, refusals)
	}
	if balance := crystalBalance(t, world, inviter.PlayerID); balance != 90 {
		t.Fatalf("concurrent claim paid %d crystal", balance)
	}
}

func isConflict(err error) bool {
	return err != nil && contains(err.Error(), "receipt")
}

func contains(value, fragment string) bool {
	for index := 0; index+len(fragment) <= len(value); index++ {
		if value[index:index+len(fragment)] == fragment {
			return true
		}
	}
	return false
}

func missionAwardable(rows []any, missionID int64) bool {
	for _, row := range rows {
		mission := row.(map[string]any)
		if numberEquals(mission["mission_id"], missionID) {
			return mission["can_award"] == true
		}
	}
	return false
}

func missionAwardableFalse(rows []any, missionID int64) bool {
	for _, row := range rows {
		mission := row.(map[string]any)
		if numberEquals(mission["mission_id"], missionID) {
			return mission["can_award"] == false
		}
	}
	return false
}

func hasAward(body map[string]any, diamond int64) bool {
	awards, ok := body["awards"].([]any)
	if !ok || len(awards) != 1 {
		return false
	}
	row, ok := awards[0].(map[string]any)
	return ok && numberEquals(row["crystal"], diamond) && numberEquals(row["item_num"], diamond)
}

func numberEquals(value any, want int64) bool {
	switch number := value.(type) {
	case int64:
		return number == want
	case int:
		return int64(number) == want
	case float64:
		return int64(number) == want
	case json.Number:
		parsed, err := number.Int64()
		return err == nil && parsed == want
	default:
		return false
	}
}
