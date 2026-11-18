package stockruntime

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/clientlog"
)

type clientLogMemoryStore struct {
	uploads []app.Upload
}

func (s *clientLogMemoryStore) SaveGrant(context.Context, app.Grant) error { return nil }
func (s *clientLogMemoryStore) Grant(context.Context, [32]byte) (app.Grant, bool, error) {
	return app.Grant{}, false, nil
}
func (s *clientLogMemoryStore) SaveUpload(_ context.Context, upload app.Upload) error {
	s.uploads = append(s.uploads, upload)
	return nil
}
func (s *clientLogMemoryStore) SaveJournal(context.Context, []app.JournalRow) error { return nil }
func (s *clientLogMemoryStore) PurgeExpired(context.Context, time.Time, int, int) (int64, error) {
	return 0, nil
}

type clientLogClock struct{}

func (clientLogClock) Now() time.Time { return time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC) }

// A-109: a malformed multipart upload is acknowledged only after its raw body
// is committed as the quarantine record (I85_CLIENT_LOG_INGEST_V1 R4).
func TestMalformedMultipartKeepsTheQuarantinedRawRecord(t *testing.T) {
	store := &clientLogMemoryStore{}
	service := &app.Service{Store: store, Clock: clientLogClock{}}
	handler := ClientLogHandler{Ingest: service, BasePath: "/client-log"}
	body := []byte("short body with no multipart framing")
	request := httptest.NewRequest(http.MethodPost, "/client-log", bytes.NewReader(body))
	request.Header.Set("Content-Type", "multipart/form-data")
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status=%d", recorder.Code)
	}
	if len(store.uploads) != 1 {
		t.Fatalf("uploads=%d", len(store.uploads))
	}
	upload := store.uploads[0]
	if upload.QuarantineReason != app.QuarantineMalformedMultipart || !bytes.Equal(upload.Attachment, body) {
		t.Fatalf("reason=%q attachment=%q", upload.QuarantineReason, upload.Attachment)
	}
}
