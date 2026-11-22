//go:build postgres

package operatorstore_test

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"testing"
	"time"

	opcatalogsource "gxb.local/backend/v2/internal/adapters/operatorcatalog"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func o2Pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_O2_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_O2_DSN required (ops/testing/fresh_db.sh o2)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

type o2Grants struct {
	keys    map[string]int
	effects []int64
}

func (g *o2Grants) AdminGrantTx(ctx context.Context, _ tx.Tx, admin appi5.AdminOperator, target identity.PlayerID, key, policy string, lines []grant.Line, op operation.Context) (appi5.GrantResult, error) {
	return g.AdminGrant(ctx, admin, target, key, policy, lines, op)
}

func (g *o2Grants) AdminGrant(_ context.Context, _ appi5.AdminOperator, target identity.PlayerID, key, _ string, _ []grant.Line, _ operation.Context) (appi5.GrantResult, error) {
	if g.keys == nil {
		g.keys = map[string]int{}
	}
	g.keys[key]++
	if g.keys[key] == 1 {
		g.effects = append(g.effects, int64(target))
	}
	return appi5.GrantResult{}, nil
}

func o2Catalogue(t *testing.T) operatorcatalog.Document {
	t.Helper()
	document, err := opcatalogsource.Load(time.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	if len(document.Entries) < 5000 || document.ContentRevision == "" {
		t.Fatalf("catalogue = %d entries revision %q", len(document.Entries), document.ContentRevision)
	}
	return document
}

func o2Command(t *testing.T, key string, payload any) operator.Command {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandGrantItems, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "native bulk grant", SemanticKey: key}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func o2Key(t *testing.T) string {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return key.String()
}

func o2Read(t *testing.T, pool *pg.Pool, store operatorstore.Store, key string) *operatorgrant.BulkTarget {
	t.Helper()
	runner := tx.Runner{DB: pool}
	current, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	var target *operatorgrant.BulkTarget
	_, err = runner.Run(context.Background(), current, tx.Profile{Name: "o2-read", AcquireTimeout: time.Second, LockTimeout: time.Second, StatementTimeout: 2 * time.Second, TransactionTimeout: 5 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 5 * time.Second}, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		var readErr error
		target, readErr = store.ReadBulkTx(ctx, scope.Tx, key)
		return readErr
	})
	if err != nil {
		t.Fatal(err)
	}
	return target
}

// TestO2BulkFreezeThenResumeNative proves the submit freeze, the resumable
// batches and the per-recipient business keys over a real database.
func TestO2BulkFreezeThenResumeNative(t *testing.T) {
	pool := o2Pool(t)
	store := operatorstore.Store{}
	grants := &o2Grants{}
	catalogue := o2Catalogue(t)
	commands := operatorgrant.Commands{Catalogue: catalogue, Store: store, Grants: grants, LineCap: 1000}
	bus := operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: store, Handlers: commands.Handlers()}
	key := o2Key(t)
	ids := make([]int64, 0, 450)
	for i := 1; i <= 450; i++ {
		ids = append(ids, int64(i))
	}
	payload := map[string]any{"target": map[string]any{"player_ids": ids}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}
	outcome, err := bus.Execute(context.Background(), o2Command(t, key, payload))
	if err != nil {
		t.Fatal(err)
	}
	var accepted operatorgrant.GrantResult
	if err := json.Unmarshal(outcome.Result, &accepted); err != nil {
		t.Fatal(err)
	}
	if !accepted.Bulk || accepted.PlayerCount != 450 || accepted.State != operatorgrant.StatePending {
		t.Fatalf("submit = %+v", accepted)
	}
	if target := o2Read(t, pool, store, key); target == nil || len(target.PlayerIDs) != 450 || target.PlayerIDs[0] != 1 || target.PlayerIDs[449] != 450 {
		t.Fatalf("frozen target = %+v", target)
	}

	applier := operatorgrant.Applier{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: store, Grants: grants, Catalogue: catalogue, LineCap: 1000, BatchSize: 200, BatchesPerRun: 1}
	// The first run settles one batch and stops, as a crash would; the next two
	// runs resume from the stored cursor.
	if _, err := applier.ApplyPending(context.Background()); err != nil {
		t.Fatal(err)
	}
	mid := o2Read(t, pool, store, key)
	if mid.State != operatorgrant.StatePending || mid.Processed != 200 {
		t.Fatalf("after first run = %+v", mid)
	}
	for run := 0; run < 3; run++ {
		if _, err := applier.ApplyPending(context.Background()); err != nil {
			t.Fatal(err)
		}
	}
	done := o2Read(t, pool, store, key)
	if done.State != operatorgrant.StateDone || done.Processed != 450 || done.Applied != 450 || done.Refused != 0 || done.FinishedAt == nil {
		t.Fatalf("final = %+v", done)
	}
	if len(grants.effects) != 450 {
		t.Fatalf("effects = %d, want 450", len(grants.effects))
	}
	for recipientKey, count := range grants.keys {
		if count != 1 {
			t.Fatalf("recipient key %q granted %d times", recipientKey, count)
		}
	}
}

