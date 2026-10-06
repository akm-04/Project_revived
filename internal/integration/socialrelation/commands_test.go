//go:build postgres && socialintegration

// Package socialrelation_test exercises real owner adapters and native PostgreSQL.
// Enable with -tags "postgres socialintegration" and a disposable migrated database.
// It deliberately fails if no DSN is supplied once this explicit native suite is selected.
package socialrelation_test

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
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

var ctx = context.Background()

type fixture struct {
	t  *testing.T
	p  *postgres.Pool
	s  sr.Service
	at time.Time
}

func existing(t *testing.T) *fixture {
	t.Helper()
	dsn := os.Getenv("GXB_I7A4B_TEST_DSN")
	if dsn == "" {
		t.Fatal("GXB_I7A4B_TEST_DSN must name a disposable migrated PostgreSQL database")
	}
	p, e := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(p.Close)
	f := &fixture{t: t, p: p}

	f.s = sr.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, PlayerRoots: i4store.PlayerRootLocker{}, Store: socialrelationstore.Store{}, Inbox: socialinbox.RelationService{Store: socialinboxstore.Store{}}, Presentation: socialpresentation.TransactionReader{}}
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
func TestRequestLegalityQuotaAndRejectionRollback(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	for i := int64(1); i <= 11; i++ {
		f.player(identity.PlayerID(200000 + i))
	}
	f.ok(100001, sr.RequestFriend, 200001)
	before := f.snapshot()
	_, e := f.runAs(100001, sr.RequestFriend, 200001)
	stock(t, e, 20009)
	_, e = f.runAs(200001, sr.RequestFriend, 100001)
	stock(t, e, 20010)
	if f.snapshot() != before {
		t.Fatal("duplicate/reverse changed canonical state")
	}
	for i := int64(2); i <= 9; i++ {
		f.ok(100001, sr.RequestFriend, identity.PlayerID(200000+i))
	}
	before = f.snapshot()
	_, e = f.runAs(100001, sr.RequestFriend, 200010)
	stock(t, e, 20011)
	if f.snapshot() != before || f.number(`SELECT successful_new_requests FROM social_request_epochs WHERE player_id=100001`) != 9 {
		t.Fatal("quota rejected effect")
	}
	_, e = f.runAs(100001, sr.RequestFriend, 100001)
	if !errors.Is(e, sr.ErrNotEligible) {
		t.Fatal(e)
	}
	_, e = f.runAs(100001, sr.RequestFriend, 299999)
	stock(t, e, 20004)
}
func TestAcceptReplayBlockCoexistenceAndRefriendGeneration(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.ok(100001, sr.RequestFriend, 200001)
	r := f.ok(200001, sr.AcceptRequest, 100001)
	if r.NoOp || r.Players.Players[100001].Minimal.PlayerID != 100001 {
		t.Fatal("missing winner projection")
	}
	f.ok(200001, sr.AddBlock, 100001)
	before := f.snapshot()
	r = f.ok(200001, sr.AcceptRequest, 100001)
	if !r.NoOp || f.snapshot() != before {
		t.Fatal("accepted convergence changed facts")
	}
	f.ok(200001, sr.RemoveBlock, 100001)
	f.ok(200001, sr.DeleteFriend, 100001)
	before = f.snapshot()
	if !f.ok(200001, sr.DeleteFriend, 100001).NoOp || f.snapshot() != before {
		t.Fatal("delete replay changed facts")
	}
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(200001, sr.AcceptRequest, 100001)
	if f.number(`SELECT generation FROM social_friendships`) != 2 || f.number(`SELECT generation FROM social_friend_requests`) != 2 || f.number(`SELECT count(*) FROM social_notices`) != 3 {
		t.Fatal("generation/source lifecycle incorrect")
	}
}
func TestDenyBatchDeduplicatesAndIgnoreExistingBlockTerminalizes(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 100002, 200001} {
		f.player(p)
	}
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(100002, sr.RequestFriend, 200001)
	f.ok(200001, sr.DenyRequests, 100001, 100001, 299999, 200001)
	if f.number(`SELECT count(*) FROM social_notices WHERE notice_type=2`) != 1 {
		t.Fatal("deny source duplicated")
	}
	f.ok(200001, sr.AddBlock, 100002)
	f.ok(200001, sr.IgnoreRequests, 100002, 100002)
	if f.text(`SELECT status FROM social_friend_requests WHERE requester_player_id=100002`) != "IGNORED" || f.number(`SELECT count(*) FROM social_blocks WHERE active`) != 1 || f.number(`SELECT count(*) FROM social_notices`) != 1 {
		t.Fatal("ignore failed pending+active block branch")
	}
}
func TestBlockLifecycleConvergenceAndClear(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 200001, 1000001} {
		f.player(p)
	}
	f.ok(100001, sr.AddBlock, 200001)
	before := f.snapshot()
	r := f.ok(100001, sr.AddBlock, 200001)
	if !r.NoOp || f.snapshot() != before || r.Players.Players[200001].Minimal.PlayerID != 200001 {
		t.Fatal("add block replay")
	}
	f.ok(100001, sr.RemoveBlock, 200001)
	f.ok(100001, sr.AddBlock, 200001)
	f.ok(100001, sr.AddBlock, 1000001)
	f.ok(100001, sr.ClearBlocks)
	if f.number(`SELECT count(*) FROM social_blocks WHERE active`) != 0 || f.number(`SELECT generation FROM social_blocks WHERE blocked_player_id=200001`) != 2 {
		t.Fatal("clear lost tombstone/generation")
	}
	before = f.snapshot()
	if !f.ok(100001, sr.ClearBlocks).NoOp || f.snapshot() != before {
		t.Fatal("clear replay")
	}
}

