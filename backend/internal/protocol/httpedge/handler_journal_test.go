package httpedge

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/limits"
)

type capturedJournal struct{ records []observability.RequestRecord }

func (c *capturedJournal) Record(record observability.RequestRecord) {
	c.records = append(c.records, record)
}

func journalHandler(t *testing.T, journal observability.RequestJournal, dispatcher DispatcherFunc) Handler {
	t.Helper()
	admission, err := NewAdmission(4)
	if err != nil {
		t.Fatal(err)
	}
	router := NewRouter()
	if err := router.Register(18, dispatcher); err != nil {
		t.Fatal(err)
	}
	return Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router, Journal: journal}
}

func post(handler http.Handler, payload string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(payload)))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	return response
}

func TestJournalRecordsDispatchedRequestWithActorAndCause(t *testing.T) {
	journal := &capturedJournal{}
	cause := errors.New("store: connection refused")
	dispatcher := func(ctx context.Context, _ DispatchRequest) Response {
		observability.NoteActor(ctx, observability.RequestActor{AccountUID: "20000007", PlayerID: 100001, SessionID: "session"})
		return Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_unavailable"}, Cause: cause}
	}
	withJournal := post(journalHandler(t, journal, dispatcher), `{"mid":18,"token":"bearer"}`)
	without := post(journalHandler(t, nil, dispatcher), `{"mid":18,"token":"bearer"}`)
	if withJournal.Code != without.Code || withJournal.Body.String() != without.Body.String() || strings.Contains(withJournal.Body.String(), "connection refused") {
		t.Fatalf("journal changed the response: %d %q vs %d %q", withJournal.Code, withJournal.Body, without.Code, without.Body)
	}
	if len(journal.records) != 1 {
		t.Fatalf("records=%d", len(journal.records))
	}
	record := journal.records[0]
	if record.Disposition != observability.RequestDispatched || record.MID != 18 || record.HTTPStatus != 503 || record.Cause != cause || record.Actor.AccountUID != "20000007" || record.Raw != nil {
		t.Fatalf("record=%+v", record)
	}
	if record.RequestBytes == 0 || record.ResponseBytes != int64(withJournal.Body.Len()) {
		t.Fatalf("bytes request=%d response=%d", record.RequestBytes, record.ResponseBytes)
	}
}

func TestJournalUsesPublicCodeWhenServerErrorHasNoCause(t *testing.T) {
	journal := &capturedJournal{}
	post(journalHandler(t, journal, func(context.Context, DispatchRequest) Response {
		return Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_unavailable"}}
	}), `{"mid":18}`)
	if journal.records[0].Cause == nil || journal.records[0].Cause.Error() != "hero_unavailable" {
		t.Fatalf("cause=%v", journal.records[0].Cause)
	}
}

func TestJournalKeepsRawEnvelopeOfUnknownAndUndecodableRequests(t *testing.T) {
	journal := &capturedJournal{}
	handler := journalHandler(t, journal, func(context.Context, DispatchRequest) Response { return Response{} })
	if code := post(handler, `{"mid":65000,"token":"bearer"}`).Code; code != http.StatusNotFound {
		t.Fatalf("unknown code=%d", code)
	}
	post(handler, `not json`)
	unknown, undecodable := journal.records[0], journal.records[1]
	if unknown.Disposition != observability.RequestUnknownMID || unknown.MID != 65000 || !strings.Contains(string(unknown.Raw), "65000") {
		t.Fatalf("unknown=%+v", unknown)
	}
	if undecodable.Disposition != observability.RequestUndecodable || undecodable.HasMID || len(undecodable.Raw) == 0 {
		t.Fatalf("undecodable=%+v", undecodable)
	}
}
