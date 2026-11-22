//go:build postgres

package operatorstore_test

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func nativeBus(t *testing.T, handlers map[string]operator.Handler) (operator.Bus, *pg.Pool) {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_DSN required")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: handlers}, pool
}

func newCommand(t *testing.T, name, payload string) operator.Command {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "native test", SemanticKey: key.String()}, json.RawMessage(payload))
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func stateOf(t *testing.T, pool *pg.Pool, key string) string {
	t.Helper()
	var state string
	if err := pool.QueryRow(context.Background(), "SELECT state FROM operator_commands WHERE semantic_key=$1", key).Scan(&state); err != nil {
		t.Fatal(err)
	}
	return state
}

func TestBusReplaysSameKeyAndRefusesReuse(t *testing.T) {
	calls := 0
	bus, pool := nativeBus(t, map[string]operator.Handler{"test.apply": func(context.Context, tx.Scope, operator.Command) (any, error) {
		calls++
		return map[string]int{"calls": calls}, nil
	}})
	command := newCommand(t, "test.apply", `{"b":1,"a":2}`)
	first, err := bus.Execute(context.Background(), command)
	if err != nil || first.State != operator.StateApplied || first.Replayed {
		t.Fatalf("first = %+v, %v", first, err)
	}
	same := command
	same.Payload = json.RawMessage(`{"a":2, "b":1}`)
	replay, err := bus.Execute(context.Background(), same)
	if err != nil || !replay.Replayed || !sameJSON(t, replay.Result, first.Result) || calls != 1 {
		t.Fatalf("replay = %+v, %v, calls %d", replay, err, calls)
	}
	reused, err := operator.NewCommand("test.apply", command.Envelope, json.RawMessage(`{"a":3}`))
	if err != nil {
		t.Fatal(err)
	}
	var refusal *operator.Refusal
	if _, err = bus.Execute(context.Background(), reused); !errors.As(err, &refusal) || refusal.Code != operator.CodeKeyReused || calls != 1 {
		t.Fatalf("reuse err = %v, calls %d", err, calls)
	}
	if got := stateOf(t, pool, command.Envelope.SemanticKey); got != operator.StateApplied {
		t.Fatalf("state = %s", got)
	}
}

func TestBusStoresRefusalAndRetriesFailure(t *testing.T) {
	fail := true
	bus, pool := nativeBus(t, map[string]operator.Handler{
		"test.refuse": func(context.Context, tx.Scope, operator.Command) (any, error) {
			return nil, operator.StaleRevision(7)
		},
		"test.flaky": func(_ context.Context, scope tx.Scope, command operator.Command) (any, error) {
			if _, err := scope.Tx.Exec(context.Background(), "SELECT 1"); err != nil {
				return nil, err
			}
			if fail {
				return nil, errors.New("owner unavailable")
			}
			return "ok", nil
		},
	})
	refused, err := bus.Execute(context.Background(), newCommand(t, "test.refuse", `{}`))
	if err != nil || refused.State != operator.StateRefused {
		t.Fatalf("refused = %+v, %v", refused, err)
	}
	var stored operator.Refusal
	if err := json.Unmarshal(refused.Result, &stored); err != nil || stored.Code != operator.CodeRevisionStale {
		t.Fatalf("stored refusal = %s, %v", refused.Result, err)
	}
	flaky := newCommand(t, "test.flaky", `{}`)
	if _, err := bus.Execute(context.Background(), flaky); err == nil {
		t.Fatal("expected the handler failure")
	}
	if got := stateOf(t, pool, flaky.Envelope.SemanticKey); got != operator.StateFailed {
		t.Fatalf("after failure state = %s", got)
	}
	fail = false
	retried, err := bus.Execute(context.Background(), flaky)
	if err != nil || retried.State != operator.StateApplied || retried.Replayed {
		t.Fatalf("retried = %+v, %v", retried, err)
	}
}

// sameJSON compares decoded values: jsonb stores the result in its own normal form.
func sameJSON(t *testing.T, left, right json.RawMessage) bool {
	t.Helper()
	var a, b any
	if json.Unmarshal(left, &a) != nil || json.Unmarshal(right, &b) != nil {
		t.Fatalf("invalid JSON %s / %s", left, right)
	}
	return reflect.DeepEqual(a, b)
}
