//go:build postgres

package playerdisplay_test

import (
	"context"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// snapshotGate pauses a read-only transaction after its first statement so the
// test can commit a concurrent write before the read's remaining statements and
// commit. It proves the request is served from one snapshot with no 40001.
type snapshotGate struct {
	inner       tx.Beginner
	firstScan   chan struct{}
	release     chan struct{}
	once        sync.Once
	releaseOnce sync.Once
}

func newSnapshotGate(inner tx.Beginner) *snapshotGate {
	return &snapshotGate{inner: inner, firstScan: make(chan struct{}), release: make(chan struct{})}
}

func (g *snapshotGate) Begin(c context.Context, options tx.Options) (tx.Tx, error) {
	inner, err := g.inner.Begin(c, options)
	if err != nil {
		return nil, err
	}
	if !options.ReadOnly {
		return inner, nil
	}
	return &snapshotTx{Tx: inner, gate: g}, nil
}

type snapshotTx struct {
	tx.Tx
	gate *snapshotGate
}

func (t *snapshotTx) ReadOnly() bool {
	probe, ok := t.Tx.(interface{ ReadOnly() bool })
	return ok && probe.ReadOnly()
}

func (t *snapshotTx) QueryRow(c context.Context, query string, args ...any) tx.Row {
	return &snapshotRow{Row: t.Tx.QueryRow(c, query, args...), gate: t.gate}
}

type snapshotRow struct {
	tx.Row
	gate *snapshotGate
}

func (r *snapshotRow) Scan(dest ...any) error {
	err := r.Row.Scan(dest...)
	r.gate.pause()
	return err
}

func (g *snapshotGate) pause() {
	g.once.Do(func() { close(g.firstScan) })
	<-g.release
}

func (g *snapshotGate) unblock() {
	g.releaseOnce.Do(func() { close(g.release) })
}

// runReadUnderWrite commits the writer after the read has taken its snapshot,
// then releases the read and returns its result.
func runReadUnderWrite(t *testing.T, gate *snapshotGate, writer func(context.Context) error, read func(context.Context) error) error {
	t.Helper()
	readResult := make(chan error, 1)
	go func() { readResult <- read(ctx) }()
	t.Cleanup(gate.unblock)
	select {
	case <-gate.firstScan:
	case err := <-readResult:
		t.Fatalf("read finished before its snapshot: %v", err)
	case <-time.After(10 * time.Second):
		t.Fatal("read did not reach its first statement")
	}
	if err := writer(ctx); err != nil {
		gate.unblock()
		t.Fatalf("concurrent write: %v", err)
	}
	gate.unblock()
	select {
	case err := <-readResult:
		return err
	case <-time.After(10 * time.Second):
		t.Fatal("read did not finish")
		return nil
	}
}

func commitConcurrentWrite(t *testing.T, p *pg.Pool, statement string, args ...any) error {
	t.Helper()
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		return err
	}
	if _, err := transaction.Exec(ctx, statement, args...); err != nil {
		_ = transaction.Rollback(ctx)
		return err
	}
	return transaction.Commit(ctx)
}

func nativeDispatch(actor identity.ActorContext, mid uint16, params map[string]any, operationContext operation.Context) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, Operation: operationContext, ReceivedAt: time.Now().UTC(),
		Claims: wire.CredentialClaims{Token: "fixture", Region: int64(actor.LogicalServerID)}, Params: params}}
}
