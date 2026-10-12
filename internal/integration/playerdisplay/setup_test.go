//go:build postgres

package playerdisplay_test

import (
	"context"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/directorysync"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
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

func uuid() ids.UUID {
	u, e := ids.NewUUID()
	if e != nil {
		panic(e)
	}
	return u
}
func op() operation.Context {
	p, _ := policy.NewSet()
	o, e := (operation.Factory{Clock: clock.System{}}).New(p)
	if e != nil {
		panic(e)
	}
	return o
}
func pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B6A_DSN")
	if dsn == "" {
		t.Fatal("exact nativeDSN required")
	}
	p, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(p.Close)
	return p
}
func exec(t *testing.T, p *pg.Pool, s string, args ...any) {
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
	if _, e = r.EnsureBuiltinInstalled(ctx, op(), b); e != nil {
		t.Fatal(e)
	}
	if _, e = r.BootstrapActivationIfMissing(ctx, op(), b); e != nil {
		t.Fatal(e)
	}
	return b.RevisionID()
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
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'i7b6a-native')`, []any{pid, a.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i7b6a-native',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{s.String(), a.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,1,$4,1,clock_timestamp())`, []any{g.String(), s.String(), a.String(), pid}},
		{`INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'',110001001,0,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, []any{pid}},
		{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,1,37,1,clock_timestamp()-interval '1 day')`, []any{pid}},
		{`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,clock_timestamp()-interval '1 day')`, []any{pid}},
		{`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp()-interval '1 day')`, []any{pid}},
	}
	for _, r := range rows {
		if _, e = tr.Exec(ctx, r.s, r.a...); e != nil {
			t.Fatal(e)
		}
	}
	if _, e = tr.Exec(ctx, `INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,'',1,110001001,0,0,0,1,clock_timestamp()-interval '1 day',clock_timestamp()-interval '1 day')`, pid); e != nil {
		t.Fatal(e)
	}

	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	aid, _ := identity.AccountIDFrom(a)
	sid, _ := identity.SessionIDFrom(s)
	cid, _ := identity.ContextIDFrom(g)
	return identity.ActorContext{AccountID: aid, AccountUID: identity.AccountUID(a.String()), SessionID: sid, ContextID: cid, LogicalServerID: 1, PlayerID: identity.PlayerID(pid), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func service(p *pg.Pool, db tx.Beginner) app.Service {
	store := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	grant := i5.Service{Runner: tx.Runner{DB: db}, Store: store, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: store, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7b6a-test-redeem-key-000000000000")}
	return app.Service{Runner: tx.Runner{DB: db}, Fresh: p, Time: pg.AuthoritativeTime{Queryer: p}, Players: i4store.PlayerRootLocker{}, Fence: store, Store: store, Content: content, Receipts: kernelstore.Store{}, Characters: characterstore.DisplayReader{Store: characterstore.Store{Queryer: p}, Content: content}, Values: i5.DisplayValueOwner{Store: store, Content: content, Grant: grant}, Directory: directorysync.Reconciler{Source: store, Sink: i4store.DirectoryLevelProjection{}}}
}
func state(t *testing.T, p *pg.Pool, a identity.ActorContext) app.State {
	t.Helper()
	x, e := (i5store.Store{}).ReadDisplayStateTx(ctx, p, a.PlayerID, false)
	if e != nil {
		t.Fatal(e)
	}
	return x
}
