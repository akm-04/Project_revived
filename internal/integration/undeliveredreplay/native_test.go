//go:build postgres

package undeliveredreplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/clientlogstore"
	"gxb.local/backend/v2/internal/adapters/postgres/gmquestionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/undeliveredstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appclientlog "gxb.local/backend/v2/internal/application/clientlog"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/gmquestion"
	domainclientlog "gxb.local/backend/v2/internal/domain/clientlog"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/foundation/undelivered"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

var ctx = context.Background()

const (
	digestSecret = "r6-native-digest-secret-0001"
	bearerSecret = "r6-native-bearer-secret-0001"
	keyID        = "r6-native-key"
)

type harness struct {
	t       *testing.T
	pool    *postgres.Pool
	router  *httpedge.Router
	handler http.Handler
	store   undeliveredstore.Store
	bearer  string
	player  int64
	journal *captureJournal
	metrics *captureMetrics
}

type captureJournal struct {
	mutex   sync.Mutex
	records []observability.RequestRecord
}

func (j *captureJournal) Record(record observability.RequestRecord) {
	j.mutex.Lock()
	defer j.mutex.Unlock()
	j.records = append(j.records, record)
}

func (j *captureJournal) all() []observability.RequestRecord {
	j.mutex.Lock()
	defer j.mutex.Unlock()
	return append([]observability.RequestRecord(nil), j.records...)
}

func (j *captureJournal) replays() int {
	count := 0
	for _, record := range j.all() {
		if record.Replay {
			count++
		}
	}
	return count
}

type captureMetrics struct {
	mutex    sync.Mutex
	counters map[string]uint64
}

func (m *captureMetrics) Counter(name string, _ observability.Labels, delta uint64) {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	if m.counters == nil {
		m.counters = map[string]uint64{}
	}
	m.counters[name] += delta
}

func (m *captureMetrics) Observe(string, observability.Labels, time.Duration) {}

func (m *captureMetrics) value(name string) uint64 {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	return m.counters[name]
}

func nativePool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_R6_UNDELIVERED_DSN")
	if dsn == "" {
		t.Fatal("GXB_R6_UNDELIVERED_DSN required")
	}
	pool, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func newHarness(t *testing.T) *harness {
	t.Helper()
	pool := nativePool(t)
	player, session, gameplayContext := seedPlayer(t, pool)
	bearer, credentialDigest := credentials(t, gameplayContext)
	credential, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at) VALUES($1,$2,$3,$4,1,$5,clock_timestamp())`, credential.String(), gameplayContext.String(), session.String(), credentialDigest[:], keyID); err != nil {
		t.Fatal(err)
	}
	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: []byte(digestSecret), BearerSecret: []byte(bearerSecret), DerivationKeyID: keyID}
	if _, err := authority.ResolveGameplayBearer(ctx, bearer, time.Now().UTC()); err != nil {
		t.Fatalf("bearer does not resolve: %v", err)
	}
	store := undeliveredstore.Store{Pool: pool.Raw()}
	journal := &captureJournal{}
	metrics := &captureMetrics{}
	dispatcher := stockruntime.GMQuestionDispatcher{Authority: authority, Service: gmQuestionService(pool)}
	router := httpedge.NewRouter()
	router.Wrap = func(next httpedge.Dispatcher) httpedge.Dispatcher {
		return stockruntime.UndeliveredReplay{Next: stockruntime.Decorated{Next: next}, Authority: authority, Marks: store, Window: 10 * time.Minute, Metrics: metrics}
	}
	for _, mid := range []uint16{4, 5} {
		if err := router.Register(mid, dispatcher); err != nil {
			t.Fatal(err)
		}
	}
	h := &harness{t: t, pool: pool, router: router, store: store, bearer: bearer, player: player, journal: journal, metrics: metrics}
	h.handler = h.buildHandler(store, metrics)
	return h
}

func credentials(t *testing.T, gameplayContext ids.UUID) (string, identity.CredentialDigest) {
	t.Helper()
	contextID, err := identity.ContextIDFrom(gameplayContext)
	if err != nil {
		t.Fatal(err)
	}
	bearer, err := identity.DeriveGameplayBearer([]byte(bearerSecret), identity.GameplayContext{ID: contextID, ContextGeneration: 1})
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer([]byte(digestSecret), bearer)
	if err != nil {
		t.Fatal(err)
	}
	return bearer, digest
}

func gmQuestionService(pool *postgres.Pool) gmquestion.Service {
	return gmquestion.Service{
		Timed:         gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: tx.Runner{DB: pool}},
		Fence:         i5store.Store{Queryer: pool},
		Players:       i4store.PlayerRootLocker{},
		Owner:         gmquestionstore.Store{},
		Directory:     i4store.TransactionDiscoveryReader{},
		Receipts:      kernelstore.Store{},
		ReceiptReader: kernelstore.Reader{Queryer: pool},
	}
}

func (h *harness) buildHandler(marker undelivered.Marker, metrics observability.Metrics) http.Handler {
	h.t.Helper()
	admission, err := httpedge.NewAdmission(16)
	if err != nil {
		h.t.Fatal(err)
	}
	return httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: h.router, Undelivered: marker, Metrics: metrics, Journal: h.journal}
}

func seedPlayer(t *testing.T, pool *postgres.Pool) (int64, ids.UUID, ids.UUID) {
	t.Helper()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	gameplayContext, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	var player int64
	if err := pool.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&player); err != nil {
		t.Fatal(err)
	}
	for _, row := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,clock_timestamp(),'r6-native')`, []any{player, account.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{session.String(), account.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at) VALUES($1,$2,$3,1,$4,1,clock_timestamp()-interval '1 hour')`, []any{gameplayContext.String(), session.String(), account.String(), player}},
	} {
		if _, err := pool.Raw().Exec(ctx, row.sql, row.args...); err != nil {
			t.Fatal(err)
		}
	}
	return player, session, gameplayContext
}

func (h *harness) questionCount() int64 {
	h.t.Helper()
	var count int64
	if err := h.pool.QueryRow(ctx, `SELECT count(*) FROM player_gm_questions WHERE player_id=$1`, h.player).Scan(&count); err != nil {
		h.t.Fatal(err)
	}
	return count
}

func (h *harness) markExists() bool {
	h.t.Helper()
	var exists bool
	if err := h.pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM player_undelivered_replies WHERE player_id=$1)`, h.player).Scan(&exists); err != nil {
		h.t.Fatal(err)
	}
	return exists
}

