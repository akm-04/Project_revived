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

// currentRealtimeBindingsSQL keeps the single-actor predicate (player_id plus
// the guild's logical server) for an entire recipient set in one read.
const currentRealtimeBindingsSQL = `
WITH requested(player_id,logical_server_id) AS (
  SELECT * FROM unnest($1::bigint[],$2::int[])
)
SELECT COALESCE(array_agg(gm.player_id), '{}'::bigint[]),
       COALESCE(array_agg(gm.guild_id), '{}'::bigint[]),
       COALESCE(array_agg(e.event_id), '{}'::bigint[])
FROM requested r
JOIN guild_memberships gm ON gm.player_id=r.player_id
JOIN guilds g ON g.guild_id=gm.guild_id AND g.logical_server_id=r.logical_server_id
JOIN LATERAL (
  SELECT event_id
  FROM guild_membership_events
  WHERE player_id=gm.player_id
    AND guild_id=gm.guild_id
    AND event_kind='JOIN'
  ORDER BY event_id DESC
  LIMIT 1
) e ON TRUE
WHERE g.retired_at IS NULL`

// CurrentRealtimeBindings reads the current I6C membership incarnation for each
// valid actor. The result omits actors with no current same-server membership.
func (s Store) CurrentRealtimeBindings(ctx context.Context, actors []identity.ActorContext) (map[identity.PlayerID]RealtimeBinding, error) {
	out := make(map[identity.PlayerID]RealtimeBinding, len(actors))
	if s.Queryer == nil {
		return nil, errors.New("invalid realtime guild binding query")
	}
	players := make([]int64, 0, len(actors))
	servers := make([]int32, 0, len(actors))
	for _, actor := range actors {
		if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() {
			continue
		}
		players = append(players, int64(actor.PlayerID))
		servers = append(servers, int32(actor.LogicalServerID))
	}
	if len(players) == 0 {
		return out, nil
	}
	var playerIDs, guildIDs, eventIDs []int64
	err := s.Queryer.QueryRow(ctx, currentRealtimeBindingsSQL, players, servers).Scan(&playerIDs, &guildIDs, &eventIDs)
	if err != nil {
		return nil, err
	}
	if len(playerIDs) != len(guildIDs) || len(playerIDs) != len(eventIDs) {
		return nil, errors.New("inconsistent canonical realtime guild bindings")
	}
	for i, playerID := range playerIDs {
		binding := RealtimeBinding{GuildID: guildIDs[i], JoinEventID: eventIDs[i]}
		if !binding.Valid() {
			return nil, errors.New("invalid canonical realtime guild binding")
		}
		out[identity.PlayerID(playerID)] = binding
	}
	return out, nil
}

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
