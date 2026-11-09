//go:build postgres

package main

import (
	"context"
	"encoding/binary"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	apparena "gxb.local/backend/v2/internal/application/arena"
	apptopfloor "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func opponentTestOperation() operation.Context {
	policies, _ := policy.NewSet()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policies)
	if err != nil {
		panic(err)
	}
	return op
}

func opponentTestPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B6A_DSN")
	if dsn == "" {
		t.Fatal("exact nativeDSN required")
	}
	p, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func opponentTestContent(t *testing.T, p *pg.Pool) string {
	t.Helper()
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	service := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, err = service.EnsureBuiltinInstalled(context.Background(), opponentTestOperation(), bundle); err != nil {
		t.Fatal(err)
	}
	if _, err = service.BootstrapActivationIfMissing(context.Background(), opponentTestOperation(), bundle); err != nil {
		t.Fatal(err)
	}
	return bundle.RevisionID()
}

// opponentTestActor is the production birth chain's bare player root.
func opponentTestActor(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, ids.UUID) {
	t.Helper()
	account, session, contextID := uuidOrFail(t), uuidOrFail(t), uuidOrFail(t)
	var pid int64
	tr, err := p.Begin(context.Background(), tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(context.Background())
	if err = tr.QueryRow(context.Background(), `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=$1 RETURNING next_player_id-1`, int64(server)).Scan(&pid); err != nil {
		t.Fatal(err)
	}
	statements := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'gauntlet6-cmd')`, []any{pid, account.String(), int64(server)}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'gauntlet6-cmd',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{session.String(), account.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,$4,$5,1,clock_timestamp())`, []any{contextID.String(), session.String(), account.String(), int64(server), pid}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,'',1,110001001,0,0,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, []any{pid}},
	}
	for _, statement := range statements {
		if _, err = tr.Exec(context.Background(), statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	if err = tr.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
	accountID, _ := identity.AccountIDFrom(account)
	sessionID, _ := identity.SessionIDFrom(session)
	contextIDValue, _ := identity.ContextIDFrom(contextID)
	actor := identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID(account.String()), SessionID: sessionID, ContextID: contextIDValue,
		LogicalServerID: server, PlayerID: identity.PlayerID(pid), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	if err = nativebirth.PersistBare(context.Background(), p, account, server, actor.PlayerID); err != nil {
		t.Fatalf("fixture birth: %v", err)
	}
	return actor, account
}

func opponentTestHero(t *testing.T, p *pg.Pool, actor identity.ActorContext, revision string, tableID, partnerID int64) character.Hero {
	t.Helper()
	at := time.Now().UTC().Add(-time.Hour)
	hero := character.Hero{PlayerID: actor.PlayerID, PartnerID: partnerID, TableID: tableID, OriginTableID: tableID, Star: 5, Level: 1, Color: 1,
		CreationContentRevision: revision, RawSkills: character.NewHeroRawSkillSeed(), IllusionSkinID: character.DefaultIllusionSkinID, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	tr, err := p.Begin(context.Background(), tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(context.Background())
	if err = (characterstore.Store{}).InsertHeroTx(context.Background(), tr, hero); err != nil {
		t.Fatal(err)
	}
	if _, err = tr.Exec(context.Background(), `UPDATE player_hero_roots SET next_partner_id=GREATEST(next_partner_id,$2+1) WHERE player_id=$1`, int64(actor.PlayerID), partnerID); err != nil {
		t.Fatal(err)
	}
	if err = characterbirth.FreshHeroFacets().InitFreshHeroTx(context.Background(), tr, hero.Ref(), at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
	return hero
}

func uuidOrFail(t *testing.T) ids.UUID {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value
}

func opponentTestServer(t *testing.T, p *pg.Pool) identity.LogicalServerID {
	t.Helper()
	for range 20 {
		raw := uuidOrFail(t).Bytes()
		server := int64(1000 + int(binary.BigEndian.Uint16(raw[:2])))
		tag, err := p.Raw().Exec(context.Background(), `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)VALUES($1,'Gauntlet cmd',clock_timestamp(),true,true,true,$2,$3,1,clock_timestamp())ON CONFLICT DO NOTHING`, server, server*100000+25001, (server+1)*100000-1)
		if err != nil {
			t.Fatal(err)
		}
		if tag.RowsAffected() == 1 {
			return identity.LogicalServerID(server)
		}
	}
	t.Fatal("no isolated native server")
	return 0
}

func insertArenaPlayer(t *testing.T, p *pg.Pool, player arena.Player, revision string) {
	t.Helper()
	tr, err := p.Begin(context.Background(), tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(context.Background())
	if err = (arenastore.Store{}).InsertPlayerTx(context.Background(), tr, player, revision); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
}

const opponentSection = int64(1000)

// TestGauntlet6AdventureOpponentsProductionNative drives the literal
// cmd/gxb-api adapter over the real Arena owner and the real Top Floor robot.
func TestGauntlet6AdventureOpponentsProductionNative(t *testing.T) {
	p := opponentTestPool(t)
	revision := opponentTestContent(t, p)
	server := opponentTestServer(t, p)
	attacker, _ := opponentTestActor(t, p, server)
	defender, _ := opponentTestActor(t, p, server)
	content := contentstore.Store{Queryer: p}
	catalog, err := content.ArenaCatalogTx(context.Background(), p, revision)
	if err != nil {
		t.Fatal(err)
	}
	season := catalog.SeasonAt(time.Now()).Number
	now := time.Now().UTC()
	tableIDs := []int64{10001001, 10001002, 10001003, 10001004, 10001005}
	partnerByTable := map[int64]int64{}
	for index, tableID := range tableIDs {
		hero := opponentTestHero(t, p, defender, revision, tableID, int64(index+1))
		partnerByTable[tableID] = hero.PartnerID
	}
	if _, err = p.Raw().Exec(context.Background(), `INSERT INTO arena_competitions(competition_id,content_revision,policy_id,settled_through,state_version,created_at,updated_at)
		VALUES($1,$2,$3,0,1,$4,$4) ON CONFLICT(competition_id) DO NOTHING`, arena.CompetitionID, revision, arena.PolicyID, now); err != nil {
		t.Fatal(err)
	}
	insertArenaPlayer(t, p, arena.Player{PlayerID: attacker.PlayerID, Server: server, Season: season, StarAt: now, Defense: arena.Lineup{Heroes: []int64{}}, Missions: []arena.MissionSlot{}, Awards: []arena.Award{}, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, revision)
	insertArenaPlayer(t, p, arena.Player{PlayerID: defender.PlayerID, Server: server, Season: season, StarAt: now, Defense: arena.Lineup{Heroes: tableIDs}, Missions: []arena.MissionSlot{}, Awards: []arena.Award{}, StateVersion: 1, CreatedAt: now, UpdatedAt: now}, revision)
	if _, err = p.Raw().Exec(context.Background(), `DELETE FROM arena_players WHERE player_id NOT IN ($1,$2)`, int64(attacker.PlayerID), int64(defender.PlayerID)); err != nil {
		t.Fatal(err)
	}

	opponents := adventureOpponents{Arena: apparena.Service{Store: arenastore.Store{}, Content: content,
		Heroes: characterstore.HeroBootstrapProjection{Content: content}, Pets: characterstore.PetBootstrapProjection{Content: content}}}
	enemy, found, err := opponents.ArenaOpponentTx(context.Background(), p, attacker.PlayerID, opponentSection, 0, time.Now().UTC())
	if err != nil || !found || enemy.PlayerID != defender.PlayerID {
		t.Fatalf("literal arena adapter found=%v enemy=%+v err=%v", found, enemy, err)
	}
	if len(enemy.Heroes) != len(tableIDs) {
		t.Fatalf("literal adapter heroes %+v", enemy.Heroes)
	}
	for index, tableID := range tableIDs {
		participant := enemy.Heroes[index]
		if participant.Origin != cd.OwnedForeign || participant.Kind != cd.HeroActor || participant.Player != defender.PlayerID ||
			participant.Identity != partnerByTable[tableID] || participant.TemplateParams != nil {
			t.Fatalf("literal adapter table %d resolved to %+v", tableID, participant)
		}
	}

	robotOpponents := adventureOpponents{TopFloor: apptopfloor.Service{Content: content}}
	robot, found, err := robotOpponents.RobotOpponentTx(context.Background(), p, 0)
	if err != nil || !found || len(robot.Heroes) == 0 {
		t.Fatalf("literal robot adapter found=%v robot=%+v err=%v", found, robot, err)
	}
	for _, participant := range robot.Heroes {
		partnerID, _ := participant.TemplateParams["partner_id"].(int64)
		if participant.Origin != cd.Template || participant.Kind != cd.HeroActor || participant.Player.Valid() ||
			participant.TemplateParams == nil || participant.Identity != partnerID {
			t.Fatalf("literal robot participant %+v", participant)
		}
	}
}
