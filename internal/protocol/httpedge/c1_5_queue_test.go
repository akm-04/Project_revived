package httpedge

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/limits"
)

type fixedQueueWait time.Duration

func (q fixedQueueWait) ExpectedWait() time.Duration { return time.Duration(q) }

func queueTestHandler(t *testing.T, admission *Admission, queue QueueWaitEstimate, budget time.Duration, dispatcher DispatcherFunc) Handler {
	t.Helper()
	router := NewRouter()
	if err := router.Register(18, dispatcher); err != nil {
		t.Fatal(err)
	}
	return Handler{
		Limits: limits.Default(), Admission: admission, QueueWait: queue, QueueBudget: budget,
		Operations: operation.Factory{Clock: clock.Fixed{T: time.Unix(100, 0)}},
		Router:     router,
	}
}

func assertCodedTransient(t *testing.T, recorder *httptest.ResponseRecorder) {
	t.Helper()
	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d body=%s want 503", recorder.Code, recorder.Body)
	}
	if got := recorder.Header().Get("Retry-After"); got != "1" {
		t.Fatalf("Retry-After=%q want 1", got)
	}
	var body map[string]any
	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("body=%q: %v", recorder.Body, err)
	}
	if body["error_code"] != float64(edgeTransientCode) || body["error_msg"] != "" {
		t.Fatalf("body=%#v want error_code 35033 and empty error_msg", body)
	}
}

// C1-5: the configured in-flight cap is a hard bound and releases a slot on Release.
func TestAdmissionCapRefusesBeyondItsBound(t *testing.T) {
	admission, err := NewAdmission(1024)
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 1024; i++ {
		if !admission.TryAcquire() {
			t.Fatalf("request %d refused below the cap", i)
		}
	}
	if admission.TryAcquire() {
		t.Fatal("request admitted above the cap")
	}
	admission.Release()
	if !admission.TryAcquire() {
		t.Fatal("released slot not reusable")
	}
}

// C1-5: over the cap the edge answers at once with the coded transient refusal R4 part 4 writes.
func TestHandlerRefusesAboveInFlightCapWithCodedTransient(t *testing.T) {
	admission, _ := NewAdmission(1)
	entered := make(chan struct{}, 1)
	release := make(chan struct{})
	handler := queueTestHandler(t, admission, nil, 0, func(context.Context, DispatchRequest) Response {
		entered <- struct{}{}
		<-release
		return Response{HTTPStatus: http.StatusOK}
	})
	first := httptest.NewRecorder()
	done := make(chan struct{})
	go func() {
		defer close(done)
		handler.ServeHTTP(first, ordinaryRequest(t, `{"mid":18}`))
	}()
	<-entered
	assertCodedTransient(t, post(handler, `{"mid":18}`))
	close(release)
	<-done
}

// C1-5: when the measured queue-to-commit time exceeds the request's remaining budget, answer at once with 35033.
func TestHandlerRefusesWhenExpectedWaitExceedsRemainingBudget(t *testing.T) {
	called := false
	handler := queueTestHandler(t, mustAdmission(t, 4), fixedQueueWait(2*time.Second), time.Second, func(context.Context, DispatchRequest) Response {
		called = true
		return Response{HTTPStatus: http.StatusOK}
	})
	assertCodedTransient(t, post(handler, `{"mid":18}`))
	if called {
		t.Fatal("request dispatched although the expected wait exceeded the budget")
	}
}

// C1-5: a wait inside the remaining budget is not a refusal.
func TestHandlerDispatchesWhenExpectedWaitFitsBudget(t *testing.T) {
	called := false
	handler := queueTestHandler(t, mustAdmission(t, 4), fixedQueueWait(500*time.Millisecond), time.Second, func(context.Context, DispatchRequest) Response {
		called = true
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"ok": true}}
	})
	if got := post(handler, `{"mid":18}`); got.Code != http.StatusOK || !called {
		t.Fatalf("status=%d called=%v", got.Code, called)
	}
}

func mustAdmission(t *testing.T, max int) *Admission {
	t.Helper()
	admission, err := NewAdmission(max)
	if err != nil {
		t.Fatal(err)
	}
	return admission
}