func (h *harness) request(mid int, message string, writer http.ResponseWriter) {
	h.t.Helper()
	params := map[string]any{"mid": int64(mid), "token": h.bearer, "region": int64(1), "app_v": "1.0", "platform": "3", "v_": "123"}
	if mid == 5 {
		params["msg"] = message
	}
	body, err := json.Marshal(params)
	if err != nil {
		h.t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(string(body))))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	if writer == nil {
		writer = httptest.NewRecorder()
	}
	h.handler.ServeHTTP(writer, request)
}

func (h *harness) requestWith(handler http.Handler, mid int, message string, bearer string, writer http.ResponseWriter) {
	h.t.Helper()
	params := map[string]any{"mid": int64(mid), "token": bearer, "region": int64(1), "app_v": "1.0", "platform": "3", "v_": "123"}
	if mid == 5 {
		params["msg"] = message
	}
	body, err := json.Marshal(params)
	if err != nil {
		h.t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(string(body))))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	handler.ServeHTTP(writer, request)
}

type disconnectWriter struct {
	header  http.Header
	status  int
	written []byte
}

func (w *disconnectWriter) Header() http.Header {
	if w.header == nil {
		w.header = http.Header{}
	}
	return w.header
}

func (w *disconnectWriter) WriteHeader(status int) { w.status = status }

func (w *disconnectWriter) Write(p []byte) (int, error) {
	w.written = append(w.written, p...)
	return 0, errors.New("client disconnected")
}

type failingMarker struct{}

func (failingMarker) Mark(context.Context, undelivered.Mark) error {
	return errors.New("mark store down")
}

func TestUndeliveredReplayThroughProductionDispatcher(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	first := &disconnectWriter{}
	h.request(5, "lost reply", first)
	if len(first.written) == 0 {
		t.Fatal("first reply was not encoded")
	}
	if !h.markExists() {
		t.Fatal("no mark after an undelivered success")
	}
	resend := httptest.NewRecorder()
	h.request(5, "lost reply", resend)
	if resend.Code != http.StatusOK || resend.Body.String() != string(first.written) {
		t.Fatalf("replay status=%d body=%q want=%q", resend.Code, resend.Body.String(), first.written)
	}
	if got := h.questionCount(); got != before+1 {
		t.Fatalf("questions=%d want=%d (a replay must not run the operation)", got, before+1)
	}
	if h.metrics.value(undelivered.MarksTotal) != 1 || h.metrics.value(undelivered.ReplaysTotal) != 1 {
		t.Fatalf("counters marks=%d replays=%d", h.metrics.value(undelivered.MarksTotal), h.metrics.value(undelivered.ReplaysTotal))
	}
	records := h.journal.all()
	if len(records) < 2 || !records[len(records)-1].Replay || records[len(records)-1].MID != 5 {
		t.Fatalf("journal=%+v", records)
	}
}

func TestUndeliveredReplayRunsAgainAfterADeliveredReply(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	h.request(5, "delivered", nil)
	h.request(5, "delivered", nil)
	if got := h.questionCount(); got != before+2 {
		t.Fatalf("questions=%d want=%d", got, before+2)
	}
}

func TestUndeliveredReplayInterveningStateRequestClearsTheMark(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	h.request(5, "first", &disconnectWriter{})
	h.request(5, "different", nil)
	if h.markExists() {
		t.Fatal("intervening state request did not clear the mark")
	}
	h.request(5, "first", nil)
	if got := h.questionCount(); got != before+3 {
		t.Fatalf("questions=%d want=%d", got, before+3)
	}
}

