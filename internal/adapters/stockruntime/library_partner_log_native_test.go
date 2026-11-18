//go:build postgres

package stockruntime

import (
	"context"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// TestI9_11GLPartnerLogNoticePushesOnce covers A-125 G1 steps 2-4: the
// registered route reloads the full map and pushes notice 24 to the actor's
// live session only; a duplicate row insert pushes nothing.
func TestI9_11GLPartnerLogNoticePushesOnce(t *testing.T) {
	dsn := os.Getenv("GXB_I7B6A_DSN")
	if dsn == "" {
		t.Skip("GXB_I7B6A_DSN with a migrated disposable database is required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	pool, err := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	players := seedPartnerLogPlayers(t, c, pool, 2)
	actor, other := players[0], players[1]
	partner := seedPartnerLogHero(t, c, pool, actor.PlayerID)

	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	actorPipe := dialPartnerLogSession(t, registry, actor, 1)
	otherPipe := dialPartnerLogSession(t, registry, other, 2)

	events, err := NewLibraryPartnerLogNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	handler := LibraryPartnerLogNoticeHandler{
		Service:    applibrary.PartnerLogReader{Queryer: pool, Library: librarystore.Store{}},
		Registry:   registry,
		Publisher:  RealtimePublisher{Registry: events, Limits: limits.Default()},
		Authority:  deliveryAuthority{},
		Time:       postgres.AuthoritativeTime{Queryer: pool},
		MaxHandles: 10,
	}
	wakeups, err := realtimewakeup.NewRegistry(realtimewakeup.Registration{Route: applibrary.PartnerLogNoticeRoute, Handler: handler})
	if err != nil {
		t.Fatal(err)
	}
	listenContext, stop := context.WithCancel(c)
	defer stop()
	ready := make(chan struct{})
	done := make(chan error, 1)
	go func() {
		done <- (postgres.RealtimeWakeupListener{Pool: pool, Registry: wakeups, OnReady: func() { close(ready) }}).Run(listenContext)
	}()
	select {
	case <-ready:
	case <-time.After(10 * time.Second):
		t.Fatal("realtime wakeup listener did not become ready")
	}
	defer func() {
		stop()
		<-done
	}()

	insertPartnerLog(t, c, pool, actor.PlayerID, partner, 20001)
	actorPipe.expectLibrarianNotice(t, partner)
	otherPipe.silent(t, "another player's session")

	insertPartnerLog(t, c, pool, actor.PlayerID, partner, 20001)
	actorPipe.silent(t, "duplicate insert")
}

func seedPartnerLogPlayers(t *testing.T, c context.Context, pool *postgres.Pool, count int) []identity.ActorContext {
	t.Helper()
	fixture, err := pool.Begin(c, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer fixture.Rollback(c)
	var first int64
	if err = fixture.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+$1,state_version=state_version+1 WHERE logical_server_id=1 RETURNING next_player_id-$1`, count).Scan(&first); err != nil {
		t.Fatal(err)
	}
	actors := make([]identity.ActorContext, 0, count)
	accounts := make([]ids.UUID, 0, count)
	for index := 0; index < count; index++ {
		player := identity.PlayerID(first + int64(index))
		account, session, gameplay := mustUUID(t), mustUUID(t), mustUUID(t)
		for _, statement := range []struct {
			sql  string
			args []any
		}{
			{`INSERT INTO accounts(account_id,status,created_at,account_uid)VALUES($1::uuid,'ACTIVE',clock_timestamp(),$1::text)`, []any{account.String()}},
			{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2::uuid,1,clock_timestamp(),'i9-11gl-fixture')`, []any{int64(player), account.String()}},
			{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1::uuid,$2::uuid,'i9-11gl-fixture',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{session.String(), account.String()}},
			{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1::uuid,$2::uuid,$3::uuid,1,$4,1,clock_timestamp())`, []any{gameplay.String(), session.String(), account.String(), int64(player)}},
			{`INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,'',1,110001001,0,0,0,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{int64(player)}},
		} {
			if _, err = fixture.Exec(c, statement.sql, statement.args...); err != nil {
				t.Fatal(err)
			}
		}
		accountID, _ := identity.AccountIDFrom(account)
		sessionID, _ := identity.SessionIDFrom(session)
		contextID, _ := identity.ContextIDFrom(gameplay)
		actors = append(actors, identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID(account.String()), SessionID: sessionID, ContextID: contextID, LogicalServerID: 1, PlayerID: player, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1})
		accounts = append(accounts, account)
	}
	if err = fixture.Commit(c); err != nil {
		t.Fatal(err)
	}
	for index, actor := range actors {
		if err = nativebirth.PersistBare(c, pool, accounts[index], 1, actor.PlayerID); err != nil {
			t.Fatal(err)
		}
	}
	return actors
}

