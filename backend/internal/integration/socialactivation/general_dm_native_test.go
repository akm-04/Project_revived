//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/generaldmbindings"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/generaldmstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	gen "gxb.local/backend/v2/internal/application/generation"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"net/http/httptest"
	"os"
	"reflect"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func (f *fixture) general() dm.Service {
	return dm.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: f.p}}, Runner: tx.Runner{DB: f.p}}, Queryer: f.p, Store: generaldmstore.Store{}, Bindings: generaldmbindings.Reader{}, Privacy: sr.GeneralDMPrivacyProvider{Store: socialrelationstore.Store{}}, Players: i4store.PlayerRootLocker{}, Presentation: socialpresentation.TransactionReader{}, Observer: socialpresentation.TransactionReader{}, Owner: presencestore.Store{Queryer: f.p}}
}
func generalPair(t *testing.T) (*fixture, dm.Service, int64) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	a, _ := f.live(200001)
	u, _ := ids.NewUUID()
	f.sql(`INSERT INTO player_social_presence(player_id,state_version,created_at,updated_at) VALUES($1,1,$2,$2)`, int64(a.PlayerID), f.now())
	f.sql(`INSERT INTO realtime_presence_leases(gameplay_context_id,player_id,physical_role,realtime_instance_id,connection_generation,realtime_owner_fence,connected_at,lease_expires_at,last_renewed_at)VALUES($1::uuid,$2,'WORLD',$3::uuid,1,$4,$5,$6,$5)`, a.ContextID.UUID().String(), int64(a.PlayerID), u.String(), fence, f.now(), f.now().Add(time.Minute))
	return f, f.general(), fence
}
func generalAccept(t *testing.T, f *fixture, s dm.Service) dm.Intent {
	t.Helper()
	i, e := s.Accept(ctx, 100001, 200001, "preserved text", f.op())
	if e != nil {
		t.Fatal(e)
	}
	return i
}
func generalAttempt(t *testing.T, f *fixture, s dm.Service, fence int64, i dm.Intent) dm.Intent {
	t.Helper()
	j, ok, e := s.Claim(ctx, i.ID, fence, f.op())
	if e != nil || !ok {
		t.Fatal(j, ok, e)
	}
	j, e = s.BeginAttempt(ctx, j, f.op())
	if e != nil || j.Status != dm.Attempting {
		t.Fatal(j, e)
	}
	return j
}
func Test6B_G06_G07_G14_G15_G16_G19_G20KnownNonfriendAndOrderedPlan(t *testing.T) {
	f, s, fence := generalPair(t)
	w := &dmLockTrace{t: t}
	s.Players = dmPlayerTrace{TxLocker: s.Players, w: w}
	s.Privacy = sr.GeneralDMPrivacyProvider{Store: dmRelationTrace{Store: socialrelationstore.Store{}, w: w}}
	s.Store = generalStoreTrace{Store: s.Store, w: w}
	op := f.op()
	i, e := s.Accept(ctx, 100001, 200001, "preserved text", op)
	if e != nil {
		t.Fatal(e)
	}
	ranks := []uint16{315, 315, 360, 360, 363, 381}
	if len(w.keys) != len(ranks) {
		t.Fatal(w.keys)
	}
	for n, k := range w.keys {
		if k.DomainRank != ranks[n] {
			t.Fatal(w.keys)
		}
	}
	s = f.general()
	j, e := s.Accept(ctx, 100001, 200001, "preserved text", op)
	if e != nil || !reflect.DeepEqual(i, j) {
		t.Fatal("known receipt", i, j, e)
	}
	if _, e = s.Accept(ctx, 100001, 200001, "collision", op); e == nil {
		t.Fatal("digest collision")
	}
	generalAccept(t, f, s)
	if f.number(`SELECT count(*) FROM personal_dm_intents`) != 2 || f.number(`SELECT count(*) FROM player_social_roots`) != 0 || f.number(`SELECT count(*) FROM friend_dm_occurrences`) != 0 {
		t.Fatal("owner boundary/absent roots")
	}
	if i.SenderName != "100001" || i.SenderAvatarID != 110001001 || i.Bindings[0].SessionID == "" || i.Bindings[0].ContextGeneration != 1 {
		t.Fatal("canonical presentation/identity", i)
	}
	if _, e = s.Accept(ctx, 100001, 100001, "self", f.op()); e == nil {
		t.Fatal("self accepted")
	}
	w = &dmLockTrace{t: t}
	s.Players = dmPlayerTrace{TxLocker: s.Players, w: w}
	s.Privacy = sr.GeneralDMPrivacyProvider{Store: dmRelationTrace{Store: socialrelationstore.Store{}, w: w}}
	s.Store = generalStoreTrace{Store: s.Store, w: w}
	if _, ok, e := s.Claim(ctx, i.ID, fence, f.op()); e != nil || !ok {
		t.Fatal(e)
	}
	if len(w.keys) != len(ranks) {
		t.Fatal(w.keys)
	}
	for n, k := range w.keys {
		if k.DomainRank != ranks[n] {
			t.Fatal(w.keys)
		}
	}
	t.Log("REAL_PG canonical cross-server315/360/363/381 same callerTx, nonfriend accepted, absent Social roots preserved, known identity/digest replay without second intent")
}

