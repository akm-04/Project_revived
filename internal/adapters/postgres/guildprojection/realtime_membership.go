package guildprojection

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RealtimeMembership is a read-only adapter from canonical I6C GuildMembership
// truth to the I7A/realtime authorization seam. It does not publish, mutate
// rooms, or own socket lifecycle.
type RealtimeMembership struct{ Queryer tx.Queryer }

const currentGuildBindingSQL = `
SELECT gm.guild_id,e.event_id
FROM guild_memberships gm
JOIN guilds g ON g.guild_id=gm.guild_id
JOIN LATERAL (
  SELECT event_id
  FROM guild_membership_events
  WHERE player_id=gm.player_id
    AND guild_id=gm.guild_id
    AND event_kind='JOIN'
  ORDER BY event_id DESC
  LIMIT 1
) e ON TRUE
WHERE gm.player_id=$1
  AND g.retired_at IS NULL
  AND g.logical_server_id=$2`

func (r RealtimeMembership) CurrentGuildBinding(ctx context.Context, actor identity.ActorContext) (apprealtime.GuildBinding, bool, error) {
	if r.Queryer == nil || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() {
		return apprealtime.GuildBinding{}, false, errors.New("invalid realtime guild binding query")
	}
	var out apprealtime.GuildBinding
	err := r.Queryer.QueryRow(ctx, currentGuildBindingSQL, int64(actor.PlayerID), int32(actor.LogicalServerID)).Scan(&out.GuildID, &out.JoinEventID)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return apprealtime.GuildBinding{}, false, nil
	}
	if err != nil {
		return apprealtime.GuildBinding{}, false, err
	}
	if !out.Valid() {
		return apprealtime.GuildBinding{}, false, errors.New("invalid canonical realtime guild binding")
	}
	return out, true, nil
}

var _ apprealtime.GuildMembershipPort = RealtimeMembership{}
