//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"reflect"
	"sync"
	"testing"
)

type orderedLocker struct {
	mu    sync.Mutex
	last  map[tx.Tx]identity.PlayerID
	calls int
}

func (o *orderedLocker) LockPlayerRootsTx(c context.Context, t tx.Tx, s identity.LogicalServerID, p []identity.PlayerID) ([]playerroot.Root, error) {
	o.mu.Lock()
	if len(p) != 1 || p[0] <= o.last[t] {
		o.mu.Unlock()
		return nil, fmt.Errorf("315 global PID ordering violation %v", p)
	}
	canonical, e := sr.CanonicalServer(p[0])
	if e != nil || canonical != s {
		o.mu.Unlock()
		return nil, fmt.Errorf("315 canonical server mismatch")
	}
	o.last[t] = p[0]
	o.calls++
	o.mu.Unlock()
	return (i4store.PlayerRootLocker{}).LockPlayerRootsTx(c, t, s, p)
}
func TestD10OneHundredNativeThreeServerInterleavedBatches(t *testing.T) {
	calls := 0
	staleConflicts := 0
	for i := 0; i < 100; i++ {
		f := fresh(t)
		a, b, c, d := identity.PlayerID(300001), identity.PlayerID(200001), identity.PlayerID(100001), identity.PlayerID(300002)
		for _, p := range []identity.PlayerID{a, b, c, d} {
			f.player(p)
		}
		recorder := &orderedLocker{last: map[tx.Tx]identity.PlayerID{}}
		f.s.PlayerRoots = recorder
		run := func(p identity.PlayerID, k sr.CommandKind, targets ...identity.PlayerID) error {
			_, e := f.runAs(p, k, targets...)
			if errors.Is(e, sr.ErrStaleDecisionTime) {
				recorder.mu.Lock()
				staleConflicts++
				recorder.mu.Unlock()
				_, e = f.runAs(p, k, targets...)
			}
			return e
		}
		errs := make(chan error, 2)
		var wg sync.WaitGroup
		for _, p := range []identity.PlayerID{a, c} {
			wg.Add(1)
			go func(p identity.PlayerID) { defer wg.Done(); e := run(p, sr.RequestFriend, b); errs <- e }(p)
		}
		wg.Wait()
		for j := 0; j < 2; j++ {
			if e := <-errs; e != nil {
				t.Fatalf("iteration%d request:%v", i, e)
			}
		}
		wg.Add(2)
		go func() { defer wg.Done(); e := run(b, sr.AcceptAllRequests, a, c, a); errs <- e }()
		go func() { defer wg.Done(); e := run(d, sr.AddBlock, b); errs <- e }()
		wg.Wait()
		for j := 0; j < 2; j++ {
			if e := <-errs; e != nil {
				t.Fatalf("iteration%d batch:%v", i, e)
			}
		}
		if f.number(`SELECT count(*) FROM social_friendships WHERE active`) != 2 || f.number(`SELECT count(*) FROM social_blocks WHERE active`) != 1 || f.number(`SELECT count(*) FROM social_friend_requests WHERE status='ACCEPTED'`) != 2 {
			t.Fatal("noncanonical stress outcome", i)
		}
		calls += recorder.calls
		f.p.Close()
	}
	t.Logf("REAL_PG 100iterations,3canonicalservers,overlappingrequest/acceptall/blockbatches,315globalPIDascending+perPIDserverbinding asserted %dlockcalls; engineeringqualification only", calls)
	t.Logf("%d staleDecision conflicts resolved by a separate later stock operation; bound operation time never resampled inside retry", staleConflicts)
}

type ambiguousBeginner struct {
	db     tx.Beginner
	commit bool
	begins int
}

func (a *ambiguousBeginner) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	a.begins++
	t, e := a.db.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return ambiguousTx{Tx: t, commit: a.commit}, nil
}

type ambiguousTx struct {
	tx.Tx
	commit bool
}

