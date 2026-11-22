//go:build postgres

package undeliveredreplay_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/undeliveredstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

// effectClass is one stock class of state change whose resend must not run the
// operation twice. The class dispatchers commit real durable rows through the
// production transaction runner; the edge, authority, guard and cache are the
// production ones (the domain services of these four classes have no fixture in
// this tree, so their effect is applied directly in the native transaction).
type effectClass string

const (
	classRepeatable effectClass = "REPEATABLE_PURCHASE"
	classClaim      effectClass = "ONE_TIME_CLAIM"
	classTerminal   effectClass = "TERMINAL_SETTLEMENT"
	classToggle     effectClass = "TOGGLE"
)

var classProfile = tx.Profile{Name: "r6-class-native", AcquireTimeout: 5 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 15 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 30 * time.Second}

type classDispatcher struct {
	Runner *tx.Runner
	Class  effectClass
	Player int64
}

func (d classDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	err := d.apply(ctx, request.Envelope.Operation)
	if err != nil {
		return httpedge.Response{HTTPStatus: http.StatusInternalServerError, Body: map[string]any{"error": err.Error()}}
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"class": string(d.Class)}}
}

func (d classDispatcher) apply(ctx context.Context, current operation.Context) error {
	_, err := d.Runner.Run(ctx, current, classProfile, tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
		switch d.Class {
		case classRepeatable:
			_, err := scope.Tx.Exec(ctx, `UPDATE player_currency_balances SET amount=amount-10,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1 AND resource_key='crystal'`, d.Player)
			return err
		case classClaim:
			_, err := scope.Tx.Exec(ctx, `INSERT INTO player_gm_questions(operation_id,player_id,logical_server_id,message,asked_at) VALUES($1,$2,1,'claim',clock_timestamp())`, current.ID.String(), d.Player)
			return err
		case classTerminal:
			_, err := scope.Tx.Exec(ctx, `INSERT INTO player_gm_questions(operation_id,player_id,logical_server_id,message,asked_at) VALUES($1,$2,1,'settlement',clock_timestamp())`, current.ID.String(), d.Player)
			return err
		default:
			_, err := scope.Tx.Exec(ctx, `UPDATE player_gm_questions SET message=CASE message WHEN 'on' THEN 'off' ELSE 'on' END WHERE player_id=$1 AND message IN ('on','off')`, d.Player)
			return err
		}
	})
	return err
}

type classHarness struct {
	t       *testing.T
	pool    *postgres.Pool
	handler http.Handler
	store   undeliveredstore.Store
	bearer  string
	player  int64
}

func newClassHarness(t *testing.T, class effectClass) *classHarness {
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
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES($1,'crystal',100,1,clock_timestamp()) ON CONFLICT(player_id,resource_key) DO NOTHING`, player); err != nil {
		t.Fatal(err)
	}
	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: []byte(digestSecret), BearerSecret: []byte(bearerSecret), DerivationKeyID: keyID}
	store := undeliveredstore.Store{Pool: pool.Raw()}
	runner := tx.Runner{DB: pool}
	dispatcher := classDispatcher{Runner: &runner, Class: class, Player: player}
	router := httpedge.NewRouter()
	router.Wrap = func(next httpedge.Dispatcher) httpedge.Dispatcher {
		return stockruntime.UndeliveredReplay{Next: stockruntime.Decorated{Next: next}, Authority: authority, Marks: store, Window: 10 * time.Minute}
	}
	if err := router.Register(23, dispatcher); err != nil {
		t.Fatal(err)
	}
	admission, err := httpedge.NewAdmission(8)
	if err != nil {
		t.Fatal(err)
	}
	handler := httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router, Undelivered: store}
	return &classHarness{t: t, pool: pool, handler: handler, store: store, bearer: bearer, player: player}
}

func (h *classHarness) request(writer http.ResponseWriter) {
	h.t.Helper()
	body, err := json.Marshal(map[string]any{"mid": int64(23), "token": h.bearer, "region": int64(1), "app_v": "1.0", "platform": "3", "v_": "123"})
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

func (h *classHarness) balance() int64 {
	h.t.Helper()
	var amount int64
	if err := h.pool.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, h.player).Scan(&amount); err != nil {
		h.t.Fatal(err)
	}
	return amount
}

func (h *classHarness) questionRows() int64 {
	h.t.Helper()
	var count int64
	if err := h.pool.QueryRow(ctx, `SELECT count(*) FROM player_gm_questions WHERE player_id=$1`, h.player).Scan(&count); err != nil {
		h.t.Fatal(err)
	}
	return count
}

func TestUndeliveredReplayClassRepeatablePurchaseDoesNotDebitTwice(t *testing.T) {
	h := newClassHarness(t, classRepeatable)
	first := &disconnectWriter{}
	h.request(first)
	if h.balance() != 90 {
		t.Fatalf("balance after first commit=%d", h.balance())
	}
	resend := httptest.NewRecorder()
	h.request(resend)
	if resend.Body.String() != string(first.written) {
		t.Fatalf("resend body=%q want=%q", resend.Body.String(), first.written)
	}
	if h.balance() != 90 {
		t.Fatalf("resend debited again: balance=%d", h.balance())
	}
}

func TestUndeliveredReplayClassOneTimeClaimGrantsOnce(t *testing.T) {
	h := newClassHarness(t, classClaim)
	h.request(&disconnectWriter{})
	h.request(nil)
	if got := h.questionRows(); got != 1 {
		t.Fatalf("claim rows=%d want=1", got)
	}
}

func TestUndeliveredReplayClassTerminalSettlementAppliesOnce(t *testing.T) {
	h := newClassHarness(t, classTerminal)
	h.request(&disconnectWriter{})
	h.request(nil)
	if got := h.questionRows(); got != 1 {
		t.Fatalf("settlement rows=%d want=1", got)
	}
}

func TestUndeliveredReplayClassToggleStays(t *testing.T) {
	h := newClassHarness(t, classToggle)
	seed, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := h.pool.Raw().Exec(ctx, `INSERT INTO player_gm_questions(operation_id,player_id,logical_server_id,message,asked_at) VALUES($1,$2,1,'off',clock_timestamp())`, seed.String(), h.player); err != nil {
		t.Fatal(err)
	}
	h.request(&disconnectWriter{})
	if state := h.toggleState(); state != "on" {
		t.Fatalf("toggle after first commit=%q", state)
	}
	h.request(nil)
	if state := h.toggleState(); state != "on" {
		t.Fatalf("resend flipped the toggle to %q", state)
	}
}

func (h *classHarness) toggleState() string {
	h.t.Helper()
	var state string
	if err := h.pool.QueryRow(ctx, `SELECT message FROM player_gm_questions WHERE player_id=$1 AND message IN ('on','off')`, h.player).Scan(&state); err != nil {
		h.t.Fatal(err)
	}
	return state
}