type brokenProjection struct{}

func (brokenProjection) ReadManyTx(context.Context, tx.Tx, []identity.PlayerID) (playerpresentation.Batch, error) {
	return playerpresentation.Batch{}, playerpresentation.ErrMissingPresentation
}
func TestProjectionFailureRollsBackAllPlannedWinners(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 100002, 200001} {
		f.player(p)
	}
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(100002, sr.RequestFriend, 200001)
	before := f.snapshot()
	f.s.Presentation = brokenProjection{}
	r, e := f.runAs(200001, sr.AcceptAllRequests, 100001, 100002)
	if !errors.Is(e, playerpresentation.ErrMissingPresentation) || len(r.Changes) != 0 || len(r.Players.Players) != 0 || f.snapshot() != before {
		t.Fatalf("projection failure leaked result/state: %+v %v", r, e)
	}
}

type fixedTime struct{ at time.Time }

func (v fixedTime) Now(context.Context) (time.Time, error) { return v.at, nil }
func TestLateStaleTimePreflightIsAtomicAndEqualityAllowed(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 100002, 200001} {
		f.player(p)
	}
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(100002, sr.RequestFriend, 200001)
	at := f.now()
	future := at.Add(time.Minute)
	f.sql(`UPDATE social_friend_requests SET requested_at=$1,updated_at=$1 WHERE requester_player_id=100002`, future)
	before := f.snapshot()
	f.s.Timed.Binder.Time = fixedTime{at}
	r, e := f.runAs(200001, sr.AcceptAllRequests, 100001, 100002)
	if !errors.Is(e, sr.ErrStaleDecisionTime) || len(r.Changes) != 0 || f.snapshot() != before {
		t.Fatalf("late stale preflight: %+v %v", r, e)
	}
	f.s.Timed.Binder.Time = fixedTime{future}
	f.ok(200001, sr.AcceptAllRequests, 100001, 100002)
	if f.number(`SELECT count(*) FROM social_friendships WHERE active`) != 2 {
		t.Fatal("time equality rejected")
	}
}
func TestMalformedBatchRejectedBeforeAnyEffects(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.ok(100001, sr.RequestFriend, 200001)
	before := f.snapshot()
	_, e := f.runAs(200001, sr.DenyRequests, 100001, 99999)
	if !errors.Is(e, sr.ErrInvalidCommand) || f.snapshot() != before {
		t.Fatal("malformed batch was partially applied", e)
	}
}
func TestDismissedSourceReplayPreservesIdentityAndRejectsMismatch(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(200001, sr.DenyRequests, 100001)
	var at time.Time
	if e := f.p.QueryRow(ctx, `SELECT notice_time FROM social_notices`).Scan(&at); e != nil {
		t.Fatal(e)
	}
	f.sql(`UPDATE social_notices SET active=false,dismissed_at=notice_time,state_version=2,updated_at=notice_time`)
	before := f.snapshot()
	handle, e := f.p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer handle.Rollback(ctx)
	root, e := (socialrelationstore.Store{}).EnsureRootTx(ctx, handle, 100001, f.now())
	if e != nil {
		t.Fatal(e)
	}
	inbox := socialinbox.RelationService{Store: socialinboxstore.Store{}}
	event := socialinbox.RelationTransition{Event: socialinbox.DenyRelationRequest, First: 100001, Second: 200001, Generation: 1, Actor: 200001, Recipient: 100001, At: at}
	plans, e := inbox.PrepareRelationsTx(ctx, handle, []socialinbox.RecipientFence{{PlayerID: 100001, StateVersion: root.StateVersion}}, []socialinbox.RelationTransition{event})
	if e != nil {
		t.Fatal(e)
	}
	view, exists := plans[0].ExistingNotice()
	if !exists || view.DismissedAt == nil {
		t.Fatal("missing dismissed view")
	}
	originalDismissal := *view.DismissedAt
	*view.DismissedAt = at.Add(time.Hour)
	got, e := inbox.ApplyRelationsTx(ctx, handle, plans)
	if e != nil || len(got) != 1 || got[0].Active || got[0].StateVersion != 2 || got[0].DismissedAt == nil || !got[0].DismissedAt.Equal(originalDismissal) {
		t.Fatalf("dismissed resurrection: %+v %v", got, e)
	}
	*got[0].DismissedAt = at.Add(2 * time.Hour)
	again, replayErr := inbox.ApplyRelationsTx(ctx, handle, plans)
	if replayErr != nil || len(again) != 1 || again[0].DismissedAt == nil || !again[0].DismissedAt.Equal(originalDismissal) {
		t.Fatal("returned notice mutation changed private replay plan", replayErr)
	}
	event.At = at.Add(time.Second)
	if _, e = inbox.PrepareRelationsTx(ctx, handle, []socialinbox.RecipientFence{{PlayerID: 100001, StateVersion: root.StateVersion}}, []socialinbox.RelationTransition{event}); !errors.Is(e, socialinbox.ErrRelationNoticeConflict) {
		t.Fatal("mismatch accepted", e)
	}
	handle.Rollback(ctx)
	if f.snapshot() != before {
		t.Fatal("source replay changed state")
	}
}

