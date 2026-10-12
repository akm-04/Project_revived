//go:build postgres

package profilemedia_test

import (
	"context"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	dom "gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

var ctx = context.Background()
var at = time.Now().UTC()

func pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B5B_DSN")
	if dsn == "" {
		t.Fatal("required exact native DSN missing")
	}
	p, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(p.Close)
	return p
}
func uuid() ids.UUID {
	u, e := ids.NewUUID()
	if e != nil {
		panic(e)
	}
	return u
}
func op() operation.Context {
	ps, _ := policy.NewSet(policy.Ref{Name: "profile", Version: dom.PolicyVersion})
	o, e := (operation.Factory{Clock: clock.System{}}).New(ps)
	if e != nil {
		panic(e)
	}
	return o
}
func prof() tx.Profile {
	return tx.Profile{Name: "I7B2B_NATIVE", AcquireTimeout: 5 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 15 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 40 * time.Second}
}
func actor(t *testing.T, p *pg.Pool) identity.ActorContext {
	t.Helper()
	a, s, g := uuid(), uuid(), uuid()
	var pid int64
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	e = tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&pid)
	if e != nil {
		t.Fatal(e)
	}
	rows := []struct {
		s string
		a []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{a.String(), a.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'i7b2b-native')`, []any{pid, a.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i7b2b-native',$3,$3)`, []any{s.String(), a.String(), at.Add(-time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,1,$4,1,clock_timestamp())`, []any{g.String(), s.String(), a.String(), pid}},
		{`INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'basis',1,0,0,1,$2::timestamptz-interval '1 day',$2)`, []any{pid, at}},
		{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,1,0,1,$2)`, []any{pid, at}},
	}
	for _, r := range rows {
		if _, e = tr.Exec(ctx, r.s, r.a...); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	aid, _ := identity.AccountIDFrom(a)
	sid, _ := identity.SessionIDFrom(s)
	cid, _ := identity.ContextIDFrom(g)
	return identity.ActorContext{AccountID: aid, AccountUID: identity.AccountUID(a.String()), SessionID: sid, ContextID: cid, LogicalServerID: 1, PlayerID: identity.PlayerID(pid), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func sqlExec(t *testing.T, p *pg.Pool, s string, args ...any) {
	t.Helper()
	if _, e := p.Raw().Exec(ctx, s, args...); e != nil {
		t.Fatal(e)
	}
}
func installed(t *testing.T, p *pg.Pool) string {
	t.Helper()
	b, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	r := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if os.Getenv("GXB_I7B5B_RESTORED") != "1" && os.Getenv("GXB_I7B5B_CHILD") == "" {
		if _, e = r.EnsureBuiltinInstalled(ctx, op(), b); e != nil {
			t.Fatal(e)
		}
		if _, e = r.BootstrapActivationIfMissing(ctx, op(), b); e != nil {
			t.Fatal(e)
		}
	}
	rev, e := (contentstore.Store{}).ActiveRevision(ctx, p)
	if e != nil || rev != b.RevisionID() {
		t.Fatalf("retainedactive policy missing %s %v", rev, e)
	}
	if _, e = (contentstore.Store{}).ReadPublicProfilePolicy(ctx, p, rev); e != nil {
		t.Fatal(e)
	}
	return rev
}
func service(p *pg.Pool, db tx.Beginner) app.CommandService {
	return app.CommandService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Fresh: p, Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}, Metrics: app.CanonicalCreationMetricProvider{Players: i5store.Store{}}}
}
func assign(t *testing.T, p *pg.Pool, a identity.ActorContext, q app.Command, o operation.Context) app.CommandResult {
	t.Helper()
	r, e := service(p, p).Execute(ctx, a, q, o)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func root(t *testing.T, p *pg.Pool, pid identity.PlayerID) (app.Root, bool) {
	t.Helper()
	r, ok, e := (publicprofilestore.Store{}).ReadRootTx(ctx, p, pid)
	if e != nil {
		t.Fatal(e)
	}
	return r, ok
}

func token(t *testing.T, p *pg.Pool, a identity.ActorContext) (i4store.RealtimeAuthority, string) {
	t.Helper()
	digestSecret := []byte("i7b2b-fixture-digest-key-00001")
	bearerSecret := []byte("i7b2b-fixture-bearer-key-00001")
	raw, e := identity.DeriveGameplayBearer(bearerSecret, identity.GameplayContext{ID: a.ContextID, ContextGeneration: a.ContextGeneration})
	if e != nil {
		t.Fatal(e)
	}
	digest, e := identity.DigestGameplayBearer(digestSecret, raw)
	if e != nil {
		t.Fatal(e)
	}
	sqlExec(t, p, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)VALUES($1,$2,$3,$4,1,'i7b2b-native',clock_timestamp())`, uuid().String(), a.ContextID.UUID().String(), a.SessionID.UUID().String(), digest[:])
	return i4store.RealtimeAuthority{Queryer: p, DigestSecret: digestSecret, BearerSecret: bearerSecret, DerivationKeyID: "i7b2b-native"}, raw
}

type actorTransport struct {
	Account, Session, Context, UID string
	PlayerID                       int64
	Server                         int32
}

func encodeActor(a identity.ActorContext) actorTransport {
	return actorTransport{a.AccountID.UUID().String(), a.SessionID.UUID().String(), a.ContextID.UUID().String(), string(a.AccountUID), int64(a.PlayerID), int32(a.LogicalServerID)}
}
func decodeActor(t *testing.T, v actorTransport) identity.ActorContext {
	t.Helper()
	u, e := ids.ParseUUID(v.Account)
	if e != nil {
		t.Fatal(e)
	}
	a, _ := identity.AccountIDFrom(u)
	u, e = ids.ParseUUID(v.Session)
	if e != nil {
		t.Fatal(e)
	}
	s, _ := identity.SessionIDFrom(u)
	u, e = ids.ParseUUID(v.Context)
	if e != nil {
		t.Fatal(e)
	}
	c, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{AccountID: a, AccountUID: identity.AccountUID(v.UID), SessionID: s, ContextID: c, LogicalServerID: identity.LogicalServerID(v.Server), PlayerID: identity.PlayerID(v.PlayerID), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