func residentKiB(t *testing.T) uint64 {
	t.Helper()
	data, err := os.ReadFile("/proc/self/statm")
	if err != nil {
		t.Skipf("resident set size unavailable: %v", err)
	}
	fields := strings.Fields(string(data))
	pages, err := strconv.ParseUint(fields[1], 10, 64)
	if err != nil {
		t.Fatal(err)
	}
	return pages * uint64(os.Getpagesize()) / 1024
}

// C1-5: 1,000 waiting requests stay parked without a goroutine or memory explosion, and every one is served.
func TestThousandWaitingRequestsAreBounded(t *testing.T) {
	const total = 1000
	entered := make(chan struct{}, total)
	release := make(chan struct{})
	handler := queueTestHandler(t, mustAdmission(t, 1024), nil, 0, func(context.Context, DispatchRequest) Response {
		entered <- struct{}{}
		<-release
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"ok": true}}
	})
	requests := make([]*http.Request, total)
	for i := range requests {
		requests[i] = ordinaryRequest(t, `{"mid":18}`)
	}
	runtime.GC()
	baselineGoroutines := runtime.NumGoroutine()
	var baseline runtime.MemStats
	runtime.ReadMemStats(&baseline)
	baselineRSS := residentKiB(t)

	responses := make([]*httptest.ResponseRecorder, total)
	var wait sync.WaitGroup
	for i := range requests {
		wait.Add(1)
		go func(i int) {
			defer wait.Done()
			responses[i] = httptest.NewRecorder()
			handler.ServeHTTP(responses[i], requests[i])
		}(i)
	}
	for range total {
		<-entered
	}
	runtime.GC()
	waitingGoroutines := runtime.NumGoroutine()
	var waiting runtime.MemStats
	runtime.ReadMemStats(&waiting)
	waitingRSS := residentKiB(t)
	t.Logf("1,000 waiting requests: goroutines +%d, heap +%d KiB (objects +%d), stack +%d KiB, RSS +%d KiB",
		waitingGoroutines-baselineGoroutines, (int64(waiting.HeapAlloc)-int64(baseline.HeapAlloc))/1024,
		int64(waiting.HeapObjects)-int64(baseline.HeapObjects),
		(int64(waiting.StackInuse)-int64(baseline.StackInuse))/1024, int64(waitingRSS)-int64(baselineRSS))

	close(release)
	wait.Wait()
	for i, response := range responses {
		if response.Code != http.StatusOK {
			t.Fatalf("request %d status=%d body=%s", i, response.Code, response.Body)
		}
	}
	if grew := waitingGoroutines - baselineGoroutines; grew < total {
		t.Fatalf("goroutines grew by %d, want every waiter parked on the handler", grew)
	}
	if grew := int64(waitingRSS) - int64(baselineRSS); grew > 128<<10 {
		t.Fatalf("resident set grew by %d KiB at 1,000 waiters", grew)
	}
}

// C1-5: above the cap every request is either admitted or refused with the coded transient body, never uncoded.
func TestThousandRequestsAreAdmittedOrCoded(t *testing.T) {
	const total = 1000
	entered := make(chan struct{}, total)
	finished := make(chan struct{}, total)
	release := make(chan struct{})
	handler := queueTestHandler(t, mustAdmission(t, 512), nil, 0, func(context.Context, DispatchRequest) Response {
		entered <- struct{}{}
		<-release
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"ok": true}}
	})
	requests := make([]*http.Request, total)
	for i := range requests {
		requests[i] = ordinaryRequest(t, `{"mid":18}`)
	}
	responses := make([]*httptest.ResponseRecorder, total)
	var wait sync.WaitGroup
	for i := 0; i < total; i++ {
		wait.Add(1)
		go func(i int) {
			defer wait.Done()
			responses[i] = httptest.NewRecorder()
			handler.ServeHTTP(responses[i], requests[i])
			finished <- struct{}{}
		}(i)
	}
	admitted, refused := 0, 0
	for admitted+refused < total {
		select {
		case <-entered:
			admitted++
		case <-finished:
			refused++
		}
	}
	close(release)
	wait.Wait()
	if admitted != 512 || refused != 488 {
		t.Fatalf("admitted=%d refused=%d want 512/488", admitted, refused)
	}
	served := 0
	for _, response := range responses {
		if response.Code == http.StatusOK {
			served++
			continue
		}
		assertCodedTransient(t, response)
	}
	if served != admitted {
		t.Fatalf("served=%d admitted=%d", served, admitted)
	}
}
