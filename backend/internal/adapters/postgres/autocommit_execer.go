//go:build postgres

package postgres

import "gxb.local/backend/v2/internal/foundation/tx"

// AutocommitExecer runs one statement outside a transaction, for a wakeup that
// follows a committed gameplay transaction.
func AutocommitExecer(p *Pool) tx.Execer { return socialWakeupExecer{p: p} }
