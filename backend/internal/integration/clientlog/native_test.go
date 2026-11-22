//go:build postgres

package clientlog_test

import (
	"bytes"
	"compress/zlib"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/clientlogstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/clientlog"
	domain "gxb.local/backend/v2/internal/domain/clientlog"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

var ctx = context.Background()

type movableClock struct{ now time.Time }

func (c *movableClock) Now() time.Time { return c.now }

type liveTokens map[string]string

func (tokens liveTokens) ResolveGameplayBearer(_ context.Context, raw string, _ time.Time) (identity.ActorContext, error) {
	uid, found := tokens[raw]
	if !found {
		return identity.ActorContext{}, errors.New("not live")
	}
	return identity.ActorContext{AccountUID: identity.AccountUID(uid), PlayerID: 300001}, nil
}

type fixture struct {
	pool    *pg.Pool
	store   clientlogstore.Store
	service *app.Service
	clock   *movableClock
	server  *httptest.Server
	uid     string
}

// newFixture serves the real handler on a test server; each test run gets its own uid so reruns share the database.
func newFixture(t *testing.T) *fixture {
	t.Helper()
	dsn := os.Getenv("GXB_I85_CLIENTLOG_DSN")
	if dsn == "" {
		t.Fatal("required exact native DSN missing")
	}
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	uid := fmt.Sprintf("85%013d", time.Now().UnixNano()%1e13)
	f := &fixture{pool: pool, store: clientlogstore.Store{Pool: pool.Raw()}, clock: &movableClock{now: time.Now().UTC().Truncate(time.Microsecond)}, uid: uid}
	mux := http.NewServeMux()
	f.server = httptest.NewServer(mux)
	t.Cleanup(f.server.Close)
	f.service = &app.Service{Store: f.store, Bearers: liveTokens{"live-" + uid: uid}, Clock: f.clock, BaseURL: f.server.URL + "/client-log"}
	mux.Handle("/client-log/", stockruntime.ClientLogHandler{Ingest: f.service, BasePath: "/client-log"})
	return f
}

func (f *fixture) logURL(t *testing.T) string {
	t.Helper()
	logURL, err := f.service.IssueLogURL(ctx, app.Owner{AccountUID: f.uid, PlayerID: 300001, SessionRef: strings.Repeat("b", 32)}, 1)
	if err != nil {
		t.Fatal(err)
	}
	return logURL
}

// stockPost builds the body Backend.lua log() sends: multipart fields, plus the dump file for type 1.
func stockPost(t *testing.T, target string, fields map[string][]byte, fileName string, file []byte) int {
	t.Helper()
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	for name, value := range fields {
		if err := writer.WriteField(name, string(value)); err != nil {
			t.Fatal(err)
		}
	}
	if fileName != "" {
		part, err := writer.CreateFormFile("file", fileName)
		if err != nil {
			t.Fatal(err)
		}
		part.Write(file)
	}
	writer.Close()
	response, err := http.Post(target, writer.FormDataContentType(), &body)
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()
	return response.StatusCode
}

func lifetime(class domain.RetentionClass) time.Duration {
	var zero time.Time
	return class.ExpiresAt(zero).Sub(zero)
}

func deflated(t *testing.T, text string) []byte {
	t.Helper()
	var buffer bytes.Buffer
	writer := zlib.NewWriter(&buffer)
	writer.Write([]byte(text))
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	return buffer.Bytes()
}

type uploadRow struct {
	attribution, status, retention string
	reason                         *string
	rows                           int
	attachment                     int
	expiresIn                      time.Duration
}

func (f *fixture) uploads(t *testing.T, where string, args ...any) []uploadRow {
	t.Helper()
	rows, err := f.pool.Raw().Query(ctx, `SELECT attribution,status,retention_class,quarantine_reason,row_count,coalesce(length(attachment),0),expires_at-received_at FROM client_log_uploads WHERE `+where+` ORDER BY received_at, upload_id`, args...)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	var out []uploadRow
	for rows.Next() {
		var row uploadRow
		if err := rows.Scan(&row.attribution, &row.status, &row.retention, &row.reason, &row.rows, &row.attachment, &row.expiresIn); err != nil {
			t.Fatal(err)
		}
		out = append(out, row)
	}
	return out
}

func TestStockErrorLogUploadIsStoredPerUID(t *testing.T) {
	f := newFixture(t)
	payload := deflated(t, `[{"rowid":1,"time":1761134400,"app_v":"1.0.4","version":"2.3","isCrash":0,"dump":"","log":"MID 73 timeout"},{"rowid":2,"time":1761134401,"app_v":"1.0.4","version":"2.3","isCrash":1,"dump":"d","log":"attempt to index nil\nstack traceback:","extra":"kept"}]`)
	if status := stockPost(t, f.logURL(t), map[string][]byte{"payload": payload}, "", nil); status != http.StatusOK {
		t.Fatalf("status=%d", status)
	}
	got := f.uploads(t, `account_uid=$1`, f.uid)
	if len(got) != 1 || got[0].attribution != "CAPABILITY" || got[0].status != "PARSED" || got[0].rows != 2 || got[0].retention != "ERROR" || got[0].expiresIn != lifetime(domain.Error) {
		t.Fatalf("uploads=%+v", got)
	}
	var crashRows, extras int
	if err := f.pool.Raw().QueryRow(ctx, `SELECT count(*) FILTER (WHERE is_crash), count(*) FILTER (WHERE extras ? 'extra') FROM client_log_rows WHERE account_uid=$1`, f.uid).Scan(&crashRows, &extras); err != nil || crashRows != 1 || extras != 1 {
		t.Fatalf("crash=%d extras=%d err=%v", crashRows, extras, err)
	}
}

// I85_CLIENT_LOG_INGEST_V1 R8: no persisted row may keep the capability the
// upload presented, whether it is logged as a bare URL or a key=value pair.
func TestStockErrorLogRedactsThePresentedCapability(t *testing.T) {
	f := newFixture(t)
	logURL := f.logURL(t)
	capability := strings.TrimPrefix(logURL, f.server.URL+"/client-log/")
	payload := deflated(t, `[{"rowid":1,"log":"post failed `+logURL+`","dump":"log_url=`+logURL+`","note":"`+logURL+`"}]`)
	if status := stockPost(t, logURL, map[string][]byte{"payload": payload}, "", nil); status != http.StatusOK {
		t.Fatalf("status=%d", status)
	}
	var logText, dumpText, extras string
	if err := f.pool.Raw().QueryRow(ctx, `SELECT log, dump, coalesce(extras::text,'') FROM client_log_rows WHERE account_uid=$1`, f.uid).Scan(&logText, &dumpText, &extras); err != nil {
		t.Fatal(err)
	}
	if stored := logText + dumpText + extras; strings.Contains(stored, capability) {
		t.Fatalf("capability stored: %q", stored)
	}
	if logText != "post failed "+strings.TrimSuffix(logURL, capability)+observability.Redacted || !strings.Contains(dumpText, observability.Redacted) || !strings.Contains(extras, observability.Redacted) {
		t.Fatalf("log=%q dump=%q extras=%q", logText, dumpText, extras)
	}
}

func TestStockCrashUploadKeepsTheDumpAndPrefersTheToken(t *testing.T) {
	f := newFixture(t)
	fields := map[string][]byte{"app_v": []byte("1.0.4"), "v": []byte("2.3"), "token": []byte("live-" + f.uid)}
	if status := stockPost(t, f.server.URL+"/client-log", fields, "crash.dmp", []byte("MDMP\x00\x01")); status != http.StatusOK {
		t.Fatalf("status=%d", status)
	}
	got := f.uploads(t, `account_uid=$1`, f.uid)
	if len(got) != 1 || got[0].attribution != "TOKEN" || got[0].attachment != 6 || got[0].retention != "ERROR" {
		t.Fatalf("uploads=%+v", got)
	}
}

func TestBadUploadsAreQuarantinedUnattributedWhenNoOwnerIsProven(t *testing.T) {
	f := newFixture(t)
	logURL := f.logURL(t)
	marker := "quarantine-" + f.uid
	stockPost(t, logURL, map[string][]byte{"payload": []byte(marker)}, "", nil)
	f.clock.now = f.clock.now.Add(time.Second)
	stockPost(t, f.server.URL+"/client-log/"+strings.Repeat("Z", 43), map[string][]byte{"payload": deflated(t, `[{"log":"`+marker+`"}]`)}, "", nil)
	f.clock.now = f.clock.now.Add(time.Second)
	response, err := http.Post(logURL, "multipart/form-data; boundary=x", strings.NewReader(marker))
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()
	owned := f.uploads(t, `account_uid=$1`, f.uid)
	if len(owned) != 2 || *owned[0].reason != app.QuarantineBadCompression || *owned[1].reason != app.QuarantineMalformedMultipart || owned[0].retention != "ANOMALY" {
		t.Fatalf("owned=%+v", owned)
	}
	unknown := f.uploads(t, `account_uid IS NULL AND upload_id IN (SELECT upload_id FROM client_log_rows WHERE log=$1)`, marker)
	if len(unknown) != 1 || unknown[0].attribution != "UNATTRIBUTED_UNKNOWN" || unknown[0].status != "PARSED" {
		t.Fatalf("unknown=%+v", unknown)
	}
	var rowRetention string
	var rowExpiresIn time.Duration
	if err := f.pool.Raw().QueryRow(ctx, `SELECT retention_class, expires_at-received_at FROM client_log_rows WHERE account_uid IS NULL AND log=$1`, marker).Scan(&rowRetention, &rowExpiresIn); err != nil || rowRetention != "ANOMALY" || rowExpiresIn != lifetime(domain.Anomaly) {
		t.Fatalf("unattributed row retention=%s expiresIn=%s err=%v", rowRetention, rowExpiresIn, err)
	}
}

// A-109: a malformed multipart upload keeps its raw body as the quarantine
// record (I85_CLIENT_LOG_INGEST_V1 R4), including when the Content-Type carries
// no boundary at all.
func TestMalformedMultipartKeepsTheRawRecord(t *testing.T) {
	f := newFixture(t)
	body := "malformed-" + f.uid + "-body without multipart framing"
	response, err := http.Post(f.logURL(t), "multipart/form-data", strings.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("status=%d", response.StatusCode)
	}
	got := f.uploads(t, `account_uid=$1`, f.uid)
	if len(got) != 1 || got[0].reason == nil || *got[0].reason != app.QuarantineMalformedMultipart || got[0].attachment != len(body) {
		t.Fatalf("uploads=%+v", got)
	}
	var stored string
	if err := f.pool.Raw().QueryRow(ctx, `SELECT encode(attachment,'escape') FROM client_log_uploads WHERE account_uid=$1`, f.uid).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if stored != body {
		t.Fatalf("attachment=%q", stored)
	}
}

// A-132: a well-framed multipart with metadata but no payload persists a
// redacted envelope summary as its quarantine record before answering 200.
func TestMetadataOnlyMultipartKeepsTheEnvelopeDiagnostic(t *testing.T) {
	f := newFixture(t)
	fields := map[string][]byte{"app_v": []byte("1.0"), "token": []byte("secret-token")}
	if status := stockPost(t, f.logURL(t), fields, "", nil); status != http.StatusOK {
		t.Fatalf("status=%d", status)
	}
	got := f.uploads(t, `account_uid=$1`, f.uid)
	if len(got) != 1 || got[0].reason == nil || *got[0].reason != app.QuarantineBadCompression || got[0].attachment == 0 {
		t.Fatalf("uploads=%+v", got)
	}
	var stored string
	if err := f.pool.Raw().QueryRow(ctx, `SELECT encode(attachment,'escape') FROM client_log_uploads WHERE account_uid=$1`, f.uid).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(stored, "app_v=1.0") || !strings.Contains(stored, "token=") {
		t.Fatalf("attachment=%q", stored)
	}
	if strings.Contains(stored, "secret-token") {
		t.Fatalf("attachment leaked a secret: %q", stored)
	}
}

// TestRequestJournalKeepsRedactedMultipartEnvelope drives the production edge,
// journal and store: an undecodable multipart upload must persist an envelope
// with its field names but no file body and no token value (I85_REQUEST_JOURNAL_V1 R3).
func TestRequestJournalKeepsRedactedMultipartEnvelope(t *testing.T) {
	f := newFixture(t)
	journal := app.NewJournal(f.store, nil)
	admission, err := httpedge.NewAdmission(4)
	if err != nil {
		t.Fatal(err)
	}
	handler := httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: f.clock}, Router: httpedge.NewRouter(), Journal: journal}
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)

	const fileBody = "FILE-BODY-MARKER-must-not-be-stored"
	marker := "journal-probe-" + f.uid
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	part, err := writer.CreateFormFile("avatar", "avatar.png")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := part.Write([]byte(fileBody)); err != nil {
		t.Fatal(err)
	}
	for _, field := range [][2]string{{"mid", "65000"}, {"token", "multipart-secret"}, {"note", marker}} {
		if err := writer.WriteField(field[0], field[1]); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	response, err := http.Post(server.URL, writer.FormDataContentType(), &body)
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()
	if response.StatusCode != http.StatusBadRequest {
		t.Fatalf("status=%d", response.StatusCode)
	}
	stopped, stop := context.WithCancel(ctx)
	stop()
	journal.Run(stopped)

	var raw, retention string
	err = f.pool.Raw().QueryRow(ctx, `SELECT encode(raw_envelope,'escape'), retention_class FROM request_journal WHERE encode(raw_envelope,'escape') LIKE $1`, "%"+marker+"%").Scan(&raw, &retention)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(raw, `name="mid"`) || !strings.Contains(raw, "65000") || retention != "ANOMALY" {
		t.Fatalf("raw=%q retention=%s", raw, retention)
	}
	if strings.Contains(raw, fileBody) {
		t.Fatalf("file body stored: %q", raw)
	}
	if strings.Contains(raw, "multipart-secret") {
		t.Fatalf("token value stored: %q", raw)
	}
}