type generalStoreTrace struct {
	dm.Store
	w *dmLockTrace
}

func (d generalStoreTrace) Lock(c context.Context, t tx.Tx, id string) (dm.Intent, bool, error) {
	k, _ := lockkey.New(dm.LockRank, "personal-dm.intent", lockkey.String(id))
	if e := d.w.lock(t, k); e != nil {
		return dm.Intent{}, false, e
	}
	return d.Store.Lock(c, t, id)
}
func (d generalStoreTrace) InsertTx(c context.Context, t tx.Tx, i dm.Intent) error {
	k, _ := lockkey.New(dm.LockRank, "personal-dm.intent", lockkey.String(i.ID))
	if e := d.w.lock(t, k); e != nil {
		return e
	}
	d.w.mutated = true
	return d.Store.InsertTx(c, t, i)
}
func (d generalStoreTrace) UpdateTx(c context.Context, t tx.Tx, i dm.Intent, v int64, at time.Time) error {
	d.w.mutated = true
	return d.Store.UpdateTx(c, t, i, v, at)
}

func Test6B_G08_G09_G10UnknownAcceptRealCommitOrRollback(t *testing.T) {
	for _, commit := range []bool{false, true} {
		t.Run(fmt.Sprint(commit), func(t *testing.T) {
			f, s, _ := generalPair(t)
			fault := &ambiguousBeginner{db: f.p, commit: commit}
			s.Timed.Runner.DB = fault
			op := f.op()
			i, e := s.Accept(ctx, 100001, 200001, "ambiguous", op)
			if commit {
				if e != nil || i.ID != op.ID.String() {
					t.Fatal(i, e)
				}
			} else {
				var unknown *tx.UnknownCommitError
				if !errors.As(e, &unknown) || i.ID != "" {
					t.Fatal("unknown output", i, e)
				}
			}
			if fault.begins != 1 || f.number(`SELECT count(*) FROM personal_dm_intents`) != map[bool]int64{false: 0, true: 1}[commit] {
				t.Fatal("blind replay")
			}
		})
	}
}
func Test6B_G11_G12_G13UnknownClaimMarkerAndFinish(t *testing.T) {
	for _, stage := range []string{"claim", "marker", "finish"} {
		for _, commit := range []bool{false, true} {
			t.Run(fmt.Sprintf("%s/%v", stage, commit), func(t *testing.T) {
				f, s, fence := generalPair(t)
				i := generalAccept(t, f, s)
				if stage != "claim" {
					var e error
					var ok bool
					i, ok, e = s.Claim(ctx, i.ID, fence, f.op())
					if e != nil || !ok {
						t.Fatal(e)
					}
				}
				if stage == "finish" {
					var e error
					i, e = s.BeginAttempt(ctx, i, f.op())
					if e != nil {
						t.Fatal(e)
					}
				}
				fault := &ambiguousBeginner{db: f.p, commit: commit}
				s.Timed.Runner.DB = fault
				var out dm.Intent
				var e error
				switch stage {
				case "claim":
					var ok bool
					out, ok, e = s.Claim(ctx, i.ID, fence, f.op())
					if ok {
						t.Fatal("unknown claim permission")
					}
				case "marker":
					out, e = s.BeginAttempt(ctx, i, f.op())
				case "finish":
					out, e = s.Finish(ctx, i, true, f.now().Add(250*time.Millisecond), f.op())
				}
				if stage == "finish" && commit {
					if e != nil || out.Status != dm.WrittenBeforeDeadline {
						t.Fatal("positive receipt resolution", out, e)
					}
				} else if e == nil || out.ID != "" {
					t.Fatal("ambiguous transition output", out, e)
				}
				if fault.begins != 1 {
					t.Fatal("blind replay", fault.begins)
				}
				if stage == "marker" && commit {
					s = f.general()
					done, e := s.Recover(ctx, i.ID, f.op())
					if e != nil || !done || f.text(`SELECT status FROM personal_dm_delivery WHERE operation_id=$1::uuid`, i.ID) != "UNKNOWN" {
						t.Fatal("marker recovery", e)
					}
				}
			})
		}
	}
}
func Test6B_G17_G18DirectedPrivacyAndVersionFence(t *testing.T) {
	f, s, fence := generalPair(t)
	f.block(100001, 200001)
	i := generalAccept(t, f, s)
	f.block(200001, 100001)
	if _, e := s.Accept(ctx, 100001, 200001, "denied", f.op()); e == nil {
		t.Fatal("recipient block allowed")
	}
	f.ok(200001, sr.RemoveBlock, 100001)
	j, ok, e := s.Claim(ctx, i.ID, fence, f.op())
	if e != nil || ok || j.Status != dm.PrivacySuppressed {
		t.Fatal("block/unblock revived", j, ok, e)
	}
	if f.number(`SELECT count(*) FROM personal_dm_payloads WHERE operation_id=$1::uuid`, i.ID) != 0 {
		t.Fatal("suppressed payload retained")
	}
}
func Test6B_G26_G27_G28_G34_G35_G38_G39BindingsLeaseRecoveryAndPurge(t *testing.T) {
	for _, fault := range []string{"no-world", "guild-only", "context-retired", "generation-replaced", "epoch", "active-claim", "lease-expired", "attempt-crash", "expiry", "backward"} {
		t.Run(fault, func(t *testing.T) {
			f, s, fence := generalPair(t)
			if fault == "no-world" || fault == "guild-only" {
				if fault == "no-world" {
					f.sql(`DELETE FROM realtime_presence_leases`)
				} else {
					f.sql(`UPDATE realtime_presence_leases SET physical_role='GUILD'`)
				}
				if _, e := s.Accept(ctx, 100001, 200001, "offline", f.op()); e == nil {
					t.Fatal("no WORLD acceptance")
				}
				return
			}
			i := generalAccept(t, f, s)
			if len(i.Bindings) != 1 || i.Bindings[0].OwnerFence != fence {
				t.Fatal(i)
			}
			switch fault {
			case "context-retired":
				f.sql(`UPDATE gameplay_contexts SET ended_at=$1,end_reason='LOGOUT',liveness_version=liveness_version+1`, f.now())
			case "generation-replaced":
				f.sql(`UPDATE realtime_presence_leases SET connection_generation=2`)
			case "epoch":
				_, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
				if e != nil {
					t.Fatal(e)
				}
			case "active-claim", "lease-expired":
				j, ok, e := s.Claim(ctx, i.ID, fence, f.op())
				if e != nil || !ok {
					t.Fatal(e)
				}
				if fault == "active-claim" {
					if _, ok, e = s.Claim(ctx, i.ID, fence, f.op()); ok || e == nil {
						t.Fatal("active claim acquired twice")
					}
					return
				}
				f.sql(`UPDATE personal_dm_delivery SET lease_expires_at=$2 WHERE operation_id=$1::uuid`, i.ID, f.now().Add(-time.Second))
				k, ok, e := s.Claim(ctx, i.ID, fence, f.op())
				if e != nil || !ok || k.ClaimGeneration != j.ClaimGeneration+1 {
					t.Fatal("expired claim", k, e)
				}
				if _, e = s.BeginAttempt(ctx, j, f.op()); e == nil {
					t.Fatal("old worker fence")
				}
				return
			case "attempt-crash":
				generalAttempt(t, f, s, fence, i)
				done, e := s.Recover(ctx, i.ID, f.op())
				if e != nil || !done {
					t.Fatal(e)
				}
				j, ok, e := s.Claim(ctx, i.ID, fence, f.op())
				if e != nil || ok || j.Status != dm.Unknown {
					t.Fatal("attempt resent", j, e)
				}
			case "expiry":
				f.sql(`UPDATE personal_dm_intents SET accepted_at=$2::timestamptz,expires_at=$2::timestamptz+interval '8 seconds' WHERE operation_id=$1::uuid`, i.ID, f.now().Add(-9*time.Second))
				done, e := s.Recover(ctx, i.ID, f.op())
				if e != nil || !done {
					t.Fatal(e)
				}
			case "backward":
				f.sql(`UPDATE personal_dm_delivery SET last_observed_at=$2 WHERE operation_id=$1::uuid`, i.ID, f.now().Add(time.Minute))
				done, e := s.Recover(ctx, i.ID, f.op())
				if e != nil || !done {
					t.Fatal(e)
				}
			}
			if fault == "context-retired" || fault == "generation-replaced" || fault == "epoch" {
				j, ok, e := s.Claim(ctx, i.ID, fence, f.op())
				if e != nil || ok || j.Status != dm.AdmissionRetired {
					t.Fatal("retired original set", j, e)
				}
			}
			if f.number(`SELECT count(*) FROM personal_dm_payloads`) != 0 || f.number(`SELECT count(*) FROM personal_dm_intents`) != 1 || f.number(`SELECT count(*) FROM personal_dm_delivery WHERE terminal_receipt IS NOT NULL`) != 1 {
				t.Fatal("tombstone/payload boundary")
			}
		})
	}
}
func Test6B_G25_G31PositiveReceiptWaitAndCancellation(t *testing.T) {
	f, s, fence := generalPair(t)
	i := generalAccept(t, f, s)
	c, cancel := context.WithTimeout(ctx, 30*time.Millisecond)
	defer cancel()
	if _, e := s.Wait(c, i); e == nil {
		t.Fatal("pending returned success")
	}
	attempt := generalAttempt(t, f, s, fence, i)
	out, e := s.Finish(ctx, attempt, true, f.now().Add(250*time.Millisecond), f.op())
	if e != nil || out.Status != dm.WrittenBeforeDeadline {
		t.Fatal(out, e)
	}
	got, e := s.Wait(ctx, i)
	if e != nil || got.Status != dm.WrittenBeforeDeadline || got.Message != "" || len(got.Bindings) != 0 {
		t.Fatal("minimal receipt", got, e)
	}
	canceled, stop := context.WithCancel(ctx)
	stop()
	if _, e = s.Wait(canceled, i); e == nil {
		t.Fatal("cancelled original waiter success")
	}
	if f.number(`SELECT count(*) FROM personal_dm_payloads`) != 0 {
		t.Fatal("positive payload retained")
	}
}

