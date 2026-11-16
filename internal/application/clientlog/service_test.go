package clientlog

import (
	"bytes"
	"compress/zlib"
	"context"
	"errors"
	"net/http"
	"strings"
	"testing"
	"time"

	domain "gxb.local/backend/v2/internal/domain/clientlog"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/observability"
)

type fixedClock struct{ now time.Time }

func (c *fixedClock) Now() time.Time { return c.now }

type memoryStore struct {
	grants  map[[32]byte]Grant
	uploads []Upload
	journal []JournalRow
	failing bool
}

func (m *memoryStore) SaveGrant(_ context.Context, grant Grant) error {
	m.grants[grant.Digest] = grant
	return nil
}
func (m *memoryStore) Grant(_ context.Context, digest [32]byte) (Grant, bool, error) {
	grant, found := m.grants[digest]
	return grant, found, nil
}
func (m *memoryStore) SaveUpload(_ context.Context, upload Upload) error {
	if m.failing {
		return errors.New("store down")
	}
	m.uploads = append(m.uploads, upload)
	return nil
}
func (m *memoryStore) SaveJournal(_ context.Context, rows []JournalRow) error {
	m.journal = append(m.journal, rows...)
	return nil
}
func (m *memoryStore) PurgeExpired(context.Context, time.Time, int) (int64, error) { return 0, nil }

type tokenResolver map[string]string

func (r tokenResolver) ResolveGameplayBearer(_ context.Context, raw string, _ time.Time) (identity.ActorContext, error) {
	uid, found := r[raw]
	if !found {
		return identity.ActorContext{}, errors.New("not live")
	}
	return identity.ActorContext{AccountUID: identity.AccountUID(uid), PlayerID: 7}, nil
}

func deflate(t *testing.T, text string) []byte {
	t.Helper()
	var buffer bytes.Buffer
	writer := zlib.NewWriter(&buffer)
	if _, err := writer.Write([]byte(text)); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	return buffer.Bytes()
}

func newService() (*Service, *memoryStore, *fixedClock) {
	store := &memoryStore{grants: map[[32]byte]Grant{}}
	clock := &fixedClock{now: time.Date(2026, 10, 22, 12, 0, 0, 0, time.UTC)}
	return &Service{Store: store, Bearers: tokenResolver{"live-token": "20000009"}, Clock: clock, BaseURL: "http://api.test/client-log/"}, store, clock
}

func issue(t *testing.T, service *Service) string {
	t.Helper()
	logURL, err := service.IssueLogURL(context.Background(), Owner{AccountUID: "20000007", PlayerID: 100001, SessionRef: strings.Repeat("a", 32)}, 1)
	if err != nil || !strings.HasPrefix(logURL, "http://api.test/client-log/") {
		t.Fatalf("url=%q err=%v", logURL, err)
	}
	return strings.TrimPrefix(logURL, "http://api.test/client-log/")
}

func TestIngestAttributesThroughTheCapability(t *testing.T) {
	service, store, _ := newService()
	capability := issue(t, service)
	status := service.Ingest(context.Background(), UploadRequest{Capability: capability, Kind: domain.KindErrorLog, Payload: deflate(t, `[{"rowid":1,"isCrash":0,"log":"x\nstack traceback:"}]`)})
	upload := store.uploads[0]
	if status != http.StatusOK || upload.Attribution != AttributedByCapability || upload.Owner.AccountUID != "20000007" || len(upload.Rows) != 1 || upload.Class != domain.Error {
		t.Fatalf("status=%d upload=%+v", status, upload)
	}
}

func TestIngestRedactsSecretsInClientRows(t *testing.T) {
	service, store, _ := newService()
	service.Ingest(context.Background(), UploadRequest{Capability: issue(t, service), Kind: domain.KindErrorLog, Payload: deflate(t, `[{"log":"GET /api?token=abc123&mid=7","dump":"sid=s1","session_token":"x","note":"kept"}]`)})
	row := store.uploads[0].Rows[0]
	if row.Log != "GET /api?token=[REDACTED]&mid=7" || row.Dump != "sid=[REDACTED]" || row.Extras["session_token"] != observability.Redacted || row.Extras["note"] != "kept" {
		t.Fatalf("row=%+v", row)
	}
}