// faultBeginner injects loss of the COMMIT acknowledgement after the native
// transaction has either committed or definitely rolled back. Neither case
// changes what the caller is allowed to know from the ambiguous transport error.
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
	return errors.New("injected acknowledgement loss")
}
func setupCommand(f *fixture, k sr.CommandKind) (identity.PlayerID, []identity.PlayerID) {
	a, b := identity.PlayerID(100001), identity.PlayerID(200001)
	f.player(a)
	f.player(b)
	switch k {
	case sr.DenyRequests, sr.IgnoreRequests, sr.AcceptRequest, sr.AcceptAllRequests:
		f.ok(b, sr.RequestFriend, a)
	case sr.DeleteFriend:
		f.ok(b, sr.RequestFriend, a)
		f.ok(a, sr.AcceptRequest, b)
	case sr.RemoveBlock, sr.ClearBlocks:
		f.ok(a, sr.AddBlock, b)
	}
	if k == sr.ClearBlocks {
		return a, nil
	}
	return a, []identity.PlayerID{b}
}
func TestUnknownCommitEveryCommandNoReplayOrAttemptedResult(t *testing.T) {
	for _, k := range []sr.CommandKind{sr.RequestFriend, sr.DenyRequests, sr.IgnoreRequests, sr.AcceptRequest, sr.DeleteFriend, sr.AcceptAllRequests, sr.AddBlock, sr.RemoveBlock, sr.ClearBlocks} {
		for _, committed := range []bool{false, true} {
			t.Run(fmt.Sprintf("MID%d_nativeCommitted=%t", k, committed), func(t *testing.T) {
				f := fresh(t)
				a, targets := setupCommand(f, k)
				before := f.snapshot()
				fault := &faultBeginner{db: f.p, commit: committed}
				f.s.Timed.Runner.DB = fault
				r, e := f.runAs(a, k, targets...)
				var unknown *tx.UnknownCommitError
				if !errors.As(e, &unknown) || fault.begins != 1 || len(r.Changes) != 0 || len(r.Players.Players) != 0 {
					t.Fatalf("unknown leaked success/replayed: result%+v err%v begins%d", r, e, fault.begins)
				}
				after := f.snapshot()
				if committed == (before == after) {
					t.Fatal("native injected commit state mismatch")
				}
				f.s.Timed.Runner.DB = f.p
				r, e = f.runAs(a, k, targets...)
				if committed && k == sr.RequestFriend {
					stock(t, e, 20009)
				} else if e != nil {
					t.Fatalf("later stock retry: %v", e)
				} else if committed && !r.NoOp {
					t.Fatal("same-generation retry made new effect")
				}
				t.Log("native outcome inspected independently; unknown error supplied no commit proof or successor-intent authority")
			})
		}
	}
}

type retryBeginner struct {
	db     tx.Beginner
	begins int
}

func (f *retryBeginner) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	f.begins++
	v, e := f.db.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return &retryTx{Tx: v, first: f.begins == 1}, nil
}

type retryTx struct {
	tx.Tx
	first bool
}

func (f *retryTx) Commit(c context.Context) error {
	if f.first {
		if e := f.Tx.Rollback(c); e != nil {
			return e
		}
		return tx.MarkDefiniteAbort(errors.New("injected serialization abort"))
	}
	return f.Tx.Commit(c)
}

type countingTime struct {
	at    time.Time
	calls int
}

func (f *countingTime) Now(context.Context) (time.Time, error) { f.calls++; return f.at, nil }

type observingProjection struct {
	reader  playerpresentation.TxReader
	times   []time.Time
	handles []tx.Tx
}

