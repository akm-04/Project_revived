//go:build postgres && socialintegration

// Package socialrelation_test exercises real owner adapters and native PostgreSQL.
// Enable with -tags "postgres socialintegration" and a disposable migrated database.
// It deliberately fails if no DSN is supplied once this explicit native suite is selected.
package socialprojection_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/socialview"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"sync"
	"testing"
	"time"
)

var ctx = context.Background()

type fixture struct {
	t  *testing.T
	p  *postgres.Pool
	s  sr.Service
	v  sp.Service
	at time.Time
}

func existing(t *testing.T) *fixture {
	t.Helper()
	dsn := os.Getenv("GXB_I7A4C_TEST_DSN")
	if dsn == "" {
		t.Fatal("GXB_I7A4C_TEST_DSN must name a disposable migrated PostgreSQL database")
	}
	p, e := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(p.Close)
	f := &fixture{t: t, p: p}

	f.s = sr.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, PlayerRoots: i4store.PlayerRootLocker{}, Store: socialrelationstore.Store{}, Inbox: socialinbox.RelationService{Store: socialinboxstore.Store{}}, Presentation: socialpresentation.TransactionReader{}}
	f.v = sp.Service{Runner: tx.Runner{DB: p}, PlayerRoots: i4store.PlayerRootLocker{}, Relations: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}, Directory: i4store.TransactionDiscoveryReader{}, Presentation: socialpresentation.TransactionReader{}, Observer: socialpresentation.TransactionReader{}}
	f.at = f.now()
	return f
}
func fresh(t *testing.T) *fixture { f := existing(t); f.sql(`TRUNCATE accounts CASCADE`); return f }

