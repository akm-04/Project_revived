//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialfriendbase"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreload"
	ref "gxb.local/backend/v2/internal/application/socialreloadref"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"net/http"
	"net/http/httptest"
	"net/url"
	"reflect"
	"strings"
	"testing"
)

type giftEmitter struct {
	f    *fixture
	refs []sr.ReloadReference
}

func (e *giftEmitter) Emit(c context.Context, rs []sr.ReloadReference) {
	for _, r := range rs {
		if e.f.number(`SELECT count(*) FROM social_gift_transfers WHERE transfer_id=$1::uuid`, r.TransferID.String()) != 1 {
			e.f.t.Fatal("hint before commit")
		}
	}
	e.refs = append(e.refs, rs...)
}
func (f *fixture) giftStock(s sg.Service, scalar i5.CurrentScalarProjectionPort) (stockruntime.SocialDispatcher, *giftEmitter, socialfriendbase.Service, socialreload.Service) {
	v := f.v
	v.Gifts = s
	v.NoticePages = socialinboxstore.Store{}
	base := socialfriendbase.Service{FriendDM: f.dm(), Projection: v}
	reload := f.reloader()
	reload.Gifts = s
	emitter := &giftEmitter{f: f}
	d := stockruntime.SocialDispatcher{Authority: f.authority(), Relations: f.s, Dismissal: f.dismiss(), Scalar: scalar, Emitter: emitter}
	group, e := stockruntime.PrepareGiftStock(d, s, base, reload)
	if e != nil {
		f.t.Fatal(e)
	}
	d, e = group.Enable(ctx, f.p)
	if e != nil {
		f.t.Fatal(e)
	}
	return d, emitter, base, reload
}
func (f *fixture) scalar() i5.CurrentScalarProjectionPort {
	return i5.ScalarProjector{Runner: tx.Runner{DB: f.p}, Store: i5store.Store{Queryer: f.p}}
}
func (f *fixture) giftHTTP(d stockruntime.SocialDispatcher) *httptest.Server {
	router := httpedge.NewRouter()
	if e := stockruntime.RegisterSocialRoutes(router, d); e != nil {
		f.t.Fatal(e)
	}
	a, _ := httpedge.NewAdmission(8)
	return httptest.NewServer(httpedge.Handler{Router: router, Admission: a, Limits: limits.Default(), Operations: operation.Factory{Clock: clock.System{}}})
}
func giftRaw(t *testing.T, s *httptest.Server, raw string) (int, any) {
	t.Helper()
	res, e := http.Post(s.URL, "application/x-www-form-urlencoded", strings.NewReader(url.Values{"payload": {raw}}.Encode()))
	if e != nil {
		t.Fatal(e)
	}
	defer res.Body.Close()
	var v any
	if e = json.NewDecoder(res.Body).Decode(&v); e != nil {
		t.Fatal(e)
	}
	return res.StatusCode, v
}
func Test7B_HTTP183184RawScalarAndHints(t *testing.T) {
	f, s, a, b := giftFixture(t)
	_, at := f.live(a.PlayerID)
	_, bt := f.live(b.PlayerID)
	d, em, _, _ := f.giftStock(s, f.scalar())
	server := f.giftHTTP(d)
	defer server.Close()
	for _, suffix := range []string{`"player_id":200001,"player_id":200001`, `"player_id":true`, `"player_id":200001.0`, `"player_id":-1`, `"player_id":200001,"amount":5`, `"player_id":200001,"nonce":"x"`} {
		raw := fmt.Sprintf(`{"mid":183,"token":%q,"region":1,%s}`, at, suffix)
		status, _ := giftRaw(t, server, raw)
		if status == 200 {
			t.Fatal(raw)
		}
	}
	status, v := httpRequest(t, server, at, 1, 183, map[string]any{"player_id": 200001})
	if status != 200 || len(v.(map[string]any)) != 0 || len(em.refs) != 2 {
		t.Fatal(status, v, em.refs)
	}
	if em.refs[0].Purpose != ref.ReloadGiftSenderList || em.refs[1].Purpose != ref.ReloadGiftRecipientNotice {
		t.Fatal(em.refs)
	}
	status, _ = httpRequest(t, server, at, 1, 183, map[string]any{"player_id": 200001})
	if status == 200 {
		t.Fatal("duplicate invokes stock success callback")
	}
	status, _ = httpRequest(t, server, at, 2, 183, map[string]any{"player_id": 200001})
	if status == 200 {
		t.Fatal("cross region admitted")
	}
	id := f.number(`SELECT notice_id FROM social_gift_transfers`)
	status, _ = giftRaw(t, server, fmt.Sprintf(`{"mid":184,"token":%q,"region":2,"notice_ids":[%d],"notice_ids":[%d]}`, bt, id, id))
	if status == 200 {
		t.Fatal("duplicate before map ignored")
	}
	values := []any{id, id}
	for i := 0; i < 1000; i++ {
		values = append(values, 900000+i)
	}
	status, v = httpRequest(t, server, bt, 2, 184, map[string]any{"notice_ids": values})
	if status != 200 {
		t.Fatal(status, v)
	}
	body := v.(map[string]any)
	if !reflect.DeepEqual(body["ids"], []any{float64(id)}) || len(body["awards"].([]any)) != 0 || body["economy_"].(map[string]any)["friendship_coin"] != float64(5) || len(em.refs) != 2 {
		t.Fatal(body)
	}
	status, _ = httpRequest(t, server, bt, 2, 184, map[string]any{"notice_ids": []any{id}})
	if status == 200 {
		t.Fatal("alreadyclaimed Gift must fail entire batch")
	}
	status, v = httpRequest(t, server, bt, 2, 184, map[string]any{"notice_ids": []any{}})
	if status != 200 || v.(map[string]any)["economy_"] != nil {
		t.Fatal(status, v)
	}
}

