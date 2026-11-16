package httpedge

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/undelivered"
	"gxb.local/backend/v2/internal/protocol/limits"
)

type recordingMarker struct {
	marks []undelivered.Mark
	err   error
}

func (m *recordingMarker) Mark(_ context.Context, mark undelivered.Mark) error {
	m.marks = append(m.marks, mark)
	return m.err
}

type failingWriter struct {
	header  http.Header
	status  int
	written []byte
	err     error
	cancel  context.CancelFunc
}

func (w *failingWriter) Header() http.Header {
	if w.header == nil {
		w.header = http.Header{}
	}
	return w.header
}

func (w *failingWriter) WriteHeader(status int) { w.status = status }

func (w *failingWriter) Write(p []byte) (int, error) {
	w.written = append(w.written, p...)
	if w.cancel != nil {
		w.cancel()
	}
	if w.err != nil {
		return 0, w.err
	}
	return len(p), nil
}

type countingMetrics struct{ counters map[string]uint64 }

func (m *countingMetrics) Counter(name string, _ observability.Labels, delta uint64) {
	if m.counters == nil {
		m.counters = map[string]uint64{}
	}
	m.counters[name] += delta
}

func (m *countingMetrics) Observe(string, observability.Labels, time.Duration) {}

func undeliveredHandler(t *testing.T, dispatcher DispatcherFunc, marker *recordingMarker, metrics observability.Metrics) Handler {
	t.Helper()
	admission, err := NewAdmission(4)
	if err != nil {
		t.Fatal(err)
	}
	router := NewRouter()
	if err := router.Register(18, dispatcher); err != nil {
		t.Fatal(err)
	}
	return Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router, Undelivered: marker, Metrics: metrics}
}

func undeliveredRequest(t *testing.T, handler http.Handler, writer *failingWriter, cancelAfterWrite bool) {
	t.Helper()
	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(`{"mid":18,"token":"bearer","region":1}`)))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	if cancelAfterWrite {
		writer.cancel = cancel
	}
	handler.ServeHTTP(writer, request.WithContext(ctx))
}

var testFingerprint = [32]byte{1, 2, 3}

func notedSuccess(actor observability.RequestActor) DispatcherFunc {
	return func(ctx context.Context, _ DispatchRequest) Response {
		observability.NoteActor(ctx, actor)
		observability.NoteParamsFingerprint(ctx, testFingerprint)
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"ok": int64(1)}}
	}
}

func TestUndeliveredMarksACommittedReplyWhoseWriteFailed(t *testing.T) {
	marker := &recordingMarker{}
	metrics := &countingMetrics{}
	actor := observability.RequestActor{AccountUID: "7", PlayerID: 100001, SessionID: "session-a"}
	writer := &failingWriter{err: errors.New("client disconnected")}
	undeliveredRequest(t, undeliveredHandler(t, notedSuccess(actor), marker, metrics), writer, false)
	if len(marker.marks) != 1 {
		t.Fatalf("marks=%d", len(marker.marks))
	}
	mark := marker.marks[0]
	if mark.PlayerID != actor.PlayerID || mark.SessionID != actor.SessionID || mark.MID != 18 || mark.Fingerprint != testFingerprint {
		t.Fatalf("mark=%+v", mark)
	}
	if string(mark.Reply) != `{"ok":1}`+"\n" || string(writer.written) != string(mark.Reply) {
		t.Fatalf("reply=%q written=%q", mark.Reply, writer.written)
	}
	if metrics.counters[undelivered.MarksTotal] != 1 {
		t.Fatalf("counters=%v", metrics.counters)
	}
}

func TestUndeliveredMarksWhenOnlyTheContextWasCancelled(t *testing.T) {
	marker := &recordingMarker{}
	actor := observability.RequestActor{AccountUID: "7", PlayerID: 100001, SessionID: "session-a"}
	writer := &failingWriter{}
	undeliveredRequest(t, undeliveredHandler(t, notedSuccess(actor), marker, nil), writer, true)
	if len(marker.marks) != 1 {
		t.Fatalf("marks=%d", len(marker.marks))
	}
}