func (f *fixture) sql(q string, args ...any) {
	f.t.Helper()
	if _, e := f.p.Raw().Exec(ctx, q, args...); e != nil {
		f.t.Fatalf("fixture SQL: %v", e)
	}
}
func (f *fixture) number(q string, args ...any) int64 {
	f.t.Helper()
	var n int64
	if e := f.p.QueryRow(ctx, q, args...).Scan(&n); e != nil {
		f.t.Fatal(e)
	}
	return n
}
func (f *fixture) text(q string, args ...any) string {
	f.t.Helper()
	var s string
	if e := f.p.QueryRow(ctx, q, args...).Scan(&s); e != nil {
		f.t.Fatal(e)
	}
	return s
}
func (f *fixture) now() time.Time {
	f.t.Helper()
	v, e := (postgres.AuthoritativeTime{Queryer: f.p}).Now(ctx)
	if e != nil {
		f.t.Fatal(e)
	}
	return v
}
func (f *fixture) player(pid identity.PlayerID) {
	f.t.Helper()
	u, _ := ids.NewUUID()
	server, _ := sr.CanonicalServer(pid)
	f.sql(`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'fixture',true,true,true,$2,$3,$4) ON CONFLICT DO NOTHING`, int32(server), int64(server)*100000+1, (int64(server)+1)*100000-1, f.at)
	f.sql(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, u.String(), fmt.Sprint(pid), f.at)
	f.sql(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'fixture')`, int64(pid), u.String(), int32(server), f.at)
	f.sql(`INSERT INTO player_directory_profiles(player_id,name,created_at,updated_at) VALUES($1,$2,$3,$3)`, int64(pid), fmt.Sprint(pid), f.at)
	f.sql(`INSERT INTO player_profiles(player_id,display_name,avatar_id,created_at,updated_at) VALUES($1,$2,110001001,$3,$3)`, int64(pid), fmt.Sprint(pid), f.at)
}
func actor(pid identity.PlayerID) identity.ActorContext {
	u, _ := ids.NewUUID()
	a, _ := identity.AccountIDFrom(u)
	s, _ := identity.SessionIDFrom(u)
	c, _ := identity.ContextIDFrom(u)
	server, _ := sr.CanonicalServer(pid)
	return identity.ActorContext{AccountID: a, AccountUID: "admitted-fixture", SessionID: s, ContextID: c, LogicalServerID: server, PlayerID: pid, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func (f *fixture) runAs(pid identity.PlayerID, k sr.CommandKind, targets ...identity.PlayerID) (sr.Result, error) {
	u, _ := ids.NewUUID()
	return f.s.Execute(ctx, actor(pid), sr.Command{Kind: k, Targets: targets}, operation.Context{ID: u, StartedAt: f.now()})
}
func (f *fixture) ok(pid identity.PlayerID, k sr.CommandKind, targets ...identity.PlayerID) sr.Result {
	f.t.Helper()
	v, e := f.runAs(pid, k, targets...)
	if e != nil {
		f.t.Fatalf("MID%d actor%d targets%v: %v", k, pid, targets, e)
	}
	return v
}
func stock(t *testing.T, e error, code int64) {
	t.Helper()
	var s *sr.StockError
	if !errors.As(e, &s) || s.Code != code {
		t.Fatalf("want stock %d got %v", code, e)
	}
}
func (f *fixture) snapshot() string {
	return f.text(`SELECT jsonb_build_object('roots',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY player_id),'[]') FROM player_social_roots t),'friends',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY player_low_id,player_high_id),'[]') FROM social_friendships t),'requests',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY requester_player_id,target_player_id),'[]') FROM social_friend_requests t),'blocks',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY blocker_player_id,blocked_player_id),'[]') FROM social_blocks t),'epochs',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY player_id,policy_id),'[]') FROM social_request_epochs t),'notices',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY recipient_player_id,notice_id),'[]') FROM social_notices t))::text`)
}

func (f *fixture) op() operation.Context {
	u, _ := ids.NewUUID()
	return operation.Context{ID: u, StartedAt: f.now(), EntropySeed: [32]byte{5, 7, 11}}
}
func (f *fixture) root(pid identity.PlayerID) {
	f.sql(`INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,$2,$2)ON CONFLICT DO NOTHING`, int64(pid), f.at)
}
func (f *fixture) friend(a, b identity.PlayerID) {
	f.root(a)
	f.root(b)
	lo, hi, _ := sr.CanonicalPair(a, b)
	f.sql(`INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,updated_at) VALUES($1,$2,1,true,$3,$3)`, int64(lo), int64(hi), f.at)
}
func (f *fixture) block(a, b identity.PlayerID) {
	f.root(a)
	f.root(b)
	f.sql(`INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,updated_at) VALUES($1,$2,1,true,$3,$3)`, int64(a), int64(b), f.at)
}
func (f *fixture) request(a, b identity.PlayerID) {
	f.root(a)
	f.root(b)
	f.sql(`INSERT INTO social_friend_requests(requester_player_id,target_player_id,generation,status,requested_at,updated_at,request_msg) VALUES($1,$2,1,'PENDING',$3,$3,'hello')`, int64(a), int64(b), f.at)
}
func (f *fixture) notice(id int64, related identity.PlayerID, kind, key string, typ int16, at time.Time) {
	f.root(100001)
	f.sql(`INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,notice_time,created_at,updated_at)VALUES(100001,$1,$2,$3,$4,NULLIF($5,0),$6,$6,$6)`, id, typ, kind, key, int64(related), at)
}
func (f *fixture) relationNotices(n int) {
	for i := 1; i <= n; i++ {
		f.notice(int64(i), 200001, "social-relation.request.v1", fmt.Sprintf("100001:200001:%d:ACCEPT", i), 1, f.at)
	}
}
func (f *fixture) many(start, n int) {
	f.sql(`INSERT INTO accounts(account_id,account_uid,status,created_at)SELECT gen_random_uuid(),g::text,'ACTIVE',$3 FROM generate_series($1::int,$2::int)g`, start, start+n-1, f.at)
	f.sql(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)SELECT account_uid::bigint,account_id,(account_uid::bigint/100000)::int,$3,'fixture' FROM accounts WHERE account_uid::bigint BETWEEN $1 AND $2`, start, start+n-1, f.at)
	f.sql(`INSERT INTO player_directory_profiles(player_id,name,created_at,updated_at)SELECT player_id,player_id::text,$3,$3 FROM players WHERE player_id BETWEEN $1 AND $2`, start, start+n-1, f.at)
	f.sql(`INSERT INTO player_profiles(player_id,display_name,avatar_id,created_at,updated_at)SELECT player_id,player_id::text,110001001,$3,$3 FROM players WHERE player_id BETWEEN $1 AND $2`, start, start+n-1, f.at)
	f.sql(`INSERT INTO player_social_roots(player_id,created_at,updated_at)SELECT player_id,$3,$3 FROM players WHERE player_id BETWEEN $1 AND $2`, start, start+n-1, f.at)
}
func (f *fixture) base() sp.Result {
	f.t.Helper()
	v, e := f.v.LoadBase(ctx, actor(100001), f.op())
	if e != nil {
		f.t.Fatal(e)
	}
	return v
}
func requireEmptyOnError(t *testing.T, v sp.Result, e error) {
	t.Helper()
	if e == nil || !reflect.DeepEqual(v, sp.Result{}) {
		t.Fatalf("error leaked attempted result: %+v %v", v, e)
	}
}
func playerIDs(v []sp.Player) []identity.PlayerID {
	out := []identity.PlayerID{}
	for _, x := range v {
		out = append(out, x.Presentation.Minimal.PlayerID)
	}
	return out
}

type countedPresentation struct {
	reader          playerpresentation.TxReader
	reads, observes int
	at              []time.Time
}

func (c *countedPresentation) ReadManyTx(x context.Context, t tx.Tx, p []identity.PlayerID) (playerpresentation.Batch, error) {
	c.reads++
	b, e := c.reader.ReadManyTx(x, t, p)
	c.at = append(c.at, b.ObservedAt)
	return b, e
}
func (c *countedPresentation) ObserveTx(x context.Context, t tx.Tx) (time.Time, error) {
	c.observes++
	return (socialpresentation.TransactionReader{}).ObserveTx(x, t)
}
func TestC02EmptyBaseClockNoCreation(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	before := f.snapshot()
	counter := &countedPresentation{reader: f.v.Presentation}
	f.v.Presentation = counter
	f.v.Observer = counter
	v := f.base()
	if v.ObservedAt.IsZero() || len(v.Friends)+len(v.Blocks)+len(v.Notices)+len(v.Requests) != 0 || counter.reads != 1 || counter.observes != 1 || !counter.at[0].IsZero() || before != f.snapshot() {
		t.Fatal("empty observation/create contract")
	}
	raw, _ := json.Marshal(socialpresentation.MapBase(v))
	t.Log(string(raw))
}