type generalVisit struct {
	service      dm.Service
	f            *fixture
	mu           sync.Mutex
	seen         map[string]bool
	active, peak atomic.Int64
}

func (v *generalVisit) DeliverIntent(c context.Context, id string) error {
	n := v.active.Add(1)
	defer v.active.Add(-1)
	for {
		old := v.peak.Load()
		if old >= n || v.peak.CompareAndSwap(old, n) {
			break
		}
	}
	v.mu.Lock()
	v.seen[id] = true
	v.mu.Unlock()
	select {
	case <-c.Done():
		return c.Err()
	case <-time.After(30 * time.Millisecond):
	}
	_, _, e := v.service.Store.Find(c, v.f.p, id)
	return e
}
func Test6B_G30_G36FairKeysetAndBoundedWorkers(t *testing.T) {
	f, s, _ := generalPair(t)
	base := generalAccept(t, f, s)
	transaction, e := f.p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer transaction.Rollback(ctx)
	for n := 0; n < 80; n++ {
		u, _ := ids.NewUUID()
		i := base
		i.ID = u.String()
		if e := s.Store.InsertTx(ctx, transaction, i); e != nil {
			t.Fatal(e)
		}
	}
	if e := transaction.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	high, e := s.Store.HighWater(ctx, f.p)
	if e != nil {
		t.Fatal(e)
	}
	page, e := s.Store.Page(ctx, f.p, "", high, 64)
	if e != nil || len(page) != 64 {
		t.Fatal(len(page), e)
	}
	v := &generalVisit{service: s, f: f, seen: map[string]bool{}}
	r := &dm.Reconciler{Store: s.Store, Queryer: f.p, Deliverer: v}
	if e := r.InitialReconcile(ctx); e != nil {
		t.Fatal(e)
	}
	c, cancel := context.WithCancel(ctx)
	done := make(chan error, 1)
	go func() { done <- r.Run(c) }()
	defer cancel()
	for n := 0; n < 100; n++ {
		ref, _ := (dm.Reference{ID: base.ID, Version: base.StateVersion}).Encode()
		if e := r.ReloadAndDeliver(ctx, ref); e != nil {
			t.Fatal(e)
		}
	}
	until := time.Now().Add(7 * time.Second)
	for {
		v.mu.Lock()
		count := len(v.seen)
		v.mu.Unlock()
		if count == 81 {
			break
		}
		if time.Now().After(until) {
			cancel()
			<-done
			t.Fatal("keyset starvation", count)
		}
		time.Sleep(10 * time.Millisecond)
	}
	cancel()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("workers unjoined")
	}
	if v.active.Load() != 0 || v.peak.Load() > 5 {
		t.Fatal("capacity/join", v.active.Load(), v.peak.Load())
	}
	t.Log("REAL_PG 81 pending intents, actual keyset pages64, bounded queue saturation, coalesced reference hints, all rows visited without starvation, <=5 joined feature workers")
}

