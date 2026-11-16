// Package adventurestore owns the adventure_occurrences, adventure_reports and
// adventure_attempt_settlements tables. Occurrences are insert-only and take the
// late rank 750 above every I5 rank (D369); the settlement is keyed by the
// Combat attempt the mode's RESULT settled.
package adventurestore

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

const occurrenceColumns = `player_id,logical_server_id,event_type,occurred_at,end_time,special_data,source_key,finished_at`

func readOccurrence(row tx.Row) (d.Occurrence, bool, error) {
	var out d.Occurrence
	err := row.Scan(&out.PlayerID, &out.LogicalServerID, &out.EventType, &out.OccurredAt, &out.EndTime, &out.SpecialData, &out.SourceKey, &out.FinishedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Occurrence{}, false, nil
	}
	return out, err == nil, err
}

// ActiveTypesTx returns the event types still live at the given instant.
func (Store) ActiveTypesTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, at time.Time) (map[int64]struct{}, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(event_type),'[]'::jsonb)::text FROM (SELECT event_type FROM adventure_occurrences WHERE player_id=$1 AND finished_at IS NULL AND end_time>$2) active`, int64(playerID), at.UTC()).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var types []int64
	if err = json.Unmarshal([]byte(raw), &types); err != nil {
		return nil, err
	}
	active := make(map[int64]struct{}, len(types))
	for _, eventType := range types {
		active[eventType] = struct{}{}
	}
	return active, nil
}

// InsertOccurrenceTx inserts one occurrence. A repeated fact or instant is a
// no-op, so the caller can treat the fact as already recorded.
func (Store) InsertOccurrenceTx(ctx context.Context, t tx.Tx, occurrence d.Occurrence) (bool, error) {
	if err := occurrence.Validate(); err != nil {
		return false, err
	}
	tag, err := t.Exec(ctx, `INSERT INTO adventure_occurrences(player_id,logical_server_id,event_type,occurred_at,end_time,special_data,source_key)VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT DO NOTHING`, int64(occurrence.PlayerID), int32(occurrence.LogicalServerID), occurrence.EventType, occurrence.OccurredAt.UTC(), occurrence.EndTime.UTC(), occurrence.SpecialData, occurrence.SourceKey)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

// ListOccurrencesTx reads one player's occurrences newest first, bounded and
// scoped to the owner's logical server.
func (Store) ListOccurrencesTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, playerID identity.PlayerID, at time.Time, limit int64) ([]d.Occurrence, error) {
	if !server.Valid() || at.IsZero() || limit < 1 || limit > 256 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(o) ORDER BY o.occurred_at DESC),'[]'::jsonb)::text
FROM (SELECT * FROM adventure_occurrences WHERE player_id=$1 AND logical_server_id=$2
ORDER BY (finished_at IS NULL AND end_time>$3) DESC, occurred_at DESC LIMIT $4) o`, int64(playerID), int32(server), at.UTC(), limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []d.Occurrence
	if err = json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

// ReadOccurrenceTx reads the newest occurrence of one event type.
func (Store) ReadOccurrenceTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, eventType int64) (d.Occurrence, bool, error) {
	return readOccurrence(q.QueryRow(ctx, `SELECT `+occurrenceColumns+` FROM adventure_occurrences WHERE player_id=$1 AND event_type=$2 ORDER BY occurred_at DESC LIMIT 1`, int64(playerID), eventType))
}

// ReadOccurrenceBySourceKeyTx reads the occurrence a START's generation froze.
func (Store) ReadOccurrenceBySourceKeyTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, eventType int64, sourceKey string) (d.Occurrence, bool, error) {
	return readOccurrence(q.QueryRow(ctx, `SELECT `+occurrenceColumns+` FROM adventure_occurrences WHERE player_id=$1 AND event_type=$2 AND source_key=$3`, int64(playerID), eventType, sourceKey))
}

