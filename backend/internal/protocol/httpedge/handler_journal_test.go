package httpedge

import (
	"bytes"
	"context"
	"errors"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/wire"
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
	if code := post(handler, `{"mid":65000,"token":"bearer"}`).Code; code != http.StatusConflict {
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

func multipartPost(t *testing.T, handler http.Handler, fields [][2]string, fileBody []byte) *httptest.ResponseRecorder {
	t.Helper()
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	part, err := writer.CreateFormFile("avatar", "avatar.png")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := part.Write(fileBody); err != nil {
		t.Fatal(err)
	}
	for _, field := range fields {
		if err := writer.WriteField(field[0], field[1]); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodPost, "/", &body)
	request.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	return response
}

func TestJournalKeepsRedactedMultipartEnvelopeOfUndecodableRequest(t *testing.T) {
	journal := &capturedJournal{}
	handler := journalHandler(t, journal, func(context.Context, DispatchRequest) Response { return Response{} })
	const fileBody = "FILE-BODY-MARKER-must-not-be-stored"
	response := multipartPost(t, handler, [][2]string{{"mid", "65000"}, {"token", "multipart-secret"}, {"form_name", "avatar"}}, []byte(fileBody))
	if response.Code != http.StatusBadRequest {
		t.Fatalf("code=%d body=%s", response.Code, response.Body)
	}
	record := journal.records[0]
	raw := string(record.Raw)
	if record.Disposition != observability.RequestUndecodable || len(record.Raw) == 0 {
		t.Fatalf("record=%+v", record)
	}
	if !strings.Contains(raw, `name="mid"`) || !strings.Contains(raw, "65000") {
		t.Fatalf("envelope lost field names or values: %q", raw)
	}
	if strings.Contains(raw, fileBody) {
		t.Fatalf("file body stored: %q", raw)
	}
	if strings.Contains(raw, "multipart-secret") {
		t.Fatalf("token value stored: %q", raw)
	}
	if len(record.Raw) > rawCaptureBytes {
		t.Fatalf("envelope is not bounded: %d", len(record.Raw))
	}
}

// A-110: every saturated admission is a SERVER_ERROR row; R2 keeps its error class and cause.
func TestJournalRecordsSaturationWithCause(t *testing.T) {
	saturations := map[string]func(*testing.T, *Handler){
		"decoding limit": func(t *testing.T, handler *Handler) {
			decoding := mustAdmission(t, 1)
			if !decoding.TryAcquire() {
				t.Fatal("acquire")
			}
			handler.Decoding = decoding
		},
		"in-flight limit": func(t *testing.T, handler *Handler) {
			admission := mustAdmission(t, 1)
			if !admission.TryAcquire() {
				t.Fatal("acquire")
			}
			handler.Admission = admission
		},
		"queue budget": func(_ *testing.T, handler *Handler) {
			handler.QueueWait = fixedQueueWait(time.Hour)
			handler.QueueBudget = time.Second
		},
	}
	for name, saturate := range saturations {
		t.Run(name, func(t *testing.T) {
			journal := &capturedJournal{}
			handler := journalHandler(t, journal, func(context.Context, DispatchRequest) Response {
				return Response{HTTPStatus: http.StatusOK}
			})
			saturate(t, &handler)
			if response := post(handler, `{"mid":18}`); response.Code != http.StatusServiceUnavailable {
				t.Fatalf("status=%d", response.Code)
			}
			record := journal.records[0]
			var edgeError *wire.EdgeError
			if record.HTTPStatus != http.StatusServiceUnavailable || !errors.As(record.Cause, &edgeError) || edgeError.Class != wire.ErrSaturated {
				t.Fatalf("saturated record has no cause or class: %+v", record)
			}
		})
	}
}

func TestJournalRecordsInactiveModeAnswer(t *testing.T) {
	journal := &capturedJournal{}
	response := post(journalHandler(t, journal, func(context.Context, DispatchRequest) Response {
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": 1}, Inactive: true}
	}), `{"mid":18}`)
	record := journal.records[0]
	if response.Code != http.StatusOK || record.Disposition != observability.RequestInactiveMode || record.ErrorCode != 1 || record.Raw != nil {
		t.Fatalf("code=%d record=%+v", response.Code, record)
	}
}