type badGiftScalar struct {
	amount int64
	fail   bool
}

func (s badGiftScalar) CurrentScalar(context.Context, identity.PlayerID, string, operation.Context) (int64, error) {
	if s.fail {
		return 0, errors.New("projection unavailable")
	}
	return s.amount, nil
}
func Test7B_PostCommitScalarFailureAndKnownFreshProjection(t *testing.T) {
	for _, bad := range []badGiftScalar{{fail: true}, {amount: -1}, {amount: 9007199254740992}} {
		t.Run(fmt.Sprint(bad), func(t *testing.T) {
			f, s, a, b := giftFixture(t)
			r, e := s.Send(ctx, a, b.PlayerID, f.op())
			if e != nil {
				t.Fatal(e)
			}
			_, token := f.live(b.PlayerID)
			d, _, _, _ := f.giftStock(s, bad)
			server := f.giftHTTP(d)
			defer server.Close()
			status, _ := httpRequest(t, server, token, 2, 184, map[string]any{"notice_ids": []any{r.NoticeIDs[0]}})
			if status == 200 {
				t.Fatal("postcommit invalid scalar accepted")
			}
			if f.number(`SELECT amount FROM player_currency_balances WHERE player_id=200001 AND resource_key='friendship_coin'`) != 5 || f.number(`SELECT count(*) FROM social_gift_claim_operations`) != 1 {
				t.Fatal("settlement compensated/lost")
			}
			status, _ = httpRequest(t, server, token, 2, 184, map[string]any{"notice_ids": []any{r.NoticeIDs[0]}})
			if status == 200 || f.number(`SELECT amount FROM player_currency_balances WHERE player_id=200001 AND resource_key='friendship_coin'`) != 5 {
				t.Fatal("blind retry")
			}
		})
	}
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	_, token := f.live(b.PlayerID)
	b, _ = f.live(b.PlayerID)
	d, _, _, _ := f.giftStock(s, f.scalar())
	op := f.op()
	req := httpedge.DispatchRequest{}
	req.Envelope.MID = 184
	req.Envelope.Operation = op
	req.Envelope.ReceivedAt = f.now()
	req.Envelope.Claims.Token = token
	req.Envelope.Claims.Region = 2
	req.Envelope.Params = map[string]any{"notice_ids": []any{int64(r.NoticeIDs[0])}}
	first := d.Dispatch(ctx, req)
	if first.HTTPStatus != 200 {
		t.Fatal(first)
	}
	f.sql(`UPDATE player_currency_balances SET amount=amount+7,state_version=state_version+1 WHERE player_id=200001 AND resource_key='friendship_coin'`)
	again := d.Dispatch(ctx, req)
	if again.HTTPStatus != 200 || again.Body["economy_"].(map[string]any)["friendship_coin"] != int64(12) {
		t.Fatal(again)
	}
}
func Test7B_PureGiftProjectionAndFriendRecovery(t *testing.T) {
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	_, _, base, _ := f.giftStock(s, f.scalar())
	epochs := f.text(`SELECT jsonb_agg(to_jsonb(e) ORDER BY player_id)::text FROM social_gift_epochs e`)
	out, e := base.LoadBase(ctx, a, f.op())
	if e != nil || out.SendCount != 1 || !out.Friends[0].IsSent {
		t.Fatal(out, e)
	}
	wire := socialpresentation.MapBase(out)
	if wire.SendCount != 1 || !wire.Friends[0].IsSent || wire.ServerTime != out.ObservedAt.Unix() {
		t.Fatal(wire)
	}
	out, e = base.LoadList(ctx, b, sp.Notice, f.op())
	if e != nil || len(out.Notices) != 1 || out.Notices[0].Notice.NoticeType != 4 {
		t.Fatal(out, e)
	}
	raw, e := socialpresentation.MapList(out, sp.Notice)
	if e != nil || reflect.ValueOf(raw).Kind() != reflect.Slice {
		t.Fatal(raw, e)
	}
	if f.text(`SELECT jsonb_agg(to_jsonb(e) ORDER BY player_id)::text FROM social_gift_epochs e`) != epochs {
		t.Fatal("pure read refreshed epoch")
	}
	f.dmSend(f.dm(), a.PlayerID, b.PlayerID, "pending before gift read")
	f.sql(`UPDATE social_notices SET source_key=gen_random_uuid()::text WHERE notice_id=$1`, int64(r.NoticeIDs[0]))
	before := f.dmSnapshot()
	if _, e = base.LoadBase(ctx, b, f.op()); e == nil || f.dmSnapshot() != before {
		t.Fatal("Gift read failure drained FriendDM", e)
	}
	f.sql(`UPDATE social_notices SET source_key=(SELECT transfer_id::text FROM social_gift_transfers WHERE notice_id=$1) WHERE notice_id=$1`, int64(r.NoticeIDs[0]))
	op := f.op()
	first, e := base.LoadBase(ctx, b, op)
	if e != nil || len(first.PrivateMessages) != 1 {
		t.Fatal(first, e)
	}
	f.dmSend(f.dm(), a.PlayerID, b.PlayerID, "later pending")
	if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); e != nil {
		t.Fatal(e)
	}
	before = f.dmSnapshot()
	again, e := base.LoadBase(ctx, b, op)
	if e != nil || again.ReceiveCount != 1 || len(again.Notices) != 0 || !reflect.DeepEqual(first.PrivateMessages, again.PrivateMessages) || f.dmSnapshot() != before {
		t.Fatal(again, e)
	}
	for _, commit := range []bool{false, true} {
		fault := &dmWriteAmbiguous{db: f.p, commit: commit}
		broken := base
		broken.FriendDM.Timed.Runner.DB = fault
		_, e = broken.LoadBase(ctx, b, f.op())
		if commit && e != nil || !commit && e == nil || fault.writes != 1 {
			t.Fatal("unknown Friend projection replay", commit, e, fault.writes)
		}
	}
}
func Test7B_WindowQualifiedBeforeLimitSaturationAndCorruption(t *testing.T) {
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	_, _, base, _ := f.giftStock(s, f.scalar())
	// 51 unsupported newer rows must not hide the older qualified gift.
	f.sql(`INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,notice_time,created_at,updated_at) SELECT 200001,100+n,10,'future-guild',n::text,100001,$1,$1,$1 FROM generate_series(1,51)n`, f.now())
	got, e := base.LoadList(ctx, b, sp.Notice, f.op())
	if e != nil || len(got.Notices) != 1 || got.Notices[0].Notice.NoticeID != r.NoticeIDs[0] {
		t.Fatal(got, e)
	}
	f.sql(`INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,notice_time,created_at,updated_at) SELECT 200001,1000+n,10,'future-guild','other'||n::text,100001,$1,$1,$1 FROM generate_series(1,4096)n`, f.now())
	before := f.giftState()
	if _, e = base.LoadList(ctx, b, sp.Notice, f.op()); e == nil || f.giftState() != before {
		t.Fatal("saturation hid/delete entitlement", e)
	}
	f.sql(`DELETE FROM social_notices WHERE source_kind='future-guild'`)
	// A recognized corrupt source fails rather than being dropped as unsupported.
	f.sql(`UPDATE social_notices SET source_key=gen_random_uuid()::text WHERE notice_id=$1`, int64(r.NoticeIDs[0]))
	if _, e = base.LoadList(ctx, b, sp.Notice, f.op()); e == nil {
		t.Fatal("missing transfer ignored")
	}
	f.sql(`UPDATE social_notices SET source_key=(SELECT transfer_id::text FROM social_gift_transfers WHERE notice_id=$1) WHERE notice_id=$1`, int64(r.NoticeIDs[0]))
	if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); e != nil {
		t.Fatal(e)
	}
	got, e = base.LoadList(ctx, b, sp.Notice, f.op())
	if e != nil || len(got.Notices) != 0 {
		t.Fatal("terminal claimed visible", e)
	}
	f.sql(`UPDATE social_notices SET active=true,dismissed_at=NULL WHERE notice_id=$1`, int64(r.NoticeIDs[0]))
	if _, e = base.LoadList(ctx, b, sp.Notice, f.op()); e == nil {
		t.Fatal("active claimed corruption ignored")
	}
}
func Test7B_GiftReloadOwnerValidationAndReadiness(t *testing.T) {
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	refs, e := s.ReloadReferences(ctx, a, b.PlayerID, r, f.op())
	if e != nil {
		t.Fatal(e)
	}
	d, _, base, reload := f.giftStock(s, f.scalar())
	_ = d
	for _, v := range refs {
		raw, e := v.Encode()
		parsed, e2 := ref.DecodeReloadReference(raw)
		if e != nil || e2 != nil || parsed != v {
			t.Fatal(raw, e, e2)
		}
		got, ok, e := reload.Reload(ctx, v, f.op())
		if e != nil || !ok || got.Recipient != v.Recipient {
			t.Fatal(got, ok, e)
		}
		future := v
		future.RootVersion += 100
		if _, ok, e := reload.Reload(ctx, future, f.op()); e != nil || ok {
			t.Fatal("uncommitted root accepted", e)
		}
		forged := v
		forged.Actor = 300001
		if _, ok, e := reload.Reload(ctx, forged, f.op()); e == nil || ok {
			t.Fatal("forged actor accepted")
		}
	}
	if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); e != nil {
		t.Fatal(e)
	}
	before := f.giftState()
	for _, v := range refs {
		if _, ok, e := reload.Reload(ctx, v, f.op()); e != nil || !ok {
			t.Fatal("consumed source refresh", e)
		}
	}
	if f.giftState() != before {
		t.Fatal("reload performed gameplay")
	}
	incomplete := base
	incomplete.Projection.NoticePages = nil
	if _, e = stockruntime.PrepareGiftStock(stockruntime.SocialDispatcher{Authority: f.authority(), Relations: f.s, Dismissal: f.dismiss(), Scalar: f.scalar(), Emitter: &giftEmitter{f: f}}, s, incomplete, reload); e == nil {
		t.Fatal("partial consumer activation")
	}
	// Legacy relation route remains available without qualified Gift group.
	legacy := f.httpServer()
	defer legacy.Close()
	_, token := f.live(b.PlayerID)
	status, _ := httpRequest(t, legacy, token, 2, 184, map[string]any{"notice_ids": []any{}})
	if status != 200 {
		t.Fatal("inactive group removed legacy dismissal")
	}
}

