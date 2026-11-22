package eventstore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const dueOccurrences = `SELECT COALESCE(jsonb_agg(` + occurrenceColumns + ` ORDER BY id),'[]'::jsonb)::text
FROM (
	SELECT * FROM event_occurrences
	WHERE id>$1 AND claim_until<=$2 AND ends_at IS NOT NULL AND cancelled_at IS NULL AND settled_at IS NULL
	ORDER BY id LIMIT $3
) due`

// DueOccurrencesAfterTx reads one bounded page of occurrences whose claim
// window has closed and that are neither cancelled nor settled (EA-9).
func (Store) DueOccurrencesAfterTx(ctx context.Context, query tx.Queryer, now time.Time, afterID int64, limit int) ([]events.Occurrence, error) {
	if query == nil || now.IsZero() || afterID < 0 || limit < 1 || limit > 500 {
		return nil, errInvalid
	}
	var raw string
	if err := query.QueryRow(ctx, dueOccurrences, afterID, now.UTC(), limit).Scan(&raw); err != nil {
		return nil, err
	}
	return decodeOccurrences(raw)
}

const markSettled = `UPDATE event_occurrences SET settled_at=$2
WHERE id=$1 AND settled_at IS NULL AND cancelled_at IS NULL AND ends_at IS NOT NULL AND claim_until<=$2`

// MarkSettledTx archives one occurrence after its tiers were delivered. The
// predicate keeps a concurrent settlement run from archiving it twice.
func (Store) MarkSettledTx(ctx context.Context, transaction tx.Tx, occurrenceID int64, at time.Time) (bool, error) {
	if transaction == nil || occurrenceID <= 0 || at.IsZero() {
		return false, errInvalid
	}
	effect, err := transaction.Exec(ctx, markSettled, occurrenceID, at.UTC())
	if err != nil {
		return false, err
	}
	return effect != nil && effect.RowsAffected() == 1, nil
}
