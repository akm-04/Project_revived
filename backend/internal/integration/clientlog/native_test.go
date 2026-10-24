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
