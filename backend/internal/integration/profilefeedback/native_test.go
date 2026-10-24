//go:build postgres

package profilefeedback_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	pp "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	dom "gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

var ctx = context.Background()
var at = time.Now().UTC()

// nativeDSN is the one database a test's fixtures and the API process it starts both use.
func nativeDSN(t *testing.T) string {
	t.Helper()
	dsn := os.Getenv("GXB_I7B4B_DSN")
	if dsn == "" {
		dsn = os.Getenv("GXB_I7B4A_DSN")
	}
	if dsn == "" {
		t.Fatal("required exact native DSN missing")
	}
	return dsn
}

func pool(t *testing.T) *pg.Pool {
	t.Helper()
	p, e := pg.Open(ctx, nativeDSN(t), pg.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
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
	if os.Getenv("GXB_I7B4A_RESTORED") != "1" && os.Getenv("GXB_I7B4A_CHILD") == "" {
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

func service(p *pg.Pool, db tx.Beginner) app.Service {
	basic := pp.BasicReader{Roots: pp.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: contentstore.Store{}}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Fresh: p, Roots: app.RootService{Store: profilefeedbackstore.Store{}}, Basic: basic, Content: contentstore.Store{}, Receipts: kernelstore.Store{}, Recipients: i4store.PlayerRootLocker{}, Authors: i5store.Store{}}
}
func praise(t *testing.T, s app.Service, a identity.ActorContext, target identity.PlayerID, o operation.Context) app.CommandResult {
	t.Helper()
	r, e := s.Execute(ctx, a, app.Command{Target: target}, o)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func root(t *testing.T, p *pg.Pool, pid identity.PlayerID) (int64, bool) {
	t.Helper()
	r, ok, e := (profilefeedbackstore.Store{}).ReadRootTx(ctx, p, pid)
	if e != nil {
		t.Fatal(e)
	}
	return r.StateVersion, ok
}
func TestPraiseAbsentNoopCurrentAndProof(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b, c := actor(t, p), actor(t, p), actor(t, p)
	s := service(p, p)
	page, e := s.List(ctx, b, app.PageRequest{Offset: 20}, op())
	if e != nil || page.Rows == nil || len(page.Rows) != 0 || page.Current.Count != 0 || page.Current.RootVersion != 0 {
		t.Fatal("absent", page, e)
	}
	if _, ok := root(t, p, b.PlayerID); ok {
		t.Fatal("read materialized")
	}
	if _, ok, e := (publicprofilestore.Store{}).ReadRootTx(ctx, p, b.PlayerID); e != nil || ok {
		t.Fatal("read touched391", e)
	}
	o := op()
	first := praise(t, s, a, b.PlayerID, o)
	second := praise(t, s, c, b.PlayerID, op())
	repeat := praise(t, s, a, b.PlayerID, op())
	known := praise(t, s, a, b.PlayerID, o)
	if !first.Terminal.Inserted || first.Terminal.RootVersion != 1 || second.Current.Count != 2 || repeat.Terminal.Inserted || repeat.Current.Count != 2 || repeat.Current.RootVersion != 2 || !repeat.Terminal.FirstAt.Equal(first.Terminal.FirstAt) || known.Terminal != first.Terminal || known.Current.Count != 2 {
		t.Fatal("pair/current/private outcome", first, second, repeat, known)
	}
	if _, e = s.Execute(ctx, a, app.Command{Target: c.PlayerID}, o); !errors.Is(e, app.ErrConflict) {
		t.Fatal("forged known target", e)
	}
	changed := o
	changed.EntropySeed[0]++
	if _, e = s.Execute(ctx, a, app.Command{Target: b.PlayerID}, changed); !errors.Is(e, app.ErrConflict) {
		t.Fatal("entropy", e)
	}
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET result_payload=jsonb_set(result_payload,'{root_version}','0') WHERE domain='profile-feedback' AND semantic_key=$1`, o.ID.String())
	if _, e = s.Execute(ctx, a, app.Command{Target: b.PlayerID}, o); !errors.Is(e, app.ErrConflict) {
		t.Fatal("corrupt proof", e)
	}
}
func TestPraisePreparedBindingAndCAS(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := service(p, p)
	one, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer one.Rollback(ctx)
	roots, e := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, one, 1, []identity.PlayerID{b.PlayerID})
	if e != nil {
		t.Fatal(e)
	}
	prep, e := s.Roots.PrepareTx(ctx, one, roots[0])
	if e != nil {
		t.Fatal(e)
	}
	two, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer two.Rollback(ctx)
	if _, _, _, e = s.Roots.AddPraiseTx(ctx, two, prep, a.PlayerID, at); e == nil {
		t.Fatal("foreign Tx accepted")
	}
	_, r, inserted, e := s.Roots.AddPraiseTx(ctx, one, prep, a.PlayerID, at)
	if e != nil || !inserted || r.StateVersion != 1 {
		t.Fatal(e)
	}
	if _, _, _, e = s.Roots.AddPraiseTx(ctx, one, prep, a.PlayerID, at); !errors.Is(e, app.ErrConflict) {
		t.Fatal("stale prepared", e)
	}
	_ = one.Rollback(ctx)
	if _, ok := root(t, p, b.PlayerID); ok {
		t.Fatal("rollback leaked")
	}
}
func TestPraiseConcurrencyAndSharedTime(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b, c := actor(t, p), actor(t, p), actor(t, p)
	s := service(p, p)
	var wg sync.WaitGroup
	errs := make(chan error, 12)
	for i := 0; i < 12; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.Execute(ctx, a, app.Command{Target: b.PlayerID}, op()); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	if v, ok := root(t, p, b.PlayerID); !ok || v != 1 {
		t.Fatal("same pair inflated", v)
	}
	earlier := at.Add(-time.Minute).Truncate(time.Microsecond)
	later := at.Truncate(time.Microsecond)
	late := s
	late.Timed.Binder.Time = fixedTime{later}
	win := praise(t, late, a, c.PlayerID, op())
	early := s
	early.Timed.Binder.Time = fixedTime{earlier}
	loserOp := op()
	loser := praise(t, early, b, c.PlayerID, loserOp)
	r, _, e := (profilefeedbackstore.Store{}).ReadRootTx(ctx, p, c.PlayerID)
	if e != nil || r.StateVersion != 2 || !r.UpdatedAt.Equal(win.Terminal.DecisionAt) || !loser.Terminal.FirstAt.Equal(earlier) {
		t.Fatal("shared time", r, loser, e)
	}
	if got := praise(t, s, b, c.PlayerID, loserOp); got.Terminal != loser.Terminal {
		t.Fatal("earlier known proof rejected")
	}
	pairs := [][2]identity.ActorContext{{a, b}, {b, a}}
	errs = make(chan error, 2)
	for _, v := range pairs {
		wg.Add(1)
		go func(v [2]identity.ActorContext) {
			defer wg.Done()
			_, e := s.Execute(ctx, v[0], app.Command{Target: v[1].PlayerID}, op())
			errs <- e
		}(v)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("opposite locks", e)
		}
	}
	target := actor(t, p)
	actors := []identity.ActorContext{a, b, c}
	errs = make(chan error, 3)
	for _, v := range actors {
		wg.Add(1)
		go func(v identity.ActorContext) {
			defer wg.Done()
			_, e := s.Execute(ctx, v, app.Command{Target: target.PlayerID}, op())
			errs <- e
		}(v)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	if n, _ := root(t, p, target.PlayerID); n != 3 {
		t.Fatal("different actors", n)
	}
}
func socialRoot(t *testing.T, p *pg.Pool, a identity.ActorContext) {
	sqlExec(t, p, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,clock_timestamp(),clock_timestamp()) ON CONFLICT DO NOTHING`, int64(a.PlayerID))
}
func TestPraisePrivacyAndActorFences(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := service(p, p)
	for _, q := range []app.Command{{Target: a.PlayerID}, {Target: 199999}, {Target: 0}} {
		if _, e := s.Execute(ctx, a, q, op()); e == nil {
			t.Fatal("invalid target accepted", q)
		}
	}
	pref := pp.CommandService{Timed: s.Timed, Reads: s.Reads, Fresh: p, Roots: s.Basic.Roots, Players: s.Basic.Players, Fence: s.Basic.Fence, Receipts: s.Receipts, Content: s.Content, Metrics: pp.CanonicalCreationMetricProvider{Players: i5store.Store{}}}
	if _, e := pref.Execute(ctx, b, pp.Command{Kind: pp.HideCommand, Hide: []int16{4}}, op()); e != nil {
		t.Fatal(e)
	}
	o := op()
	praise(t, s, a, b.PlayerID, o) // SPACE hidden; MAIN praise remains available.
	socialRoot(t, p, a)
	socialRoot(t, p, b)
	for _, v := range [][2]identity.PlayerID{{a.PlayerID, b.PlayerID}, {b.PlayerID, a.PlayerID}} {
		sqlExec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp())`, int64(v[0]), int64(v[1]))
		if _, e := s.Execute(ctx, a, app.Command{Target: b.PlayerID}, op()); e == nil {
			t.Fatal("block bypass")
		}
		page, e := s.List(ctx, b, app.PageRequest{Offset: 20}, op())
		if e != nil || page.Current.Count != 1 || len(page.Rows) != 1 {
			t.Fatal("retained own history filtered", e)
		}
		praise(t, s, a, b.PlayerID, o) // Known private outcome is retained, with current authentication.
		sqlExec(t, p, `DELETE FROM social_blocks WHERE blocker_player_id=$1 AND blocked_player_id=$2`, int64(v[0]), int64(v[1]))
	}
	wrong := a
	wrong.LogicalServerID = 2
	if _, e := s.Execute(ctx, wrong, app.Command{Target: b.PlayerID}, op()); e == nil {
		t.Fatal("region")
	}
	wrong = a
	wrong.ContextID = b.ContextID
	if _, e := s.Execute(ctx, wrong, app.Command{Target: b.PlayerID}, op()); e == nil {
		t.Fatal("context")
	}
	sqlExec(t, p, `UPDATE account_sessions SET revoked_at=clock_timestamp(),revocation_reason='test' WHERE session_id=$1`, a.SessionID.UUID().String())
	if _, e := s.Execute(ctx, a, app.Command{Target: b.PlayerID}, o); e == nil {
		t.Fatal("revoked known replay")
	}
}

type faultDB struct {
	tx.Beginner
	commit bool
}
type faultTx struct {
	tx.Tx
	commit bool
}

func (d faultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	return faultTx{t, d.commit}, e
}
func (t faultTx) Commit(c context.Context) error {
	if t.commit {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	} else {
		_ = t.Tx.Rollback(c)
	}
	return errors.New("injected commit ACK loss")
}

type countingTime struct {
	inner gen.TimeAuthority
	calls atomic.Int32
}

func (c *countingTime) Now(ctx context.Context) (time.Time, error) {
	c.calls.Add(1)
	return c.inner.Now(ctx)
}

type abortOnceDB struct {
	tx.Beginner
	first atomic.Bool
}
type abortOnceTx struct {
	tx.Tx
	db *abortOnceDB
}

func (d *abortOnceDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	return abortOnceTx{t, d}, e
}
func (t abortOnceTx) Commit(c context.Context) error {
	if !t.db.first.Swap(true) {
		_, e := t.Tx.Exec(c, `DO $$ BEGIN RAISE EXCEPTION 'native definite abort' USING ERRCODE='40001'; END $$`)
		return e
	}
	return t.Tx.Commit(c)
}

type fixedTime struct{ at time.Time }

func (f fixedTime) Now(context.Context) (time.Time, error) { return f.at, nil }
func TestPraiseAbortAndUnknownReconciliation(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b, c := actor(t, p), actor(t, p), actor(t, p)
	counter := &countingTime{inner: pg.AuthoritativeTime{Queryer: p}}
	s := service(p, &abortOnceDB{Beginner: p})
	s.Timed.Binder.Time = counter
	r := praise(t, s, a, b.PlayerID, op())
	if counter.calls.Load() != 1 || r.Current.RootVersion != 1 {
		t.Fatal("retry resampled", counter.calls.Load())
	}
	o := op()
	r = praise(t, service(p, faultDB{p, true}), c, b.PlayerID, o)
	if r.Current.Count != 2 || r.Terminal.Actor != c.PlayerID {
		t.Fatal("found reconciliation")
	}
	before, _ := root(t, p, b.PlayerID)
	_, e := service(p, faultDB{p, false}).Execute(ctx, b, app.Command{Target: a.PlayerID}, op())
	var unknown *tx.UnknownCommitError
	if !errors.As(e, &unknown) {
		t.Fatal("missing proof not UNKNOWN", e)
	}
	if _, ok := root(t, p, a.PlayerID); ok {
		t.Fatal("blind replay")
	}
	after, _ := root(t, p, b.PlayerID)
	if before != after {
		t.Fatal("rollback changed unrelatedroot")
	}
}
func TestPraiseHistoryPagingAndProviderFailure(t *testing.T) {
	p := pool(t)
	installed(t, p)
	target := actor(t, p)
	s := service(p, p)
	s.Timed.Binder.Time = fixedTime{at.Truncate(time.Microsecond)}
	actors := make([]identity.ActorContext, 23)
	for i := range actors {
		actors[i] = actor(t, p)
		praise(t, s, actors[i], target.PlayerID, op())
	}
	hint := int64(999)
	page, e := s.List(ctx, target, app.PageRequest{Offset: 20, TotalHint: &hint}, op())
	if e != nil || len(page.Rows) != 20 || page.Current.Count != 23 {
		t.Fatal(page, e)
	}
	for i, row := range page.Rows {
		want := actors[22-i]
		if row.Author.PlayerID != int64(want.PlayerID) || row.Author.Region != 1 || row.Author.Level != 1 || row.Author.Name != "basis" || row.PraiseTime != at.Unix() {
			t.Fatal("author/tie order", row)
		}
	}
	last, e := s.List(ctx, target, app.PageRequest{Start: 20, Offset: 20}, op())
	if e != nil || len(last.Rows) != 3 || last.Current.Count != 23 {
		t.Fatal(last, e)
	}
	end, e := s.List(ctx, target, app.PageRequest{Start: 23, Offset: 20}, op())
	if e != nil || end.Rows == nil || len(end.Rows) != 0 {
		t.Fatal(end, e)
	}
	for _, q := range []app.PageRequest{{Start: -1, Offset: 20}, {Offset: 0}, {Offset: 21}} {
		if _, e = s.List(ctx, target, q, op()); e == nil {
			t.Fatal("bad page accepted")
		}
	}
	before, _ := root(t, p, target.PlayerID)
	sqlExec(t, p, `UPDATE player_profiles SET display_name='current author',state_version=state_version+1 WHERE player_id=$1`, int64(actors[22].PlayerID))
	page, e = s.List(ctx, target, app.PageRequest{Offset: 1}, op())
	if e != nil || page.Rows[0].Author.Name != "current author" {
		t.Fatal("stale identity", e)
	}
	sqlExec(t, p, `DELETE FROM player_profiles WHERE player_id=$1`, int64(actors[22].PlayerID))
	if _, e = s.List(ctx, target, app.PageRequest{Offset: 1}, op()); !errors.Is(e, app.ErrProvider) {
		t.Fatal("fabricated missing author", e)
	}
	n, e := (profilefeedbackstore.Store{}).CountTx(ctx, p, target.PlayerID)
	after, _ := root(t, p, target.PlayerID)
	if e != nil || n != 23 || before != after {
		t.Fatal("read deleted/changed facts")
	}
	sqlExec(t, p, `DELETE FROM gameplay_contexts WHERE player_id=$1`, int64(actors[22].PlayerID))
	sqlExec(t, p, `DELETE FROM players WHERE player_id=$1`, int64(actors[22].PlayerID))
	if _, e = s.List(ctx, target, app.PageRequest{Offset: 1}, op()); !errors.Is(e, app.ErrProvider) {
		t.Fatal("absent canonical author fabricated", e)
	}
	n, e = (profilefeedbackstore.Store{}).CountTx(ctx, p, target.PlayerID)
	if e != nil || n != 23 {
		t.Fatal("retired author erased praise", e)
	}

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

func TestPraiseHTTPRawAndCallbacks(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	auth, bearer := token(t, p, a)
	router := httpedge.NewRouter()
	d := stockruntime.ProfileFeedbackDispatcher{Authority: auth, Service: service(p, p)}
	for _, mid := range []uint16{1830, 1842} {
		if e := router.Register(mid, d); e != nil {
			t.Fatal(e)
		}
	}
	ad, _ := httpedge.NewAdmission(4)
	ps, _ := policy.NewSet(policy.Ref{Name: "profile", Version: dom.PolicyVersion})
	h := httpedge.Handler{Limits: limits.Default(), Admission: ad, Operations: operation.Factory{Clock: clock.System{}}, Policies: ps, Router: router}
	server := httptest.NewServer(h)
	defer server.Close()
	send := func(raw string) (int, map[string]any) {
		t.Helper()
		resp, e := http.Post(server.URL, "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {raw}}.Encode()))
		if e != nil {
			t.Fatal(e)
		}
		defer resp.Body.Close()
		var body map[string]any
		if e = json.NewDecoder(resp.Body).Decode(&body); e != nil {
			t.Fatal(e)
		}
		return resp.StatusCode, body
	}
	raw := fmt.Sprintf(`{"mid":1830,"token":%q,"region":1,"to_player_id":%d}`, bearer, b.PlayerID)
	status, body := send(raw)
	if status != 200 || body["praise_num"] != float64(1) || body["is_has_praise"] != float64(1) {
		t.Fatal(status, body)
	}
	status, body = send(fmt.Sprintf(`{"mid":1842,"token":%q,"region":1,"start":0,"offset":20,"total_num":999}`, bearer))
	if status != 200 || body["total_num"] != float64(0) || len(body["praise_list"].([]any)) != 0 {
		t.Fatal(status, body)
	}
	for _, bad := range []string{`"to_player_id":null`, `"to_player_id":100001.0`, `"to_player_id":1e5`, `"to_player_id":100001,"actor_player_id":100002`, `"to_player_id":100001,"to_player_id":100002`} {
		status, body = send(fmt.Sprintf(`{"mid":1830,"token":%q,"region":1,%s}`, bearer, bad))
		if status == 200 || body["praise_num"] != nil {
			t.Fatal("bad callback", status, body)
		}
	}
	for _, bad := range []string{`"start":0,"offset":20,"to_player_id":100002`, `"start":0.0,"offset":20`, `"start":0,"offset":2e1`, `"start":0,"offset":null`, `"start":0,"start":1,"offset":20`} {
		status, body = send(fmt.Sprintf(`{"mid":1842,"token":%q,"region":1,%s}`, bearer, bad))
		if status == 200 || body["praise_list"] != nil {
			t.Fatal("bad page callback", status, body)
		}
	}
	status, _ = send(fmt.Sprintf(`{"mid":1830,"token":%q,"region":2,"to_player_id":%d}`, bearer, b.PlayerID))
	if status != 403 {
		t.Fatal("region mismatch", status)
	}
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

func TestPraiseProcessHelper(t *testing.T) {
	mode := os.Getenv("GXB_I7B4A_CHILD")
	if mode == "" {
		t.Skip("subprocess only")
	}
	p := pool(t)
	var a actorTransport
	if e := json.Unmarshal([]byte(os.Getenv("GXB_I7B4A_ACTOR")), &a); e != nil {
		t.Fatal(e)
	}
	actor := decodeActor(t, a)
	n, e := strconv.ParseInt(os.Getenv("GXB_I7B4A_TARGET"), 10, 64)
	if e != nil {
		t.Fatal(e)
	}
	if mode == "praise" {
		praise(t, service(p, p), actor, identity.PlayerID(n), op())
	} else {
		r, ok, e := (profilefeedbackstore.Store{}).ReadRootTx(ctx, p, identity.PlayerID(n))
		if e != nil || !ok || r.StateVersion != 1 {
			t.Fatal("process root reload", e)
		}
	}
}
func TestPraiseIndependentProcesses(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	raw, _ := json.Marshal(encodeActor(a))
	makeCmd := func(mode string) *exec.Cmd {
		c := exec.Command(os.Args[0], "-test.run=^TestPraiseProcessHelper$", "-test.v")
		c.Env = append(os.Environ(), "GXB_I7B4A_CHILD="+mode, "GXB_I7B4A_ACTOR="+string(raw), "GXB_I7B4A_TARGET="+strconv.FormatInt(int64(b.PlayerID), 10))
		return c
	}
	one, two := makeCmd("praise"), makeCmd("praise")
	var x, y bytes.Buffer
	one.Stdout = &x
	one.Stderr = &x
	two.Stdout = &y
	two.Stderr = &y
	if e := one.Start(); e != nil {
		t.Fatal(e)
	}
	if e := two.Start(); e != nil {
		t.Fatal(e)
	}
	if e := one.Wait(); e != nil {
		t.Fatal(e, x.String())
	}
	if e := two.Wait(); e != nil {
		t.Fatal(e, y.String())
	}
	if out, e := makeCmd("reload").CombinedOutput(); e != nil {
		t.Fatal(e, string(out))
	}
}
func TestPraiseRestoredReload(t *testing.T) {
	if os.Getenv("GXB_I7B4A_RESTORED") != "1" {
		t.Skip("restore/restart gate")
	}
	p := pool(t)
	installed(t, p)
	var actorID, targetID int64
	var opID string
	if e := p.QueryRow(ctx, `SELECT (result_payload->>'actor')::bigint,(result_payload->>'target')::bigint,semantic_key FROM gxb_operation_receipts WHERE domain='profile-feedback' AND (result_payload->>'root_version')::bigint>0 ORDER BY recorded_at LIMIT 1`).Scan(&actorID, &targetID, &opID); e != nil {
		t.Fatal(e)
	}
	fact, ok, e := (profilefeedbackstore.Store{}).FindPraiseTx(ctx, p, identity.PlayerID(targetID), identity.PlayerID(actorID))
	r, present, e2 := (profilefeedbackstore.Store{}).ReadRootTx(ctx, p, identity.PlayerID(targetID))
	if e != nil || e2 != nil || !ok || !present || fact.Validate() != nil || r.StateVersion < fact.RootVersion {
		t.Fatal("restored typed facts", e, e2)
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(actorID, 10), Domain: "profile-feedback", Operation: "praise", SemanticKey: opID}
	rr, yes, e := (kernelstore.Store{}).FindTx(ctx, p, id)
	if e != nil || !yes || rr.Validate() != nil {
		t.Fatal("receipt reload", e)
	}
	rev, yes := rr.OperationPolicyRefs.Get("content")
	if !yes {
		t.Fatal("retained policy")
	}
	if _, e = (contentstore.Store{}).ReadPublicProfilePolicy(ctx, p, rev); e != nil {
		t.Fatal(e)
	}
}

var _ playerroot.TxLocker = i4store.PlayerRootLocker{}

func TestPraiseRetainedPolicyAndKnownACKLoss(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := service(p, p)
	o := op()
	first := praise(t, s, a, b.PlayerID, o)
	sqlExec(t, p, `DELETE FROM gxb_content_activation WHERE slot='content'`)
	again := praise(t, s, a, b.PlayerID, o)
	if again.Terminal != first.Terminal {
		t.Fatal("retained result")
	}
	if _, e := s.Execute(ctx, a, app.Command{Target: b.PlayerID}, op()); e == nil {
		t.Fatal("new operation missing active policy")
	}
	defer sqlExec(t, p, `INSERT INTO gxb_content_activation(slot,revision_id,activation_version,activated_at,activated_by)VALUES('content',$1,999,clock_timestamp(),'4a-test')`, rev)
	knownACK := praise(t, service(p, faultDB{p, true}), a, b.PlayerID, o)
	if knownACK.Terminal != first.Terminal {
		t.Fatal("known receipt ACK loss")
	}
	var old string
	if e := p.QueryRow(ctx, `SELECT payload::text FROM content_public_profile_policies WHERE revision_id=$1`, rev).Scan(&old); e != nil {
		t.Fatal(e)
	}
	sqlExec(t, p, `UPDATE content_public_profile_policies SET payload=jsonb_set(payload,'{intro_codepoints}','41') WHERE revision_id=$1`, rev)
	_, e := s.Execute(ctx, a, app.Command{Target: b.PlayerID}, o)
	sqlExec(t, p, `UPDATE content_public_profile_policies SET payload=$2::jsonb WHERE revision_id=$1`, rev, old)
	if e == nil {
		t.Fatal("corrupt retained policy accepted")
	}
}

type afterCommitDB struct {
	tx.Beginner
	after func()
}
type afterCommitTx struct {
	tx.Tx
	after func()
}

func (d afterCommitDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	return &afterCommitTx{t, d.after}, e
}
func (t afterCommitTx) Commit(c context.Context) error {
	if e := t.Tx.Commit(c); e != nil {
		return e
	}
	t.after()
	return errors.New("ACK lost after concurrent committed change")
}
func TestPraiseReconciliationCurrentAndSnapshot(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b, c := actor(t, p), actor(t, p), actor(t, p)
	s := service(p, p)
	injected := afterCommitDB{p, func() { praise(t, s, c, b.PlayerID, op()) }}
	r := praise(t, service(p, injected), a, b.PlayerID, op())
	if r.Terminal.RootVersion != 1 || r.Current.RootVersion != 2 || r.Current.Count != 2 {
		t.Fatal("reconciliation stale privatecount", r)
	}
	o := op()
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	sc := tx.Scope{Tx: tr, Operation: o, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}
	before, e := s.Roots.ObserveTx(ctx, sc, b.PlayerID, a.PlayerID, rev, at)
	if e != nil {
		t.Fatal(e)
	}
	newActor := actor(t, p)
	praise(t, s, newActor, b.PlayerID, op())
	same, e := s.Roots.ObserveTx(ctx, sc, b.PlayerID, a.PlayerID, rev, at)
	if e != nil || before != same {
		t.Fatal("mixedsnapshot", e, before, same)
	}
	_ = tr.Rollback(ctx)
	now := praise(t, s, a, b.PlayerID, op())
	if now.Current.Count != 3 {
		t.Fatal("stale fresh current")
	}
}
func TestPraiseBlockRaceAndCanonicalCrossServer(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := service(p, p)
	socialRoot(t, p, a)
	socialRoot(t, p, b)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, tr, 1, []identity.PlayerID{a.PlayerID, b.PlayerID}); e != nil {
		t.Fatal(e)
	}
	if _, e = tr.Exec(ctx, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp())`, int64(b.PlayerID), int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	done := make(chan error, 1)
	go func() { _, e := s.Execute(ctx, a, app.Command{Target: b.PlayerID}, op()); done <- e }()
	// Writer already holds the shared315 fence; praise must observe the committed block or retry its old snapshot.
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if e = <-done; e == nil {
		t.Fatal("blockrace admitted")
	}
	if _, ok := root(t, p, b.PlayerID); ok {
		t.Fatal("blocked fact created")
	}
	aid := uuid()
	var foreign int64
	if e = p.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=2 RETURNING next_player_id-1`).Scan(&foreign); e != nil {
		t.Fatal(e)
	}
	sqlExec(t, p, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, aid.String(), aid.String())
	sqlExec(t, p, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,2,clock_timestamp(),'4a')`, foreign, aid.String())
	sqlExec(t, p, `INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'cross-server',1,0,0,1,clock_timestamp(),clock_timestamp())`, foreign)
	sqlExec(t, p, `INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,1,0,1,clock_timestamp())`, foreign)
	got := praise(t, s, a, identity.PlayerID(foreign), op())
	if got.Current.Target != identity.PlayerID(foreign) {
		t.Fatal("foreign canonical target")
	}
}
func TestPraiseActualAPIProcess(t *testing.T) {
	binary := os.Getenv("GXB_I7B4A_API_BINARY")
	if binary == "" {
		t.Skip("final exact API binary required")
	}
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	_, bearer := token(t, p, a)
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := listener.Addr().String()
	listener.Close()
	cmd := exec.Command(binary)
	cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+nativeDSN(t), "GXB_HTTP_ADDR="+addr, "GXB_PUBLIC_ENGINE_URL=http://"+addr+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19001", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b4a-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native")
	var output bytes.Buffer
	cmd.Stdout = &output
	cmd.Stderr = &output
	if e = cmd.Start(); e != nil {
		t.Fatal(e)
	}
	defer func() { _ = cmd.Process.Signal(os.Interrupt); _ = cmd.Wait() }()
	send := func(raw string) (int, map[string]any, error) {
		resp, e := http.Post("http://"+addr+"/engine", "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {raw}}.Encode()))
		if e != nil {
			return 0, nil, e
		}
		defer resp.Body.Close()
		var body map[string]any
		e = json.NewDecoder(resp.Body).Decode(&body)
		return resp.StatusCode, body, e
	}
	raw := fmt.Sprintf(`{"mid":1830,"token":%q,"region":1,"to_player_id":%d}`, bearer, b.PlayerID)
	var status int
	var body map[string]any
	deadline := time.Now().Add(12 * time.Second)
	for time.Now().Before(deadline) {
		status, body, e = send(raw)
		if e == nil {
			break
		}
		time.Sleep(25 * time.Millisecond)
	}
	if e != nil || status != 200 || body["praise_num"] != float64(1) {
		t.Fatalf("actual API %d %v %v", status, body, e)
	}
	_, receiverBearer := token(t, p, b)
	status, body, e = send(fmt.Sprintf(`{"mid":1842,"token":%q,"region":1,"start":0,"offset":20}`, receiverBearer))
	if e != nil || status != 200 || body["total_num"] != float64(1) || len(body["praise_list"].([]any)) != 1 {
		t.Fatal(status, body, e)
	}
	for _, raw := range []string{fmt.Sprintf(`{"mid":1830,"token":%q,"region":1,"to_player_id":%d,"to_player_id":%d}`, bearer, b.PlayerID, b.PlayerID), fmt.Sprintf(`{"mid":1842,"token":%q,"region":1,"start":0,"offset":2e1}`, bearer)} {
		status, body, e = send(raw)
		if e != nil || status == 200 || body["praise_num"] != nil || body["praise_list"] != nil {
			t.Fatal("actual API malformed", status, body, e)
		}
	}
}
