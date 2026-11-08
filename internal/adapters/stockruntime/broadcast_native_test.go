//go:build postgres

package stockruntime

import (
	"context"
	"net"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	ach "gxb.local/backend/v2/internal/application/achievement"
	appbroadcast "gxb.local/backend/v2/internal/application/broadcast"
	cp "gxb.local/backend/v2/internal/application/commerceprivilege"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"gxb.local/backend/v2/internal/protocol/wire"
)

var broadcastContext = context.Background()

func broadcastOp() operation.Context {
	policies, _ := policy.NewSet()
	op, err := (operation.Factory{Clock: clock.System{}}).New(policies)
	if err != nil {
		panic(err)
	}
	return op
}

func broadcastPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B6A_DSN")
	if dsn == "" {
		t.Fatal("exact nativeDSN required")
	}
	p, err := pg.Open(broadcastContext, dsn, pg.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

func broadcastExec(t *testing.T, p *pg.Pool, statement string, args ...any) {
	t.Helper()
	if _, err := p.Raw().Exec(broadcastContext, statement, args...); err != nil {
		t.Fatal(err)
	}
}

func broadcastInstalled(t *testing.T, p *pg.Pool) string {
	t.Helper()
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	service := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, err = service.EnsureBuiltinInstalled(broadcastContext, broadcastOp(), bundle); err != nil {
		t.Fatal(err)
	}
	if _, err = service.BootstrapActivationIfMissing(broadcastContext, broadcastOp(), bundle); err != nil {
		t.Fatal(err)
	}
	return bundle.RevisionID()
}

func broadcastPlayerRoot(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, ids.UUID) {
	t.Helper()
	account, session, contextID := broadcastUUID(t), broadcastUUID(t), broadcastUUID(t)
	var playerID int64
	tr, err := p.Begin(broadcastContext, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(broadcastContext)
	if err = tr.QueryRow(broadcastContext, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=$1 RETURNING next_player_id-1`, int64(server)).Scan(&playerID); err != nil {
		t.Fatal(err)
	}
	rows := []struct {
		statement string
		args      []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'i9-10-broadcast-native')`, []any{playerID, account.String(), int64(server)}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i9-10-broadcast-native',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{session.String(), account.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,$4,$5,1,clock_timestamp())`, []any{contextID.String(), session.String(), account.String(), int64(server), playerID}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,'',1,110001001,0,0,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, []any{playerID}},
	}
	for _, row := range rows {
		if _, err = tr.Exec(broadcastContext, row.statement, row.args...); err != nil {
			t.Fatal(err)
		}
	}
	if err = tr.Commit(broadcastContext); err != nil {
		t.Fatal(err)
	}
	accountID, _ := identity.AccountIDFrom(account)
	sessionID, _ := identity.SessionIDFrom(session)
	contextUUID, _ := identity.ContextIDFrom(contextID)
	return identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID(account.String()), SessionID: sessionID, ContextID: contextUUID, LogicalServerID: server, PlayerID: identity.PlayerID(playerID), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}, account
}

func broadcastUUID(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}

func broadcastBornActor(t *testing.T, p *pg.Pool) identity.ActorContext {
	t.Helper()
	actor, account := broadcastPlayerRoot(t, p, 1)
	if err := nativebirth.PersistBare(broadcastContext, p, account, actor.LogicalServerID, actor.PlayerID); err != nil {
		t.Fatal(err)
	}
	for _, statement := range []string{
		`UPDATE player_profiles SET display_name='',avatar_id=110001001,avatar_frame_id=0,created_at=clock_timestamp()-interval '1 day',updated_at=clock_timestamp()-interval '1 day' WHERE player_id=$1`,
		`UPDATE player_progression SET exp=37,updated_at=clock_timestamp()-interval '1 day' WHERE player_id=$1`,
		`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp()-interval '1 day')
			ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=excluded.amount,updated_at=excluded.updated_at`,
	} {
		broadcastExec(t, p, statement, int64(actor.PlayerID))
	}
	return actor
}

func broadcastPrivilegeProvider(p *pg.Pool) cp.Provider {
	return cp.Provider{Store: ps.Store{}, Content: contentstore.Store{Queryer: p}}
}

func broadcastCompositeI5(p *pg.Pool) i5.Service {
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	return i5.Service{Runner: tx.Runner{DB: p}, Store: values, Content: content, Privileges: broadcastPrivilegeProvider(p), Functions: i5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Audit: audit.NopEmitter{}}
}

func broadcastLibraryService(p *pg.Pool) applibrary.Service {
	content := contentstore.Store{Queryer: p}
	heroes := characterstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	service := applibrary.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Reads: tx.Runner{DB: p}, Heroes: characterstore.LibraryHeroPort{Store: heroes}, Library: librarystore.Store{}, Content: content, Players: i4store.PlayerRootLocker{}, Fence: values, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Receipts: kernelstore.Store{}}
	service.Achievements = ach.Service{Store: achievementstore.Store{}, Content: content, Population: service}
	service.Roster = characterstore.HeroBootstrapProjection{Content: content, Library: service}
	service.Grants = broadcastCompositeI5(p)
	service.Facts = i5.ObjectiveFacts{Owner: broadcastCompositeI5(p), Open: values}
	service.Stacks = values
	service.Skins = heroes
	service.Broadcast = pg.BroadcastEmitter{}
	return service
}

