//go:build postgres

package publication_test

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/publicationstore"
	"gxb.local/backend/v2/internal/application/operator"
	app "gxb.local/backend/v2/internal/application/publication"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func publicationOperatorProfile() tx.Profile {
	return tx.Profile{Name: "operator-publication-native", AcquireTimeout: time.Second, LockTimeout: time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 10 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 20 * time.Second}
}

func TestOperatorPublicationInstallClearAndShowNative(t *testing.T) {
	dsn := os.Getenv("GXB_I7A9_DSN")
	if dsn == "" {
		t.Skip("GXB_I7A9_DSN required (ops/testing/fresh_db.sh)")
	}
	c := context.Background()
	pool, err := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	runner := tx.Runner{DB: pool}
	commands := app.OperatorCommands{Store: publicationstore.Store{}}
	setID := uid()
	boardID := 7_000_000 + int64(time.Now().UnixNano()%1_000_000)
	payload := json.RawMessage(fmt.Sprintf(`{"set_id":%q,"family":"board","server_id":1,"board":[{"id":%d,"title":"Operator board","start_date":"2026-11-22","content":"hi"}]}`, setID.String(), boardID))
	command, err := operator.NewCommand("publication.install", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "native", SemanticKey: uid().String()}, payload)
	if err != nil {
		t.Fatal(err)
	}
	var installed app.FamilyView
	_, err = runner.Run(c, op(t), publicationOperatorProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		result, handlerErr := commands.Install(ctx, scope.Tx, command.Payload)
		if handlerErr != nil {
			return handlerErr
		}
		installed = result
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if !installed.Visible || installed.SetID != setID.String() {
		t.Fatalf("installed = %+v", installed)
	}
	read := app.OperatorRead{Runner: runner, Operations: operation.Factory{Clock: clock.System{}}, Store: publicationstore.Store{}, Clock: func() time.Time { return time.Now().UTC() }}
	reply, err := read.Show(c, "board", 1)
	if err != nil {
		t.Fatal(err)
	}
	if len(reply.Families) != 1 || reply.Families[0].SetID != setID.String() || !reply.Families[0].Visible {
		t.Fatalf("show = %+v", reply.Families)
	}
	clearID := uid()
	clearPayload := json.RawMessage(fmt.Sprintf(`{"family":"board","server_id":1}`))
	clearCommand, err := operator.NewCommand("publication.clear", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "native", SemanticKey: clearID.String()}, clearPayload)
	if err != nil {
		t.Fatal(err)
	}
	_, err = runner.Run(c, op(t), publicationOperatorProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		_, handlerErr := commands.Clear(ctx, scope.Tx, clearCommand.Payload)
		return handlerErr
	})
	if err != nil {
		t.Fatal(err)
	}
	reply, err = read.Show(c, "board", 1)
	if err != nil {
		t.Fatal(err)
	}
	if len(reply.Families) != 1 || reply.Families[0].Visible {
		t.Fatalf("after clear = %+v", reply.Families)
	}
}
