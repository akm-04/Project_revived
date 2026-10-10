package socialinboxstore

import (
	"context"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ValidateInviteSchema(c context.Context, q tx.Queryer) error {
	var n int64
	return q.QueryRow(c, `SELECT count(*) FROM (SELECT t.source_id,t.recipient_player_id,t.source_fingerprint,t.target_payload,t.receipt_id,t.notice_id,t.root_version,t.decision_at,i.marker_id,i.source_id,i.source_serial,i.source_key,i.marker_fingerprint,i.source_fingerprint,i.target_payload,i.receipt_id,i.recipient_player_id,i.notice_id,i.consumed,i.root_version,i.decision_at FROM social_guild_invite_materializations t CROSS JOIN social_guild_invite_invalidations i LIMIT 0) checked`).Scan(&n)
}
