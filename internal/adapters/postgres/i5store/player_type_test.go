package i5store

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type playerTypeQueryer struct{ row tx.Row }

func (q playerTypeQueryer) QueryRow(context.Context, string, ...any) tx.Row { return q.row }

type playerTypeRow struct {
	pid int64
	typ int64
	err error
}

func (r playerTypeRow) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	*(dest[0].(*int64)) = r.pid
	*(dest[1].(*int64)) = r.typ
	return nil
}

func TestPlayerTypeReadPreservesCanonicalInt64WithoutRangeInference(t *testing.T) {
	s := Store{Queryer: playerTypeQueryer{row: playerTypeRow{pid: 100001, typ: -9}}}
	got, ok, err := s.PlayerType(context.Background(), identity.PlayerID(100001))
	if err != nil || !ok || got != -9 {
		t.Fatalf("got=%d ok=%v err=%v", got, ok, err)
	}
}

func TestPlayerTypeReadMissingAndOwnerMismatchFailClosed(t *testing.T) {
	s := Store{Queryer: playerTypeQueryer{row: playerTypeRow{err: kernelstore.ErrNoRows}}}
	if got, ok, err := s.PlayerType(context.Background(), identity.PlayerID(100001)); err != nil || ok || got != 0 {
		t.Fatalf("missing got=%d ok=%v err=%v", got, ok, err)
	}
	s = Store{Queryer: playerTypeQueryer{row: playerTypeRow{pid: 100002, typ: 3}}}
	if _, ok, err := s.PlayerType(context.Background(), identity.PlayerID(100001)); err == nil || ok {
		t.Fatalf("owner mismatch ok=%v err=%v", ok, err)
	}
}
