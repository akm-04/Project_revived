package retentionstore

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store owns the R8 retention rules. Each rule deletes at most BatchSize rows
// in one statement inside the caller's READ COMMITTED transaction.
//
// The R8 design's combat-chain and combat-blob rules are absent: every combat
// table carries a BEFORE DELETE append-only trigger (C5A), so a DELETE there is
// refused; that conflict needs a lead decision. The "existing purges" row stays
// with its adventure, occult, illusion and client-log owners, which already run
// it in production.
type Store struct{}

// DeleteReplayOnlyReceipts removes receipts whose semantic key is their own
// operation id and that no reference column still holds. Every other receipt
// is evidence and is kept forever (6A), as is a replay-only receipt an
// operation-id or receipt-id column still holds (6B A-050).
func (Store) DeleteReplayOnlyReceipts(c context.Context, t tx.Tx, recordedBefore time.Time) (int64, error) {
	if t == nil {
		return 0, errors.New("retention receipts rule requires a transaction")
	}
	query := `DELETE FROM gxb_operation_receipts WHERE receipt_id IN (
SELECT r.receipt_id FROM gxb_operation_receipts r
WHERE r.operation_id IS NOT NULL
  AND r.semantic_key = r.operation_id::text
  AND r.recorded_at < $1
  AND ` + receiptKeptWhileSQL() + `
ORDER BY r.recorded_at, r.receipt_id
LIMIT $2
FOR UPDATE SKIP LOCKED)`
	tag, err := t.Exec(c, query, recordedBefore.UTC(), BatchSize)
	return tag.RowsAffected(), err
}

// DeleteStaleRankingSnapshots removes ranking snapshot generations older than
// the cache window while keeping the latest generation per server and policy
// and any generation a period still binds.
func (Store) DeleteStaleRankingSnapshots(c context.Context, t tx.Tx, observedBefore time.Time) (int64, error) {
	if t == nil {
		return 0, errors.New("retention ranking snapshot rule requires a transaction")
	}
	query := `DELETE FROM ranking_girls_snapshots WHERE (logical_server_id, policy_id, generation) IN (
SELECT s.logical_server_id, s.policy_id, s.generation FROM ranking_girls_snapshots s
WHERE s.observed_at < $1
  AND EXISTS (SELECT 1 FROM ranking_girls_snapshots newer
              WHERE newer.logical_server_id = s.logical_server_id
                AND newer.policy_id = s.policy_id
                AND newer.generation > s.generation)
  AND NOT EXISTS (SELECT 1 FROM ranking_girls_periods p
                  WHERE p.logical_server_id = s.logical_server_id
                    AND p.policy_id = s.policy_id
                    AND p.snapshot_generation = s.generation)
ORDER BY s.observed_at, s.generation
LIMIT $2
FOR UPDATE SKIP LOCKED)`
	tag, err := t.Exec(c, query, observedBefore.UTC(), BatchSize)
	return tag.RowsAffected(), err
}

// DeleteExpiredMediaHistory removes replaced avatars whose URL window ended,
// together with their receipt, while keeping the current avatar and any history
// row a newer history row still uses as its origin.
func (Store) DeleteExpiredMediaHistory(c context.Context, t tx.Tx, replacedBefore time.Time) (int64, error) {
	if t == nil {
		return 0, errors.New("retention media history rule requires a transaction")
	}
	query := `WITH doomed AS (
SELECT h.operation_id FROM player_public_profile_media_history h
WHERE h.decision_at < $1
  AND NOT EXISTS (SELECT 1 FROM player_public_profile_media_current c
                  WHERE c.player_id = h.player_id AND c.operation_id = h.operation_id)
  AND NOT EXISTS (SELECT 1 FROM player_public_profile_media_history child
                  WHERE child.operation_id <> h.operation_id
                    AND (child.reference->>'operation')::uuid = h.operation_id)
ORDER BY h.decision_at, h.operation_id
LIMIT $2
FOR UPDATE OF h SKIP LOCKED
), deleted_receipts AS (
DELETE FROM gxb_operation_receipts r USING doomed d
WHERE r.owner_kind = 'player' AND r.domain = 'public-profile' AND r.operation = 'custom-avatar'
  AND r.semantic_key = d.operation_id::text
RETURNING 1
)
DELETE FROM player_public_profile_media_history h USING doomed d
WHERE h.operation_id = d.operation_id`
	tag, err := t.Exec(c, query, replacedBefore.UTC(), BatchSize)
	return tag.RowsAffected(), err
}

// DeleteStaleHeroRecommendSnapshots removes hero-recommend generations older
// than the cache window while keeping the latest generation per server.
func (Store) DeleteStaleHeroRecommendSnapshots(c context.Context, t tx.Tx, observedBefore time.Time) (int64, error) {
	if t == nil {
		return 0, errors.New("retention hero snapshot rule requires a transaction")
	}
	query := `DELETE FROM hero_recommend_snapshots WHERE (logical_server_id, generation) IN (
SELECT s.logical_server_id, s.generation FROM hero_recommend_snapshots s
WHERE s.observed_at < $1
  AND EXISTS (SELECT 1 FROM hero_recommend_snapshots newer
              WHERE newer.logical_server_id = s.logical_server_id
                AND newer.generation > s.generation)
ORDER BY s.observed_at, s.generation
LIMIT $2
FOR UPDATE SKIP LOCKED)`
	tag, err := t.Exec(c, query, observedBefore.UTC(), BatchSize)
	return tag.RowsAffected(), err
}
