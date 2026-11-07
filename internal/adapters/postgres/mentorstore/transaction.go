package mentorstore

import (
	"context"

	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// requireWritableTx enforces the owner's Serializable, read-write write rule
// without a caller-supplied Scope. A read-only or weaker transaction fails
// closed before any row is touched.
func requireWritableTx(ctx context.Context, t tx.Tx) error {
	if t == nil {
		return domain.ErrRelationship
	}
	var readOnly bool
	if err := t.QueryRow(ctx, `SELECT current_setting('transaction_read_only')::boolean`).Scan(&readOnly); err != nil {
		return err
	}
	if readOnly {
		return domain.ErrRelationship
	}
	var isolation string
	if err := t.QueryRow(ctx, `SELECT current_setting('transaction_isolation')`).Scan(&isolation); err != nil {
		return err
	}
	if isolation != "serializable" {
		return domain.ErrRelationship
	}
	return nil
}
