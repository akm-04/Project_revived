package guildstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
)

// RealtimeBinding is the canonical I6C GuildMembership incarnation used by
// established GUILD-socket authorization. JoinEventID is the latest same-Guild
// JOIN event that created the current membership; mutable membership_version is
// deliberately not an incarnation identifier.
type RealtimeBinding struct {
	GuildID     int64
	JoinEventID int64
}

func (b RealtimeBinding) Valid() bool { return b.GuildID > 0 && b.JoinEventID > 0 }

const currentRealtimeBindingSQL = `
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

// CurrentRealtimeBinding reads only I6C-owned Guild state. It returns ok=false
// when no current active same-server membership incarnation exists.
func (s Store) CurrentRealtimeBinding(ctx context.Context, actor identity.ActorContext) (RealtimeBinding, bool, error) {
	if s.Queryer == nil || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() {
		return RealtimeBinding{}, false, errors.New("invalid realtime guild binding query")
	}
	var out RealtimeBinding
	err := s.Queryer.QueryRow(ctx, currentRealtimeBindingSQL, int64(actor.PlayerID), int32(actor.LogicalServerID)).Scan(&out.GuildID, &out.JoinEventID)
	if noRows(err) {
		return RealtimeBinding{}, false, nil
	}
	if err != nil {
		return RealtimeBinding{}, false, err
	}
	if !out.Valid() {
		return RealtimeBinding{}, false, errors.New("invalid canonical realtime guild binding")
	}
	return out, true, nil
}
