package guildstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) AppendMembershipEventReturningTx(c context.Context, t tx.Tx, v guild.MembershipEvent, op ids.UUID) (guild.MembershipEvent, error) {
	if t == nil || v.Validate() != nil || op.IsZero() {
		return v, gi.ErrEvidence
	}
	e := t.QueryRow(c, `INSERT INTO guild_membership_events(player_id,guild_id,event_kind,actor_player_id,occurred_at,policy_revision,operation_id) VALUES($1,$2,$3,$4,$5,$6,$7::uuid) RETURNING event_id`, int64(v.PlayerID), int64(v.GuildID), string(v.Kind), int64(v.ActorPlayerID), v.OccurredAt.UTC(), v.PolicyRevision, op.String()).Scan(&v.EventID)
	if e == nil && v.EventID < 1 {
		e = gi.ErrEvidence
	}
	return v, e
}
func (Store) AppendInviteSendReturningTx(c context.Context, t tx.Tx, gid guild.ID, inviter, target identity.PlayerID, at time.Time, rev string, op ids.UUID) (int64, error) {
	if t == nil || (gi.Tuple{GuildID: gid, Recipient: target, Generation: 1}).Validate() != nil || !inviter.Valid() || inviter == target || int64(inviter)/100000 != int64(gid)/1000000 || at.IsZero() || rev == "" || op.IsZero() {
		return 0, gi.ErrEvidence
	}
	var id int64
	e := t.QueryRow(c, `INSERT INTO guild_invite_send_events(guild_id,inviter_player_id,invited_player_id,occurred_at,policy_revision,operation_id) VALUES($1,$2,$3,$4,$5,$6::uuid) RETURNING event_id`, int64(gid), int64(inviter), int64(target), at.UTC(), rev, op.String()).Scan(&id)
	if e == nil && id < 1 {
		e = gi.ErrEvidence
	}
	return id, e
}
func (Store) BindInviteIssueTx(c context.Context, t tx.Tx, s gi.Issue) error {
	if s.Validate() != nil {
		return gi.ErrEvidence
	}
	tag, e := t.Exec(c, `UPDATE guild_invites SET projection_source_id=$4::uuid WHERE guild_id=$1 AND invited_player_id=$2 AND invite_generation=$3 AND inviter_player_id=$5 AND created_at=$6 AND expires_at=$7 AND projection_source_id IS NULL`, int64(s.Tuple.GuildID), int64(s.Tuple.Recipient), s.Tuple.Generation, s.Operation.ID.String(), int64(s.Inviter), s.DecisionAt, s.ExpiresAt)
	if e != nil {
		return e
	}
	return one(tag, "invite projection binding")
}
func (Store) BindMembershipMarkerTx(c context.Context, t tx.Tx, m gi.Marker) error {
	if m.Validate() != nil {
		return gi.ErrEvidence
	}
	kind := "JOIN"
	if m.Kind == gi.Retire {
		kind = "DISSOLVE"
	}
	tag, e := t.Exec(c, `UPDATE guild_membership_events SET projection_source_id=$2::uuid WHERE event_id=$1 AND player_id=$3 AND guild_id=$4 AND event_kind=$5 AND actor_player_id=$6 AND occurred_at=$7 AND policy_revision=$8 AND operation_id=$2::uuid AND projection_source_id IS NULL`, m.EventID, m.Operation.ID.String(), int64(m.Subject), int64(m.GuildID), kind, int64(m.Actor), m.DecisionAt, m.GuildCoreRevision)
	if e != nil {
		return e
	}
	return one(tag, "membership projection binding")
}
func (Store) ReadInviteIssueIDTx(c context.Context, q tx.Queryer, gid guild.ID, pid identity.PlayerID) (ids.UUID, error) {
	var raw *string
	e := q.QueryRow(c, `SELECT projection_source_id::text FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2`, int64(gid), int64(pid)).Scan(&raw)
	if noRows(e) {
		return ids.UUID{}, nil
	}
	if e != nil {
		return ids.UUID{}, e
	}
	if raw == nil {
		return ids.UUID{}, nil
	}
	return ids.ParseUUID(*raw)
}
func (Store) ReadMembershipMarkerIDTx(c context.Context, q tx.Queryer, id int64) (ids.UUID, error) {
	var raw *string
	e := q.QueryRow(c, `SELECT projection_source_id::text FROM guild_membership_events WHERE event_id=$1`, id).Scan(&raw)
	if noRows(e) {
		return ids.UUID{}, gi.ErrEvidence
	}
	if e != nil {
		return ids.UUID{}, e
	}
	if raw == nil {
		return ids.UUID{}, nil
	}
	return ids.ParseUUID(*raw)
}
func (Store) PrepareMembershipCleanupTx(c context.Context, t tx.Tx, pid identity.PlayerID) error {
	if t == nil || !pid.Valid() {
		return gi.ErrEvidence
	}
	var count int64
	// PlayerRoot315 fences this player's application absence; acquire every
	// existing330 leaf before any membership or deletion effect.
	return t.QueryRow(c, `SELECT count(*) FROM (SELECT guild_id FROM guild_applications WHERE player_id=$1 ORDER BY guild_id::text FOR UPDATE) prepared`, int64(pid)).Scan(&count)
}
func (Store) PrepareRetirementChildrenTx(c context.Context, t tx.Tx, gid guild.ID) error {
	if t == nil || gid <= 0 {
		return gi.ErrEvidence
	}
	var count int64
	if e := t.QueryRow(c, `SELECT count(*) FROM (SELECT player_id FROM guild_applications WHERE guild_id=$1 ORDER BY player_id::text FOR UPDATE) prepared`, int64(gid)).Scan(&count); e != nil {
		return e
	}
	return t.QueryRow(c, `SELECT count(*) FROM (SELECT invited_player_id FROM guild_invites WHERE guild_id=$1 ORDER BY invited_player_id::text FOR UPDATE) prepared`, int64(gid)).Scan(&count)
}
func (Store) ValidateIssueBindingsTx(c context.Context, q tx.Queryer, s gi.Issue) error {
	if s.Validate() != nil {
		return gi.ErrEvidence
	}
	var count int64
	e := q.QueryRow(c, `SELECT count(*) FROM guild_invite_send_events WHERE event_id=$1 AND guild_id=$2 AND inviter_player_id=$3 AND invited_player_id=$4 AND occurred_at=$5 AND policy_revision=$6 AND operation_id=$7::uuid`, s.SendEventID, int64(s.Tuple.GuildID), int64(s.Inviter), int64(s.Tuple.Recipient), s.DecisionAt, s.GuildCoreRevision, s.Operation.ID.String()).Scan(&count)
	if e != nil {
		return e
	}
	if count != 1 {
		return gi.ErrEvidence
	}
	if s.LastJoinEventID > 0 {
		e = q.QueryRow(c, `SELECT count(*) FROM guild_membership_events WHERE event_id=$1 AND player_id=$2 AND event_kind='JOIN' AND occurred_at=$3`, s.LastJoinEventID, int64(s.Tuple.Recipient), s.LastJoinedAt).Scan(&count)
		if e != nil {
			return e
		}
		if count != 1 {
			return gi.ErrEvidence
		}
	}
	return nil
}
func (Store) ValidateMarkerBindingsTx(c context.Context, q tx.Queryer, m gi.Marker) error {
	if m.Validate() != nil {
		return gi.ErrEvidence
	}
	kind := "JOIN"
	if m.Kind == gi.Retire {
		kind = "DISSOLVE"
	}
	var count int64
	e := q.QueryRow(c, `SELECT count(*) FROM guild_membership_events WHERE event_id=$1 AND player_id=$2 AND guild_id=$3 AND actor_player_id=$4 AND event_kind=$5 AND occurred_at=$6 AND policy_revision=$7 AND operation_id=$8::uuid AND projection_source_id=$8::uuid`, m.EventID, int64(m.Subject), int64(m.GuildID), int64(m.Actor), kind, m.DecisionAt, m.GuildCoreRevision, m.Operation.ID.String()).Scan(&count)
	if e != nil {
		return e
	}
	if count != 1 {
		return gi.ErrEvidence
	}
	return nil
}

