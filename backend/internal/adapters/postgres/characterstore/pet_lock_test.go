package characterstore

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petLockTestRow struct{ err error }

func (r petLockTestRow) Scan(...any) error { return r.err }

type petLockTestTx struct{ err error }

func (t petLockTestTx) QueryRow(context.Context, string, ...any) tx.Row {
	return petLockTestRow{err: t.err}
}
func (petLockTestTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, errors.New("unexpected exec")
}
func (petLockTestTx) Commit(context.Context) error   { return nil }
func (petLockTestTx) Rollback(context.Context) error { return nil }

func TestLockPetByIDTxSeparatesMissingFromInfrastructureFailure(t *testing.T) {
	_, found, err := (Store{}).LockPetByIDTx(context.Background(), petLockTestTx{err: kernelstore.ErrNoRows}, identity.PlayerID(7), 9)
	if err != nil || found {
		t.Fatalf("missing row classification: found=%v err=%v", found, err)
	}
	infra := errors.New("connection lost")
	_, found, err = (Store{}).LockPetByIDTx(context.Background(), petLockTestTx{err: infra}, identity.PlayerID(7), 9)
	if found || !errors.Is(err, infra) {
		t.Fatalf("infrastructure error masked: found=%v err=%v", found, err)
	}
}