// A-110: a saturated decoding admission persists a SERVER_ERROR row with its error class and cause (R2).
func TestRequestJournalRecordsSaturatedAdmissionCause(t *testing.T) {
	f := newFixture(t)
	journal := app.NewJournal(f.store, nil)
	admission, err := httpedge.NewAdmission(4)
	if err != nil {
		t.Fatal(err)
	}
	decoding, err := httpedge.NewAdmission(1)
	if err != nil {
		t.Fatal(err)
	}
	if !decoding.TryAcquire() {
		t.Fatal("acquire")
	}
	handler := httpedge.Handler{Limits: limits.Default(), Admission: admission, Decoding: decoding, Operations: operation.Factory{Clock: f.clock}, Router: httpedge.NewRouter(), Journal: journal}
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)

	response, err := http.Post(server.URL, "application/x-www-form-urlencoded", strings.NewReader("payload=%7B%22mid%22%3A18%7D"))
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("status=%d", response.StatusCode)
	}
	stopped, stop := context.WithCancel(ctx)
	stop()
	journal.Run(stopped)

	var outcome, errorClass, cause, retention string
	err = f.pool.Raw().QueryRow(ctx, `SELECT outcome, error_class, cause, retention_class FROM request_journal WHERE http_status = 503 AND cause LIKE 'SATURATED:%' ORDER BY journal_id DESC LIMIT 1`).Scan(&outcome, &errorClass, &cause, &retention)
	if err != nil {
		t.Fatal(err)
	}
	if outcome != "SERVER_ERROR" || errorClass == "" || !strings.Contains(cause, "decoding limit saturated") || retention != "ERROR" {
		t.Fatalf("outcome=%s class=%q cause=%q retention=%s", outcome, errorClass, cause, retention)
	}
}