func (f *observingProjection) ReadManyTx(c context.Context, t tx.Tx, p []identity.PlayerID) (playerpresentation.Batch, error) {
	v, e := f.reader.ReadManyTx(c, t, p)
	f.times = append(f.times, v.ObservedAt)
	f.handles = append(f.handles, t)
	return v, e
}
func TestDefiniteAbortRetryKeepsDecisionAndResamplesResponseOnly(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	clock := &countingTime{at: f.now()}
	retry := &retryBeginner{db: f.p}
	reader := &observingProjection{reader: f.s.Presentation}
	f.s.Timed.Binder.Time = clock
	f.s.Timed.Runner.DB = retry
	f.s.Presentation = reader
	f.ok(100001, sr.AddBlock, 200001)
	if clock.calls != 1 || retry.begins != 2 || len(reader.times) != 2 || !reader.times[1].After(reader.times[0]) || reader.handles[0] == reader.handles[1] {
		t.Fatalf("retry binding drift: clock%d attempts%d observations%v", clock.calls, retry.begins, reader.times)
	}
	var at time.Time
	if e := f.p.QueryRow(ctx, `SELECT activated_at FROM social_blocks`).Scan(&at); e != nil {
		t.Fatal(e)
	}
	if !at.Equal(clock.at) || f.number(`SELECT generation FROM social_blocks`) != 1 || f.number(`SELECT state_version FROM player_social_roots WHERE player_id=100001`) != 2 {
		t.Fatal("retry charged/retimed effect")
	}
}
func (f *fixture) root(p identity.PlayerID) {
	f.sql(`INSERT INTO player_social_roots(player_id,created_at,updated_at) VALUES($1,$2,$2) ON CONFLICT DO NOTHING`, int64(p), f.at)
}
func (f *fixture) friend(a, b identity.PlayerID) {
	f.root(a)
	f.root(b)
	if a > b {
		a, b = b, a
	}
	f.sql(`INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,updated_at) VALUES($1,$2,1,true,$3,$3)`, int64(a), int64(b), f.at)
}
func (f *fixture) capacity(a identity.PlayerID, n int) {
	for i := 0; i < n; i++ {
		p := identity.PlayerID(100010 + i)
		if p == a {
			panic("fixture overlap")
		}
		f.player(p)
		f.friend(a, p)
	}
}
func TestAcceptAllFirstBusinessWinnerAtCapacity(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 200001, 200002} {
		f.player(p)
	}
	f.capacity(100001, 79)
	f.ok(200001, sr.RequestFriend, 100001)
	f.ok(200002, sr.RequestFriend, 100001)
	r := f.ok(100001, sr.AcceptAllRequests, 200002, 200001, 200002, 100001, 299999)
	if len(r.Players.Players) != 1 || r.Players.Players[200002].Minimal.PlayerID != 200002 || f.text(`SELECT status FROM social_friend_requests WHERE requester_player_id=200001`) != "PENDING" || f.number(`SELECT count(*) FROM social_friendships WHERE active AND player_low_id=100001`) != 80 {
		t.Fatal("capacity winner did not preserve first business occurrence")
	}
	before := f.snapshot()
	_, e := f.runAs(100001, sr.AcceptRequest, 200001)
	stock(t, e, 20012)
	if f.snapshot() != before {
		t.Fatal("full capacity single accept changed state")
	}
}
func TestCounterOverflowIsAtomic(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.ok(100001, sr.RequestFriend, 200001)
	f.sql(`UPDATE player_social_roots SET state_version=9223372036854775807 WHERE player_id=200001`)
	before := f.snapshot()
	_, e := f.runAs(200001, sr.AcceptRequest, 100001)
	if !errors.Is(e, sr.ErrCounterOverflow) || f.snapshot() != before {
		t.Fatal("overflow applied command", e)
	}
}
func TestEpochBoundaryQuotaAndRegression(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 200001, 200002, 200003} {
		f.player(p)
	}
	beforeMidnight := time.Date(2026, 10, 6, 15, 59, 59, 0, time.UTC)
	f.sql(`UPDATE accounts SET created_at=$1`, beforeMidnight.Add(-time.Hour))
	f.s.Timed.Binder.Time = fixedTime{beforeMidnight}
	f.ok(100001, sr.RequestFriend, 200001)
	day := f.number(`SELECT epoch_generation FROM social_request_epochs`)
	f.s.Timed.Binder.Time = fixedTime{beforeMidnight.Add(time.Second)}
	f.ok(100001, sr.RequestFriend, 200002)
	if f.number(`SELECT epoch_generation FROM social_request_epochs`) != day+1 || f.number(`SELECT successful_new_requests FROM social_request_epochs`) != 1 {
		t.Fatal("GMT+8 midnight did not roll quota")
	}
	before := f.snapshot()
	f.s.Timed.Binder.Time = fixedTime{beforeMidnight}
	_, e := f.runAs(100001, sr.RequestFriend, 200003)
	if !errors.Is(e, sr.ErrStaleDecisionTime) || f.snapshot() != before {
		t.Fatal("clock regression reopened quota", e)
	}
}

type failingInbox struct {
	socialinbox.RelationMaterializer
}

func (f failingInbox) ApplyRelationsTx(context.Context, tx.Tx, []socialinbox.PreparedRelationNotice) ([]socialinbox.Notice, error) {
	return nil, errors.New("injected inbox failure after relation effects")
}
func TestLateInboxFailureRollsBackRelationsRootsAndResponses(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 100002, 200001} {
		f.player(p)
	}
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(100002, sr.RequestFriend, 200001)
	before := f.snapshot()
	f.s.Inbox = failingInbox{f.s.Inbox}
	r, e := f.runAs(200001, sr.AcceptAllRequests, 100001, 100002)
	if e == nil || len(r.Players.Players) != 0 || len(r.Changes) != 0 || f.snapshot() != before {
		t.Fatal("late inbox error leaked result/state", e)
	}
}
func TestExistingNoticeSourceConflictAbortsWholeBatch(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 100002, 200001} {
		f.player(p)
	}
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(100002, sr.RequestFriend, 200001)
	f.sql(`INSERT INTO social_notices(recipient_player_id,notice_type,source_kind,source_key,related_player_id,active,notice_time,state_version,created_at,updated_at) VALUES(100002,2,'social-relation.request.v1','100002:200001:1:ACCEPT',200001,true,$1,1,$1,$1)`, f.now())
	before := f.snapshot()
	_, e := f.runAs(200001, sr.AcceptAllRequests, 100001, 100002)
	if !errors.Is(e, socialinbox.ErrRelationNoticeConflict) || f.snapshot() != before {
		t.Fatal("source conflict did not atomically abort batch", e)
	}
}

