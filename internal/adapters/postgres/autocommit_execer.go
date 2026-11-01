//go:build postgres

package postgres

import (
	"context"

	"gxb.local/backend/v2/internal/foundation/tx"
)

// AutocommitExecer runs one statement outside a transaction, for a wakeup that
// follows a committed gameplay transaction.
func AutocommitExecer(p *Pool) tx.Execer { return socialWakeupExecer{p: p} }

type autocommitExecer struct{ p *Pool }

func (a autocommitExecer) Exec(ctx context.Context, q string, args ...any) (tx.CommandTag, error) {
	return socialWakeupExecer{p: a.p}.Exec(ctx, q, args...)
}