type badRoots struct{ playerroot.TxLocker }

func (b badRoots) LockPlayerRootsTx(c context.Context, t tx.Tx, s identity.LogicalServerID, p []identity.PlayerID) ([]playerroot.Root, error) {
	return []playerroot.Root{{PlayerID: 999999, LogicalServerID: s}}, nil
}
func TestC03ActorBindingAndMalformedPorts(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	a := actor(100001)
	a.ContextLivenessVersion = 0
	v, e := f.v.LoadBase(ctx, a, f.op())
	requireEmptyOnError(t, v, e)
	a = actor(100001)
	a.LogicalServerID = 2
	v, e = f.v.LoadBase(ctx, a, f.op())
	requireEmptyOnError(t, v, e)
	v, e = f.v.LoadBase(ctx, actor(100002), f.op())
	requireEmptyOnError(t, v, e)
	f.v.PlayerRoots = badRoots{f.v.PlayerRoots}
	v, e = f.v.LoadBase(ctx, actor(100001), f.op())
	requireEmptyOnError(t, v, e)
	f.v.Observer = nil
	v, e = f.v.LoadBase(ctx, actor(100001), f.op())
	requireEmptyOnError(t, v, e)
}
func TestC04CanonicalListsDirectionTombstonesCoexistence(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.many(200001, 6)
	f.friend(100001, 200001)
	f.friend(100001, 200002)
	f.sql(`UPDATE social_friendships SET active=false,ended_at=$1 WHERE player_high_id=200002`, f.at)
	f.block(100001, 200001)
	f.block(200002, 100001)
	f.block(100001, 200003)
	f.sql(`UPDATE social_blocks SET active=false,removed_at=$1 WHERE blocked_player_id=200003`, f.at)
	f.request(200004, 100001)
	f.request(100001, 200005)
	f.request(200006, 100001)
	f.sql(`UPDATE social_friend_requests SET status='IGNORED',terminal_at=$1 WHERE requester_player_id=200006`, f.at)
	f.relationNotices(1)
	v := f.base()
	if !reflect.DeepEqual(playerIDs(v.Friends), []identity.PlayerID{200001}) || !reflect.DeepEqual(playerIDs(v.Blocks), []identity.PlayerID{200001}) || len(v.Requests) != 1 || v.Requests[0].Relation.RequesterPlayerID != 200004 || len(v.Notices) != 1 {
		t.Fatalf("lists %+v", v)
	}
	for _, k := range []sp.ListKind{sp.Friend, sp.Request, sp.Blacklist, sp.Notice} {
		x, e := f.v.LoadList(ctx, actor(100001), k, f.op())
		if e != nil {
			t.Fatal(e)
		}
		wire, e := socialpresentation.MapList(x, k)
		if e != nil {
			t.Fatal(e)
		}
		raw, _ := json.Marshal(wire)
		if len(raw) == 0 || raw[0] != '[' {
			t.Fatal(string(raw))
		}
	}
}
func TestC05FullListsBeyond512StableOrder(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.root(100001)
	f.many(200001, 520)
	f.sql(`INSERT INTO social_friend_requests(requester_player_id,target_player_id,generation,status,requested_at,updated_at)SELECT player_id,100001,1,'PENDING',$1,$1 FROM players WHERE player_id>=200001`, f.at)
	f.sql(`INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,updated_at)SELECT 100001,player_id,1,true,$1,$1 FROM players WHERE player_id>=200001`, f.at)
	v := f.base()
	if len(v.Requests) != 520 || len(v.Blocks) != 520 {
		t.Fatalf("truncated %d %d", len(v.Requests), len(v.Blocks))
	}
	for i := 1; i < 520; i++ {
		if v.Requests[i].Relation.RequesterPlayerID <= v.Requests[i-1].Relation.RequesterPlayerID || playerIDs(v.Blocks)[i] <= playerIDs(v.Blocks)[i-1] {
			t.Fatal("unstable order")
		}
	}
	f.sql(`UPDATE social_friend_requests SET requested_at=$1,updated_at=$1 WHERE requester_player_id=200520`, f.at.Add(time.Second))
	v = f.base()
	if v.Requests[0].Relation.RequesterPlayerID != 200520 {
		t.Fatal("newest not first")
	}
}
func TestC06RelationWindowFiltersBeforeLimitNoAuthority(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.relationNotices(60)
	for i := 61; i <= 160; i++ {
		f.notice(int64(i), 200001, "future.gift.v1", fmt.Sprint(i), 77, f.at.Add(time.Minute))
	}
	f.notice(161, 0, "social-relation.request.v1", "not projected null", 1, f.at.Add(time.Minute))
	before := f.snapshot()
	v := f.base()
	if len(v.Notices) != 50 || v.Notices[0].Notice.NoticeID != 60 || v.Notices[49].Notice.NoticeID != 11 || before != f.snapshot() {
		t.Fatalf("window/filter/write %+v", v.Notices)
	}
}
func TestC07ActualFKNullDeletionRefillsOlderNotice(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.player(200002)
	f.relationNotices(51)
	f.notice(52, 200002, "social-relation.request.v1", "100001:200002:1:ACCEPT", 1, f.at.Add(time.Minute))
	f.sql(`DELETE FROM player_directory_profiles WHERE player_id=200002`)
	f.sql(`DELETE FROM player_profiles WHERE player_id=200002`)
	f.sql(`DELETE FROM players WHERE player_id=200002`)
	if f.number(`SELECT count(*) FROM social_notices WHERE notice_id=52 AND related_player_id IS NULL`) != 1 {
		t.Fatal("FK not SET NULL")
	}
	v := f.base()
	if len(v.Notices) != 50 || v.Notices[0].Notice.NoticeID != 51 || v.Notices[49].Notice.NoticeID != 2 {
		t.Fatal("older valid notice not refilled")
	}
	if f.number(`SELECT count(*)FROM social_notices`) != 52 {
		t.Fatal("read cleaned notices")
	}
}
func TestC08CorruptIncludedDescriptorsFailWholeRead(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.relationNotices(1)
	for _, key := range []string{"100001:200001:0:ACCEPT", "100001:200001:01:ACCEPT", "200001:100001:1:ACCEPT", "100001:200002:1:ACCEPT", "100001:200001:1:DELETE", "bad"} {
		f.sql(`UPDATE social_notices SET source_key=$1`, key)
		v, e := f.v.LoadBase(ctx, actor(100001), f.op())
		requireEmptyOnError(t, v, e)
	}
	f.sql(`UPDATE social_notices SET source_key='100001:200001:1:ACCEPT',notice_type=2`)
	v, e := f.v.LoadBase(ctx, actor(100001), f.op())
	requireEmptyOnError(t, v, e)
}
func TestC09MissingRequiredProfilesFailEveryShape(t *testing.T) {
	for _, table := range []string{"player_directory_profiles", "player_profiles"} {
		t.Run(table, func(t *testing.T) {
			f := fresh(t)
			f.player(100001)
			f.player(200001)
			f.friend(100001, 200001)
			f.block(100001, 200001)
			f.request(200001, 100001)
			f.relationNotices(1)
			f.sql("DELETE FROM " + table + " WHERE player_id=200001")
			for _, k := range []sp.ListKind{sp.Friend, sp.Request, sp.Blacklist, sp.Notice} {
				v, e := f.v.LoadList(ctx, actor(100001), k, f.op())
				requireEmptyOnError(t, v, e)
			}
			v, e := f.v.LoadBase(ctx, actor(100001), f.op())
			requireEmptyOnError(t, v, e)
			if table == "player_profiles" {
				v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: "200001"}, f.op())
				requireEmptyOnError(t, v, e)
				f.sql(`DELETE FROM social_friendships;DELETE FROM social_blocks;DELETE FROM social_friend_requests`)
				v, e = f.v.Recommend(ctx, actor(100001), f.op())
				requireEmptyOnError(t, v, e)
			}
		})
	}
}
func (f *fixture) presence(pid identity.PlayerID) {
	f.sql(`INSERT INTO player_social_presence(player_id,last_seen_at,created_at,updated_at)VALUES($1,$2,$2,$2)`, int64(pid), f.at.Add(-time.Hour))
}
func (f *fixture) lease(pid identity.PlayerID, role string, connected, expires time.Time) {
	u, _ := ids.NewUUID()
	v, _ := ids.NewUUID()
	f.sql(`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at,liveness_version)SELECT $1::uuid,account_id,'fixture',$2,$2,1 FROM players WHERE player_id=$3`, u.String(), f.at, int64(pid))
	f.sql(`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)SELECT $1::uuid,$1::uuid,account_id,logical_server_id,player_id,1,$2 FROM players WHERE player_id=$3`, u.String(), f.at, int64(pid))
	f.sql(`INSERT INTO realtime_presence_leases(gameplay_context_id,physical_role,player_id,realtime_instance_id,connection_generation,connected_at,last_renewed_at,lease_expires_at,realtime_owner_fence)VALUES($1::uuid,$2,$3,$4::uuid,1,$5,$5,$6,1)`, u.String(), role, int64(pid), v.String(), connected, expires)
}
func TestC10PresenceSingleObservationRoleExpiryAndWireTime(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.many(200001, 3)
	for _, id := range []identity.PlayerID{200001, 200002, 200003} {
		f.friend(100001, id)
	}
	f.presence(200001)
	f.presence(200002)
	old := f.at.Add(-2 * time.Minute)
	latest := f.at.Add(-time.Minute)
	f.lease(200001, "WORLD", old, f.at.Add(time.Hour))
	f.lease(200001, "GUILD", latest, f.at.Add(time.Hour))
	f.lease(200001, "SERVICE", f.at.Add(-30*time.Second), f.at.Add(-time.Second))
	f.lease(200002, "WORLD", old, f.at.Add(-time.Second))
	counter := &countedPresentation{reader: f.v.Presentation}
	f.v.Presentation = counter
	f.v.Observer = counter
	before := f.snapshot()
	v := f.base()
	wire := socialpresentation.MapBase(v)
	if counter.reads != 1 || counter.observes != 0 || !counter.at[0].Equal(v.ObservedAt) || wire.Friends[0].IsOnline != 1 || wire.Friends[0].LastTime != latest.Unix() || wire.Friends[1].IsOnline != 0 || wire.Friends[1].LastTime != f.at.Add(-time.Hour).Unix() || wire.Friends[2].LastTime != 0 || before != f.snapshot() {
		t.Fatalf("presence %+v", wire.Friends)
	}
}
func TestC11ModernNumericAndRawNameUnionNoExclusions(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.many(200001, 4)
	f.friend(100001, 200001)
	f.block(100001, 200002)
	f.sql(`UPDATE player_directory_profiles SET name='200001'WHERE player_id IN(100001,200001,200002,200003)`)
	v, e := f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: "200001"}, f.op())
	if e != nil || !reflect.DeepEqual(playerIDs(v.Players), []identity.PlayerID{200001, 100001, 200002, 200003}) {
		t.Fatalf("union %v %v", playerIDs(v.Players), e)
	}
	f.sql(`UPDATE player_directory_profiles SET name='0200001'WHERE player_id=200004`)
	v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: "0200001"}, f.op())
	if e != nil || !reflect.DeepEqual(playerIDs(v.Players), []identity.PlayerID{200001, 200004}) {
		t.Fatal("leading zero union")
	}
	f.sql(`UPDATE player_directory_profiles SET name='Case'WHERE player_id=200004`)
	v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: "case"}, f.op())
	if e != nil || len(v.Players) != 0 {
		t.Fatal("case folding")
	}
}
func TestC12EmptyAndOutgoingOnlyOverlay(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.many(200001, 3)
	f.request(100001, 200001)
	f.request(200002, 100001)
	f.request(100001, 200003)
	f.sql(`UPDATE social_friend_requests SET status='DENIED',terminal_at=$1 WHERE target_player_id=200003`, f.at)
	for _, term := range []string{"", "not-a-match"} {
		v, e := f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: term}, f.op())
		if e != nil || v.Players == nil || len(v.Players) != 0 {
			t.Fatal("modern []")
		}
	}
	for i := 1; i <= 3; i++ {
		v, e := f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: fmt.Sprint(200000 + i)}, f.op())
		if e != nil || len(v.Players) != 1 || v.Players[0].OutgoingPending != (i == 1) {
			t.Fatal("direction overlay", e)
		}
	}
}
func TestC13StrictShapeUTF8LengthAndRawNameBranches(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.many(200001, 6)
	terms := []string{"0", "+200001", " 200001", "２００００１", "9223372036854775808", "200001 "}
	for i, term := range terms {
		f.sql(`UPDATE player_directory_profiles SET name=$1 WHERE player_id=$2`, term, 200001+i)
		v, e := f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: term}, f.op())
		if e != nil || len(v.Players) != 1 || v.Players[0].Presentation.Minimal.PlayerID != identity.PlayerID(200001+i) {
			t.Fatal("raw nonnumeric name suppressed", term, e)
		}
	}
	for _, raw := range []string{`{}`, `{"msg":"a","player_name":"a"}`, `{"msg":1}`, `{"msg":null}`, `{"other":"a"}`, `{"msg":"a","msg":"b"}`, `{"msg":"123456789012345678901"}`} {
		if _, e := socialpresentation.DecodeSearch([]byte(raw)); e == nil {
			t.Fatal("decoder accepted", raw)
		}
	}
	if _, e := socialpresentation.DecodeSearch([]byte{'{', '"', 'm', 's', 'g', '"', ':', '"', 255, '"', '}'}); e == nil {
		t.Fatal("invalid UTF8")
	}
	q, e := socialpresentation.DecodeSearch([]byte(`{"msg":"一二三四五六七八九十一二三四五六七八九十"}`))
	if e != nil || q.Mode != sp.Modern {
		t.Fatal("20 Unicode codepoints")
	}
}
func TestC14ExactNameSaturationLegacySingleNoneAmbiguous(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.many(200001, 101)
	f.sql(`UPDATE player_directory_profiles SET name='same' WHERE player_id BETWEEN 200001 AND 200100`)
	v, e := f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: "same"}, f.op())
	if e != nil || len(v.Players) != 100 {
		t.Fatal("100 boundary", e)
	}
	v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Legacy, Term: "same"}, f.op())
	requireEmptyOnError(t, v, e)
	if !errors.Is(e, sp.ErrAmbiguousSearch) {
		t.Fatal(e)
	}
	f.sql(`UPDATE player_directory_profiles SET name='same' WHERE player_id=200101`)
	v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Modern, Term: "same"}, f.op())
	requireEmptyOnError(t, v, e)
	if !errors.Is(e, sp.ErrSearchSaturated) {
		t.Fatal(e)
	}
	for _, term := range []string{"", "none"} {
		v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Legacy, Term: term}, f.op())
		requireEmptyOnError(t, v, e)
		stock(t, e, 20004)
	}
	v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: sp.Legacy, Term: "100001"}, f.op())
	if e != nil || len(v.Players) != 1 {
		t.Fatal(e)
	}
	wire, e := socialpresentation.MapSearch(v, sp.Legacy)
	if e != nil {
		t.Fatal(e)
	}
	raw, _ := json.Marshal(wire)
	if raw[0] != '{' {
		t.Fatal("legacy not object")
	}
}
func TestC15RecommendTypedExclusionsNoQuotaCapacityPresenceFilter(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.many(200001, 8)
	f.friend(100001, 200001)
	f.block(100001, 200002)
	f.block(200003, 100001)
	f.request(100001, 200004)
	f.request(200005, 100001)
	f.request(100001, 200006)
	f.sql(`UPDATE social_friend_requests SET status='IGNORED',terminal_at=$1 WHERE target_player_id=200006`, f.at)
	f.presence(200007)
	f.lease(200007, "WORLD", f.at.Add(-time.Minute), f.at.Add(time.Hour))
	f.sql(`INSERT INTO social_request_epochs(player_id,policy_id,epoch_generation,epoch_started_at,successful_new_requests,updated_at)VALUES(100001,'fixture',99,$1,9999,$1)`, f.at)
	v, e := f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil {
		t.Fatal(e)
	}
	got := playerIDs(v.Players)
	sortIDs := append([]identity.PlayerID{}, got...)
	sort.Slice(sortIDs, func(i, j int) bool { return sortIDs[i] < sortIDs[j] })
	if !reflect.DeepEqual(sortIDs, []identity.PlayerID{200006, 200007, 200008}) {
		t.Fatalf("eligibility %v", got)
	}
}