func TestRateLimitAnswers429(t *testing.T) {
	f := newFixture(t)
	logURL := f.logURL(t)
	payload := map[string][]byte{"payload": deflated(t, `{}`)}
	for range domain.UploadsPerMinute {
		stockPost(t, logURL, payload, "", nil)
	}
	if status := stockPost(t, logURL, payload, "", nil); status != http.StatusTooManyRequests {
		t.Fatalf("status=%d", status)
	}
	if got := f.uploads(t, `account_uid=$1`, f.uid); len(got) != domain.UploadsPerMinute || got[0].retention != "ROUTINE" || got[0].expiresIn != lifetime(domain.Routine) {
		t.Fatalf("uploads=%d first=%+v", len(got), got[0])
	}
}

func TestJournalPurgeAndTimeline(t *testing.T) {
	f := newFixture(t)
	actor := observability.RequestActor{AccountUID: f.uid, PlayerID: 300001, SessionID: "00000000-0000-4000-8000-000000000005"}
	journal := app.NewJournal(f.store, nil)
	base := f.clock.now.Add(-time.Hour)
	records := []observability.RequestRecord{
		{ReceivedAt: base, Disposition: observability.RequestDispatched, MID: 1, HasMID: true, HTTPStatus: 200, Actor: actor},
		{ReceivedAt: base.Add(time.Second), Disposition: observability.RequestDispatched, MID: 73, HasMID: true, HTTPStatus: 200, ErrorCode: 2008, Actor: actor},
		{ReceivedAt: base.Add(2 * time.Second), Disposition: observability.RequestDispatched, MID: 73, HasMID: true, HTTPStatus: 503, Cause: errors.New("conn refused password=hunter2"), Actor: actor},
		{ReceivedAt: base.Add(3 * time.Second), Disposition: observability.RequestUnknownMID, MID: 65000, HasMID: true, HTTPStatus: 404, Raw: []byte("payload=%7B%22token%22%3A%22t%22%7D"), Actor: actor},
	}
	for _, record := range records {
		journal.Record(record)
	}
	stopped, stop := context.WithCancel(ctx)
	stop()
	journal.Run(stopped)
	f.clock.now = base.Add(4 * time.Second)
	stockPost(t, f.logURL(t), map[string][]byte{"payload": deflated(t, `[{"rowid":9,"log":"after"}]`)}, "", nil)

	lines, err := f.store.Timeline(ctx, f.uid, base.Add(-time.Minute), 100)
	if err != nil {
		t.Fatal(err)
	}
	var sources, outcomes []string
	for _, line := range lines {
		var entry map[string]any
		if err := json.Unmarshal(line, &entry); err != nil {
			t.Fatal(err)
		}
		sources = append(sources, entry["source"].(string))
		if outcome, found := entry["outcome"].(string); found {
			outcomes = append(outcomes, outcome)
		}
		if cause, found := entry["cause"].(string); found && strings.Contains(cause, "hunter2") {
			t.Fatalf("cause not redacted: %s", cause)
		}
	}
	if strings.Join(sources, ",") != "journal,journal,journal,journal,upload,client_row" || strings.Join(outcomes, ",") != "OK,CLIENT_ERROR,SERVER_ERROR,UNKNOWN_MID" {
		t.Fatalf("sources=%v outcomes=%v", sources, outcomes)
	}

	f.clock.now = base.Add(lifetime(domain.Routine) + 5*time.Second)
	if _, err := f.service.Purge(ctx); err != nil {
		t.Fatal(err)
	}
	var journalRows, uploadRows, clientRows int
	if err := f.pool.Raw().QueryRow(ctx, `SELECT (SELECT count(*) FROM request_journal WHERE account_uid=$1), (SELECT count(*) FROM client_log_uploads WHERE account_uid=$1), (SELECT count(*) FROM client_log_rows WHERE account_uid=$1)`, f.uid).Scan(&journalRows, &uploadRows, &clientRows); err != nil {
		t.Fatal(err)
	}
	if journalRows != 3 || uploadRows != 0 || clientRows != 0 {
		t.Fatalf("after routine expiry journal=%d uploads=%d rows=%d (error and anomaly rows stay)", journalRows, uploadRows, clientRows)
	}
}