// I85_CLIENT_LOG_INGEST_V1 R8: the capability the upload presented is a secret;
// it never reaches persisted row text, even as a bare URL path segment.
func TestIngestRedactsThePresentedCapability(t *testing.T) {
	service, store, _ := newService()
	capability := issue(t, service)
	logURL := "http://api.test/client-log/" + capability
	payload := deflate(t, `[{"log":"post failed `+logURL+`","dump":"log_url=`+logURL+`","note":"`+logURL+`","keep":"value"}]`)
	service.Ingest(context.Background(), UploadRequest{Capability: capability, Kind: domain.KindErrorLog, Payload: payload})
	row := store.uploads[0].Rows[0]
	if row.Log != "post failed http://api.test/client-log/"+observability.Redacted {
		t.Fatalf("log=%q", row.Log)
	}
	if row.Dump != "log_url="+observability.Redacted || row.Extras["keep"] != "value" {
		t.Fatalf("dump=%q extras=%v", row.Dump, row.Extras)
	}
	if note, _ := row.Extras["note"].(string); note != "http://api.test/client-log/"+observability.Redacted {
		t.Fatalf("extras=%v", row.Extras)
	}
	other, otherStore, _ := newService()
	other.Ingest(context.Background(), UploadRequest{Capability: "x", Kind: domain.KindErrorLog, Payload: deflate(t, `[{"log":"x marks the spot"}]`)})
	if got := otherStore.uploads[0].Rows[0].Log; got != "x marks the spot" {
		t.Fatalf("malformed segment mangled text: %q", got)
	}
}

func TestIngestNeverGuessesAnOwner(t *testing.T) {
	service, store, clock := newService()
	capability := issue(t, service)
	payload := deflate(t, `[{"log":"routine"}]`)
	service.Ingest(context.Background(), UploadRequest{Kind: domain.KindErrorLog, Payload: payload})
	service.Ingest(context.Background(), UploadRequest{Capability: strings.Repeat("A", 43), Kind: domain.KindErrorLog, Payload: payload})
	clock.now = clock.now.Add(domain.CapabilityLifetime)
	service.Ingest(context.Background(), UploadRequest{Capability: capability, Kind: domain.KindErrorLog, Payload: payload})
	want := []Attribution{UnattributedMissing, UnattributedUnknown, UnattributedExpired}
	for index, upload := range store.uploads {
		if upload.Attribution != want[index] || upload.Owner != nil || upload.Class != domain.Anomaly || upload.Rows[0].Class != domain.Anomaly {
			t.Errorf("upload %d=%+v", index, upload)
		}
	}
}

func TestCrashUploadPrefersTheLiveTokenWhenTheCapabilityDisagrees(t *testing.T) {
	service, store, _ := newService()
	capability := issue(t, service)
	service.Ingest(context.Background(), UploadRequest{Capability: capability, Kind: domain.KindCrash, Token: "live-token", AttachmentName: "a.dmp", Attachment: []byte{0, 1, 2}})
	service.Ingest(context.Background(), UploadRequest{Kind: domain.KindCrash, Token: "dead-token", AttachmentName: "b.dmp", Attachment: []byte{3}})
	if store.uploads[0].Attribution != AttributedByToken || store.uploads[0].Owner.AccountUID != "20000009" || store.uploads[0].Class != domain.Error {
		t.Fatalf("token upload=%+v", store.uploads[0])
	}
	if store.uploads[1].Attribution != UnattributedMissing || !bytes.Equal(store.uploads[1].Attachment, []byte{3}) {
		t.Fatalf("dead token upload=%+v", store.uploads[1])
	}
}

func TestBadInputIsQuarantinedAndAcknowledged(t *testing.T) {
	service, store, _ := newService()
	capability := issue(t, service)
	cases := map[string]UploadRequest{
		QuarantineBadCompression:     {Capability: capability, Kind: domain.KindErrorLog, Payload: []byte("plain")},
		QuarantineBadRows:            {Capability: capability, Kind: domain.KindErrorLog, Payload: deflate(t, `"text"`)},
		QuarantineMalformedMultipart: {Capability: capability, Malformed: QuarantineMalformedMultipart},
	}
	for reason, request := range cases {
		store.uploads = nil
		if status := service.Ingest(context.Background(), request); status != http.StatusOK {
			t.Fatalf("%s status=%d", reason, status)
		}
		upload := store.uploads[0]
		if upload.QuarantineReason != reason || upload.Class != domain.Anomaly || !bytes.Equal(upload.Attachment, request.Payload) {
			t.Errorf("%s upload=%+v", reason, upload)
		}
	}
}

func TestIngestRateLimitAndStoreFailure(t *testing.T) {
	service, store, _ := newService()
	capability := issue(t, service)
	request := UploadRequest{Capability: capability, Kind: domain.KindErrorLog, Payload: deflate(t, `{}`)}
	for range domain.UploadsPerMinute {
		if status := service.Ingest(context.Background(), request); status != http.StatusOK {
			t.Fatalf("status=%d", status)
		}
	}
	if status := service.Ingest(context.Background(), request); status != http.StatusTooManyRequests {
		t.Fatalf("over limit status=%d", status)
	}
	other, failing, _ := newService()
	failing.failing = true
	if status := other.Ingest(context.Background(), UploadRequest{Kind: domain.KindErrorLog}); status != http.StatusServiceUnavailable {
		t.Fatalf("store failure status=%d", status)
	}
	if len(store.uploads) != domain.UploadsPerMinute {
		t.Fatalf("stored=%d", len(store.uploads))
	}
}