// TestO2BulkFailedReasonNative proves a frozen payload whose catalogue row was
// removed before settlement ends FAILED with its reason persisted and readable.
func TestO2BulkFailedReasonNative(t *testing.T) {
	pool := o2Pool(t)
	store := operatorstore.Store{}
	grants := &o2Grants{}
	catalogue := o2Catalogue(t)
	commands := operatorgrant.Commands{Catalogue: catalogue, Store: store, Grants: grants, LineCap: 1000}
	bus := operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: store, Handlers: commands.Handlers()}
	key := o2Key(t)
	ids := make([]int64, 0, operatorgrant.InlineRecipientLimit+1)
	for i := 1; i <= operatorgrant.InlineRecipientLimit+1; i++ {
		ids = append(ids, int64(i))
	}
	payload := map[string]any{"target": map[string]any{"player_ids": ids}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}
	if _, err := bus.Execute(context.Background(), o2Command(t, key, payload)); err != nil {
		t.Fatal(err)
	}
	// A later content update no longer carries the frozen line.
	reduced, err := operatorcatalog.Build([]operatorcatalog.Resource{{DefinitionKey: "stack_item:1", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 1}}, nil, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	applier := operatorgrant.Applier{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: store, Grants: grants, Catalogue: reduced, LineCap: 1000}
	finished, err := applier.ApplyPending(context.Background())
	if err != nil || finished != 1 {
		t.Fatalf("finished=%d err=%v", finished, err)
	}
	target := o2Read(t, pool, store, key)
	if target == nil || target.State != operatorgrant.StateFailed || target.FailedReason == "" || target.FinishedAt == nil {
		t.Fatalf("failed target = %+v", target)
	}
	if len(grants.effects) != 0 {
		t.Fatalf("a failed target granted %v", grants.effects)
	}
}

type o2FlakyGrants struct {
	failAt       int64
	failuresLeft int
	err          error
	calls        map[string]int
}

func (g *o2FlakyGrants) AdminGrantTx(ctx context.Context, _ tx.Tx, admin appi5.AdminOperator, target identity.PlayerID, key, policy string, lines []grant.Line, op operation.Context) (appi5.GrantResult, error) {
	return g.AdminGrant(ctx, admin, target, key, policy, lines, op)
}

func (g *o2FlakyGrants) AdminGrant(_ context.Context, _ appi5.AdminOperator, target identity.PlayerID, key, _ string, _ []grant.Line, _ operation.Context) (appi5.GrantResult, error) {
	if g.calls == nil {
		g.calls = map[string]int{}
	}
	g.calls[key]++
	if int64(target) == g.failAt && g.failuresLeft > 0 {
		g.failuresLeft--
		return appi5.GrantResult{}, g.err
	}
	return appi5.GrantResult{}, nil
}

// TestO2BulkLastErrorNative proves a transient recipient fault is persisted as
// last_error while the target stays PENDING and is cleared when it moves on.
func TestO2BulkLastErrorNative(t *testing.T) {
	pool := o2Pool(t)
	store := operatorstore.Store{}
	grants := &o2FlakyGrants{failAt: 25, failuresLeft: 1, err: errors.New("connection reset")}
	catalogue := o2Catalogue(t)
	commands := operatorgrant.Commands{Catalogue: catalogue, Store: store, Grants: grants, LineCap: 1000}
	bus := operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: store, Handlers: commands.Handlers()}
	key := o2Key(t)
	ids := make([]int64, 0, operatorgrant.InlineRecipientLimit+1)
	for i := 1; i <= operatorgrant.InlineRecipientLimit+1; i++ {
		ids = append(ids, int64(i))
	}
	payload := map[string]any{"target": map[string]any{"player_ids": ids}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}
	if _, err := bus.Execute(context.Background(), o2Command(t, key, payload)); err != nil {
		t.Fatal(err)
	}
	applier := operatorgrant.Applier{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: store, Grants: grants, Catalogue: catalogue, LineCap: 1000}
	if _, err := applier.ApplyPending(context.Background()); err == nil {
		t.Fatal("the transient recipient fault did not stop the run")
	}
	target := o2Read(t, pool, store, key)
	if target == nil || target.State != operatorgrant.StatePending || target.LastError != "connection reset" {
		t.Fatalf("target after the transient fault = %+v", target)
	}
	read := operatorgrant.BulkReadService{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: store}
	progress, err := read.Show(context.Background(), key)
	if err != nil || progress.LastError != "connection reset" {
		t.Fatalf("bulk.show = %+v err=%v", progress, err)
	}
	for {
		finished, err := applier.ApplyPending(context.Background())
		if err != nil {
			t.Fatal(err)
		}
		done := o2Read(t, pool, store, key)
		if done.State == operatorgrant.StateDone {
			break
		}
		if finished != 0 {
			t.Fatalf("finished=%d without DONE: %+v", finished, done)
		}
	}
	if done := o2Read(t, pool, store, key); done.LastError != "" {
		t.Fatalf("last_error was not cleared: %+v", done)
	}
}
