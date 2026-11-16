package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/undelivered"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type replayAuthority struct{ actor identity.ActorContext }

func (a replayAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return a.actor, nil
}

type rejectingAuthority struct{}

func (rejectingAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return identity.ActorContext{}, errors.New("not live")
}

type replayTaker struct {
	mark  undelivered.Mark
	found bool
	err   error
	calls int
}

func (t *replayTaker) TakeMark(context.Context, int64) (undelivered.Take, error) {
	t.calls++
	return undelivered.Take{Claim: 1, Mark: t.mark, HasMark: t.found}, t.err
}

type nextDispatcher struct {
	calls int
}

func (n *nextDispatcher) Dispatch(context.Context, httpedge.DispatchRequest) httpedge.Response {
	n.calls++
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"fresh": true}}
}

type replayMetrics struct{ counters map[string]uint64 }

func (m *replayMetrics) Counter(name string, _ observability.Labels, delta uint64) {
	if m.counters == nil {
		m.counters = map[string]uint64{}
	}
	m.counters[name] += delta
}

func (m *replayMetrics) Observe(string, observability.Labels, time.Duration) {}

func replayRequest(t *testing.T, mid uint16, params map[string]any, token string, now time.Time) httpedge.DispatchRequest {
	t.Helper()
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, ReceivedAt: now, Params: params, Claims: wire.CredentialClaims{Token: token, Region: 1}}}
}

func replayMark(t *testing.T, actor identity.ActorContext, mid int64, params map[string]any, now time.Time) undelivered.Mark {
	t.Helper()
	fingerprint, err := paramsFingerprint(params)
	if err != nil {
		t.Fatal(err)
	}
	return undelivered.Mark{PlayerID: int64(actor.PlayerID), SessionID: actor.SessionID.UUID().String(), MID: mid, Fingerprint: fingerprint, Reply: []byte(`{"was":"first"}` + "\n"), MarkedAt: now.Add(-time.Minute)}
}

func TestUndeliveredReplayAnswersAMatchingResend(t *testing.T) {
	now := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := actorForHTTP(t)
	params := map[string]any{"token": "bearer", "region": int64(1), "index": int64(3)}
	taker := &replayTaker{mark: replayMark(t, actor, 5, params, now), found: true}
	next := &nextDispatcher{}
	metrics := &replayMetrics{}
	guard := UndeliveredReplay{Next: next, Authority: replayAuthority{actor}, Marks: taker, Window: 10 * time.Minute, Metrics: metrics}
	response := guard.Dispatch(context.Background(), replayRequest(t, 5, params, "bearer", now))
	if next.calls != 0 || string(response.Raw) != `{"was":"first"}`+"\n" || response.HTTPStatus != http.StatusOK {
		t.Fatalf("next=%d response=%#v", next.calls, response)
	}
	if metrics.counters[undelivered.ReplaysTotal] != 1 {
		t.Fatalf("counters=%v", metrics.counters)
	}
}

func TestUndeliveredReplayRunsWhenNothingMatches(t *testing.T) {
	now := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := actorForHTTP(t)
	params := map[string]any{"token": "bearer", "region": int64(1)}
	cases := []struct {
		name   string
		mid    uint16
		params map[string]any
		token  string
		taker  *replayTaker
	}{
		{name: "read mid", mid: 7, params: params, token: "bearer", taker: &replayTaker{mark: replayMark(t, actor, 7, params, now), found: true}},
		{name: "no token", mid: 5, params: params, token: "", taker: &replayTaker{}},
		{name: "different mid", mid: 5, params: params, token: "bearer", taker: &replayTaker{mark: replayMark(t, actor, 6, params, now), found: true}},
		{name: "different params", mid: 5, params: params, token: "bearer", taker: &replayTaker{mark: replayMark(t, actor, 5, map[string]any{"token": "bearer", "region": int64(2)}, now), found: true}},
		{name: "expired", mid: 5, params: params, token: "bearer", taker: &replayTaker{mark: undelivered.Mark{PlayerID: int64(actor.PlayerID), SessionID: actor.SessionID.UUID().String(), MID: 5, Fingerprint: mustFingerprint(t, params), Reply: []byte("x"), MarkedAt: now.Add(-11 * time.Minute)}, found: true}},
		{name: "absent", mid: 5, params: params, token: "bearer", taker: &replayTaker{}},
		{name: "lookup error", mid: 5, params: params, token: "bearer", taker: &replayTaker{err: errors.New("database down")}},
	}
	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			next := &nextDispatcher{}
			guard := UndeliveredReplay{Next: next, Authority: replayAuthority{actor}, Marks: test.taker, Window: 10 * time.Minute}
			response := guard.Dispatch(context.Background(), replayRequest(t, test.mid, test.params, test.token, now))
			if next.calls != 1 || response.Raw != nil || response.Body["fresh"] != true {
				t.Fatalf("next=%d response=%#v", next.calls, response)
			}
		})
	}
}

func TestUndeliveredReplayRunsWhenTheBearerDoesNotResolve(t *testing.T) {
	now := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	next := &nextDispatcher{}
	taker := &replayTaker{}
	guard := UndeliveredReplay{Next: next, Authority: rejectingAuthority{}, Marks: taker, Window: 10 * time.Minute}
	guard.Dispatch(context.Background(), replayRequest(t, 5, map[string]any{"token": "bearer"}, "bearer", now))
	if next.calls != 1 || taker.calls != 0 {
		t.Fatalf("next=%d taker=%d", next.calls, taker.calls)
	}
}

func TestUndeliveredReplayUsesTheSessionOfTheMark(t *testing.T) {
	now := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := actorForHTTP(t)
	params := map[string]any{"token": "bearer", "region": int64(1)}
	mark := replayMark(t, actor, 5, params, now)
	mark.SessionID = "00000000-0000-0000-0000-0000000000ff"
	next := &nextDispatcher{}
	guard := UndeliveredReplay{Next: next, Authority: replayAuthority{actor}, Marks: &replayTaker{mark: mark, found: true}, Window: 10 * time.Minute}
	guard.Dispatch(context.Background(), replayRequest(t, 5, params, "bearer", now))
	if next.calls != 1 {
		t.Fatalf("next=%d", next.calls)
	}
}

func mustFingerprint(t *testing.T, params map[string]any) [32]byte {
	t.Helper()
	fingerprint, err := paramsFingerprint(params)
	if err != nil {
		t.Fatal(err)
	}
	return fingerprint
}