func TestEmptyBaseKeepsTheStockEmptyLogURL(t *testing.T) {
	service, _, _ := newService()
	service.BaseURL = ""
	if logURL, err := service.IssueLogURL(context.Background(), Owner{}, 1); logURL != "" || err != nil {
		t.Fatalf("url=%q err=%v", logURL, err)
	}
}

func TestJournalRowsRedactAndClassify(t *testing.T) {
	store := &memoryStore{}
	journal := NewJournal(store, nil)
	journal.Record(observability.RequestRecord{Disposition: observability.RequestDispatched, MID: 7, HasMID: true, HTTPStatus: 503, Cause: errors.New("dial: password=hunter2"), Actor: observability.RequestActor{AccountUID: "u1", SessionID: "s"}})
	journal.Record(observability.RequestRecord{Disposition: observability.RequestUnknownMID, MID: 65000, HasMID: true, HTTPStatus: 404, Raw: []byte("payload=%7B%22mid%22%3A65000%2C%22token%22%3A%22abc%22%7D")})
	journal.Record(observability.RequestRecord{Disposition: observability.RequestDispatched, MID: 7, HasMID: true, HTTPStatus: 200, Cause: errors.New("ignored")})
	journal.Record(observability.RequestRecord{Disposition: observability.RequestDispatched, MID: 1, HasMID: true, HTTPStatus: 503, Cause: errors.New("log post failed log_url=https://api.test/client-log/secret")})
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	journal.Run(ctx)
	if len(store.journal) != 4 {
		t.Fatalf("rows=%d", len(store.journal))
	}
	failure, unknown, ok, logURL := store.journal[0], store.journal[1], store.journal[2], store.journal[3]
	if failure.Outcome != domain.OutcomeServerError || failure.Class != domain.Error || failure.Cause != "dial: password=[REDACTED]" || failure.ErrorClass != "*errors.errorString" || failure.Owner.AccountUID != "u1" {
		t.Fatalf("failure=%+v", failure)
	}
	if unknown.Outcome != domain.OutcomeUnknownMID || unknown.Class != domain.Anomaly || string(unknown.RawEnvelope) != `payload={"mid":65000,"token":"[REDACTED]"}` || unknown.Owner != nil {
		t.Fatalf("unknown=%+v raw=%s", unknown, unknown.RawEnvelope)
	}
	if ok.Outcome != domain.OutcomeOK || ok.Cause != "" || ok.Class != domain.Routine {
		t.Fatalf("ok=%+v", ok)
	}
	if logURL.Cause != "log post failed log_url=[REDACTED]" {
		t.Fatalf("log url cause=%q", logURL.Cause)
	}
}

func TestJournalKeepsMultipartEnvelopeWithoutFormUnescaping(t *testing.T) {
	store := &memoryStore{}
	journal := NewJournal(store, nil)
	const envelope = "--x\r\nContent-Disposition: form-data; name=\"file_path\"\r\n\r\n/a+b%2Fc\r\n"
	journal.Record(observability.RequestRecord{Disposition: observability.RequestUndecodable, Raw: []byte(envelope)})
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	journal.Run(ctx)
	if got := string(store.journal[0].RawEnvelope); got != envelope {
		t.Fatalf("raw=%q", got)
	}
}

// A-048: uploads that resolve to no grant share one bucket, so a poster without
// a capability cannot store without bound.
func TestIngestRateLimitsUnattributedUploads(t *testing.T) {
	service, store, _ := newService()
	payload := deflate(t, `{}`)
	for index := range domain.UploadsPerMinute {
		request := UploadRequest{Capability: strings.Repeat("A", 42) + string(rune('a'+index%26)), Kind: domain.KindErrorLog, Payload: payload}
		if status := service.Ingest(context.Background(), request); status != http.StatusOK {
			t.Fatalf("upload %d status=%d", index, status)
		}
	}
	for _, capability := range []string{"", strings.Repeat("B", 43)} {
		if status := service.Ingest(context.Background(), UploadRequest{Capability: capability, Kind: domain.KindErrorLog, Payload: payload}); status != http.StatusTooManyRequests {
			t.Fatalf("capability %q over limit status=%d", capability, status)
		}
	}
	if len(store.uploads) != domain.UploadsPerMinute {
		t.Fatalf("stored=%d", len(store.uploads))
	}
	attributed := UploadRequest{Capability: issue(t, service), Kind: domain.KindErrorLog, Payload: payload}
	if status := service.Ingest(context.Background(), attributed); status != http.StatusOK {
		t.Fatalf("attributed upload shares the unattributed bucket: status=%d", status)
	}
}
