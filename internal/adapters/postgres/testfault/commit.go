//go:build postgres

// Package testfault supplies only an explicit native-test COMMIT transport fault.
// Serving compositions never import it.
package testfault

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type UnknownCommitDB struct {
	Pool      *postgres.Pool
	Committed bool
}

func (v UnknownCommitDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := v.Pool.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return &unknownTx{Tx: t, committed: v.Committed}, nil
}

type unknownTx struct {
	tx.Tx
	committed bool
}

func (v *unknownTx) RawPGX() pgx.Tx { p, _ := postgres.UnwrapTx(v.Tx); return p }
func (v *unknownTx) Commit(c context.Context) error {
	if v.committed {
		if e := v.Tx.Commit(c); e != nil {
			return e
		}
	}
	return errors.New("injected unknown COMMIT transport boundary")
}