func seedPartnerLogHero(t *testing.T, c context.Context, pool *postgres.Pool, player identity.PlayerID) int64 {
	t.Helper()
	revision, err := (contentstore.Store{}).ActiveRevision(c, pool)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(c, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(c)
	at := time.Now().UTC().Add(-time.Minute)
	hero := character.Hero{PlayerID: player, PartnerID: 1, TableID: 10001001, OriginTableID: 10001001, Star: 1, Level: 1, Color: 1,
		CreationContentRevision: revision, RawSkills: character.NewHeroRawSkillSeed(), IllusionSkinID: character.DefaultIllusionSkinID,
		StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	if err = (characterstore.Store{}).InsertHeroTx(c, transaction, hero); err != nil {
		t.Fatal(err)
	}
	if err = characterbirth.FreshHeroFacets().InitFreshHeroTx(c, transaction, hero.Ref(), at); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(c); err != nil {
		t.Fatal(err)
	}
	return hero.PartnerID
}

func insertPartnerLog(t *testing.T, c context.Context, pool *postgres.Pool, player identity.PlayerID, partner, logID int64) {
	t.Helper()
	transaction, err := pool.Begin(c, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(c)
	if _, err = (librarystore.Store{}).InsertHeroLogTx(c, transaction, library.HeroLogFact{PlayerID: player, PartnerID: partner, LogID: logID, OccurredAt: time.Now().UTC()}); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(c); err != nil {
		t.Fatal(err)
	}
}

func dialPartnerLogSession(t *testing.T, registry *ConnectionRegistry, actor identity.ActorContext, room int64) *noticePipe {
	t.Helper()
	writer, _, client := newRegistryPipeWriter(t)
	t.Cleanup(func() { client.Close() })
	if _, err := registry.Replace(registryAdmission(t, actor.ContextID.UUID().String(), actor.PlayerID, domainrt.World, room), writer); err != nil {
		t.Fatal(err)
	}
	return startNoticePipe(client)
}

func (p *noticePipe) expectLibrarianNotice(t *testing.T, partner int64) {
	t.Helper()
	select {
	case frame := <-p.frames:
		if frame.MID != mids.MIDPlayerNotice {
			t.Fatalf("notice MID %d", frame.MID)
		}
		if reason := decodedPartnerLogNotice(frame.Params, partner); reason != "" {
			t.Fatalf("notice 24 %s: %+v", reason, frame.Params)
		}
	case err := <-p.errors:
		t.Fatalf("notice read %v", err)
	case <-time.After(3 * time.Second):
		t.Fatal("no partner log notice delivered")
	}
}

func decodedPartnerLogNotice(value any, partner int64) string {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return "payload is not an AMF3 object"
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 {
		return "notice envelope"
	}
	noticeType, ok := decodedNumber(fields["notice_type"])
	params, paramsOK := fields["params"].(*amf3.Object)
	if !ok || noticeType != LibraryPartnerLogNoticeType || !paramsOK || params == nil {
		return "notice type or params"
	}
	body, err := params.StrictMap()
	if err != nil || len(body) != 2 {
		return "params shape"
	}
	gotPartner, ok := decodedNumber(body["partner_id"])
	if !ok || gotPartner != partner {
		return "partner id"
	}
	logInfo, ok := body["log_info"].(*amf3.Object)
	if !ok || logInfo == nil {
		return "log_info shape"
	}
	logs, err := logInfo.StrictMap()
	if err != nil {
		return "log_info map"
	}
	for _, key := range []string{"10001", "20001"} {
		entry, ok := logs[key].(*amf3.Object)
		if !ok || entry == nil {
			return "missing log " + key
		}
		if _, ok := entry.Map()["time"]; !ok {
			return "log " + key + " time"
		}
	}
	return ""
}

func mustUUID(t *testing.T) ids.UUID {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value
}
