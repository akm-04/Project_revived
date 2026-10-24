package guildinvitestore

import (
	"context"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadRetainedValidityTx(c context.Context, q tx.Queryer, s gi.Issue) (ids.UUID, error) {
	if q == nil || s.Validate() != nil {
		return ids.UUID{}, gi.ErrEvidence
	}
	var cursor int64
	var marker *string
	e := q.QueryRow(c, `SELECT COALESCE((SELECT last_generation FROM guild_invite_projection_cursors WHERE guild_id=$1 AND recipient_player_id=$2),0),(SELECT marker_id::text FROM guild_invite_projection_markers WHERE guild_id=$1 AND marker_kind='RETIRE' ORDER BY event_id DESC LIMIT 1)`, int64(s.Tuple.GuildID), int64(s.Tuple.Recipient)).Scan(&cursor, &marker)
	if e != nil {
		return ids.UUID{}, e
	}
	if cursor < s.Tuple.Generation {
		return ids.UUID{}, gi.ErrEvidence
	}
	if marker == nil {
		return ids.UUID{}, nil
	}
	return ids.ParseUUID(*marker)
}