var _ app.GuildBindings = Store{}

func (Store) ReadRetirementEventTx(c context.Context, q tx.Queryer, gid guild.ID) (guild.MembershipEvent, bool, error) {
	var v guild.MembershipEvent
	var pid, actor int64
	e := q.QueryRow(c, `SELECT event_id,player_id,actor_player_id,occurred_at,policy_revision FROM guild_membership_events WHERE guild_id=$1 AND event_kind='DISSOLVE' ORDER BY event_id DESC LIMIT 1`, int64(gid)).Scan(&v.EventID, &pid, &actor, &v.OccurredAt, &v.PolicyRevision)
	if noRows(e) {
		return v, false, nil
	}
	if e != nil {
		return v, false, e
	}
	v.GuildID = gid
	v.PlayerID = identity.PlayerID(pid)
	v.ActorPlayerID = identity.PlayerID(actor)
	v.Kind = guild.EventDissolve
	v.OccurredAt = v.OccurredAt.UTC()
	if v.Validate() != nil || v.EventID < 1 {
		return v, false, gi.ErrEvidence
	}
	return v, true, nil
}

// A newly replaced Invite starts unbound, including the inactive legacy
// producer path on schema38. An older issue's immutable binding is retained
// in its own source tables and must not leak onto a new current generation.
func (Store) UpsertInviteForProjectionTx(c context.Context, t tx.Tx, v guild.Invite) error {
	if t == nil || v.Validate() != nil {
		return gi.ErrEvidence
	}
	_, e := t.Exec(c, `INSERT INTO guild_invites(guild_id,invited_player_id,invite_generation,inviter_player_id,created_at,expires_at,state_version,projection_source_id) VALUES($1,$2,$3,$4,$5,$6,$7,NULL) ON CONFLICT(guild_id,invited_player_id) DO UPDATE SET invite_generation=EXCLUDED.invite_generation,inviter_player_id=EXCLUDED.inviter_player_id,created_at=EXCLUDED.created_at,expires_at=EXCLUDED.expires_at,state_version=guild_invites.state_version+1,projection_source_id=NULL`, int64(v.GuildID), int64(v.InvitedPlayerID), v.Generation, int64(v.InviterPlayerID), v.CreatedAt.UTC(), v.ExpiresAt.UTC(), v.StateVersion)
	return e
}

func (Store) LatestJoinTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (guild.MembershipEvent, bool, error) {
	var v guild.MembershipEvent
	var gid, actor int64
	e := q.QueryRow(c, `SELECT event_id,guild_id,actor_player_id,occurred_at,policy_revision FROM guild_membership_events WHERE player_id=$1 AND event_kind='JOIN' ORDER BY event_id DESC LIMIT 1`, int64(pid)).Scan(&v.EventID, &gid, &actor, &v.OccurredAt, &v.PolicyRevision)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return v, false, nil
	}
	if e != nil {
		return v, false, e
	}
	v.GuildID = guild.ID(gid)
	v.ActorPlayerID = identity.PlayerID(actor)
	v.PlayerID = pid
	v.Kind = guild.EventJoin
	v.OccurredAt = v.OccurredAt.UTC()
	if v.EventID < 1 || v.Validate() != nil {
		return v, false, gi.ErrEvidence
	}
	return v, true, nil
}