type barrierBeginner struct {
	db    tx.Beginner
	ready chan struct{}
	n     atomic.Int32
}

func (b *barrierBeginner) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	v, e := b.db.Begin(c, o)
	if e != nil {
		return nil, e
	}
	if b.n.Add(1) == 2 {
		close(b.ready)
	}
	select {
	case <-b.ready:
		return v, nil
	case <-c.Done():
		v.Rollback(context.WithoutCancel(c))
		return nil, c.Err()
	}
}

type commandCall struct {
	actor   identity.PlayerID
	kind    sr.CommandKind
	targets []identity.PlayerID
}

func (f *fixture) race(a, b commandCall) []error {
	f.t.Helper()
	barrier := &barrierBeginner{db: f.p, ready: make(chan struct{})}
	f.s.Timed.Runner.DB = barrier
	var wg sync.WaitGroup
	errlist := make([]error, 2)
	for i, c := range []commandCall{a, b} {
		wg.Add(1)
		go func(i int, c commandCall) { defer wg.Done(); _, errlist[i] = f.runAs(c.actor, c.kind, c.targets...) }(i, c)
	}
	wg.Wait()
	f.s.Timed.Runner.DB = f.p
	return errlist
}
func allowedConcurrent(t *testing.T, err error) {
	t.Helper()
	if err == nil || errors.Is(err, sr.ErrStaleDecisionTime) || errors.Is(err, sr.ErrNotEligible) || tx.IsDefiniteAbortError(err) {
		return
	}
	var stock *sr.StockError
	if errors.As(err, &stock) && (stock.Code == 20012 || stock.Code == 20014) {
		return
	}
	t.Fatalf("unexpected concurrent failure: %v", err)
}
func TestConcurrentAcceptBlockAndTerminalRaces(t *testing.T) {
	for _, other := range []sr.CommandKind{sr.AddBlock, sr.DenyRequests, sr.IgnoreRequests} {
		for run := 0; run < 4; run++ {
			t.Run(fmt.Sprintf("otherMID%d_run%d", other, run), func(t *testing.T) {
				f := fresh(t)
				a, b := identity.PlayerID(100001), identity.PlayerID(200001)
				f.player(a)
				f.player(b)
				f.ok(b, sr.RequestFriend, a)
				errs := f.race(commandCall{a, sr.AcceptRequest, []identity.PlayerID{b}}, commandCall{a, other, []identity.PlayerID{b}})
				for _, e := range errs {
					allowedConcurrent(t, e)
				}
				status := f.text(`SELECT status FROM social_friend_requests`)
				active := f.number(`SELECT count(*) FROM social_friendships WHERE active`)
				notices := f.number(`SELECT count(*) FROM social_notices`)
				blocks := f.number(`SELECT count(*) FROM social_blocks WHERE active`)
				if status == "ACCEPTED" {
					if active != 1 || notices != 1 {
						t.Fatal("accepted race lost canonical composition")
					}
				} else if active != 0 {
					t.Fatal("friendship without accepted request")
				}
				if other == sr.AddBlock {
					if blocks == 1 && status == "ACCEPTED" {
						t.Log("accept serialized before block, selected coexistence")
					}
					if status != "PENDING" && status != "ACCEPTED" {
						t.Fatal("unexpected request transition")
					}
				} else if status == "DENIED" {
					if notices != 1 || blocks != 0 {
						t.Fatal("denied composition")
					}
				} else if status == "IGNORED" {
					if notices != 0 || blocks != 1 {
						t.Fatal("ignored composition")
					}
				} else if status != "ACCEPTED" {
					t.Fatal("neither terminal command committed")
				}
				if f.number(`SELECT count(*) FROM social_notices WHERE notice_type=1`)+f.number(`SELECT count(*) FROM social_notices WHERE notice_type=2`) > 1 {
					t.Fatal("competing terminal sources duplicated")
				}
			})
		}
	}
}
func TestConcurrentCapacityAndOppositeDelete(t *testing.T) {
	f := fresh(t)
	a, b, c := identity.PlayerID(100001), identity.PlayerID(200001), identity.PlayerID(200002)
	for _, p := range []identity.PlayerID{a, b, c} {
		f.player(p)
	}
	f.capacity(a, 79)
	f.ok(b, sr.RequestFriend, a)
	f.ok(c, sr.RequestFriend, a)
	errs := f.race(commandCall{a, sr.AcceptRequest, []identity.PlayerID{b}}, commandCall{a, sr.AcceptRequest, []identity.PlayerID{c}})
	for _, e := range errs {
		allowedConcurrent(t, e)
	}
	if f.number(`SELECT count(*) FROM social_friendships WHERE active AND player_low_id=100001`) != 80 || f.number(`SELECT count(*) FROM social_friend_requests WHERE status='ACCEPTED'`) != 1 || f.number(`SELECT count(*) FROM social_notices`) != 1 {
		t.Fatal("capacity overbooked or terminal duplicated")
	}
	winner := b
	if f.text(`SELECT status FROM social_friend_requests WHERE requester_player_id=200001`) != "ACCEPTED" {
		winner = c
	}
	errs = f.race(commandCall{a, sr.DeleteFriend, []identity.PlayerID{winner}}, commandCall{winner, sr.DeleteFriend, []identity.PlayerID{a}})
	for _, e := range errs {
		allowedConcurrent(t, e)
	}
	if f.number(`SELECT count(*) FROM social_notices WHERE notice_type=3`) != 1 {
		t.Fatal("opposite delete produced duplicate sources")
	}
}
func TestConcurrentClearAddLegalSerialState(t *testing.T) {
	for run := 0; run < 4; run++ {
		t.Run(fmt.Sprint(run), func(t *testing.T) {
			f := fresh(t)
			for _, p := range []identity.PlayerID{100001, 200001, 200002} {
				f.player(p)
			}
			f.ok(100001, sr.AddBlock, 200001)
			errs := f.race(commandCall{100001, sr.ClearBlocks, nil}, commandCall{100001, sr.AddBlock, []identity.PlayerID{200002}})
			for _, e := range errs {
				allowedConcurrent(t, e)
			}
			if errs[0] == nil && f.number(`SELECT count(*) FROM social_blocks WHERE blocked_player_id=200001 AND active`) != 0 {
				t.Fatal("clear did not remove pre-existing block")
			}
			if f.number(`SELECT count(*) FROM social_blocks WHERE active`) > 2 {
				t.Fatal("invalid dynamic set")
			}
			if errs[0] != nil && errs[1] != nil {
				t.Fatal("no command committed")
			}
		})
	}
}