type anchoredDirectory struct {
	playerdirectory.TxDiscoveryReader
	min, max identity.PlayerID
	bounds   int
	afters   []identity.PlayerID
	limits   []int
}

func (d *anchoredDirectory) PlayerIDBoundsTx(c context.Context, t tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error) {
	d.bounds++
	return d.min, d.max, d.min != 0, nil
}
func (d *anchoredDirectory) ProfilesAfterTx(c context.Context, t tx.Tx, p identity.PlayerID, l int) ([]playerdirectory.Profile, error) {
	d.afters = append(d.afters, p)
	d.limits = append(d.limits, l)
	return d.TxDiscoveryReader.ProfilesAfterTx(c, t, p, l)
}
func TestC16SparseInclusivePivotWrapEmptyAndExtreme(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.player(900001)
	d := &anchoredDirectory{TxDiscoveryReader: f.v.Directory, min: 200001, max: 200001}
	f.v.Directory = d
	v, e := f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || !reflect.DeepEqual(playerIDs(v.Players), []identity.PlayerID{200001, 900001}) || !v.Scan.Wrapped || d.afters[0] != 200000 {
		t.Fatal("inclusive sparse wrap", e, playerIDs(v.Players), d.afters)
	}
	d.min = 0
	d.max = 0
	v, e = f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || len(v.Players) != 0 {
		t.Fatal("empty anchored bounds")
	}
	d.min = 214748364799998
	d.max = d.min
	f.player(d.min)
	v, e = f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || playerIDs(v.Players)[0] != d.min {
		t.Fatal("maximum supported server", e)
	}
	d.min = 214748364800001
	d.max = d.min
	v, e = f.v.Recommend(ctx, actor(100001), f.op())
	requireEmptyOnError(t, v, e)
}
func TestC17ScanTotalFetchedCeilingAndPageBounds(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.root(100001)
	f.many(200001, 4200)
	f.sql(`INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,updated_at)SELECT 100001,player_id,1,true,$1,$1 FROM players WHERE player_id>=200001`, f.at)
	d := &anchoredDirectory{TxDiscoveryReader: f.v.Directory, min: 200001, max: 200001}
	f.v.Directory = d
	v, e := f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || v.Scan.Fetched != 4096 || v.Scan.Evaluated != 4096 || len(v.Players) != 0 {
		t.Fatal("scan cap", v.Scan, e)
	}
	for _, l := range d.limits {
		if l < 1 || l > 128 {
			t.Fatal("page", l)
		}
	}
}

