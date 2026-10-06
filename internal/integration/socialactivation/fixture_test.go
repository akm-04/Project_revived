//go:build postgres && socialintegration

// Package socialrelation_test exercises real owner adapters and native PostgreSQL.
// Enable with -tags "postgres socialintegration" and a disposable migrated database.
// It deliberately fails if no DSN is supplied once this explicit native suite is selected.
package socialactivation_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"reflect"
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
	dsn := os.Getenv("GXB_I7A4D_TEST_DSN")
	if dsn == "" {
		t.Fatal("GXB_I7A4D_TEST_DSN must name a disposable migrated PostgreSQL database")
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
func fresh(t *testing.T) *fixture {
	f := existing(t)
	f.sql(`TRUNCATE accounts CASCADE`)
	f.sql(`SELECT setval('social_notice_id_seq',1,false)`)
	return f
}

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
