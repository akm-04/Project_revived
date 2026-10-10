//go:build postgres

package publicprofilecommands_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/content/builtin"
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
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

var ctx = context.Background()
var at = time.Now().UTC()

func pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B2B_DSN")
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
	if os.Getenv("GXB_I7B2B_RESTORED") != "1" && os.Getenv("GXB_I7B2B_CHILD") == "" {
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
func TestCommandsValidationMetricsAndKnownReplay(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	empty := assign(t, p, a, app.Command{Kind: app.HideCommand, Hide: []int16{}}, op())
	if empty.RootVersion != 0 {
		t.Fatal("absent noopmaterialized")
	}
	if _, ok := root(t, p, a.PlayerID); ok {
		t.Fatal("read/nooprootcreated")
	}
	corpus, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	q := app.Command{Kind: app.IntroCommand, Intro: corpus.PublicProfile.Words[0]}
	o := op()
	first := assign(t, p, a, q, o)
	want, e := dom.ModerateIntro(q.Intro, corpus.PublicProfile.Words)
	if e != nil || first.Intro != want || strings.Contains(first.Intro, q.Intro) {
		t.Fatalf("moderation %q %v", first.Intro, e)
	}
	later := assign(t, p, a, app.Command{Kind: app.IntroCommand, Intro: "later 😀"}, op())
	again := assign(t, p, a, q, o)
	if again.Intro != first.Intro || again.RootVersion != first.RootVersion {
		t.Fatal("stored outcome drift")
	}
	r, _ := root(t, p, a.PlayerID)
	if r.Preferences.Intro != later.Intro {
		t.Fatal("replay overwrote newer state")
	}
	if _, e = service(p, p).Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: "different"}, o); !errors.Is(e, app.ErrConflict) {
		t.Fatalf("fingerprint conflict %v", e)
	}
	for _, bad := range []string{strings.Repeat("😀", 41), "nul\x00", string([]byte{255})} {
		before, _ := root(t, p, a.PlayerID)
		if _, e = service(p, p).Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: bad}, op()); e == nil {
			t.Fatal("invalidintro accepted")
		}
		after, _ := root(t, p, a.PlayerID)
		if after.StateVersion != before.StateVersion {
			t.Fatal("invalidintro wrote")
		}
	}
	assign(t, p, a, app.Command{Kind: app.IntroCommand, Intro: strings.Repeat("😀", 40)}, op())
	for _, ids := range [][]int16{{2}, {2, 4}, {4}, {}} {
		got := assign(t, p, a, app.Command{Kind: app.HideCommand, Hide: ids}, op())
		if len(got.Hide) != len(ids) {
			t.Fatal("hide shape")
		}
	}
	selected := assign(t, p, a, app.Command{Kind: app.ShowCommand, Show: []int64{1011}}, op())
	basis, e := (i5store.Store{}).ReadPublicPlayerBasisTx(ctx, p, a.PlayerID)
	if e != nil || selected.Show["1011"] != basis.Profile.CreatedAt.Unix() || len(selected.MetricObservations) != 1 {
		t.Fatalf("canonical metric %v", e)
	}
	before, _ := root(t, p, a.PlayerID)
	o = op()
	if _, e = service(p, p).Execute(ctx, a, app.Command{Kind: app.ShowCommand, Show: []int64{1001}}, o); !errors.Is(e, app.ErrContent) {
		t.Fatalf("unavailablemetric %v", e)
	}
	after, _ := root(t, p, a.PlayerID)
	if after.StateVersion != before.StateVersion {
		t.Fatal("unavailable wrote")
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "public-profile", Operation: app.ShowCommand, SemanticKey: o.ID.String()}
	if _, yes, e := (kernelstore.Store{}).FindTx(ctx, p, id); e != nil || yes {
		t.Fatal("unavailable receipt", e)
	}
	assign(t, p, a, app.Command{Kind: app.ShowCommand, Show: []int64{}}, op()) // Qualified Unix-zero/negative values come from the canonical owner;
	// they are not fabricated unavailable-provider defaults.
	for _, when := range []string{"1970-01-01T00:00:00Z", "1969-12-31T23:59:59Z"} {
		fresh := actor(t, p)
		sqlExec(t, p, `UPDATE player_profiles SET created_at=$2::timestamptz WHERE player_id=$1`, int64(fresh.PlayerID), when)
		got := assign(t, p, fresh, app.Command{Kind: app.ShowCommand, Show: []int64{1011}}, op())
		parsed, _ := time.Parse(time.RFC3339, when)
		if got.Show["1011"] != parsed.Unix() || len(got.MetricObservations) != 1 || got.MetricObservations[0].SourceVersion < 1 {
			t.Fatal("qualifiedtimestamp zero confusedwithunavailable")
		}
	}

}
func basic(t *testing.T, p *pg.Pool, a identity.ActorContext, target identity.PlayerID, rev string) app.BasicResult {
	t.Helper()
	instant, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	var out app.BasicResult
	s := app.BasicReader{Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: contentstore.Store{}}
	res, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, e = s.ReadBasicTx(c, sc, a, target, rev, instant)
		return e
	})
	if e != nil || res.Outcome != tx.DefiniteCommit {
		t.Fatalf("basic coherent %v", e)
	}
	return out
}
func socialRoot(t *testing.T, p *pg.Pool, a identity.ActorContext) {
	sqlExec(t, p, `INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,clock_timestamp(),clock_timestamp()) ON CONFLICT DO NOTHING`, int64(a.PlayerID))
}
func TestPrivacyBothDirectionsSelfAndCrossServer(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	socialRoot(t, p, a)
	socialRoot(t, p, b)
	assign(t, p, b, app.Command{Kind: app.HideCommand, Hide: []int16{2, 4}}, op())
	assign(t, p, b, app.Command{Kind: app.IntroCommand, Intro: "visible"}, op())
	self := basic(t, p, b, b.PlayerID, rev)
	if !self.Eligible[2] || !self.Eligible[4] || !self.Eligible[6] || self.SelfPreferences == nil {
		t.Fatal("selfhidden denied")
	}
	other := basic(t, p, a, b.PlayerID, rev)
	if other.Eligible[2] || other.Eligible[4] || other.Eligible[6] || other.SelfPreferences != nil || other.Intro != "visible" {
		t.Fatal("hidden/system exposed")
	}
	for _, pair := range [][2]identity.PlayerID{{a.PlayerID, b.PlayerID}, {b.PlayerID, a.PlayerID}} {
		sqlExec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp()) ON CONFLICT(blocker_player_id,blocked_player_id)DO UPDATE SET active=true,removed_at=NULL,state_version=social_blocks.state_version+1,updated_at=clock_timestamp()`, int64(pair[0]), int64(pair[1]))
		r := basic(t, p, a, b.PlayerID, rev)
		if !r.Relation.Blocked || r.Intro != "" || r.Identity.Name == "" || r.Eligible[1] || r.Eligible[3] || r.Eligible[4] {
			t.Fatal("blocked basic/protected policy")
		}
		sqlExec(t, p, `UPDATE social_blocks SET active=false,removed_at=clock_timestamp(),updated_at=clock_timestamp() WHERE blocker_player_id=$1 AND blocked_player_id=$2`, int64(pair[0]), int64(pair[1]))
	}
	// Existing full-ID convention and typed root admission distinguish actorserver
	// from targetserver. Fixture target moves only before any owner references exist.
	var foreignPID int64
	if e := p.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=2 RETURNING next_player_id-1`).Scan(&foreignPID); e != nil {
		t.Fatal(e)
	}
	sqlExec(t, p, `INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at)VALUES(2,'native cross',true,true,true,299998,299999,clock_timestamp()) ON CONFLICT DO NOTHING`)
	// New canonical foreign player receives owner rows; no mutation of existing IDs.
	aid := uuid()
	sqlExec(t, p, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, aid.String(), aid.String())
	sqlExec(t, p, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,2,clock_timestamp(),'i7b2b-native')`, foreignPID, aid.String())
	sqlExec(t, p, `INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'foreign',1,0,0,1,clock_timestamp(),clock_timestamp())`, foreignPID)
	sqlExec(t, p, `INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,1,0,1,clock_timestamp())`, foreignPID)
	r := basic(t, p, a, identity.PlayerID(foreignPID), rev)
	if r.Identity.Server != 2 || r.Identity.PlayerID != identity.PlayerID(foreignPID) || r.SelfPreferences != nil {
		t.Fatal("crossserver target denied orauth changed")
	}
	if _, ok := root(t, p, identity.PlayerID(foreignPID)); ok {
		t.Fatal("read created foreignroot")
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
func TestCommandACKLossUNKNOWNAndAuthFences(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	q := app.Command{Kind: app.IntroCommand, Intro: "ack loss"}
	o := op()
	r, e := service(p, faultDB{p, true}).Execute(ctx, a, q, o)
	if e != nil || r.Intro != q.Intro {
		t.Fatalf("known ACKloss %v", e)
	}
	stored, _ := root(t, p, a.PlayerID)
	if stored.Preferences.Intro != q.Intro {
		t.Fatal("uncommitted leaked")
	}
	before := stored
	o = op()
	r, e = service(p, faultDB{p, false}).Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: "must not leak"}, o)
	if e == nil || r.Schema != "" {
		t.Fatal("UNKNOWN successleak", e)
	}
	after, _ := root(t, p, a.PlayerID)
	if after.StateVersion != before.StateVersion {
		t.Fatal("abort changed")
	}
	q = app.Command{Kind: app.IntroCommand, Intro: "rejected"}
	wrong := a
	wrong.LogicalServerID = 2
	if _, e = service(p, p).Execute(ctx, wrong, q, op()); e == nil {
		t.Fatal("wrongserver accepted")
	}
	sqlExec(t, p, `UPDATE account_sessions SET revoked_at=clock_timestamp(),revocation_reason='i7b2b-native' WHERE session_id=$1`, a.SessionID.UUID().String())
	if _, e = service(p, p).Execute(ctx, a, q, op()); e == nil {
		t.Fatal("revoked writer admitted")
	}
	if _, e = service(p, p).Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: "ack loss"}, op()); e == nil {
		t.Fatal("revoked read bypass")
	}
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
func TestRetryTimeAndConcurrentAssignments(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	db := &abortOnceDB{Beginner: p}
	s := service(p, db)
	clock := &countingTime{inner: pg.AuthoritativeTime{Queryer: p}}
	s.Timed.Binder.Time = clock
	r, e := s.Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: "retry stable"}, op())
	if e != nil || clock.calls.Load() != 1 || r.RootVersion != 1 {
		t.Fatalf("stable retry %d %v", clock.calls.Load(), e)
	}
	row, _ := root(t, p, a.PlayerID)
	if !row.CreatedAt.Equal(r.DecisionAt) {
		t.Fatal("decision resampled")
	}
	// A deliberate older decision must fail without writing or resampling.
	stale := service(p, p)
	stale.Timed.Binder.Time = fixedTime{r.DecisionAt.Add(-time.Microsecond)}
	if got, e := stale.Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: "stale rejected"}, op()); !errors.Is(e, app.ErrInvalidState) || got.Schema != "" {
		t.Fatal("stale decision didnot failclosed", e)
	}
	latest, _ := root(t, p, a.PlayerID)
	if latest.StateVersion != 1 {
		t.Fatal("stale decision mutated")
	}
	common, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	type observed struct {
		result    app.CommandResult
		err       error
		operation operation.Context
	}
	var wg sync.WaitGroup
	results := make(chan observed, 4)
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			s := service(p, p)
			s.Timed.Binder.Time = fixedTime{common}
			o := op()
			r, e := s.Execute(ctx, a, app.Command{Kind: app.HideCommand, Hide: []int16{int16(2 + 2*(i%2))}}, o)
			results <- observed{r, e, o}
		}(i)
	}
	wg.Wait()
	close(results)
	committed := 0
	var highest int64
	for got := range results {
		if got.err == nil {
			committed++
			if got.result.RootVersion > highest {
				highest = got.result.RootVersion
			}
			continue
		}
		if tx.SQLState(got.err) != "40001" || got.result.Schema != "" {
			t.Fatal("unexpected concurrency result", got.err)
		}
		id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "public-profile", Operation: app.HideCommand, SemanticKey: got.operation.ID.String()}
		if _, present, e := (kernelstore.Store{}).FindTx(ctx, p, id); e != nil || present {
			t.Fatal("definiteabort retained outcome", e)
		}
		t.Log("bounded serializable retry exhausted safely, no success or receipt")
	}
	if committed == 0 {
		t.Fatal("no concurrent operationcommitted")
	}
	row, _ = root(t, p, a.PlayerID)
	if row.StateVersion < 2 || row.StateVersion > int64(1+committed) || row.StateVersion != highest {
		t.Fatal("effective version/receipt inconsistency", row.StateVersion, highest)
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
func TestRealHTTPBearerAndNonSuccessCallbacks(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	auth, bearer := token(t, p, a)
	router := httpedge.NewRouter()
	d := stockruntime.PublicProfileDispatcher{Authority: auth, Service: service(p, p)}
	for _, mid := range []uint16{1831, 1833, 1834} {
		if e := router.Register(mid, d); e != nil {
			t.Fatal(e)
		}
	}
	ad, _ := httpedge.NewAdmission(4)
	h := httpedge.Handler{Limits: limits.Default(), Admission: ad, Operations: operation.Factory{Clock: clock.System{}}, Policies: profilePolicySet(), Router: router}
	server := httptest.NewServer(h)
	defer server.Close()
	send := func(payload string) (int, map[string]any) {
		t.Helper()
		resp, e := http.Post(server.URL, "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {payload}}.Encode()))
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
	payload := func(mid int, params map[string]any) string {
		params["mid"] = mid
		params["token"] = bearer
		params["region"] = 1
		b, e := json.Marshal(params)
		if e != nil {
			t.Fatal(e)
		}
		return string(b)
	}
	for _, tc := range []struct {
		mid    int
		params map[string]any
		status int
		field  string
	}{{1834, map[string]any{"content": "native HTTP 😀"}, 200, "intro"}, {1833, map[string]any{"sub_types": []any{2, 4}}, 200, "hide_types"}, {1833, map[string]any{"sub_types": map[string]any{}}, 200, "hide_types"}, {1831, map[string]any{"show_types": []any{1011}}, 200, "show_types"}, {1831, map[string]any{"show_types": []any{1001}}, 409, ""}, {1834, map[string]any{"content": strings.Repeat("😀", 41)}, 400, ""}} {
		status, body := send(payload(tc.mid, tc.params))
		if status != tc.status {
			t.Fatalf("HTTP %d body%v want%d", status, body, tc.status)
		}
		if tc.status == 200 {
			if _, yes := body[tc.field]; !yes {
				t.Fatal("consumer fieldmissing")
			}
		} else if _, yes := body["intro"]; yes {
			t.Fatal("failure enteredOKshape")
		}
	}
	status, _ := send(`{"mid":1834,"mid":50,"content":"x"}`)
	if status != 400 {
		t.Fatal("duplicateMID accepted")
	}
	status, _ = send(`{"mid":1834,"content":"\ud800"}`)
	if status != 400 {
		t.Fatal("surrogate accepted")
	}
	wrong := map[string]any{"mid": 1834, "token": bearer, "region": 2, "content": "forbidden"}
	raw, _ := json.Marshal(wrong)
	status, _ = send(string(raw))
	if status != 403 {
		t.Fatal("region accepted", status)
	}
	sqlExec(t, p, `UPDATE account_sessions SET absolute_expires_at=clock_timestamp()-interval '1 second' WHERE session_id=$1`, a.SessionID.UUID().String())
	status, _ = send(payload(1834, map[string]any{"content": "expired"}))
	if status != 403 {
		t.Fatal("expired bearer accepted", status)
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
func TestProcessHelper(t *testing.T) {
	mode := os.Getenv("GXB_I7B2B_CHILD")
	if mode == "" {
		t.Skip("OS-subprocess helper only")
	}
	p := pool(t)
	installed(t, p)
	var v actorTransport
	if e := json.Unmarshal([]byte(os.Getenv("GXB_I7B2B_ACTOR")), &v); e != nil {
		t.Fatal(e)
	}
	a := decodeActor(t, v)
	if mode == "assign" {
		s := service(p, p)
		when, e := time.Parse(time.RFC3339Nano, os.Getenv("GXB_I7B2B_DECISION"))
		if e != nil {
			t.Fatal(e)
		}
		s.Timed.Binder.Time = fixedTime{when}
		r, e := s.Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: os.Getenv("GXB_I7B2B_TEXT")}, op())
		if e != nil {
			t.Fatal(e)
		}
		if r.RootVersion < 1 {
			t.Fatal("processmissing root")
		}
	} else {
		row, ok := root(t, p, a.PlayerID)
		if !ok || row.Validate() != nil || row.Preferences.Intro == "" {
			t.Fatal("process reload missing")
		}
		var n int64
		if e := p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1 AND domain='public-profile'`, strconv.FormatInt(int64(a.PlayerID), 10)).Scan(&n); e != nil || n < 1 {
			t.Fatal("retainedreceiptsmissing", e)
		}
	}
}