type retryBeginner struct {
	db         tx.Beginner
	begins     int
	afterFirst func()
	always     bool
}

func (f *retryBeginner) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	if o.Isolation != tx.RepeatableRead || o.ReadOnly {
		return nil, errors.New("wrong projection options")
	}
	f.begins++
	v, e := f.db.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return &retryTx{Tx: v, abort: f.begins == 1 || f.always, after: f.afterFirst}, nil
}

type retryTx struct {
	tx.Tx
	abort bool
	after func()
}

func (f *retryTx) Commit(c context.Context) error {
	if f.abort {
		if e := f.Tx.Rollback(c); e != nil {
			return e
		}
		if f.after != nil {
			f.after()
		}
		return tx.MarkDefiniteAbort(errors.New("injected serialization abort after native rollback"))
	}
	return f.Tx.Commit(c)
}
func TestC18DefiniteAbortRetainsAbsoluteAnchorAndPrivateResult(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.player(900001)
	d := &anchoredDirectory{TxDiscoveryReader: f.v.Directory, min: 200001, max: 200001}
	f.v.Directory = d
	retry := &retryBeginner{db: f.p, afterFirst: func() { d.min = 100001; d.max = 900001; f.player(300001) }}
	f.v.Runner.DB = retry
	op := f.op()
	v, e := f.v.Recommend(ctx, actor(100001), op)
	if e != nil || retry.begins != 2 || d.bounds != 1 || v.Scan.Pivot != 200001 || !reflect.DeepEqual(playerIDs(v.Players), []identity.PlayerID{200001, 300001, 900001}) || d.afters[0] != d.afters[2] {
		t.Fatalf("anchor retry %+v %v bounds%d after%v begins%d", v.Scan, e, d.bounds, d.afters, retry.begins)
	}
	retry = &retryBeginner{db: f.p, always: true}
	f.v.Runner.DB = retry
	v, e = f.v.LoadBase(ctx, actor(100001), op)
	requireEmptyOnError(t, v, e)
	if retry.begins != 3 {
		t.Fatal("retry bound", retry.begins)
	}
}