type queryTrace struct {
	query string
	args  []any
}
type traceBeginner struct {
	db     tx.Beginner
	traces []*traceTx
}

func (b *traceBeginner) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	v, e := b.db.Begin(c, o)
	if e != nil {
		return nil, e
	}
	t := &traceTx{Tx: v}
	b.traces = append(b.traces, t)
	return t, nil
}

type traceTx struct {
	tx.Tx
	events []queryTrace
}

func (t *traceTx) QueryRow(c context.Context, q string, args ...any) tx.Row {
	t.events = append(t.events, queryTrace{q, append([]any(nil), args...)})
	return t.Tx.QueryRow(c, q, args...)
}
func (t *traceTx) Exec(c context.Context, q string, args ...any) (tx.CommandTag, error) {
	t.events = append(t.events, queryTrace{q, append([]any(nil), args...)})
	return t.Tx.Exec(c, q, args...)
}
func TestDynamicChildLocksAndSourcesBeforeEffectsAndCallerTxReaders(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 200001, 1000001} {
		f.player(p)
	}
	f.ok(100001, sr.AddBlock, 200001)
	f.ok(100001, sr.AddBlock, 1000001)
	trace := &traceBeginner{db: f.p}
	f.s.Timed.Runner.DB = trace
	f.ok(100001, sr.ClearBlocks)
	if len(trace.traces) != 1 {
		t.Fatal("unexpected attempts")
	}
	var locked []int64
	effects := false
	for _, e := range trace.traces[0].events {
		if strings.Contains(e.query, "UPDATE player_social_roots") {
			effects = true
		}
		if strings.Contains(e.query, "FROM social_blocks") && strings.Contains(e.query, "FOR UPDATE") {
			if effects {
				t.Fatal("child lock after effects")
			}
			locked = append(locked, e.args[1].(int64))
		}
	}
	if len(locked) != 2 || locked[0] != 1000001 || locked[1] != 200001 {
		t.Fatalf("dynamic locks sorted by SQL numeric enumeration: %v", locked)
	}
	f.s.Timed.Runner.DB = f.p
	f.ok(200001, sr.RequestFriend, 100001)
	f.ok(1000001, sr.RequestFriend, 100001)
	trace = &traceBeginner{db: f.p}
	f.s.Timed.Runner.DB = trace
	f.ok(100001, sr.AcceptAllRequests, 200001, 1000001)
	events := trace.traces[0].events
	effects = false
	var sourceKeys []lockkey.Key
	observations := 0
	types := 0
	presence := 0
	var roots []int64
	for _, e := range events {
		q := e.query
		if strings.Contains(q, "UPDATE player_social_roots") {
			effects = true
		}
		if q == "SELECT clock_timestamp()" {
			observations++
		}
		if strings.Contains(q, "FROM player_profiles") {
			types++
		}
		if strings.Contains(q, "realtime_presence_leases") && !strings.Contains(q, "FOR UPDATE") {
			presence++
		}
		if strings.Contains(q, "FROM players WHERE player_id=") && strings.Contains(q, "FOR UPDATE") {
			roots = append(roots, e.args[0].(int64))
		}
		if strings.Contains(q, "FROM social_notices") && strings.Contains(q, "FOR UPDATE") {
			if effects {
				t.Fatal("source lock after effects")
			}
			k, e2 := socialinbox.NoticeSourceLockKey(identity.PlayerID(e.args[0].(int64)), socialinbox.SourceKey{Kind: e.args[1].(string), Key: e.args[2].(string)})
			if e2 != nil {
				t.Fatal(e2)
			}
			sourceKeys = append(sourceKeys, k)
		}
	}
	if len(sourceKeys) != 2 || lockkey.Compare(sourceKeys[0], sourceKeys[1]) >= 0 || observations != 1 || types != 2 || presence != 1 || fmt.Sprint(roots) != "[100001 200001 1000001]" {
		t.Fatalf("callerTx/order evidence: source%v observation%d type%d presence%d roots%v", sourceKeys, observations, types, presence, roots)
	}
	t.Log("Recorded exact caller transaction SQL: numeric I4 root order, actual string child/source Compare order, one response observation, owner readers before effects")
}