// FinishOccurrenceTx closes one occurrence once. A second attempt reports no
// change, so a repeated terminal never pays twice.
func (Store) FinishOccurrenceTx(ctx context.Context, t tx.Tx, playerID identity.PlayerID, eventType int64, occurredAt, at time.Time) (bool, error) {
	tag, err := t.Exec(ctx, `UPDATE adventure_occurrences SET finished_at=$4 WHERE player_id=$1 AND event_type=$2 AND occurred_at=$3 AND finished_at IS NULL`, int64(playerID), eventType, occurredAt.UTC(), at.UTC())
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

// InsertSettlementTx records the damage the RESULT credited to one terminal
// Combat attempt; the transaction is Combat's attest transaction.
func (Store) InsertSettlementTx(ctx context.Context, t tx.Tx, attemptID ids.UUID, playerID identity.PlayerID, damage int64, settledAt time.Time) error {
	if t == nil || attemptID.IsZero() || playerID <= 0 || damage < 0 || damage > d.IllusionTotalDamage || settledAt.IsZero() {
		return d.ErrInvalid
	}
	_, err := t.Exec(ctx, `INSERT INTO adventure_attempt_settlements(attempt_id,player_id,damage,settled_at)VALUES($1,$2,$3,$4)`, attemptID.String(), int64(playerID), damage, settledAt.UTC())
	return err
}

// ReadSettlementTx answers a duplicate RESULT from the settlement row, not
// from the occurrence that may have advanced since the attempt.
func (Store) ReadSettlementTx(ctx context.Context, q tx.Queryer, attemptID ids.UUID) (int64, bool, error) {
	if q == nil || attemptID.IsZero() {
		return 0, false, d.ErrInvalid
	}
	var damage int64
	err := q.QueryRow(ctx, `SELECT damage FROM adventure_attempt_settlements WHERE attempt_id=$1`, attemptID.String()).Scan(&damage)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	if damage < 0 || damage > d.IllusionTotalDamage {
		return 0, true, fmt.Errorf("adventure: settlement damage %d out of range", damage)
	}
	return damage, true, nil
}

func (Store) InsertReportTx(ctx context.Context, t tx.Tx, reportID string, serverID, roomID int64, memberIDs []int64, content string, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO adventure_reports(report_id,logical_server_id,room_id,member_ids,content,created_at,expires_at)VALUES($1,$2,$3,$4,$5,$6,$6::timestamptz+interval '7 days')`, reportID, serverID, roomID, memberIDs, content, at)
	return err
}

// ReadReportTx answers only a seated member of the same logical server and only
// inside the retention window.
func (Store) ReadReportTx(ctx context.Context, q tx.Queryer, reportID string, serverID int64, playerID identity.PlayerID, at time.Time) (string, bool, error) {
	var content string
	err := q.QueryRow(ctx, `SELECT content FROM adventure_reports WHERE report_id=$1 AND logical_server_id=$2 AND $3=ANY(member_ids) AND expires_at>$4`, reportID, serverID, int64(playerID), at).Scan(&content)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return "", false, nil
	}
	return content, err == nil, err
}

// PurgeExpiredReportsTx deletes one bounded batch past retention.
func (Store) PurgeExpiredReportsTx(ctx context.Context, t tx.Tx, at time.Time, limit int64) (int64, error) {
	if limit < 1 || limit > 10000 {
		return 0, d.ErrInvalid
	}
	tag, err := t.Exec(ctx, `DELETE FROM adventure_reports WHERE report_id IN (SELECT report_id FROM adventure_reports WHERE expires_at<=$1 ORDER BY expires_at,report_id LIMIT $2)`, at, limit)
	return tag.RowsAffected(), err
}

// PurgeOccurrencesTx deletes one bounded batch of finished or expired
// occurrences older than the retention cutoff.
func (Store) PurgeOccurrencesTx(ctx context.Context, t tx.Tx, cutoff time.Time, limit int64) (int64, error) {
	if limit < 1 || limit > 10000 {
		return 0, d.ErrInvalid
	}
	tag, err := t.Exec(ctx, `DELETE FROM adventure_occurrences WHERE ctid IN (
SELECT ctid FROM adventure_occurrences
WHERE (finished_at IS NOT NULL AND finished_at<=$1) OR (finished_at IS NULL AND end_time<=$1)
ORDER BY end_time LIMIT $2)`, cutoff, limit)
	return tag.RowsAffected(), err
}