type generalWaitFault struct {
	entered chan struct{}
	release <-chan struct{}
}

func (v generalWaitFault) Accept(c context.Context, a, b int64, msg string, op operation.Context) (dm.Intent, error) {
	return dm.Intent{ID: op.ID.String(), Digest: dm.Digest(a, b, msg), ExpiresAt: time.Now().Add(8 * time.Second), Status: dm.Pending}, nil
}
func (v generalWaitFault) Wait(c context.Context, i dm.Intent) (dm.Intent, error) {
	v.entered <- struct{}{}
	select {
	case <-c.Done():
		return dm.Intent{}, c.Err()
	case <-v.release:
		return i, nil
	}
}
func Test6B_G25_G30APIWaiterCapacityAndFalseEcho(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	_, token := f.live(100001)
	release := make(chan struct{})
	var once sync.Once
	defer once.Do(func() { close(release) })
	entered := make(chan struct{}, 16)
	r := httpedge.NewRouter()
	d := stockruntime.GeneralDMDispatcher{Authority: f.authority(), Service: generalWaitFault{entered: entered, release: release}, Slots: make(chan struct{}, 16)}
	if e := r.Register(513, d); e != nil {
		t.Fatal(e)
	}
	admission, e := httpedge.NewAdmission(64)
	if e != nil {
		t.Fatal(e)
	}
	server := httptest.NewServer(httpedge.Handler{Router: r, Admission: admission, Limits: limits.Default(), Operations: operation.Factory{Clock: clock.System{}}})
	defer server.Close()
	results := make(chan int, 16)
	for n := 0; n < 16; n++ {
		go func() {
			code, _ := httpRequest(t, server, token, 1, 513, map[string]any{"to_player_id": 200001, "message": "wait"})
			results <- code
		}()
	}
	for n := 0; n < 16; n++ {
		select {
		case <-entered:
		case <-time.After(3 * time.Second):
			t.Fatal("waiter not admitted", n)
		}
	}
	if code, _ := httpRequest(t, server, token, 1, 513, map[string]any{"to_player_id": 200001, "message": "overflow"}); code != 503 {
		t.Fatal("capacity not finite", code)
	}
	once.Do(func() { close(release) })
	for n := 0; n < 16; n++ {
		if code := <-results; code == 200 {
			t.Fatal("pending fake completion returned stock200")
		}
	}
	if len(d.Slots) != 0 {
		t.Fatal("slots leaked")
	}
	t.Log("NATIVE_HTTP + real I4 auth; explicit Wait-port fault holds16 API waiters, 17th503, all pending/false-echo results non200 and slots released")
}