func TestRecoverySeed(t *testing.T) {
	record := os.Getenv("GXB_I7A4B_RECOVERY_RECORD")
	if record == "" {
		t.Skip("standalone restart/restore harness supplies record path")
	}
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 100002, 100003, 100004, 100005, 200001} {
		f.player(p)
	}
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(200001, sr.AcceptRequest, 100001)
	f.ok(200001, sr.DeleteFriend, 100001)
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(200001, sr.AcceptRequest, 100001)
	f.ok(100002, sr.RequestFriend, 200001)
	f.ok(200001, sr.AcceptRequest, 100002)
	f.ok(200001, sr.DeleteFriend, 100002)
	f.ok(100003, sr.RequestFriend, 200001)
	f.ok(200001, sr.DenyRequests, 100003)
	f.ok(100004, sr.RequestFriend, 200001)
	f.ok(200001, sr.IgnoreRequests, 100004)
	f.ok(100005, sr.RequestFriend, 200001)
	f.ok(200001, sr.AddBlock, 100001)
	f.ok(200001, sr.RemoveBlock, 100001)
	f.sql(`UPDATE social_notices SET active=false,dismissed_at=notice_time,state_version=2,updated_at=notice_time WHERE notice_id=(SELECT min(notice_id) FROM social_notices)`)
	if e := os.WriteFile(record, []byte(f.snapshot()), 0644); e != nil {
		t.Fatal(e)
	}
	if e := os.WriteFile(record+".sequence", []byte(fmt.Sprint(f.number(`SELECT last_value FROM social_notice_id_seq`))), 0644); e != nil {
		t.Fatal(e)
	}
	t.Log("Seeded active and tombstone friendships, pending/terminal requests, active/inactive blocks, source generations, one dismissed notice, request epochs and exact sequence head")
}
func TestRecoveryReadOnlyReplayProof(t *testing.T) {
	record := os.Getenv("GXB_I7A4B_RECOVERY_RECORD")
	if record == "" {
		t.Skip("standalone restart/restore harness supplies record path")
	}
	f := existing(t)
	want, e := os.ReadFile(record)
	if e != nil {
		t.Fatal(e)
	}
	seq, e := os.ReadFile(record + ".sequence")
	if e != nil {
		t.Fatal(e)
	}
	if f.snapshot() != string(want) || fmt.Sprint(f.number(`SELECT last_value FROM social_notice_id_seq`)) != string(seq) {
		t.Fatal("restart/restore changed canonical facts or source allocator")
	}
	before := f.snapshot()
	if !f.ok(200001, sr.AcceptRequest, 100001).NoOp || !f.ok(200001, sr.AddBlock, 100004).NoOp || !f.ok(200001, sr.DeleteFriend, 100002).NoOp {
		t.Fatal("retained state did not converge")
	}
	if f.snapshot() != before || fmt.Sprint(f.number(`SELECT last_value FROM social_notice_id_seq`)) != string(seq) {
		t.Fatal("replay regenerated source facts")
	}
	t.Log("Exact canonical state and allocator survived; canonical owner presentation works and replay creates no new source/time/generation")
}

type mismatchingRoots struct{ inner playerroot.TxLocker }

