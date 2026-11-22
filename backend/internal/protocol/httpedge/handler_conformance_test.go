package httpedge

import (
	"bytes"
	"context"
	"log"
	"net/http"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

type recordingConformance struct {
	checked []uint16
	paths   map[uint16][]string
}

func (c *recordingConformance) Check(mid uint16, _ any) []string {
	c.checked = append(c.checked, mid)
	return c.paths[mid]
}

func conformanceHandler(t *testing.T, router *Router, metrics observability.Metrics, conformance interface {
	Check(mid uint16, reply any) []string
}) Handler {
	t.Helper()
	admission, err := NewAdmission(4)
	if err != nil {
		t.Fatal(err)
	}
	return Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router, Metrics: metrics, Conformance: conformance}
}

func TestConformanceChecksRepliesRegisteredBeforeAndAfterWrap(t *testing.T) {
	var logs bytes.Buffer
	previous := log.Writer()
	log.SetOutput(&logs)
	defer log.SetOutput(previous)

	reply := Response{HTTPStatus: http.StatusOK, Body: map[string]any{"ok": int64(1)}}
	router := NewRouter()
	if err := router.Register(18, DispatcherFunc(func(context.Context, DispatchRequest) Response { return reply })); err != nil {
		t.Fatal(err)
	}
	router.Wrap = func(dispatcher Dispatcher) Dispatcher { return dispatcher }
	if err := router.Register(1, DispatcherFunc(func(context.Context, DispatchRequest) Response { return reply })); err != nil {
		t.Fatal(err)
	}
	checker := &recordingConformance{paths: map[uint16][]string{18: {"regions[].region_id"}}}
	checked := post(conformanceHandler(t, router, &countingMetrics{}, checker), `{"mid":18,"token":"bearer"}`)
	post(conformanceHandler(t, router, &countingMetrics{}, checker), `{"mid":1,"token":"bearer"}`)
	unchecked := post(conformanceHandler(t, router, &countingMetrics{}, nil), `{"mid":18,"token":"bearer"}`)

	if len(checker.checked) != 2 || checker.checked[0] != 18 || checker.checked[1] != 1 {
		t.Fatalf("checked MIDs %#v, want the pre-Wrap 18 and post-Wrap 1", checker.checked)
	}
	if checked.Code != unchecked.Code || checked.Body.String() != unchecked.Body.String() {
		t.Fatalf("conformance changed the reply: %d %q vs %d %q", checked.Code, checked.Body, unchecked.Code, unchecked.Body)
	}
	if !strings.Contains(logs.String(), "reply_conformance_violation mid=18 path=regions[].region_id") {
		t.Fatalf("violation log %q", logs.String())
	}
}

func TestConformanceSkipsRawAndFailureReplies(t *testing.T) {
	checker := &recordingConformance{}
	cases := []struct {
		name     string
		response Response
	}{
		{"raw", Response{HTTPStatus: http.StatusOK, Raw: []byte(`{"ok":1}`)}},
		{"refusal", Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error_code": int64(35028)}}},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			router := NewRouter()
			response := testCase.response
			if err := router.Register(18, DispatcherFunc(func(context.Context, DispatchRequest) Response { return response })); err != nil {
				t.Fatal(err)
			}
			post(conformanceHandler(t, router, &countingMetrics{}, checker), `{"mid":18,"token":"bearer"}`)
		})
	}
	if len(checker.checked) != 0 {
		t.Fatalf("checked MIDs %#v, want none", checker.checked)
	}
}

func TestConformanceMID18MissingRegionIDIsLoggedAndCounted(t *testing.T) {
	var logs bytes.Buffer
	previous := log.Writer()
	log.SetOutput(&logs)
	defer log.SetOutput(previous)

	router := NewRouter()
	dispatcher := DispatcherFunc(func(context.Context, DispatchRequest) Response {
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{
			"regions": []map[string]any{{"name": "Server 1"}},
		}}
	})
	if err := router.Register(18, dispatcher); err != nil {
		t.Fatal(err)
	}
	metrics := &countingMetrics{}
	checked := post(conformanceHandler(t, router, metrics, replyconformance.Checker{}), `{"mid":18,"token":"bearer"}`)
	unchecked := post(conformanceHandler(t, router, metrics, nil), `{"mid":18,"token":"bearer"}`)

	if checked.Code != http.StatusOK || unchecked.Code != http.StatusOK {
		t.Fatalf("statuses %d %d", checked.Code, unchecked.Code)
	}
	if checked.Body.String() != unchecked.Body.String() {
		t.Fatalf("conformance changed the reply: %q vs %q", checked.Body, unchecked.Body)
	}
	if !strings.Contains(logs.String(), "reply_conformance_violation mid=18 path=regions[].region_id") {
		t.Fatalf("violation log %q", logs.String())
	}
	if metrics.counters[replyConformanceViolations] != 1 {
		t.Fatalf("counter %#v, want exactly one violation", metrics.counters)
	}
}