func TestUndeliveredSkipsADeliveredReply(t *testing.T) {
	marker := &recordingMarker{}
	actor := observability.RequestActor{AccountUID: "7", PlayerID: 100001, SessionID: "session-a"}
	writer := &failingWriter{}
	undeliveredRequest(t, undeliveredHandler(t, notedSuccess(actor), marker, nil), writer, false)
	if len(marker.marks) != 0 {
		t.Fatalf("marks=%d", len(marker.marks))
	}
}

func TestUndeliveredSkipsAnErrorReply(t *testing.T) {
	marker := &recordingMarker{}
	actor := observability.RequestActor{AccountUID: "7", PlayerID: 100001, SessionID: "session-a"}
	dispatcher := func(ctx context.Context, _ DispatchRequest) Response {
		observability.NoteActor(ctx, actor)
		observability.NoteParamsFingerprint(ctx, testFingerprint)
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(100)}}
	}
	writer := &failingWriter{err: errors.New("client disconnected")}
	undeliveredRequest(t, undeliveredHandler(t, dispatcher, marker, nil), writer, false)
	if len(marker.marks) != 0 {
		t.Fatalf("marks=%d", len(marker.marks))
	}
}

func TestUndeliveredSkipsAReplay(t *testing.T) {
	marker := &recordingMarker{}
	actor := observability.RequestActor{AccountUID: "7", PlayerID: 100001, SessionID: "session-a"}
	dispatcher := func(ctx context.Context, _ DispatchRequest) Response {
		observability.NoteActor(ctx, actor)
		observability.NoteParamsFingerprint(ctx, testFingerprint)
		observability.NoteReplay(ctx)
		return Response{HTTPStatus: http.StatusOK, Raw: []byte(`{"ok":1}` + "\n")}
	}
	writer := &failingWriter{err: errors.New("client disconnected")}
	undeliveredRequest(t, undeliveredHandler(t, dispatcher, marker, nil), writer, false)
	if len(marker.marks) != 0 {
		t.Fatalf("marks=%d", len(marker.marks))
	}
	if string(writer.written) != `{"ok":1}`+"\n" {
		t.Fatalf("raw reply written=%q", writer.written)
	}
}

func TestUndeliveredSkipsWhenNoActorOrFingerprintWasNoted(t *testing.T) {
	marker := &recordingMarker{}
	dispatcher := func(context.Context, DispatchRequest) Response {
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"ok": int64(1)}}
	}
	writer := &failingWriter{err: errors.New("client disconnected")}
	undeliveredRequest(t, undeliveredHandler(t, dispatcher, marker, nil), writer, false)
	if len(marker.marks) != 0 {
		t.Fatalf("marks=%d", len(marker.marks))
	}
}

func TestUndeliveredCountsAFailedMarkWrite(t *testing.T) {
	marker := &recordingMarker{err: errors.New("database down")}
	metrics := &countingMetrics{}
	actor := observability.RequestActor{AccountUID: "7", PlayerID: 100001, SessionID: "session-a"}
	writer := &failingWriter{err: errors.New("client disconnected")}
	undeliveredRequest(t, undeliveredHandler(t, notedSuccess(actor), marker, metrics), writer, false)
	if metrics.counters[undelivered.MarkFailuresTotal] != 1 {
		t.Fatalf("counters=%v", metrics.counters)
	}
}

func TestWriteJSONValueReportsEncodingFailure(t *testing.T) {
	writer := &failingWriter{}
	_, encodable, err := writeJSONValue(writer, http.StatusOK, map[string]any{"bad": make(chan int)})
	if err != nil || encodable {
		t.Fatalf("encodable=%v err=%v", encodable, err)
	}
	if !strings.Contains(string(writer.written), "20003") {
		t.Fatalf("body=%q", writer.written)
	}
}