func (m mismatchingRoots) LockPlayerRootsTx(c context.Context, t tx.Tx, s identity.LogicalServerID, p []identity.PlayerID) ([]playerroot.Root, error) {
	r, e := m.inner.LockPlayerRootsTx(c, t, s, p)
	if e == nil && len(r) > 0 {
		r[0].LogicalServerID++
	}
	return r, e
}
func TestParticipantBindingAndAbsentPolicies(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	before := f.snapshot()
	f.s.PlayerRoots = mismatchingRoots{f.s.PlayerRoots}
	_, e := f.runAs(100001, sr.AddBlock, 200001)
	if !errors.Is(e, sr.ErrStateConflict) || f.snapshot() != before {
		t.Fatal("incorrect returned root binding accepted", e)
	}
	f.s.PlayerRoots = i4store.PlayerRootLocker{}
	_, e = f.runAs(199999, sr.RequestFriend, 200001)
	if !errors.Is(e, playerroot.ErrPlayerRootNotFound) || f.snapshot() != before {
		t.Fatal("absent actor accepted", e)
	}
	for _, k := range []sr.CommandKind{sr.DeleteFriend, sr.RemoveBlock} {
		f.ok(100001, k, 299999)
	}
	_, e = f.runAs(100001, sr.AcceptRequest, 299999)
	if !errors.Is(e, sr.ErrNotEligible) {
		t.Fatal("absent accept", e)
	}
	_, e = f.runAs(100001, sr.AddBlock, 299999)
	stock(t, e, 20004)
	before = f.snapshot()
	for _, p := range []identity.PlayerID{0, 99999, 214748364800000, 9223372036854775807} {
		_, e = f.runAs(100001, sr.DenyRequests, 200001, p)
		if !errors.Is(e, sr.ErrInvalidCommand) || f.snapshot() != before {
			t.Fatal("malformed/overflow quotient accepted", p, e)
		}
	}
}
func TestRequestMessageUnicodeBoundAndPolicyDrift(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	u, _ := ids.NewUUID()
	op := operation.Context{ID: u, StartedAt: f.now()}
	before := f.snapshot()
	drift := op
	drift.Policies, _ = policy.NewSet(policy.Ref{Name: "social.relation", Version: "unqualified-source"})
	_, driftErr := f.s.Execute(ctx, actor(100001), sr.Command{Kind: sr.RequestFriend, Targets: []identity.PlayerID{200001}}, drift)
	if !errors.Is(driftErr, sr.ErrPolicyDrift) || f.snapshot() != before {
		t.Fatal("policy drift accepted", driftErr)
	}
	for _, message := range []string{strings.Repeat("女", 27), string([]byte{0xff})} {
		_, e := f.s.Execute(ctx, actor(100001), sr.Command{Kind: sr.RequestFriend, Targets: []identity.PlayerID{200001}, Message: message}, op)
		if !errors.Is(e, sr.ErrInvalidCommand) || f.snapshot() != before {
			t.Fatal("invalid message changed state", e)
		}
	}
	_, e := f.s.Execute(ctx, actor(100001), sr.Command{Kind: sr.RequestFriend, Targets: []identity.PlayerID{200001}, Message: strings.Repeat("女", 26)}, op)
	if e != nil || f.text(`SELECT request_msg FROM social_friend_requests`) != strings.Repeat("女", 26) {
		t.Fatal("valid unicode bound", e)
	}
}
func TestRequestBlocksAndBothCapacityErrors(t *testing.T) {
	t.Run("either block", func(t *testing.T) {
		f := fresh(t)
		f.player(100001)
		f.player(200001)
		f.ok(200001, sr.AddBlock, 100001)
		before := f.snapshot()
		_, e := f.runAs(100001, sr.RequestFriend, 200001)
		if !errors.Is(e, sr.ErrNotEligible) || f.snapshot() != before {
			t.Fatal("reverse block ignored", e)
		}
	})
	for _, full := range []identity.PlayerID{100001, 200001} {
		t.Run(fmt.Sprint(full), func(t *testing.T) {
			f := fresh(t)
			f.player(100001)
			f.player(200001)
			f.capacity(full, 80)
			before := f.snapshot()
			_, e := f.runAs(100001, sr.RequestFriend, 200001)
			code := int64(20012)
			if full == 200001 {
				code = 20014
			}
			stock(t, e, code)
			if f.snapshot() != before {
				t.Fatal("rejected cap charged request")
			}
		})
	}
}

func TestNoticeInsertFailureAllowsSequenceGapButNoCanonicalEffect(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.ok(100001, sr.RequestFriend, 200001)
	before := f.snapshot()
	seq := f.number(`SELECT last_value FROM social_notice_id_seq`)
	// nextval is nontransactional; the AFTER trigger proves a failure after allocation.
	f.sql(`CREATE FUNCTION i7a4b_reject_notice() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'injected notice insert failure'; END $$`)
	f.sql(`CREATE TRIGGER i7a4b_reject_notice AFTER INSERT ON social_notices FOR EACH ROW EXECUTE FUNCTION i7a4b_reject_notice()`)
	defer func() {
		f.sql(`DROP TRIGGER i7a4b_reject_notice ON social_notices`)
		f.sql(`DROP FUNCTION i7a4b_reject_notice()`)
	}()
	r, e := f.runAs(200001, sr.AcceptRequest, 100001)
	if e == nil || len(r.Players.Players) != 0 || len(r.Changes) != 0 || f.snapshot() != before {
		t.Fatal("native failed insertion leaked facts", e)
	}
	var called bool
	if e := f.p.QueryRow(ctx, `SELECT is_called FROM social_notice_id_seq`).Scan(&called); e != nil {
		t.Fatal(e)
	}
	if !called || f.number(`SELECT last_value FROM social_notice_id_seq`) < seq {
		t.Fatal("sequence allocation was not observed")
	}
	t.Log("Native AFTER INSERT failure consumed allocator state and rolled back every canonical relation/request/root/notice; sequence gaps carry no semantic fact")
}
