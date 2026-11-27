//go:build postgres

package stockruntime

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

func activityNativePool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_SESSION_ACTIVITY_DSN")
	if dsn == "" {
		t.Skip("GXB_SESSION_ACTIVITY_DSN required (ops/testing/fresh_db.sh activity)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

type nativeActivityToucher struct {
	service    appidentity.Service
	operations operation.Factory
}

func (t nativeActivityToucher) TouchActivity(ctx context.Context, sessionID identity.SessionID) error {
	current, err := t.operations.New(policy.Set{})
	if err != nil {
		return err
	}
	_, err = t.service.TouchActivity(ctx, sessionID, current)
	return err
}

func activityNativeUUID(t *testing.T) string {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value.String()
}

func TestHTTPSessionActivityTouchNative(t *testing.T) {
	pool := activityNativePool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	account, session := activityNativeUUID(t), activityNativeUUID(t)
	cleanup := []struct {
		sql  string
		args []any
	}{
		{`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM accounts WHERE account_uid LIKE 'activity-native-%')`, nil},
		{`DELETE FROM accounts WHERE account_uid LIKE 'activity-native-%'`, nil},
	}
	for _, statement := range cleanup {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}
	statements := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, []any{account, "activity-native-" + account, now}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version) VALUES($1::uuid,$2::uuid,'stock',$3,86400,$4,1)`, []any{session, account, now.Add(-time.Hour), now.Add(-time.Hour)}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}

	activity := &SessionActivity{
		Touch: nativeActivityToucher{
			service: appidentity.Service{
				Runner: tx.Runner{DB: pool}, Store: identitystore.Store{},
				IdleExpiryEnabled: true, ActivityTouchInterval: identity.ActivityTouchCoalesceInterval,
			},
			operations: operation.Factory{Clock: clock.System{}},
		},
		Interval: identity.ActivityTouchCoalesceInterval,
	}
	router := httpedge.NewRouter()
	router.Wrap = func(next httpedge.Dispatcher) httpedge.Dispatcher {
		return activity.Wrap(next)
	}
	dispatcher := httpedge.DispatcherFunc(func(ctx context.Context, _ httpedge.DispatchRequest) httpedge.Response {
		observability.NoteActor(ctx, observability.RequestActor{SessionID: session})
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
	})
	if err := router.Register(5, dispatcher); err != nil {
		t.Fatal(err)
	}
	admission, err := httpedge.NewAdmission(2)
	if err != nil {
		t.Fatal(err)
	}
	handler := httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router}
	body := `{"mid":5,"token":"bearer","region":1}`
	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(body)))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("status=%d body=%q", response.Code, response.Body)
	}

	deadline := time.Now().Add(5 * time.Second)
	for {
		var touched time.Time
		if err := pool.Raw().QueryRow(ctx, `SELECT last_activity_at FROM account_sessions WHERE session_id=$1::uuid`, session).Scan(&touched); err != nil {
			t.Fatal(err)
		}
		if touched.After(now.Add(-30 * time.Minute)) {
			if touched.Before(now) {
				t.Fatalf("touched at %s, want a request-time touch", touched)
			}
			return
		}
		if time.Now().After(deadline) {
			t.Fatalf("HTTP request did not advance last_activity_at (still %s)", touched)
		}
		time.Sleep(10 * time.Millisecond)
	}
}
