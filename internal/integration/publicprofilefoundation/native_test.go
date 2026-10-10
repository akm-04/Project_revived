//go:build postgres

package publicprofilefoundation_test

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	dom "gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"os"
	"os/exec"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

var ctx = context.Background()
var at = time.Date(2026, 10, 10, 20, 0, 0, 0, time.UTC)
var revision = strings.Repeat("a", 64)
var service = app.RootService{Store: publicprofilestore.Store{}}

func pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B2A_DSN")
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
	return tx.Profile{Name: "I7B2A_NATIVE", AcquireTimeout: 5 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 15 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 40 * time.Second}
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
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'i7b2a-native')`, []any{pid, a.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i7b2a-native',clock_timestamp(),clock_timestamp())`, []any{s.String(), a.String()}},
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
func prepare(c context.Context, t tx.Tx, a identity.ActorContext, when time.Time) (app.PreparedRoot, error) {
	if e := (i5store.Store{}).FenceActorTx(c, t, a, when); e != nil {
		return app.PreparedRoot{}, e
	}
	r, e := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(c, t, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
	if e != nil {
		return app.PreparedRoot{}, e
	}
	return service.PreparePreferencesTx(c, t, r[0])
}
func write(p *pg.Pool, a identity.ActorContext, ch dom.Change, when time.Time) (app.Root, bool, error) {
	var out app.Root
	var present bool
	_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, s tx.Scope) error {
		pr, e := prepare(c, s.Tx, a, when)
		if e != nil {
			return e
		}
		out, present, e = service.ApplyPreferencesTx(c, s.Tx, pr, ch, when)
		return e
	})
	if e != nil {
		return app.Root{}, false, e
	}
	return out, present, nil
}
func read(t *testing.T, p *pg.Pool, pid identity.PlayerID) app.Snapshot {
	t.Helper()
	var out app.Snapshot
	_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, s tx.Scope) error {
		var e error
		out, e = service.ReadSnapshotTx(c, s, pid, revision, at)
		return e
	})
	if e != nil {
		t.Fatal(e)
	}
	return out
}
func mustWrite(t *testing.T, p *pg.Pool, a identity.ActorContext, ch dom.Change) app.Root {
	t.Helper()
	r, _, e := write(p, a, ch, at)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func sqlExec(t *testing.T, p *pg.Pool, s string, args ...any) {
	t.Helper()
	if _, e := p.Raw().Exec(ctx, s, args...); e != nil {
		t.Fatal(e)
	}
}
func TestAbsenceConstraintsAndNoop(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	v := read(t, p, a.PlayerID)
	if v.Present || v.Root.StateVersion != 0 || !v.Root.CreatedAt.IsZero() {
		t.Fatal(v)
	}
	if r, present, e := write(p, a, dom.Change{}, at); e != nil || present || r.StateVersion != 0 {
		t.Fatal(r, present, e)
	}
	wrong := a
	wrong.LogicalServerID = 2
	if _, _, e := write(p, wrong, dom.Change{}, at); e == nil {
		t.Fatal("wrong server admitted")
	}
	missing := a
	missing.PlayerID = math.MaxInt64
	if _, _, e := write(p, missing, dom.Change{}, at); e == nil {
		t.Fatal("missing player admitted")
	}
	text := strings.Repeat("界", 40)
	r := mustWrite(t, p, a, dom.Change{Intro: &text})
	if r.StateVersion != 1 {
		t.Fatal(r)
	}
	noop := mustWrite(t, p, a, dom.Change{Intro: &text})
	if noop.StateVersion != r.StateVersion || !noop.UpdatedAt.Equal(r.UpdatedAt) {
		t.Fatal(noop)
	}
	fields := []string{"state_version=0", "policy_version='bad'", "updated_at=created_at-interval '1 second'", "intro=repeat('界',41)", "show_type_ids=NULL", "show_type_ids=ARRAY[NULL]::bigint[]", "show_type_ids=ARRAY[1001,1001]::bigint[]", "show_type_ids=ARRAY[1000]::bigint[]", "show_type_ids=ARRAY[1001,1002,1003,1004,1005]::bigint[]", "show_type_ids='[0:0]={1001}'::bigint[]", "show_type_ids=ARRAY[[1001,1002]]::bigint[]", "hide_subtypes=ARRAY[1]::smallint[]", "hide_subtypes=ARRAY[2,2]::smallint[]", "hide_subtypes=ARRAY[4,2]::smallint[]", "hide_subtypes=NULL", "hide_subtypes=ARRAY[NULL]::smallint[]", "share_switch=2", "is_first_time=-1"}
	for _, f := range fields {
		if _, e := p.Raw().Exec(ctx, "UPDATE player_public_profile_roots SET "+f+" WHERE player_id=$1", int64(a.PlayerID)); e == nil {
			t.Fatal("SQL accepted", f)
		}
	}
	for _, bad := range []string{"a\x00", strings.Repeat("界", 41), "\xff"} {
		if _, _, e := write(p, a, dom.Change{Intro: &bad}, at); e == nil {
			t.Fatal("invalid intro accepted")
		}
	}
	sqlExec(t, p, "UPDATE player_public_profile_roots SET share_switch=1,is_first_time=1 WHERE player_id=$1", int64(a.PlayerID))
	ids := []int64{1011, 1001}
	h := []int16{4, 2}
	r = mustWrite(t, p, a, dom.Change{ShowTypeIDs: &ids, HideSubtypes: &h})
	if r.Preferences.ShareSwitch != 1 || r.Preferences.IsFirstTime != 1 || r.Preferences.HideSubtypes[0] != 2 {
		t.Fatal(r)
	}
}
func TestPreparedCASAliasingAndTime(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	txt := "first"
	mustWrite(t, p, a, dom.Change{Intro: &txt})
	tr, _ := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	defer tr.Rollback(ctx)
	pr, e := prepare(ctx, tr, a, at)
	if e != nil {
		t.Fatal(e)
	}
	copy, _ := pr.Existing()
	copy.Preferences.Intro = "alias"
	copy.Preferences.ShowTypeIDs = append(copy.Preferences.ShowTypeIDs, 1001)
	other, _ := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	defer other.Rollback(ctx)
	if _, _, e = service.ApplyPreferencesTx(ctx, other, pr, dom.Change{}, at); e == nil {
		t.Fatal("wrong Tx")
	}
	txt = "second"
	if _, _, e = service.ApplyPreferencesTx(ctx, tr, pr, dom.Change{Intro: &txt}, at); e != nil {
		t.Fatal(e)
	}
	if _, _, e = service.ApplyPreferencesTx(ctx, tr, pr, dom.Change{}, at); !errors.Is(e, app.ErrStaleRoot) {
		t.Fatal("stale no-op token", e)
	}
	if _, e = service.TouchForChildChangeTx(ctx, tr, pr, at); !errors.Is(e, app.ErrStaleRoot) {
		t.Fatal("stale CAS", e)
	}
	tr.Rollback(ctx)
	sqlExec(t, p, "UPDATE player_public_profile_roots SET state_version=$2 WHERE player_id=$1", int64(a.PlayerID), int64(math.MaxInt64))
	if _, _, e = write(p, a, dom.Change{Intro: &txt}, at); e == nil {
		t.Fatal("overflow")
	}
	sqlExec(t, p, "UPDATE player_public_profile_roots SET state_version=1,updated_at=$2 WHERE player_id=$1", int64(a.PlayerID), at.Add(time.Second))
	if _, _, e = write(p, a, dom.Change{Intro: &txt}, at); e == nil {
		t.Fatal("stale decision")
	}
	if _, _, e = write(p, a, dom.Change{Intro: &txt}, at.Add(time.Second)); e != nil {
		t.Fatal(e)
	}
}
func TestCoherentReadsAndRequiredOwners(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	txt := "before"
	mustWrite(t, p, a, dom.Change{Intro: &txt})
	_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, s tx.Scope) error {
		first, e := service.ReadSnapshotTx(c, s, a.PlayerID, revision, at)
		if e != nil {
			return e
		}
		basis, e := (i5store.Store{}).ReadPublicPlayerBasisTx(c, s.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if len(basis.Functions) != 0 || !basis.Profile.CreatedAt.Equal(at.Add(-24*time.Hour)) {
			return errors.New("basis absence/creation")
		}
		txt = "after"
		if _, _, e = write(p, a, dom.Change{Intro: &txt}, at); e != nil {
			return e
		}
		sqlExec(t, p, "UPDATE player_progression SET level=2,state_version=state_version+1 WHERE player_id=$1", int64(a.PlayerID))
		sqlExec(t, p, "INSERT INTO player_function_unlocks(player_id,function_id,opened_at,source_fact_key,state_version)VALUES($1,11,$2,'native-source',1)", int64(a.PlayerID), at)
		second, e := service.ReadSnapshotTx(c, s, a.PlayerID, revision, at)
		if e != nil {
			return e
		}
		again, e := (i5store.Store{}).ReadPublicPlayerBasisTx(c, s.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if !first.Root.Preferences.Equal(second.Root.Preferences) || again.Progression.Level != basis.Progression.Level || len(again.Functions) != 0 {
			return errors.New("snapshot drift")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	tr, _ := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	defer tr.Rollback(ctx)
	scope := tx.Scope{Tx: tr, Operation: op(), Attempt: 1, Options: tx.Options{Isolation: tx.ReadCommitted}}
	if _, e := service.ReadSnapshotTx(ctx, scope, a.PlayerID, revision, at); e == nil {
		t.Fatal("RC accepted")
	}
	scope.Options.Isolation = tx.RepeatableRead
	for _, rev := range []string{"active", strings.Repeat("A", 64), ""} {
		if _, e := service.ReadSnapshotTx(ctx, scope, a.PlayerID, rev, at); e == nil {
			t.Fatal("invalid revision")
		}
	}
	scope.Attempt = 0
	if _, e := service.ReadSnapshotTx(ctx, scope, a.PlayerID, revision, at); e == nil {
		t.Fatal("missing witness")
	}
	tr.Rollback(ctx)
	b, e := (i5store.Store{}).ReadPublicPlayerBasisTx(ctx, p, a.PlayerID)
	if e != nil || b.Progression.Level != 2 || len(b.Functions) != 1 || b.Functions[0].StateVersion != 1 {
		t.Fatal(b, e)
	}
	sqlExec(t, p, "DELETE FROM player_progression WHERE player_id=$1", int64(a.PlayerID))
	if _, e := (i5store.Store{}).ReadPublicPlayerBasisTx(ctx, p, a.PlayerID); e == nil {
		t.Fatal("missing progression defaulted")
	}
}

// This component outcome schema is fixture-only, not a MID command contract.
func rid(a identity.ActorContext, o operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "PublicProfile", OwnerKey: fmt.Sprint(a.PlayerID), Domain: "i7b2a-native", Operation: "component", SemanticKey: o.ID.String()}
}
func fingerprint(ch dom.Change) [32]byte { b, _ := json.Marshal(ch); return sha256.Sum256(b) }
func match(r receipt.Receipt, id receipt.Identity, fp [32]byte, a identity.ActorContext, o operation.Context) error {
	p, _ := policy.MarshalCanonicalJSON(o.Policies)
	q, _ := policy.MarshalCanonicalJSON(r.OperationPolicyRefs)
	if r.Identity != id || r.RequestFingerprint != fp || r.OperationClass != "native-component" || r.ResultSchema != "fixture-root-v1" || r.ActorAccountUID != string(a.AccountUID) || r.ContextID != a.ContextID.UUID() || r.PolicyVersion != dom.PolicyVersion || string(p) != string(q) {
		return errors.New("component receipt binding mismatch")
	}
	return r.Validate()
}

type fixedTime struct {
	p  tx.Queryer
	at time.Time
}

func (f fixedTime) Now(c context.Context) (time.Time, error) {
	var v time.Time
	e := f.p.QueryRow(c, "SELECT $1::timestamptz", f.at).Scan(&v)
	return v, e
}

type timedResolve struct {
	p  *pg.Pool
	a  identity.ActorContext
	id receipt.Identity
	fp [32]byte
	o  operation.Context
}

func (r timedResolve) ResolveTimed(c context.Context, q gen.TimedResolutionRequest) (tx.Resolution, error) {
	v, e := (receipt.Resolver{Reader: kernelstore.Reader{Queryer: r.p}, Identity: r.id, Fingerprint: r.fp}).Resolve(c, tx.ResolutionRequest{Operation: q.Operation.Operation()})
	if e != nil || v.State != tx.ResolutionCommitted {
		return v, e
	}
	stored := v.Evidence.(receipt.Receipt)
	if e = match(stored, r.id, r.fp, r.a, r.o); e != nil {
		return tx.Resolution{}, e
	}
	return v, nil
}
func component(p *pg.Pool, db tx.Beginner, a identity.ActorContext, o operation.Context, ch dom.Change, fail bool) (app.Root, tx.Result, error) {
	id := rid(a, o)
	fp := fingerprint(ch)
	var private app.Root
	_, result, e := (gen.TimedRunner{Binder: gen.Binder{Time: fixedTime{p, at}}, Runner: tx.Runner{DB: db}}).Run(ctx, o, prof(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, timedResolve{p, a, id, fp, o}, func(c context.Context, s gen.TimedScope) error {
		pr, e := prepare(c, s.Tx, a, s.Operation.DecisionAt())
		if e != nil {
			return e
		}
		old, ok, e := (kernelstore.Store{}).FindTx(c, s.Tx, id)
		if e != nil {
			return e
		}
		if ok {
			if e = match(old, id, fp, a, o); e != nil {
				return e
			}
			return json.Unmarshal(old.ResultPayload, &private)
		}
		private, _, e = service.ApplyPreferencesTx(c, s.Tx, pr, ch, s.Operation.DecisionAt())
		if e != nil {
			return e
		}
		payload, _ := json.Marshal(private)
		r, e := receipt.New(o, id, "native-component", "fixture-root-v1", payload, fp)
		if e != nil {
			return e
		}
		r.ActorAccountUID = string(a.AccountUID)
		r.ContextID = a.ContextID.UUID()
		r.PolicyVersion = dom.PolicyVersion
		if _, e = (kernelstore.Store{}).PutTx(c, s.Tx, r); e != nil {
			return e
		}
		if fail {
			return errors.New("failure before commit")
		}
		return nil
	})
	if e != nil || result.Outcome != tx.DefiniteCommit {
		return app.Root{}, result, e
	}
	if result.Evidence != nil {
		r := result.Evidence.(receipt.Receipt)
		if e = json.Unmarshal(r.ResultPayload, &private); e != nil {
			return app.Root{}, result, e
		}
	}
	return private, result, nil
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
func TestAtomicReceiptsKnownAttemptAndUNKNOWN(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	o := op()
	txt := "committed"
	ch := dom.Change{Intro: &txt}
	if out, res, e := component(p, p, a, o, ch, true); e == nil || out.PlayerID != 0 || res.Outcome != tx.DefiniteAbort {
		t.Fatal(out, res, e)
	}
	if read(t, p, a.PlayerID).Present {
		t.Fatal("rollback root")
	}
	if _, ok, e := (kernelstore.Reader{Queryer: p}).Find(ctx, rid(a, o)); e != nil || ok {
		t.Fatal("rollback receipt", e)
	}
	first, res, e := component(p, faultDB{p, true}, a, o, ch, false)
	if e != nil || res.Outcome != tx.DefiniteCommit || !res.Reconciled || res.Evidence == nil || first.StateVersion != 1 {
		t.Fatal(first, res, e)
	}
	cmd := childCmd(t, a, "receipt")
	cmd.Env = append(cmd.Env, "GXB_I7B2A_CHILD_RECEIPT="+o.ID.String())
	if b, e := cmd.CombinedOutput(); e != nil {
		t.Fatal(e, string(b))
	}
	later := "later"
	mustWrite(t, p, a, dom.Change{Intro: &later})
	replay, _, e := component(p, p, a, o, ch, false)
	if e != nil || replay.Preferences.Intro != "committed" || read(t, p, a.PlayerID).Root.Preferences.Intro != "later" {
		t.Fatal(replay, e)
	}
	if _, _, e = component(p, p, a, o, dom.Change{Intro: &later}, false); e == nil {
		t.Fatal("fingerprint conflict")
	}
	old, _, _ := (kernelstore.Reader{Queryer: p}).Find(ctx, rid(a, o))
	bad := old
	bad.ResultSchema = "wrong"
	if match(bad, rid(a, o), fingerprint(ch), a, o) == nil {
		t.Fatal("schema")
	}
	bad = old
	bad.ContextID = uuid()
	if match(bad, rid(a, o), fingerprint(ch), a, o) == nil {
		t.Fatal("context")
	}
	bad = old
	bad.ActorAccountUID = "wrong"
	if match(bad, rid(a, o), fingerprint(ch), a, o) == nil {
		t.Fatal("actor")
	}
	bad = old
	bad.PolicyVersion = "wrong"
	if match(bad, rid(a, o), fingerprint(ch), a, o) == nil {
		t.Fatal("policy")
	}
	b := actor(t, p)
	out, res, e := component(p, faultDB{p, false}, b, op(), ch, false)
	if e == nil || res.Outcome != tx.UnknownCommitOutcome || res.Attempts != 1 || out.PlayerID != 0 || read(t, p, b.PlayerID).Present {
		t.Fatal(out, res, e)
	}
	absent := actor(t, p)
	emptyOp := op()
	v, _, e := component(p, p, absent, emptyOp, dom.Change{}, false)
	if e != nil || v.StateVersion != 0 || read(t, p, absent.PlayerID).Present {
		t.Fatal("no-op receipt created root", e)
	}
}
func TestActorRevocationAndExpiryFences(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	tr, _ := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if _, e := prepare(ctx, tr, a, at); e != nil {
		t.Fatal(e)
	}
	started := make(chan struct{})
	done := make(chan error, 1)
	go func() {
		close(started)
		_, e := p.Raw().Exec(ctx, "UPDATE account_sessions SET revoked_at=$2,liveness_version=liveness_version+1 WHERE session_id=$1", a.SessionID.UUID().String(), at)
		done <- e
	}()
	<-started
	select {
	case e := <-done:
		t.Fatal("revocation crossed held fence", e)
	case <-time.After(50 * time.Millisecond):
	}
	tr.Commit(ctx)
	if e := <-done; e != nil {
		t.Fatal(e)
	}
	if _, _, e := write(p, a, dom.Change{}, at); e == nil {
		t.Fatal("revoked accepted")
	}
	b := actor(t, p)
	sqlExec(t, p, "UPDATE account_sessions SET absolute_expires_at=$2 WHERE session_id=$1", b.SessionID.UUID().String(), at)
	if _, _, e := write(p, b, dom.Change{}, at); e == nil {
		t.Fatal("expired accepted")
	}
}

type actorTransport struct {
	Account, Session, Context                  ids.UUID
	PID                                        identity.PlayerID
	UID                                        identity.AccountUID
	Server                                     identity.LogicalServerID
	Generation, SessionVersion, ContextVersion int64
}

func childActor(t *testing.T) (identity.ActorContext, bool) {
	t.Helper()
	raw := os.Getenv("GXB_I7B2A_CHILD_ACTOR")
	if raw == "" {
		return identity.ActorContext{}, false
	}
	var x actorTransport
	if e := json.Unmarshal([]byte(raw), &x); e != nil {
		t.Fatal(e)
	}
	a, _ := identity.AccountIDFrom(x.Account)
	ss, _ := identity.SessionIDFrom(x.Session)
	c, _ := identity.ContextIDFrom(x.Context)
	return identity.ActorContext{AccountID: a, SessionID: ss, ContextID: c, AccountUID: x.UID, PlayerID: x.PID, LogicalServerID: x.Server, ContextGeneration: x.Generation, SessionLivenessVersion: x.SessionVersion, ContextLivenessVersion: x.ContextVersion}, true
}
func childCmd(t *testing.T, a identity.ActorContext, mode string) *exec.Cmd {
	t.Helper()
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	b, _ := json.Marshal(actorTransport{a.AccountID.UUID(), a.SessionID.UUID(), a.ContextID.UUID(), a.PlayerID, a.AccountUID, a.LogicalServerID, a.ContextGeneration, a.SessionLivenessVersion, a.ContextLivenessVersion})
	c := exec.Command(exe, "-test.run=^TestProcessHelper$", "-test.v")
	c.Env = append(os.Environ(), "GXB_I7B2A_CHILD_ACTOR="+string(b), "GXB_I7B2A_CHILD_MODE="+mode)
	return c
}
func TestProcessHelper(t *testing.T) {
	a, ok := childActor(t)
	if !ok {
		return
	}
	p := pool(t)
	switch os.Getenv("GXB_I7B2A_CHILD_MODE") {
	case "receipt":
		o := op()
		o.ID, _ = ids.ParseUUID(os.Getenv("GXB_I7B2A_CHILD_RECEIPT"))
		txt := "committed"
		ch := dom.Change{Intro: &txt}
		r, ok, e := (kernelstore.Reader{Queryer: p}).Find(ctx, rid(a, o))
		if e != nil || !ok || match(r, rid(a, o), fingerprint(ch), a, o) != nil {
			t.Fatal("process receipt reload", e)
		}
		var root app.Root
		if e = json.Unmarshal(r.ResultPayload, &root); e != nil || root.StateVersion != 1 || root.Preferences.Intro != txt {
			t.Fatal(root, e)
		}
	case "intro":
		s := "process"
		mustWrite(t, p, a, dom.Change{Intro: &s})
	case "ids":
		ids := []int64{1001}
		mustWrite(t, p, a, dom.Change{ShowTypeIDs: &ids})
	case "read":
		v := read(t, p, a.PlayerID)
		if !v.Present || v.Root.Preferences.Intro != "process" || v.Root.StateVersion != 2 || len(v.Root.Preferences.ShowTypeIDs) != 1 {
			t.Fatal(v)
		}
		if _, e := (i5store.Store{}).ReadPublicPlayerBasisTx(ctx, p, a.PlayerID); e != nil {
			t.Fatal(e)
		}
	default:
		t.Fatal("invalid mode")
	}
}
func TestIndependentProcessesCreationRaceAndReload(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for _, mode := range []string{"intro", "ids"} {
		c := childCmd(t, a, mode)
		wg.Add(1)
		go func() {
			defer wg.Done()
			o, e := c.CombinedOutput()
			if e != nil {
				e = fmt.Errorf("%v: %s", e, o)
			}
			errs <- e
		}()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	v := read(t, p, a.PlayerID)
	if v.Root.StateVersion != 2 || v.Root.Preferences.Intro != "process" || len(v.Root.Preferences.ShowTypeIDs) != 1 {
		t.Fatal(v)
	}
	if b, e := childCmd(t, a, "read").CombinedOutput(); e != nil {
		t.Fatal(e, string(b))
	}
	var count int
	if e := p.QueryRow(ctx, "SELECT count(*) FROM player_public_profile_roots WHERE player_id=$1", int64(a.PlayerID)).Scan(&count); e != nil || count != 1 {
		t.Fatal(count, e)
	}
}
func TestRestoredOwnerReload(t *testing.T) {
	if os.Getenv("GXB_I7B2A_RESTORED") != "1" {
		return
	}
	p := pool(t)
	var raw string
	if e := p.QueryRow(ctx, "SELECT json_agg(player_id ORDER BY player_id)::text FROM player_public_profile_roots").Scan(&raw); e != nil {
		t.Fatal(e)
	}
	var pids []int64
	if e := json.Unmarshal([]byte(raw), &pids); e != nil || len(pids) == 0 {
		t.Fatal(raw, e)
	}
	for _, pid := range pids {
		if !read(t, p, identity.PlayerID(pid)).Present {
			t.Fatal(pid)
		}
	}
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
func TestDefiniteAbortUsesStableRootDecisionTime(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	db := &abortOnceDB{Beginner: p}
	txt := "retry"
	r, res, e := component(p, db, a, op(), dom.Change{Intro: &txt}, false)
	if e != nil || res.Attempts != 2 || res.Outcome != tx.DefiniteCommit || r.StateVersion != 1 || !r.CreatedAt.Equal(at) || !r.UpdatedAt.Equal(at) {
		t.Fatal(r, res, e)
	}
}