func TestUndeliveredReplayReadRequestLeavesTheMark(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	h.request(5, "first", &disconnectWriter{})
	h.request(4, "", nil)
	if !h.markExists() {
		t.Fatal("read request consumed the mark")
	}
	first := &disconnectWriter{}
	h.request(5, "first", first)
	resend := httptest.NewRecorder()
	h.request(5, "first", resend)
	if resend.Body.String() != string(first.written) {
		t.Fatalf("read request broke the replay: %q != %q", resend.Body.String(), first.written)
	}
	if got := h.questionCount(); got != before+2 {
		t.Fatalf("questions=%d want=%d", got, before+2)
	}
}

func TestUndeliveredReplayExpiresOutsideTheWindow(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	h.request(5, "first", &disconnectWriter{})
	if _, err := h.pool.Raw().Exec(ctx, `UPDATE player_undelivered_replies SET marked_at=marked_at-interval '11 minutes' WHERE player_id=$1`, h.player); err != nil {
		t.Fatal(err)
	}
	h.request(5, "first", nil)
	if got := h.questionCount(); got != before+2 {
		t.Fatalf("questions=%d want=%d", got, before+2)
	}
}

func TestUndeliveredReplayAnotherSessionRunsNormally(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	h.request(5, "first", &disconnectWriter{})
	h.requestWith(h.handler, 5, "first", h.secondSessionBearer(t), httptest.NewRecorder())
	if got := h.questionCount(); got != before+2 {
		t.Fatalf("questions=%d want=%d", got, before+2)
	}
}

func (h *harness) secondSessionBearer(t *testing.T) string {
	t.Helper()
	var account string
	if err := h.pool.QueryRow(ctx, `SELECT account_id::text FROM players WHERE player_id=$1`, h.player).Scan(&account); err != nil {
		t.Fatal(err)
	}
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	gameplayContext, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	credential, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := h.pool.Raw().Exec(ctx, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, session.String(), account); err != nil {
		t.Fatal(err)
	}
	if _, err := h.pool.Raw().Exec(ctx, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at) VALUES($1,$2,$3,1,$4,1,clock_timestamp()-interval '1 hour')`, gameplayContext.String(), session.String(), account, h.player); err != nil {
		t.Fatal(err)
	}
	bearer, digest := credentials(t, gameplayContext)
	if _, err := h.pool.Raw().Exec(ctx, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at) VALUES($1,$2,$3,$4,1,$5,clock_timestamp())`, credential.String(), gameplayContext.String(), session.String(), digest[:], keyID); err != nil {
		t.Fatal(err)
	}
	return bearer
}

func TestUndeliveredReplayConcurrentResendsReplayOnce(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	h.request(5, "first", &disconnectWriter{})
	var wait sync.WaitGroup
	for range 2 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			h.request(5, "first", httptest.NewRecorder())
		}()
	}
	wait.Wait()
	if got := h.questionCount(); got != before+2 {
		t.Fatalf("questions=%d want=%d (one dispatch, one replay)", got, before+2)
	}
	if replays := h.journal.replays(); replays != 1 {
		t.Fatalf("journal replays=%d", replays)
	}
}

func TestUndeliveredReplayJournalRowPersistsItsFlag(t *testing.T) {
	pool := nativePool(t)
	account := "r6-replay-journal-" + time.Now().UTC().Format("150405.000000000")
	store := clientlogstore.Store{Pool: pool.Raw()}
	row := appclientlog.JournalRow{
		ReceivedAt: time.Now().UTC(), Owner: &appclientlog.Owner{AccountUID: account, PlayerID: 1},
		Outcome: domainclientlog.OutcomeOK, HTTPStatus: http.StatusOK, Class: domainclientlog.Routine, Replay: true,
	}
	if err := store.SaveJournal(ctx, []appclientlog.JournalRow{row}); err != nil {
		t.Fatal(err)
	}
	var replay bool
	if err := pool.QueryRow(ctx, `SELECT replay FROM request_journal WHERE account_uid=$1`, account).Scan(&replay); err != nil {
		t.Fatal(err)
	}
	if !replay {
		t.Fatal("journal row did not keep the replay flag")
	}
}

func TestUndeliveredReplayFailedMarkWriteStaysAsToday(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	failing := h.buildHandler(failingMarker{}, h.metrics)
	h.handler = failing
	h.request(5, "first", &disconnectWriter{})
	if h.markExists() {
		t.Fatal("a failed mark write still stored a mark")
	}
	if h.metrics.value(undelivered.MarkFailuresTotal) != 1 {
		t.Fatalf("mark failure counter=%d", h.metrics.value(undelivered.MarkFailuresTotal))
	}
	h.handler = h.buildHandler(h.store, h.metrics)
	h.request(5, "first", nil)
	if got := h.questionCount(); got != before+2 {
		t.Fatalf("questions=%d want=%d", got, before+2)
	}
}
