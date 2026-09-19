package directorysync

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type noopTx struct{}

func (noopTx) QueryRow(context.Context, string, ...any) tx.Row             { panic("unexpected QueryRow") }
func (noopTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { panic("unexpected Exec") }
func (noopTx) Commit(context.Context) error                                { return nil }
func (noopTx) Rollback(context.Context) error                              { return nil }

type sourceFake struct{ snap CanonicalSnapshot }

func (f sourceFake) ReadCanonicalDirectoryTx(context.Context, tx.Queryer, identity.PlayerID) (CanonicalSnapshot, error) {
	return f.snap, nil
}

type sinkFake struct {
	current ProjectionSnapshot
	applied bool
	got     CanonicalSnapshot
	version int64
}

func (f *sinkFake) LockOwnedDirectoryTx(context.Context, tx.Tx, identity.PlayerID) (ProjectionSnapshot, error) {
	return f.current, nil
}
func (f *sinkFake) ApplyOwnedDirectoryTx(_ context.Context, _ tx.Tx, got CanonicalSnapshot, version int64, _ operation.Context) error {
	f.applied, f.got, f.version = true, got, version
	return nil
}

func TestReconcileDirectorySelectiveOwnedSnapshot(t *testing.T) {
	canonical := CanonicalSnapshot{PlayerID: identity.PlayerID(100001), Name: "Alice", Level: 9, AvatarID: 110001002, AvatarFrameID: 7}
	sink := &sinkFake{current: ProjectionSnapshot{Name: "Old", Level: 8, AvatarID: 110001001, AvatarFrameID: 0, StateVersion: 4}}
	r := Reconciler{Source: sourceFake{snap: canonical}, Sink: sink}
	if err := r.ReconcileDirectoryTx(context.Background(), noopTx{}, canonical.PlayerID, operation.Context{StartedAt: time.Unix(100, 0).UTC()}); err != nil {
		t.Fatal(err)
	}
	if !sink.applied || sink.got != canonical || sink.version != 4 {
		t.Fatalf("applied=%v got=%+v version=%d", sink.applied, sink.got, sink.version)
	}
}

func TestReconcileDirectoryNoopWhenOwnedFieldsMatch(t *testing.T) {
	canonical := CanonicalSnapshot{PlayerID: identity.PlayerID(100001), Name: "Alice", Level: 9, AvatarID: 110001002, AvatarFrameID: 7}
	sink := &sinkFake{current: ProjectionSnapshot{Name: canonical.Name, Level: canonical.Level, AvatarID: canonical.AvatarID, AvatarFrameID: canonical.AvatarFrameID, StateVersion: 4}}
	r := Reconciler{Source: sourceFake{snap: canonical}, Sink: sink}
	if err := r.ReconcileDirectoryTx(context.Background(), noopTx{}, canonical.PlayerID, operation.Context{StartedAt: time.Unix(100, 0).UTC()}); err != nil {
		t.Fatal(err)
	}
	if sink.applied {
		t.Fatal("matching projection should not advance state_version")
	}
}