type fixedTime struct{ at time.Time }

func (f fixedTime) Now(context.Context) (time.Time, error) { return f.at, nil }
func child(t *testing.T, a identity.ActorContext, mode, text string, instant time.Time) *exec.Cmd {
	t.Helper()
	raw, _ := json.Marshal(encodeActor(a))
	cmd := exec.Command(os.Args[0], "-test.run=^TestProcessHelper$", "-test.v")
	cmd.Env = append(os.Environ(), "GXB_I7B2B_CHILD="+mode, "GXB_I7B2B_ACTOR="+string(raw), "GXB_I7B2B_TEXT="+text, "GXB_I7B2B_DECISION="+instant.Format(time.RFC3339Nano))
	return cmd
}
func TestIndependentProcessCommandsAndReload(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	instant, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	commands := []*exec.Cmd{child(t, a, "assign", "process A", instant), child(t, a, "assign", "process B", instant)}
	buffers := []bytes.Buffer{{}, {}}
	for i, cmd := range commands {
		cmd.Stdout = &buffers[i]
		cmd.Stderr = &buffers[i]
		if e = cmd.Start(); e != nil {
			t.Fatal(e)
		}
	}
	for i, cmd := range commands {
		if e = cmd.Wait(); e != nil {
			t.Fatal("process", e, buffers[i].String())
		}
	}
	row, ok := root(t, p, a.PlayerID)
	if !ok || row.StateVersion != 2 {
		t.Fatal("creationrace version", row.StateVersion)
	}
	if out, e := child(t, a, "reload", "", instant).CombinedOutput(); e != nil {
		t.Fatal(e, string(out))
	}
}
func TestRestoredTypedOwnerPolicyReceiptReload(t *testing.T) {
	if os.Getenv("GXB_I7B2B_RESTORED") != "1" {
		t.Skip("requires actual qualificationrestore/restart flag")
	}
	p := pool(t)
	installed(t, p)
	var raw string
	if e := p.QueryRow(ctx, `SELECT result_payload::text FROM gxb_operation_receipts WHERE domain='public-profile' AND operation='intro' ORDER BY recorded_at LIMIT 1`).Scan(&raw); e != nil {
		t.Fatal(e)
	}
	var r app.CommandResult
	if e := json.Unmarshal([]byte(raw), &r); e != nil {
		t.Fatal(e)
	}
	row, ok := root(t, p, identity.PlayerID(r.PlayerID))
	if !ok || row.StateVersion < r.RootVersion {
		t.Fatal("restoredowner inconsistency")
	}
	if _, e := (contentstore.Store{}).ReadPublicProfilePolicy(ctx, p, r.Revision); e != nil {
		t.Fatal("retainedpolicymissing", e)
	}
}