type broadcastAuthority struct{ actor identity.ActorContext }

func (a broadcastAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

func broadcastAdmission(t *testing.T, contextUUID string, player identity.PlayerID, server identity.LogicalServerID) domainrt.Admission {
	t.Helper()
	accountUUID := broadcastUUID(t)
	sessionUUID := broadcastUUID(t)
	contextID, err := ids.ParseUUID(contextUUID)
	if err != nil {
		t.Fatal(err)
	}
	accountID, _ := identity.AccountIDFrom(accountUUID)
	sessionID, _ := identity.SessionIDFrom(sessionUUID)
	contextValue, _ := identity.ContextIDFrom(contextID)
	return domainrt.Admission{Role: domainrt.World, RoomID: int64(server), Actor: identity.ActorContext{
		AccountID: accountID, AccountUID: identity.AccountUID(accountUUID.String()), SessionID: sessionID,
		ContextID: contextValue, LogicalServerID: server, PlayerID: player, ContextGeneration: 3,
		SessionLivenessVersion: 4, ContextLivenessVersion: 5,
	}}
}

type broadcastPipe struct {
	frames chan rt.Frame
	errors chan error
}

func broadcastStartPipe(client net.Conn) *broadcastPipe {
	out := &broadcastPipe{frames: make(chan rt.Frame, 8), errors: make(chan error, 1)}
	go func() {
		decoder, err := rt.NewStreamDecoder(limits.Default())
		if err != nil {
			out.errors <- err
			return
		}
		buffer := make([]byte, 4096)
		for {
			count, err := client.Read(buffer)
			if err != nil {
				out.errors <- err
				return
			}
			values, err := decoder.Feed(buffer[:count])
			if err != nil {
				out.errors <- err
				return
			}
			for _, value := range values {
				out.frames <- value
			}
		}
	}()
	return out
}

func broadcastNumberValue(value any) (int64, bool) {
	switch number := value.(type) {
	case float64:
		return int64(number), number == float64(int64(number))
	case int64:
		return number, true
	case int32:
		return int64(number), true
	default:
		return 0, false
	}
}

func (p *broadcastPipe) expect(t *testing.T, msgType int64, playerName string) {
	t.Helper()
	select {
	case frame := <-p.frames:
		if frame.MID != mids.MIDSystemBroadcast {
			t.Fatalf("MID=%d want %d", frame.MID, mids.MIDSystemBroadcast)
		}
		outer, ok := frame.Params.(*amf3.Object)
		if !ok {
			t.Fatalf("params=%T", frame.Params)
		}
		fields, err := outer.StrictMap()
		if err != nil {
			t.Fatal(err)
		}
		msg, ok := fields["msg"].(*amf3.Object)
		if !ok {
			t.Fatalf("msg=%T", fields["msg"])
		}
		body, err := msg.StrictMap()
		if err != nil {
			t.Fatal(err)
		}
		gotType, ok := broadcastNumberValue(body["msg_type"])
		if !ok || gotType != msgType {
			t.Fatalf("msg_type=%v want %d", body["msg_type"], msgType)
		}
		if body["player_name"] != playerName {
			t.Fatalf("player_name=%v want %s", body["player_name"], playerName)
		}
		if cgID, ok := broadcastNumberValue(body["cg_id"]); !ok || cgID != 1 {
			t.Fatalf("cg_id=%v", body["cg_id"])
		}
		if region, ok := broadcastNumberValue(body["region"]); !ok || region != 1 {
			t.Fatalf("region=%v", body["region"])
		}
	case err := <-p.errors:
		t.Fatalf("read error: %v", err)
	case <-time.After(3 * time.Second):
		t.Fatalf("no broadcast delivered")
	}
}

func (p *broadcastPipe) silent(t *testing.T) {
	t.Helper()
	select {
	case frame := <-p.frames:
		t.Fatalf("unexpected frame MID=%d params=%+v", frame.MID, frame.Params)
	case <-p.errors:
	case <-time.After(300 * time.Millisecond):
	}
}

// TestI9_10BroadcastReachesSameServerOnly drives a delivered producer (Library
// CG claim) through its production dispatcher and asserts the announcement
// reaches a second World session on the same logical server and no session on
// another server.
func TestI9_10BroadcastReachesSameServerOnly(t *testing.T) {
	p := broadcastPool(t)
	broadcastInstalled(t, p)
	actor := broadcastBornActor(t, p)
	watcher := broadcastBornActor(t, p)
	remote, _ := broadcastPlayerRoot(t, p, 2)
	for player, name := range map[identity.PlayerID]string{actor.PlayerID: "Announcer", watcher.PlayerID: "Watcher", remote.PlayerID: "Remote"} {
		broadcastExec(t, p, `UPDATE player_directory_profiles SET name=$2 WHERE player_id=$1`, int64(player), name)
	}

	connections := NewConnectionRegistry()
	defer connections.CloseAll()
	watcherWriter, _, watcherClient := newRegistryPipeWriter(t)
	defer watcherClient.Close()
	if _, err := connections.Replace(broadcastAdmission(t, broadcastUUID(t).String(), watcher.PlayerID, 1), watcherWriter); err != nil {
		t.Fatal(err)
	}
	remoteWriter, _, remoteClient := newRegistryPipeWriter(t)
	defer remoteClient.Close()
	if _, err := connections.Replace(broadcastAdmission(t, broadcastUUID(t).String(), remote.PlayerID, 2), remoteWriter); err != nil {
		t.Fatal(err)
	}
	watcherPipe, remotePipe := broadcastStartPipe(watcherClient), broadcastStartPipe(remoteClient)

	events, err := NewBroadcastNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	handler := BroadcastNoticeHandler{DB: p, Names: i4store.PlayerRootLocker{}, Registry: connections,
		Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, MaxHandles: 10}
	wakeups, err := realtimewakeup.NewRegistry(realtimewakeup.Registration{Route: appbroadcast.Route, Handler: handler})
	if err != nil {
		t.Fatal(err)
	}
	listenerContext, stopListener := context.WithCancel(broadcastContext)
	defer stopListener()
	ready := make(chan struct{})
	listenerDone := make(chan error, 1)
	go func() {
		listenerDone <- (pg.RealtimeWakeupListener{Pool: p, Registry: wakeups, OnReady: func() { close(ready) }}).Run(listenerContext)
	}()
	select {
	case <-ready:
	case <-time.After(10 * time.Second):
		t.Fatal("realtime wakeup listener did not become ready")
	}
	defer func() {
		stopListener()
		<-listenerDone
	}()

	dispatcher := LibraryDispatcher{Authority: broadcastAuthority{actor: actor}, Service: broadcastLibraryService(p)}
	response := dispatcher.Dispatch(broadcastContext, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 855, Operation: broadcastOp(), ReceivedAt: time.Now().UTC(),
		Claims: wire.CredentialClaims{Token: "fixture", Region: int64(actor.LogicalServerID)}, Params: map[string]any{"index": int64(1)}}})
	if response.HTTPStatus != 200 {
		t.Fatalf("855 status %d body %+v", response.HTTPStatus, response.Body)
	}

	watcherPipe.expect(t, appbroadcast.UnlockCG, "Announcer")
	remotePipe.silent(t)
}