type faultBeginner struct {
	db     tx.Beginner
	commit bool
	begins int
}

func (f *faultBeginner) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	f.begins++
	v, e := f.db.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return &faultTx{Tx: v, commit: f.commit}, nil
}

type faultTx struct {
	tx.Tx
	commit bool
}

func (f *faultTx) Commit(c context.Context) error {
	var e error
	if f.commit {
		e = f.Tx.Commit(c)
	} else {
		e = f.Tx.Rollback(c)
	}
	if e != nil {
		return e
	}
	return errors.New("injected acknowledgement loss after native finalization")
}
func TestC19UnknownCommitEveryReadNoPublishNoReplayNoWrites(t *testing.T) {
	for _, committed := range []bool{true, false} {
		for k := 0; k < 8; k++ {
			t.Run(fmt.Sprintf("committed%v_shape%d", committed, k), func(t *testing.T) {
				f := fresh(t)
				f.player(100001)
				f.player(200001)
				f.friend(100001, 200001)
				before := f.snapshot()
				fault := &faultBeginner{db: f.p, commit: committed}
				f.v.Runner.DB = fault
				var v sp.Result
				var e error
				switch {
				case k == 0:
					v, e = f.v.LoadBase(ctx, actor(100001), f.op())
				case k <= 4:
					v, e = f.v.LoadList(ctx, actor(100001), sp.ListKind(k), f.op())
				case k <= 6:
					mode := sp.Modern
					if k == 6 {
						mode = sp.Legacy
					}
					v, e = f.v.Search(ctx, actor(100001), sp.SearchQuery{Mode: mode, Term: "200001"}, f.op())
				default:
					v, e = f.v.Recommend(ctx, actor(100001), f.op())
				}
				requireEmptyOnError(t, v, e)
				var unknown *tx.UnknownCommitError
				if !errors.As(e, &unknown) || fault.begins != 1 || before != f.snapshot() {
					t.Fatal("unknown outcome/replay/write", e, fault.begins)
				}
			})
		}
	}
}

