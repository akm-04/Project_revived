package guildinvitestore

import (
	"context"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) SchemaPresent(c context.Context, q tx.Queryer) (bool, error) {
	var present bool
	e := q.QueryRow(c, `SELECT to_regclass('guild_invite_projection_sources') IS NOT NULL`).Scan(&present)
	return present, e
}
func (Store) ValidateSchema(c context.Context, q tx.Queryer) error {
	var n int64
	return q.QueryRow(c, `SELECT count(*) FROM (SELECT c.guild_id,c.recipient_player_id,c.last_generation,c.state_version,c.updated_at,s.source_id,s.source_serial,s.source_payload,s.source_fingerprint,s.guild_id,s.recipient_player_id,s.invite_generation,s.last_join_event_id,s.core_receipt_id,d.state,d.target_receipt_id,d.acknowledged_at,d.last_enqueue_at,d.next_wakeup_at,m.marker_id,m.source_payload,m.source_fingerprint,m.event_id,m.max_issue_serial,m.cursor_serial,m.cursor_receipt_id,m.cursor_proof,m.state,m.completed_at FROM guild_invite_projection_cursors c CROSS JOIN guild_invite_projection_sources s CROSS JOIN guild_invite_projection_deliveries d CROSS JOIN guild_invite_projection_markers m LIMIT 0) checked`).Scan(&n)
}