func Test7B_WindowTiesDeletedSenderAndDayOccupancy(t *testing.T) {
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	_, _, base, _ := f.giftStock(s, f.scalar())
	// Same-time keyset pages span 128 rows; IDs order the final eligible window.
	f.sql(`INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,notice_time,created_at,updated_at) SELECT 200001,100+n,1,'social-relation.request.v1','200001:100001:'||n::text||':ACCEPT',100001,$1,$1,$1 FROM generate_series(1,150)n`, f.now())
	got, e := base.LoadList(ctx, b, sp.Notice, f.op())
	if e != nil || len(got.Notices) != 50 {
		t.Fatal(got, e)
	}
	for i, n := range got.Notices {
		if int64(n.Notice.NoticeID) != 250-int64(i) {
			t.Fatal("tie order", i, n)
		}
	}
	f.sql(`DELETE FROM social_notices WHERE source_kind='social-relation.request.v1'`)
	f.sql(`DELETE FROM gameplay_context_credentials WHERE context_id IN(SELECT context_id FROM gameplay_contexts WHERE player_id=100001)`)
	f.sql(`DELETE FROM gameplay_contexts WHERE player_id=100001`)
	f.sql(`DELETE FROM player_directory_profiles WHERE player_id=100001`)
	f.sql(`DELETE FROM players WHERE player_id=100001`)
	got, e = base.LoadList(ctx, b, sp.Notice, f.op())
	if e != nil || len(got.Notices) != 0 {
		t.Fatal("fabricated deleted sender", got, e)
	}
	if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); e != nil {
		t.Fatal("hidden gift lost value", e)
	}
	t.Log("deleted sender hidden from stock projection, exact Gift claim and receipt retained")
}