type pausingRelations struct {
	sr.ProjectionReader
	started, release chan struct{}
	once             sync.Once
}

func (p *pausingRelations) ActiveFriendsTx(c context.Context, t tx.Tx, id identity.PlayerID) ([]identity.PlayerID, error) {
	v, e := p.ProjectionReader.ActiveFriendsTx(c, t, id)
	p.once.Do(func() { close(p.started); <-p.release })
	return v, e
}

type conflictRoots struct {
	playerroot.TxLocker
	f     *fixture
	calls int
}

func (p *conflictRoots) LockPlayerRootsTx(c context.Context, t tx.Tx, s identity.LogicalServerID, ids []identity.PlayerID) ([]playerroot.Root, error) {
	p.calls++
	if p.calls == 1 {
		var n int
		if e := t.QueryRow(c, `SELECT 1`).Scan(&n); e != nil {
			return nil, e
		}
		p.f.sql(`UPDATE players SET state_version=state_version+1 WHERE player_id=100001`)
	}
	return p.TxLocker.LockPlayerRootsTx(c, t, s, ids)
}
func TestC20NativeSerializationRetryAndConcurrent4BMutation(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.friend(100001, 200001)
	conflict := &conflictRoots{TxLocker: f.v.PlayerRoots, f: f}
	f.v.PlayerRoots = conflict
	v := f.base()
	if conflict.calls != 2 || len(v.Friends) != 1 {
		t.Fatal("native 40001 not retried", conflict.calls)
	}
	f.v.PlayerRoots = i4store.PlayerRootLocker{}
	pause := &pausingRelations{ProjectionReader: f.v.Relations, started: make(chan struct{}), release: make(chan struct{})}
	f.v.Relations = pause
	readDone := make(chan sp.Result, 1)
	readErr := make(chan error, 1)
	go func() { v, e := f.v.LoadBase(ctx, actor(100001), f.op()); readDone <- v; readErr <- e }()
	<-pause.started
	mutDone := make(chan error, 1)
	go func() { _, e := f.runAs(100001, sr.DeleteFriend, 200001); mutDone <- e }()
	select {
	case e := <-mutDone:
		t.Fatal("mutation crossed actor root fence", e)
	case <-time.After(50 * time.Millisecond):
	}
	close(pause.release)
	v = <-readDone
	if e := <-readErr; e != nil || len(v.Friends) != 1 {
		t.Fatal("mixed snapshot", e)
	}
	if e := <-mutDone; e != nil {
		t.Fatal(e)
	}
	v = f.base()
	if len(v.Friends) != 0 || len(v.Notices) != 0 {
		t.Fatal("post mutation actor snapshot")
	}
}
func recoveryJSON(f *fixture) string {
	v := f.base()
	v.ObservedAt = time.Unix(1700000000, 0).UTC()
	wire := socialpresentation.MapBase(v)
	raw, e := json.Marshal(struct {
		Wire     socialview.Base
		Durable  string
		Sequence string
	}{wire, f.snapshot(), f.text(`SELECT last_value::text||':'||is_called::text FROM social_notice_id_seq`)})
	if e != nil {
		f.t.Fatal(e)
	}
	return string(raw)
}
func TestC21RecoverySeed(t *testing.T) {
	if os.Getenv("GXB_I7A4C_RECOVERY_MODE") != "seed" {
		t.Skip("explicit recovery seed mode only")
	}
	f := fresh(t)
	f.player(100001)
	f.many(200001, 4)
	f.friend(100001, 200001)
	f.friend(100001, 200002)
	f.sql(`UPDATE social_friendships SET active=false,ended_at=$1,generation=7,state_version=9 WHERE player_high_id=200002`, f.at)
	f.block(100001, 200003)
	f.sql(`UPDATE social_blocks SET active=false,removed_at=$1,generation=8,state_version=11`, f.at)
	f.request(200004, 100001)
	f.sql(`UPDATE social_friend_requests SET status='IGNORED',terminal_at=$1,generation=6,state_version=4`, f.at)
	f.relationNotices(2)
	f.sql(`UPDATE social_notices SET active=false,dismissed_at=$1,state_version=5 WHERE notice_id=1`, f.at)
	f.presence(200001)
	f.sql(`SELECT setval('social_notice_id_seq',77,true)`)
	p := os.Getenv("GXB_I7A4C_RECOVERY_EXPECTED")
	if p == "" {
		t.Fatal("expected path required")
	}
	if e := os.WriteFile(filepath.Clean(p), []byte(recoveryJSON(f)), 0600); e != nil {
		t.Fatal(e)
	}
}
func TestC21RecoveryCompare(t *testing.T) {
	if os.Getenv("GXB_I7A4C_RECOVERY_MODE") != "compare" {
		t.Skip("explicit recovery compare mode only")
	}
	f := existing(t)
	raw, e := os.ReadFile(os.Getenv("GXB_I7A4C_RECOVERY_EXPECTED"))
	if e != nil {
		t.Fatal(e)
	}
	if string(raw) != recoveryJSON(f) {
		t.Fatal("restart/restore DTO/durable/sequence parity failed")
	}
}