func Test6B_G08KnownPositiveAfterExpiryNoResend(t *testing.T) {
	f, s, fence := generalPair(t)
	op := f.op()
	i, e := s.Accept(ctx, 100001, 200001, "known after expiry", op)
	if e != nil {
		t.Fatal(e)
	}
	j := generalAttempt(t, f, s, fence, i)
	if _, e = s.Finish(ctx, j, true, f.now().Add(250*time.Millisecond), f.op()); e != nil {
		t.Fatal(e)
	}
	time.Sleep(time.Until(i.ExpiresAt) + 20*time.Millisecond)
	got, e := s.Accept(ctx, 100001, 200001, "known after expiry", op)
	if e != nil || got.Status != dm.WrittenBeforeDeadline {
		t.Fatal(got, e)
	}
	if _, e = s.Wait(ctx, i); e != nil {
		t.Fatal(e)
	}
	if f.number(`SELECT count(*) FROM personal_dm_intents`) != 1 || f.number(`SELECT count(*) FROM personal_dm_payloads`) != 0 {
		t.Fatal("known positive replayed")
	}
}
func Test6B_G07MigrationRecoveryFixture(t *testing.T) {
	mode := os.Getenv("GXB6B_MIGRATION_FIXTURE")
	if mode == "" {
		t.Skip("auxiliary seed/restore helper executed separately with explicit migration fixture mode")
	}
	if mode == "seed" {
		f, s, fence := generalPair(t)
		generalAccept(t, f, s)
		i := generalAccept(t, f, s)
		if _, ok, e := s.Claim(ctx, i.ID, fence, f.op()); e != nil || !ok {
			t.Fatal(e)
		}
		i = generalAccept(t, f, s)
		generalAttempt(t, f, s, fence, i)
		i = generalAccept(t, f, s)
		j := generalAttempt(t, f, s, fence, i)
		if _, e := s.Finish(ctx, j, true, f.now().Add(250*time.Millisecond), f.op()); e != nil {
			t.Fatal(e)
		}
		t.Log("NATIVE_SEED real Accept/Claim/Attempt/Finish: four intents PENDING/CLAIMED/ATTEMPTING/WRITTEN, three ephemeral payloads, terminal positive tombstone")
		return
	}
	if mode != "restore" {
		t.Fatal("invalid fixture mode")
	}
	f := existing(t)
	s := f.general()
	fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	var raw []byte
	if e := f.p.QueryRow(ctx, `SELECT jsonb_agg(operation_id::text) FROM personal_dm_intents`).Scan(&raw); e != nil {
		t.Fatal(e)
	}
	var all []string
	if json.Unmarshal(raw, &all) != nil || len(all) != 4 {
		t.Fatal(string(raw))
	}
	for _, id := range all {
		done, e := s.Recover(ctx, id, f.op())
		if e != nil {
			t.Fatal(e)
		}
		if !done {
			if _, ok, e := s.Claim(ctx, id, fence, f.op()); e != nil || ok {
				t.Fatal("restore retarget permission", ok, e)
			}
		}
	}
	if f.number(`SELECT count(*) FROM personal_dm_payloads`) != 0 || f.number(`SELECT count(*) FROM personal_dm_delivery WHERE status='WRITTEN_BEFORE_DEADLINE'`) != 1 || f.number(`SELECT count(*) FROM personal_dm_delivery WHERE status IN('PENDING','CLAIMED','ATTEMPTING')`) != 0 {
		t.Fatal("restore did not reconcile safely")
	}
	t.Log("NATIVE_RESTORE no-network canonical epoch/expiry/crash recovery, three payloads purged, all four tombstones retained, positive unchanged")
}