func (a ambiguousTx) Commit(c context.Context) error {
	var e error
	if a.commit {
		e = a.Tx.Commit(c)
	} else {
		e = a.Tx.Rollback(c)
	}
	if e != nil {
		return e
	}
	return errors.New("qualified injected lost commit acknowledgement")
}
func TestD11DismissUnknownCommitNoOutputNoReplayCanonicalRecovery(t *testing.T) {
	for _, committed := range []bool{false, true} {
		t.Run(fmt.Sprint(committed), func(t *testing.T) {
			f := fresh(t)
			f.player(100001)
			f.player(200001)
			f.relationNotices(1)
			s := f.dismiss()
			fault := &ambiguousBeginner{db: f.p, commit: committed}
			s.Timed.Runner.DB = fault
			ids, e := s.Dismiss(ctx, actor(100001), []socialinbox.NoticeID{1}, f.op())
			var unknown *tx.UnknownCommitError
			if !errors.As(e, &unknown) || ids != nil || fault.begins != 1 {
				t.Fatal("unknown commit replay/output", ids, e, fault.begins)
			}
			active := f.number(`SELECT count(*) FROM social_notices WHERE active`)
			if committed == (active == 1) {
				t.Fatal("native outcome fixture mismatch")
			}
			before := f.snapshot()
			ids, e = f.dismiss().Dismiss(ctx, actor(100001), []socialinbox.NoticeID{1}, f.op())
			if e != nil || !reflect.DeepEqual(ids, []socialinbox.NoticeID{1}) {
				t.Fatal("canonical retry", e)
			}
			if committed && f.snapshot() != before {
				t.Fatal("repeat native effect")
			}
			_ = f.base()
			f.v.LoadList(ctx, actor(100001), sp.Friend, f.op())
			t.Log("Real native commit/rollback with acknowledgement-loss injection; no physical transport partition claimed")
		})
	}
}
func ownerSnapshot(f *fixture) string {
	return f.text(`SELECT jsonb_build_object('accounts',(SELECT jsonb_agg(to_jsonb(t)ORDER BY account_uid)FROM accounts t),'players',(SELECT jsonb_agg(to_jsonb(t)ORDER BY player_id)FROM players t),'profiles',(SELECT jsonb_agg(to_jsonb(t)ORDER BY player_id)FROM player_profiles t),'directory',(SELECT jsonb_agg(to_jsonb(t)ORDER BY player_id)FROM player_directory_profiles t),'sessions',(SELECT jsonb_agg(to_jsonb(t)ORDER BY session_id)FROM account_sessions t),'contexts',(SELECT jsonb_agg(to_jsonb(t)ORDER BY context_id)FROM gameplay_contexts t),'credentials',(SELECT jsonb_agg(to_jsonb(t)ORDER BY credential_id)FROM gameplay_context_credentials t),'presence',(SELECT jsonb_agg(to_jsonb(t)ORDER BY player_id)FROM player_social_presence t),'leases',(SELECT jsonb_agg(to_jsonb(t)ORDER BY gameplay_context_id)FROM realtime_presence_leases t),'owner',(SELECT jsonb_agg(to_jsonb(t))FROM realtime_presence_owner_state t),'fence',(SELECT row_to_json(q) FROM (SELECT last_value,is_called FROM realtime_presence_owner_fence_seq) q))::text`)
}
func TestD12UpgradePopulated32Seed(t *testing.T) {
	if os.Getenv("GXB_I7A4D_MODE") != "upgrade_seed" {
		t.Skip("explicit 00032seed only")
	}
	f := existing(t)
	f.legacyPlayer(100001)
	f.legacyPlayer(200001)
	a, _ := f.live(100001)
	f.sql(`INSERT INTO player_social_presence(player_id,last_seen_at,created_at,updated_at)VALUES(100001,$1,$1,$1)`, f.at)
	f.sql(`INSERT INTO realtime_presence_owner_state(singleton,owner_fence,activated_at)VALUES(true,1,$1)`, f.at)
	f.sql(`SELECT setval('realtime_presence_owner_fence_seq',1,true)`)
	f.sql(`INSERT INTO realtime_presence_leases(gameplay_context_id,physical_role,player_id,realtime_instance_id,connection_generation,connected_at,last_renewed_at,lease_expires_at,realtime_owner_fence)VALUES($1::uuid,'WORLD',100001,gen_random_uuid(),1,$2::timestamptz,$2::timestamptz,$2::timestamptz+interval '1 hour',1)`, a.ContextID.UUID().String(), f.at)
	if e := os.WriteFile(os.Getenv("GXB_I7A4D_EXPECTED"), []byte(ownerSnapshot(f)), 0600); e != nil {
		t.Fatal(e)
	}
}
func TestD12UpgradePopulated32Compare(t *testing.T) {
	if os.Getenv("GXB_I7A4D_MODE") != "upgrade_compare" {
		t.Skip("explicit 00033compare only")
	}
	f := existing(t)
	b, e := os.ReadFile(os.Getenv("GXB_I7A4D_EXPECTED"))
	if e != nil || string(b) != ownerSnapshot(f) {
		t.Fatal("preexisting owner/presence data changed", e)
	}
	if f.number(`SELECT (SELECT count(*)FROM player_social_roots)+(SELECT count(*)FROM social_friend_requests)+(SELECT count(*)FROM social_friendships)+(SELECT count(*)FROM social_blocks)+(SELECT count(*)FROM social_notices)+(SELECT count(*)FROM social_request_epochs)`) != 0 {
		t.Fatal("synthetic social history")
	}
	if f.number(`SELECT count(*) FROM pg_indexes WHERE tablename='player_directory_profiles' AND indexdef LIKE '%COLLATE%'`) < 1 {
		t.Fatal("directory index missing")
	}
	t.Log("REAL_PG populated00032->Goose00033 preserved I4/presence/lease/fence rows exactly andemptySocial")
}