func TestC03NilCallerTransactionsRejected(t *testing.T) {
	f := fresh(t)
	id := identity.PlayerID(100001)
	d := i4store.TransactionDiscoveryReader{}
	if _, _, e := d.ProfileTx(ctx, nil, id); e == nil {
		t.Fatal("directory nil Tx")
	}
	if _, e := d.ProfilesAfterTx(ctx, nil, 0, 128); e == nil {
		t.Fatal("page nil Tx")
	}
	if _, _, _, e := d.PlayerIDBoundsTx(ctx, nil); e == nil {
		t.Fatal("bounds nil Tx")
	}
	if _, e := d.ProfilesByExactNameTx(ctx, nil, "x", 101); e == nil {
		t.Fatal("name nil Tx")
	}
	if _, e := (socialrelationstore.Store{}).ActiveFriendsTx(ctx, nil, id); e == nil {
		t.Fatal("friends nil Tx")
	}
	if _, e := (socialinboxstore.Store{}).RelationWindowTx(ctx, nil, id); e == nil {
		t.Fatal("inbox nil Tx")
	}
	if _, e := (socialpresentation.TransactionReader{}).ReadManyTx(ctx, nil, nil); e == nil {
		t.Fatal("presentation nil Tx")
	}
	if _, e := (socialpresentation.TransactionReader{}).ObserveTx(ctx, nil); e == nil {
		t.Fatal("observer nil Tx")
	}
	_ = f
}
func TestC16NativeEmptySingletonAndHolePivot(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	v, e := f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || len(v.Players) != 0 || !v.Scan.Wrapped {
		t.Fatal("self singleton", e)
	}
	f.sql(`DELETE FROM player_directory_profiles`)
	v, e = f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || len(v.Players) != 0 || v.Scan.Pivot != 0 || v.Scan.Fetched != 0 {
		t.Fatal("native empty", e)
	}
	f.player(200001)
	f.player(900001)
	d := &anchoredDirectory{TxDiscoveryReader: f.v.Directory, min: 500001, max: 500001}
	f.v.Directory = d
	v, e = f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || !reflect.DeepEqual(playerIDs(v.Players), []identity.PlayerID{900001, 200001}) || v.Scan.Fetched > 4096 || v.Scan.Evaluated != 2 {
		t.Fatal("hole pivot", e, playerIDs(v.Players), v.Scan)
	}
}
func TestC18EmptyAnchorRemainsEmptyAcrossRetry(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.sql(`DELETE FROM player_directory_profiles`)
	d := &anchoredDirectory{TxDiscoveryReader: f.v.Directory}
	f.v.Directory = d
	retry := &retryBeginner{db: f.p, afterFirst: func() { f.player(200001); d.min = 200001; d.max = 200001 }}
	f.v.Runner.DB = retry
	v, e := f.v.Recommend(ctx, actor(100001), f.op())
	if e != nil || len(v.Players) != 0 || retry.begins != 2 || d.bounds != 1 || v.Scan.Pivot != 0 {
		t.Fatal("empty anchor rebound", e)
	}
}