func profilePolicySet() policy.Set {
	s, e := policy.NewSet(policy.Ref{Name: "profile", Version: dom.PolicyVersion})
	if e != nil {
		panic(e)
	}
	return s
}
func TestCoherentReadAcrossConcurrentOwnerChanges(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	assign(t, p, b, app.Command{Kind: app.IntroCommand, Intro: "old snapshot"}, op())
	instant, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	var old string
	if e = tr.QueryRow(ctx, `SELECT display_name FROM player_profiles WHERE player_id=$1`, int64(b.PlayerID)).Scan(&old); e != nil {
		t.Fatal(e)
	}
	// An independent owner transaction commits all facts while the caller retains
	// its established RR snapshot. This fixture proves read coherence, not a new
	// cross-owner mutation authority or a guarantee across different requests.
	writer, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer writer.Rollback(ctx)
	for _, q := range []string{`UPDATE player_profiles SET display_name='new snapshot',state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1`, `UPDATE player_progression SET level=2,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1`, `UPDATE player_public_profile_roots SET intro='new snapshot',hide_subtypes=ARRAY[2,4]::smallint[],state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1`} {
		if _, e = writer.Exec(ctx, q, int64(b.PlayerID)); e != nil {
			t.Fatal(e)
		}
	}
	if e = writer.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	s := app.BasicReader{Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: contentstore.Store{}}
	r, e := s.ReadBasicTx(ctx, tx.Scope{Tx: tr, Operation: op(), Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}, a, b.PlayerID, rev, instant)
	if e != nil {
		if tx.SQLState(e) != "40001" || r.Identity.PlayerID != 0 {
			t.Fatal("unsafe/coherence error", e)
		}
		if e = tr.Rollback(ctx); e != nil {
			t.Fatal(e)
		}
		t.Log("old RR snapshot safely rejected by PostgreSQL row-lock conflict; no mixed projection")
	} else {
		if r.Identity.Name != old || r.Identity.Level != 1 || r.Intro != "old snapshot" || !r.Eligible[2] || !r.Eligible[4] {
			t.Fatal("mixed owner observations")
		}
		if e = tr.Commit(ctx); e != nil {
			t.Fatal(e)
		}
	}

	newest := basic(t, p, a, b.PlayerID, rev)
	if newest.Identity.Name != "new snapshot" || newest.Identity.Level != 2 || newest.Intro != "new snapshot" || newest.Eligible[2] || newest.Eligible[4] {
		t.Fatal("fresh read failed canonicalreload")
	}
}
func TestRetainedPolicyReplayAndCorruptProofRejection(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	q := app.Command{Kind: app.IntroCommand, Intro: "retained policy"}
	o := op()
	first := assign(t, p, a, q, o)
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "public-profile", Operation: app.IntroCommand, SemanticKey: o.ID.String()}
	rr, yes, e := (kernelstore.Store{}).FindTx(ctx, p, id)
	if e != nil || !yes {
		t.Fatal(e)
	}
	var oldPayload string
	if e = p.QueryRow(ctx, `SELECT payload::text FROM content_public_profile_policies WHERE revision_id=$1`, rev).Scan(&oldPayload); e != nil {
		t.Fatal(e)
	}
	// Unavailable current activation is a controlled administrative-fault case.
	// It does not claim a full qualified alternate content deployment. Receipt
	// recovery must use retained exact policy, never the activation pointer.
	sqlExec(t, p, `DELETE FROM gxb_content_activation WHERE slot='content'`)
	again, e := service(p, p).Execute(ctx, a, q, o)
	if e != nil || again.Intro != first.Intro {
		t.Fatal("retained replay consulted current pointer", e)
	}
	if _, e = service(p, p).Execute(ctx, a, q, op()); e == nil {
		t.Fatal("missing current activation allowed newoperation")
	}
	sqlExec(t, p, `INSERT INTO gxb_content_activation(slot,revision_id,activation_version,activated_at,activated_by)VALUES('content',$1,99,clock_timestamp(),'i7b2b-native-fault-restore')`, rev)
	altered := o
	altered.EntropySeed[0] ^= 1
	if _, e = service(p, p).Execute(ctx, a, q, altered); !errors.Is(e, app.ErrConflict) {
		t.Fatal("changed semanticcontext accepted", e)
	}
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET result_payload=jsonb_set(result_payload,'{server}','2'::jsonb) WHERE receipt_id=$1`, rr.ID.String())
	if _, e = service(p, p).Execute(ctx, a, q, o); !errors.Is(e, app.ErrConflict) {
		t.Fatal("corrupt result binding accepted", e)
	}
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET result_payload=$2::jsonb WHERE receipt_id=$1`, rr.ID.String(), string(rr.ResultPayload))
	sqlExec(t, p, `UPDATE content_public_profile_policies SET payload=jsonb_set(payload,'{intro_codepoints}','41'::jsonb) WHERE revision_id=$1`, rev)
	if _, e = service(p, p).Execute(ctx, a, q, o); e == nil {
		t.Fatal("corrupt retained policy accepted")
	}
	sqlExec(t, p, `UPDATE content_public_profile_policies SET payload=$2::jsonb WHERE revision_id=$1`, rev, oldPayload)
}
