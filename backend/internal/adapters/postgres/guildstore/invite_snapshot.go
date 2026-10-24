package guildstore

import (
	"context"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) ReadGuildInviteSnapshotTx(c context.Context, q tx.Queryer, s gi.Issue) (gi.Snapshot, error) {
	v := gi.Snapshot{Issue: s}
	if q == nil || s.Validate() != nil {
		return v, gi.ErrEvidence
	}
	var inviter int64
	var source, retire *string
	var created, expires *time.Time
	var retired *time.Time
	var currentGID int64
	var latestKind string
	var latestGID, latestEvent int64
	e := q.QueryRow(c, `SELECT
 EXISTS(SELECT 1 FROM guilds WHERE guild_id=$1),
 (SELECT retired_at FROM guilds WHERE guild_id=$1),
 COALESCE((SELECT guild_id FROM guild_memberships WHERE player_id=$2),0),
 COALESCE((SELECT invite_generation FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2),0),
 (SELECT projection_source_id::text FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2),
 COALESCE((SELECT inviter_player_id FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2),0),
 (SELECT created_at FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2),
 (SELECT expires_at FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2),
 COALESCE((SELECT max(event_id) FROM guild_membership_events WHERE player_id=$2 AND event_kind='JOIN'),0),
 (SELECT projection_source_id::text FROM guild_membership_events WHERE guild_id=$1 AND event_kind='DISSOLVE' ORDER BY event_id DESC LIMIT 1),
 COALESCE((SELECT event_kind FROM guild_membership_events WHERE player_id=$2 ORDER BY event_id DESC LIMIT 1),''),
 COALESCE((SELECT guild_id FROM guild_membership_events WHERE player_id=$2 ORDER BY event_id DESC LIMIT 1),0),
 COALESCE((SELECT event_id FROM guild_membership_events WHERE player_id=$2 ORDER BY event_id DESC LIMIT 1),0)`, int64(s.Tuple.GuildID), int64(s.Tuple.Recipient)).Scan(&v.GuildPresent, &retired, &currentGID, &v.CurrentGeneration, &source, &inviter, &created, &expires, &v.LatestJoinEventID, &retire, &latestKind, &latestGID, &latestEvent)
	if e != nil {
		return v, e
	}
	v.Retired = retired != nil
	v.CurrentMember = currentGID != 0
	if source != nil {
		v.CurrentSourceID, e = ids.ParseUUID(*source)
		if e != nil {
			return v, e
		}
	}
	if retire != nil {
		v.RetirementMarkerID, e = ids.ParseUUID(*retire)
		if e != nil {
			return v, e
		}
		v.Retired = true
	}
	if v.LatestJoinEventID < s.LastJoinEventID || !v.GuildPresent && v.RetirementMarkerID.IsZero() || v.CurrentMember && (latestKind != "JOIN" || latestGID != currentGID || latestEvent != v.LatestJoinEventID) {
		return v, gi.ErrEvidence
	}
	if v.CurrentGeneration == s.Tuple.Generation && (v.CurrentSourceID != s.Operation.ID || inviter != int64(s.Inviter) || created == nil || expires == nil || created.UnixMicro() != s.DecisionAt.UnixMicro() || expires.UnixMicro() != s.ExpiresAt.UnixMicro()) {
		return v, gi.ErrEvidence
	}
	if retired != nil && retired.Before(s.DecisionAt) {
		return v, gi.ErrEvidence
	}
	return v, nil
}
