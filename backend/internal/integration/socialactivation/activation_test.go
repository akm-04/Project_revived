//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/socialdismiss"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreload"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"net/http"
	"net/http/httptest"
	"net/url"
	"path/filepath"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"
)

func (f *fixture) dismiss() socialdismiss.Service {
	return socialdismiss.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: f.p}}, Runner: tx.Runner{DB: f.p}}, PlayerRoots: i4store.PlayerRootLocker{}, Roots: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}}
}
func (f *fixture) reloader() socialreload.Service {
	return socialreload.Service{Runner: tx.Runner{DB: f.p}, Relations: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}, Observer: socialpresentation.TransactionReader{}}
}
func TestD01DismissBatchConvergenceAndForeignIsolation(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.player(300001)
	f.relationNotices(3)
	f.root(300001)
	f.notice(10, 200001, "gift.v1", "x", 4, f.at)
	f.notice(11, 200001, "guild.v1", "x", 10, f.at)
	f.sql(`INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,notice_time,created_at,updated_at)VALUES(300001,20,1,'social-relation.request.v1','300001:200001:1:ACCEPT',200001,$1,$1,$1)`, f.at)
	f.notice(12, 0, "social-relation.request.v1", "100001:200001:9:ACCEPT", 1, f.at)
	want := []socialinbox.NoticeID{3, 1, 12}
	got, e := f.dismiss().Dismiss(ctx, actor(100001), []socialinbox.NoticeID{3, 1, 3, 10, 11, 20, 999, 12}, f.op())
	if e != nil || !reflect.DeepEqual(got, want) {
		t.Fatal(got, e)
	}
	if f.number(`SELECT count(*) FROM social_notices WHERE active`) != 4 {
		t.Fatal("foreign/provider rows changed")
	}
	before := f.snapshot()
	again, e := f.dismiss().Dismiss(ctx, actor(100001), want, f.op())
	if e != nil || !reflect.DeepEqual(again, want) || f.snapshot() != before {
		t.Fatal("repeated dismissal mutated state", e)
	}
	if f.number(`SELECT count(*) FROM social_notices WHERE NOT active AND dismissed_at IS NOT NULL`) != 3 {
		t.Fatal("tombstone missing")
	}
	t.Log("REAL_PG relation-only mixed batch,first occurrence responseorder,SQLNULL lifecycle,idempotentrepeat andforeign/provider isolation")
}
func TestD02DismissWholeBatchRollbackAndOverflow(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.relationNotices(2)
	f.sql(`UPDATE social_notices SET source_key='corrupt' WHERE notice_id=2`)
	before := f.snapshot()
	got, e := f.dismiss().Dismiss(ctx, actor(100001), []socialinbox.NoticeID{1, 2}, f.op())
	if e == nil || got != nil || f.snapshot() != before {
		t.Fatal("corrupt batch leaked", got, e)
	}
	f.sql(`UPDATE social_notices SET source_key='100001:200001:2:ACCEPT',state_version=9223372036854775807 WHERE notice_id=2`)
	before = f.snapshot()
	if _, e := f.dismiss().Dismiss(ctx, actor(100001), []socialinbox.NoticeID{1, 2}, f.op()); e == nil || f.snapshot() != before {
		t.Fatal("overflow leaked")
	}
	f.sql(`UPDATE social_notices SET state_version=1 WHERE notice_id=2`)
	f.sql(`UPDATE player_social_roots SET state_version=9223372036854775807 WHERE player_id=100001`)
	before = f.snapshot()
	if _, e := f.dismiss().Dismiss(ctx, actor(100001), []socialinbox.NoticeID{1}, f.op()); e == nil || f.snapshot() != before {
		t.Fatal("root overflow leaked")
	}
}
func TestD03DismissConcurrencyNoRootCreation(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	before := f.snapshot()
	got, e := f.dismiss().Dismiss(ctx, actor(100001), []socialinbox.NoticeID{99}, f.op())
	if e != nil || len(got) != 0 || f.snapshot() != before {
		t.Fatal("missing root created", e)
	}
	f.player(200001)
	f.relationNotices(3)
	root := f.number(`SELECT state_version FROM player_social_roots WHERE player_id=100001`)
	var wg sync.WaitGroup
	errs := make(chan error, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := f.dismiss().Dismiss(ctx, actor(100001), []socialinbox.NoticeID{1, 2, 3}, f.op())
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
	if f.number(`SELECT sum(state_version) FROM social_notices`) != 6 || f.number(`SELECT state_version FROM player_social_roots WHERE player_id=100001`) != root+1 {
		t.Fatal("duplicate lifecycle effect")
	}
}
func TestD04CommittedReferencesAndCanonicalReload(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	r := f.ok(100001, sr.RequestFriend, 200001)
	if len(r.Reloads) != 1 || r.Reloads[0].Purpose != sr.ReloadRequest {
		t.Fatal(r.Reloads)
	}
	raw, e := r.Reloads[0].Encode()
	ref, e2 := sr.DecodeReloadReference(raw)
	if e != nil || e2 != nil || ref != r.Reloads[0] {
		t.Fatal(e, e2)
	}
	intent, ok, e := f.reloader().Reload(ctx, ref, f.op())
	if e != nil || !ok || intent.Recipient != 200001 {
		t.Fatal(intent, ok, e)
	}
	denied := f.ok(200001, sr.DenyRequests, 100001)
	if len(denied.Reloads) != 1 || denied.Reloads[0].Purpose != sr.ReloadDeny {
		t.Fatal(denied.Reloads)
	}
	if _, ok, e := f.reloader().Reload(ctx, ref, f.op()); e != nil || ok {
		t.Fatal("terminal request still reloads pending", e)
	}
	if _, ok, e := f.reloader().Reload(ctx, denied.Reloads[0], f.op()); e != nil || !ok {
		t.Fatal("retained terminal source", e)
	}
	forged := denied.Reloads[0]
	forged.Generation++
	if _, ok, e := f.reloader().Reload(ctx, forged, f.op()); e != nil || ok {
		t.Fatal("forged source accepted", e)
	}
	repeated := f.ok(200001, sr.DenyRequests, 100001)
	if len(repeated.Reloads) != 0 {
		t.Fatal("no-op hint")
	}
	f.ok(100001, sr.RequestFriend, 200001)
	accept := f.ok(200001, sr.AcceptRequest, 100001)
	if len(accept.Reloads) != 1 || accept.Reloads[0].Purpose != sr.ReloadAccept {
		t.Fatal("accept refs")
	}
	deleted := f.ok(200001, sr.DeleteFriend, 100001)
	if len(deleted.Reloads) != 1 || deleted.Reloads[0].Purpose != sr.ReloadDelete {
		t.Fatal("delete refs")
	}
}

var digestSecret = []byte("i7a4d-digest-fixture-secret-long")
var bearerSecret = []byte("i7a4d-bearer-fixture-secret-long")

func (f *fixture) live(pid identity.PlayerID) (identity.ActorContext, string) {
	aidRaw := f.text(`SELECT account_id::text FROM players WHERE player_id=$1`, int64(pid))
	au, _ := ids.ParseUUID(aidRaw)
	aid, _ := identity.AccountIDFrom(au)
	u, _ := ids.NewUUID()
	sid, _ := identity.SessionIDFrom(u)
	u, _ = ids.NewUUID()
	cid, _ := identity.ContextIDFrom(u)
	server, _ := sr.CanonicalServer(pid)
	a := identity.ActorContext{AccountID: aid, AccountUID: identity.AccountUID(fmt.Sprint(pid)), SessionID: sid, ContextID: cid, LogicalServerID: server, PlayerID: pid, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	now := f.now()
	gc := identity.GameplayContext{ID: cid, SessionID: sid, AccountID: aid, LogicalServerID: server, PlayerID: pid, ContextGeneration: 1, CreatedAt: now, LivenessVersion: 1}
	bearer, e := identity.DeriveGameplayBearer(bearerSecret, gc)
	if e != nil {
		f.t.Fatal(e)
	}
	digest, e := identity.DigestGameplayBearer(digestSecret, bearer)
	if e != nil {
		f.t.Fatal(e)
	}
	f.sql(`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1::uuid,$2::uuid,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, sid.UUID().String(), aid.UUID().String(), now)
	f.sql(`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6)`, cid.UUID().String(), sid.UUID().String(), aid.UUID().String(), int32(server), int64(pid), now)
	f.sql(`INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)VALUES(gen_random_uuid(),$1::uuid,$2::uuid,$3,1,'fixture',$4)`, cid.UUID().String(), sid.UUID().String(), digest[:], now)
	return a, bearer
}
func (f *fixture) authority() i4store.RealtimeAuthority {
	return i4store.RealtimeAuthority{Queryer: f.p, DigestSecret: digestSecret, BearerSecret: bearerSecret, DerivationKeyID: "fixture"}
}
func (f *fixture) httpServer() *httptest.Server {
	r := httpedge.NewRouter()
	d := stockruntime.SocialDispatcher{Authority: f.authority(), Relations: f.s, Projection: f.v, Dismissal: f.dismiss()}
	if e := stockruntime.RegisterSocialRoutes(r, d); e != nil {
		f.t.Fatal(e)
	}
	admission, err := httpedge.NewAdmission(8)
	if err != nil {
		f.t.Fatal(err)
	}
	return httptest.NewServer(httpedge.Handler{Router: r, Admission: admission, Limits: limits.Default(), Operations: operation.Factory{Clock: clock.System{}}})
}
func httpRequest(t *testing.T, s *httptest.Server, bearer string, region int64, mid int, fields map[string]any) (int, any) {
	t.Helper()
	m := map[string]any{"mid": mid, "token": bearer, "region": region, "v_": "source-version", "app_v": "source-app", "platform": 3}
	for k, v := range fields {
		m[k] = v
	}
	b, _ := json.Marshal(m)
	res, e := http.Post(s.URL, "application/x-www-form-urlencoded", strings.NewReader(url.Values{"payload": {string(b)}}.Encode()))
	if e != nil {
		t.Fatal(e)
	}
	defer res.Body.Close()
	var v any
	if e := json.NewDecoder(res.Body).Decode(&v); e != nil {
		t.Fatal(e)
	}
	return res.StatusCode, v
}
func TestD05NativeHTTPWireAuthAndNoticeKey(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.relationNotices(1)
	_, token := f.live(100001)
	s := f.httpServer()
	defer s.Close()
	status, v := httpRequest(t, s, token, 1, 176, nil)
	if status != 200 {
		t.Fatal(status, v)
	}
	n := v.(map[string]any)["notice_list"].([]any)[0].(map[string]any)
	if n["notice_type"] != float64(1) || n["type"] != nil {
		t.Fatal(n)
	}
	status, v = httpRequest(t, s, token, 1, 189, map[string]any{"list_type": 4})
	if status != 200 || len(v.([]any)) != 1 {
		t.Fatal(v)
	}
	status, v = httpRequest(t, s, token, 1, 188, map[string]any{"msg": "no match"})
	if status != 200 || len(v.([]any)) != 0 {
		t.Fatal(v)
	}
	status, v = httpRequest(t, s, token, 1, 184, map[string]any{"notice_ids": []any{1, 1, 999}})
	if status != 200 || !reflect.DeepEqual(v.(map[string]any)["ids"], []any{float64(1)}) {
		t.Fatal(v)
	}
	status, _ = httpRequest(t, s, token, 2, 176, nil)
	if status != 403 {
		t.Fatal("region accepted")
	}
	status, _ = httpRequest(t, s, "bad", 1, 176, nil)
	if status != 403 {
		t.Fatal("token accepted")
	}
	for _, fields := range []map[string]any{{"list_type": "4"}, {"list_type": 4.5}, {"list_type": 4, "unknown": 1}} {
		status, _ = httpRequest(t, s, token, 1, 189, fields)
		if status != 400 {
			t.Fatal("invalid input", fields, status)
		}
	}
	status, _ = httpRequest(t, s, token, 1, 184, map[string]any{"notice_ids": []any{int64(1 << 53)}})
	if status != 400 {
		t.Fatal("unsafe integer accepted")
	}
}
func TestD06SafeNoticeProjectionAndMaterialization(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.notice(1<<53, 200001, "social-relation.request.v1", "100001:200001:1:ACCEPT", 1, f.at)
	before := f.snapshot()
	v, e := f.v.LoadBase(ctx, actor(100001), f.op())
	if e == nil || len(v.Notices) != 0 || f.snapshot() != before {
		t.Fatal("unsafe projection", e)
	}
	f.sql(`TRUNCATE social_gift_transfers,social_notices`)
	f.sql(`SELECT setval('social_notice_id_seq',9007199254740991,true)`)
	f.ok(100001, sr.RequestFriend, 200001)
	before = f.snapshot()
	r, e := f.runAs(200001, sr.AcceptRequest, 100001)
	if e == nil || len(r.Reloads) != 0 || f.snapshot() != before {
		t.Fatal("unsafe sequence escaped rollback", e)
	}
}

var _ = context.Background
var _ = time.Second

func TestD08AllStockRoutesAndPartialShapes(t *testing.T) {
	f := fresh(t)
	for _, p := range []identity.PlayerID{100001, 200001, 300001} {
		f.player(p)
	}
	_, a := f.live(100001)
	_, b := f.live(200001)
	_, c := f.live(300001)
	server := f.httpServer()
	defer server.Close()
	call := func(token string, region int64, mid int, fields map[string]any) any {
		status, v := httpRequest(t, server, token, region, mid, fields)
		if status != 200 {
			t.Fatal(mid, status, v)
		}
		if m, ok := v.(map[string]any); ok && m["error_code"] != nil {
			t.Fatal(mid, v)
		}
		return v
	}
	call(a, 1, 177, map[string]any{"player_id": 200001, "msg": "hi"})
	call(b, 2, 178, map[string]any{"player_ids": []any{100001, 100001}})
	call(a, 1, 177, map[string]any{"player_id": 200001})
	call(b, 2, 179, map[string]any{"player_ids": []any{100001}})
	call(b, 2, 186, map[string]any{"player_id": 100001})
	call(a, 1, 177, map[string]any{"player_id": 200001})
	call(c, 3, 177, map[string]any{"player_id": 200001})
	got := call(b, 2, 182, map[string]any{"player_ids": []any{300001, 100001, 300001}}).(map[string]any)
	if len(got) != 2 || got["100001"] == nil || got["300001"] == nil {
		t.Fatal("partial string-keyed map", got)
	}
	call(b, 2, 181, map[string]any{"player_id": 100001})
	call(a, 1, 185, map[string]any{"player_id": 300001})
	call(a, 1, 187, nil)
	for k := 1; k <= 4; k++ {
		if _, ok := call(a, 1, 189, map[string]any{"list_type": k}).([]any); !ok {
			t.Fatal("list shape", k)
		}
	}
	if _, ok := call(a, 1, 188, map[string]any{"player_name": "200001"}).(map[string]any); !ok {
		t.Fatal("legacy object")
	}
	if _, ok := call(a, 1, 188, map[string]any{"msg": "200001"}).([]any); !ok {
		t.Fatal("modern array")
	}
	if _, ok := call(a, 1, 190, nil).(map[string]any)["list"].([]any); !ok {
		t.Fatal("recommend array")
	}
	status, _ := httpRequest(t, server, a, 1, 183, nil)
	if status != 501 {
		t.Fatal("gift activated", status)
	}
	t.Log("All14selectedHTTP branches, numeric/array/string-keyed-map/ACKshapes,modern/legacy and183inactive exercised onrealPG")
}

type checkEmitter struct {
	f     *fixture
	calls int
	refs  []sr.ReloadReference
}

func (e *checkEmitter) Emit(c context.Context, refs []sr.ReloadReference) {
	e.calls++
	e.refs = append(e.refs, refs...)
	t, err := e.f.p.Raw().Begin(c)
	if err != nil {
		e.f.t.Fatal(err)
	}
	defer t.Rollback(c)
	if _, err := t.Exec(c, `SELECT player_id FROM players WHERE player_id IN (100001,200001) ORDER BY player_id FOR UPDATE NOWAIT`); err != nil {
		e.f.t.Fatal("socket emission under315lock", err)
	}
	if _, err := t.Exec(c, `SELECT player_id FROM player_social_roots ORDER BY player_id FOR UPDATE NOWAIT`); err != nil {
		e.f.t.Fatal("socket emission under360lock", err)
	}
}
func TestD09PostCommitOutputOnlyAndBootCorrelation(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	a, bearer := f.live(100001)
	tracker, err := lobby.NewCapturedBootTracker(lobby.EvidenceConfig{RunID: "i7a4d-native", ProcessRole: lobby.ProcessAPI, ProcessID: "fixture", SinkPath: filepath.Join(t.TempDir(), "api.jsonl"), MaxEvents: 1000, RingEvents: 1000, StartedAt: f.now()})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { tracker.Close() })
	emitter := &checkEmitter{f: f}
	router := httpedge.NewRouter()
	d := stockruntime.SocialDispatcher{Authority: f.authority(), Relations: f.s, Projection: f.v, Dismissal: f.dismiss(), Tracker: tracker, Emitter: emitter}
	if e := stockruntime.RegisterSocialRoutes(router, d); e != nil {
		t.Fatal(e)
	}
	admission, _ := httpedge.NewAdmission(8)
	server := httptest.NewServer(httpedge.Handler{Router: router, Admission: admission, Limits: limits.Default(), Operations: operation.Factory{Clock: clock.System{}}})
	defer server.Close()
	status, _ := httpRequest(t, server, bearer, 1, 176, nil)
	if status != 200 {
		t.Fatal(status)
	}
	events := []lobby.BootEvent{}
	for _, e := range tracker.Events() {
		if e.Kind == lobby.BootExplicitHTTP {
			events = append(events, e)
		}
	}
	stag, ctag := tracker.CorrelationTags(a.SessionID.UUID().String(), a.ContextID.UUID().String())
	if len(events) != 1 || events[0].Kind != lobby.BootExplicitHTTP || events[0].SessionTag != stag || events[0].ContextTag != ctag {
		t.Fatal("uncorrelated explicit176", events)
	}
	status, _ = httpRequest(t, server, bearer, 1, 177, map[string]any{"player_id": 200001})
	if status != 200 || emitter.calls != 1 || len(emitter.refs) != 1 {
		t.Fatal("committedref absent")
	}
	if f.number(`SELECT count(*) FROM social_friend_requests WHERE status='PENDING'`) != 1 {
		t.Fatal("hint before canonical commit")
	}
	status, _ = httpRequest(t, server, bearer, 1, 177, map[string]any{"player_id": 200001})
	if status != 200 || emitter.calls != 1 {
		t.Fatal("failed duplicate emitted")
	}
}
