package operatorapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
)

type fakeBus struct {
	outcome operator.Outcome
	err     error
	calls   int
}

func (bus *fakeBus) Execute(context.Context, operator.Command) (operator.Outcome, error) {
	bus.calls++
	return bus.outcome, bus.err
}

const validBody = `{"envelope":{"principal":"root","role":"root","scope":"global","reason":"test","semantic_key":"k1"},"payload":{"a":1}}`

func serve(t *testing.T, bus *fakeBus, remote, token, path, body string) *httptest.ResponseRecorder {
	t.Helper()
	request := httptest.NewRequest(http.MethodPost, path, strings.NewReader(body))
	request.RemoteAddr = remote
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	recorder := httptest.NewRecorder()
	Handler{Bus: bus, Token: "secret"}.ServeHTTP(recorder, request)
	return recorder
}

func errorCode(t *testing.T, recorder *httptest.ResponseRecorder) string {
	t.Helper()
	var refusal operator.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil {
		t.Fatalf("body %s: %v", recorder.Body, err)
	}
	return refusal.Code
}

func TestHandlerStatusMapping(t *testing.T) {
	const loopbackRemote, command = "127.0.0.1:5000", "/operator/v1/commands/ota.publish"
	cases := []struct {
		name, remote, token, body string
		bus                       fakeBus
		status                    int
		code                      string
	}{
		{"remote caller", "10.0.0.2:5000", "secret", validBody, fakeBus{}, http.StatusUnauthorized, codeUnauthorized},
		{"wrong token", loopbackRemote, "wrong", validBody, fakeBus{}, http.StatusUnauthorized, codeUnauthorized},
		{"unknown field", loopbackRemote, "secret", `{"envelope":{},"payload":{},"extra":1}`, fakeBus{}, http.StatusBadRequest, codeBadRequest},
		{"invalid envelope", loopbackRemote, "secret", `{"envelope":{},"payload":{}}`, fakeBus{}, http.StatusConflict, operator.CodeEnvelopeInvalid},
		{"refusal", loopbackRemote, "secret", validBody, fakeBus{err: operator.StaleRevision(3)}, http.StatusConflict, operator.CodeRevisionStale},
		{"unavailable", loopbackRemote, "secret", validBody, fakeBus{err: operator.ErrUnavailable}, http.StatusServiceUnavailable, codeUnavailable},
		{"failure", loopbackRemote, "secret", validBody, fakeBus{err: errors.New("boom")}, http.StatusInternalServerError, codeFailed},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			recorder := serve(t, &testCase.bus, testCase.remote, testCase.token, command, testCase.body)
			if recorder.Code != testCase.status || errorCode(t, recorder) != testCase.code {
				t.Fatalf("got %d %s", recorder.Code, recorder.Body)
			}
		})
	}
}

func TestHandlerOutcomes(t *testing.T) {
	applied := &fakeBus{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{"ok":true}`)}}
	if recorder := serve(t, applied, "[::1]:5000", "secret", "/operator/v1/commands/ota.publish", validBody); recorder.Code != http.StatusOK || applied.calls != 1 {
		t.Fatalf("applied: %d %s", recorder.Code, recorder.Body)
	}
	replayedRefusal := &fakeBus{outcome: operator.Outcome{State: operator.StateRefused, Result: json.RawMessage(`{}`), Replayed: true}}
	if recorder := serve(t, replayedRefusal, "127.0.0.1:1", "secret", "/operator/v1/commands/ota.publish", validBody); recorder.Code != http.StatusConflict {
		t.Fatalf("replayed refusal: %d", recorder.Code)
	}
}

func paddedCommandBody(size int) string {
	head := `{"envelope":{"principal":"root","role":"root","scope":"global","reason":"test","semantic_key":"k1"},"payload":{"pad":"`
	tail := `"}}`
	return head + strings.Repeat("a", size-len(head)-len(tail)) + tail
}

func TestHandlerRefusesAnOversizedBodyDistinguishably(t *testing.T) {
	bus := &fakeBus{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{}`)}}
	recorder := serve(t, bus, "127.0.0.1:1", "secret", "/operator/v1/commands/ota.register_build", paddedCommandBody(maxRequestBody+1))
	if recorder.Code != http.StatusRequestEntityTooLarge || errorCode(t, recorder) != codeBodyTooLarge {
		t.Fatalf("oversized body: %d %s", recorder.Code, recorder.Body)
	}
	if bus.calls != 0 {
		t.Fatalf("an oversized body reached the bus %d times", bus.calls)
	}
}

func TestHandlerAcceptsABodyJustUnderTheCap(t *testing.T) {
	bus := &fakeBus{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{}`)}}
	recorder := serve(t, bus, "127.0.0.1:1", "secret", "/operator/v1/commands/ota.register_build", paddedCommandBody(maxRequestBody-1024))
	if recorder.Code != http.StatusOK || bus.calls != 1 {
		t.Fatalf("under-cap body: %d %s calls=%d", recorder.Code, recorder.Body, bus.calls)
	}
}

func TestHandlerRefusesATrailingTailOverTheCap(t *testing.T) {
	bus := &fakeBus{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{}`)}}
	body := validBody + strings.Repeat(" ", maxRequestBody)
	recorder := serve(t, bus, "127.0.0.1:1", "secret", "/operator/v1/commands/ota.publish", body)
	if recorder.Code != http.StatusRequestEntityTooLarge || errorCode(t, recorder) != codeBodyTooLarge {
		t.Fatalf("early-completing over-cap body: %d %s", recorder.Code, recorder.Body)
	}
	if bus.calls != 0 {
		t.Fatalf("an over-cap body reached the bus %d times", bus.calls)
	}
}

func TestHandlerBodyTrailingData(t *testing.T) {
	cases := []struct {
		name   string
		tail   string
		status int
	}{
		{"second value", `{"junk":1}`, http.StatusBadRequest},
		{"malformed tail", `junk`, http.StatusBadRequest},
		{"spaces", "   \n", http.StatusOK},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			bus := &fakeBus{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{}`)}}
			recorder := serve(t, bus, "127.0.0.1:1", "secret", "/operator/v1/commands/ota.publish", validBody+testCase.tail)
			if recorder.Code != testCase.status {
				t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
			}
		})
	}
}

func TestHandlerAcceptsAFullReleaseManifest(t *testing.T) {
	rows := strings.Repeat(`{"path":"res/web/images/vip_recharge/90002309.png","md5":"0123456789abcdef0123456789abcdef","size":123456},`, 30000)
	body := `{"envelope":{"principal":"root","role":"root","scope":"global","reason":"test","semantic_key":"k1"},"payload":{"manifest":[` + strings.TrimSuffix(rows, ",") + `]}}`
	if len(body) <= 1<<20 {
		t.Fatalf("fixture is %d bytes; it must exceed the old 1 MiB cap", len(body))
	}
	bus := &fakeBus{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{}`)}}
	if recorder := serve(t, bus, "127.0.0.1:1", "secret", "/operator/v1/commands/ota.register_build", body); recorder.Code != http.StatusOK || bus.calls != 1 {
		t.Fatalf("manifest body: %d %s", recorder.Code, recorder.Body)
	}
}
