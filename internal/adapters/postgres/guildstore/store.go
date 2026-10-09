package guildstore

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{ Queryer tx.Queryer }

func noRows(err error) bool { return errors.Is(err, kernelstore.ErrNoRows) }
func one(tag tx.CommandTag, what string) error {
	if tag == nil || tag.RowsAffected() != 1 {
		var n int64
		if tag != nil {
			n = tag.RowsAffected()
		}
		return fmt.Errorf("%s affected %d rows", what, n)
	}
	return nil
}

func (Store) LockAllocatorTx(ctx context.Context, t tx.Tx, server identity.LogicalServerID, now time.Time) (int64, int64, error) {
	if t == nil || !server.Valid() || now.IsZero() {
		return 0, 0, errors.New("invalid guild allocator lock")
	}
	if _, err := t.Exec(ctx, `INSERT INTO guild_server_allocators(logical_server_id,next_serial,state_version,updated_at) VALUES($1,1,1,$2) ON CONFLICT(logical_server_id) DO NOTHING`, int32(server), now.UTC()); err != nil {
		return 0, 0, err
	}
	var next, ver int64
	if err := t.QueryRow(ctx, `SELECT next_serial,state_version FROM guild_server_allocators WHERE logical_server_id=$1 FOR UPDATE`, int32(server)).Scan(&next, &ver); err != nil {
		return 0, 0, err
	}
	if next < 1 || next > 999999 || ver <= 0 {
		return 0, 0, errors.New("guild allocator exhausted or corrupt")
	}
	return next, ver, nil
}
func (Store) AdvanceAllocatorTx(ctx context.Context, t tx.Tx, server identity.LogicalServerID, oldSerial, oldVersion int64, now time.Time) error {
	tag, err := t.Exec(ctx, `UPDATE guild_server_allocators SET next_serial=$2,state_version=state_version+1,updated_at=$3 WHERE logical_server_id=$1 AND next_serial=$4 AND state_version=$5`, int32(server), oldSerial+1, now.UTC(), oldSerial, oldVersion)
	if err != nil {
		return err
	}
	return one(tag, "guild allocator")
}

func scanGuild(row tx.Row) (guild.Guild, error) {
	var g guild.Guild
	var sid int32
	var id int64
	var role int16
	_ = role
	err := row.Scan(&id, &sid, &g.Name, &g.Icon, &g.IconFrame, &g.Description, (*int16)(&g.ApplyType), &g.MinAllowLevel, &g.Vitality, &g.PolicyRevision, &g.StateVersion, &g.CreatedAt, &g.UpdatedAt, &g.RetiredAt)
	g.ID = guild.ID(id)
	g.LogicalServerID = identity.LogicalServerID(sid)
	if err == nil {
		err = g.Validate()
	}
	return g, err
}

const guildColumns = `guild_id,logical_server_id,name,icon,icon_frame,des,apply_type,min_allow_level,vitality,policy_revision,state_version,created_at,updated_at,retired_at`

func (Store) LockGuildTx(ctx context.Context, t tx.Tx, id guild.ID) (guild.Guild, bool, error) {
	if t == nil || id <= 0 {
		return guild.Guild{}, false, errors.New("invalid guild lock")
	}
	g, err := scanGuild(t.QueryRow(ctx, `SELECT `+guildColumns+` FROM guilds WHERE guild_id=$1 FOR UPDATE`, int64(id)))
	if noRows(err) {
		return guild.Guild{}, false, nil
	}
	return g, err == nil, err
}
func (s Store) ReadGuild(ctx context.Context, id guild.ID) (guild.Guild, bool, error) {
	if s.Queryer == nil {
		return guild.Guild{}, false, errors.New("nil guild queryer")
	}
	return s.ReadGuildTx(ctx, s.Queryer, id)
}
func (Store) ReadGuildTx(ctx context.Context, q tx.Queryer, id guild.ID) (guild.Guild, bool, error) {
	if q == nil || id <= 0 {
		return guild.Guild{}, false, errors.New("invalid guild read")
	}
	g, err := scanGuild(q.QueryRow(ctx, `SELECT `+guildColumns+` FROM guilds WHERE guild_id=$1`, int64(id)))
	if noRows(err) {
		return guild.Guild{}, false, nil
	}
	return g, err == nil, err
}
func (Store) GuildNameInUseTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, name string, exclude guild.ID) (bool, error) {
	if q == nil || !server.Valid() || name == "" {
		return false, errors.New("invalid guild name lookup")
	}
	var exists bool
	err := q.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM guilds WHERE logical_server_id=$1 AND name COLLATE "C"=$2 COLLATE "C" AND retired_at IS NULL AND ($3::bigint=0 OR guild_id<>$3))`, int32(server), name, int64(exclude)).Scan(&exists)
	return exists, err
}

func (Store) InsertGuildTx(ctx context.Context, t tx.Tx, g guild.Guild) error {
	if t == nil {
		return errors.New("nil guild tx")
	}
	if err := g.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `INSERT INTO guilds(guild_id,logical_server_id,name,icon,icon_frame,des,apply_type,min_allow_level,vitality,policy_revision,state_version,created_at,updated_at,retired_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`, int64(g.ID), int32(g.LogicalServerID), g.Name, g.Icon, g.IconFrame, g.Description, int16(g.ApplyType), g.MinAllowLevel, g.Vitality, g.PolicyRevision, g.StateVersion, g.CreatedAt.UTC(), g.UpdatedAt.UTC(), g.RetiredAt)
	if err != nil {
		return err
	}
	return one(tag, "insert guild")
}
func (Store) SaveGuildTx(ctx context.Context, t tx.Tx, g guild.Guild, oldVersion int64) error {
	if err := g.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE guilds SET name=$2,icon=$3,icon_frame=$4,des=$5,apply_type=$6,min_allow_level=$7,vitality=$8,policy_revision=$9,state_version=$10,updated_at=$11,retired_at=$12 WHERE guild_id=$1 AND state_version=$13`, int64(g.ID), g.Name, g.Icon, g.IconFrame, g.Description, int16(g.ApplyType), g.MinAllowLevel, g.Vitality, g.PolicyRevision, g.StateVersion, g.UpdatedAt.UTC(), g.RetiredAt, oldVersion)
	if err != nil {
		return err
	}
	return one(tag, "save guild")
}

func scanMembership(row tx.Row) (guild.Membership, error) {
	var m guild.Membership
	var pid, gid int64
	var role int16
	err := row.Scan(&pid, &gid, &role, &m.JoinedAt, &m.MembershipVersion, &m.StateVersion, &m.UpdatedAt)
	m.PlayerID = identity.PlayerID(pid)
	m.GuildID = guild.ID(gid)
	m.Role = guild.Role(role)
	if err == nil {
		err = m.Validate()
	}
	return m, err
}

const membershipColumns = `player_id,guild_id,role,joined_at,membership_version,state_version,updated_at`

func (Store) LockMembershipTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (guild.Membership, bool, error) {
	if t == nil || !pid.Valid() {
		return guild.Membership{}, false, errors.New("invalid membership lock")
	}
	m, err := scanMembership(t.QueryRow(ctx, `SELECT `+membershipColumns+` FROM guild_memberships WHERE player_id=$1 FOR UPDATE`, int64(pid)))
	if noRows(err) {
		return guild.Membership{}, false, nil
	}
	return m, err == nil, err
}
func (s Store) ReadMembership(ctx context.Context, pid identity.PlayerID) (guild.Membership, bool, error) {
	if s.Queryer == nil {
		return guild.Membership{}, false, errors.New("nil guild queryer")
	}
	return s.ReadMembershipTx(ctx, s.Queryer, pid)
}
func (Store) ReadMembershipTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (guild.Membership, bool, error) {
	if q == nil || !pid.Valid() {
		return guild.Membership{}, false, errors.New("invalid membership read")
	}
	m, err := scanMembership(q.QueryRow(ctx, `SELECT `+membershipColumns+` FROM guild_memberships WHERE player_id=$1`, int64(pid)))
	if noRows(err) {
		return guild.Membership{}, false, nil
	}
	return m, err == nil, err
}
func (Store) InsertMembershipTx(ctx context.Context, t tx.Tx, m guild.Membership) error {
	if err := m.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7)`, int64(m.PlayerID), int64(m.GuildID), int16(m.Role), m.JoinedAt.UTC(), m.MembershipVersion, m.StateVersion, m.UpdatedAt.UTC())
	if err != nil {
		return err
	}
	return one(tag, "insert membership")
}
func (Store) SaveMembershipRoleTx(ctx context.Context, t tx.Tx, m guild.Membership, oldVersion int64) error {
	if err := m.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE guild_memberships SET role=$2,membership_version=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND state_version=$6`, int64(m.PlayerID), int16(m.Role), m.MembershipVersion, m.StateVersion, m.UpdatedAt.UTC(), oldVersion)
	if err != nil {
		return err
	}
	return one(tag, "save membership")
}
func (Store) DeleteMembershipTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, gid guild.ID, stateVersion int64) error {
	tag, err := t.Exec(ctx, `DELETE FROM guild_memberships WHERE player_id=$1 AND guild_id=$2 AND state_version=$3`, int64(pid), int64(gid), stateVersion)
	if err != nil {
		return err
	}
	return one(tag, "delete membership")
}
func (Store) CountMembersTx(ctx context.Context, q tx.Queryer, gid guild.ID) (int64, error) {
	var n int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM guild_memberships WHERE guild_id=$1`, int64(gid)).Scan(&n)
	return n, err
}
func (Store) CountRoleTx(ctx context.Context, q tx.Queryer, gid guild.ID, role guild.Role) (int64, error) {
	if q == nil || gid <= 0 || !role.Valid() {
		return 0, errors.New("invalid guild role count")
	}
	var n int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM guild_memberships WHERE guild_id=$1 AND role=$2`, int64(gid), int16(role)).Scan(&n)
	return n, err
}

func (Store) AppendMembershipEventTx(ctx context.Context, t tx.Tx, e guild.MembershipEvent, op ids.UUID) error {
	if err := e.Validate(); err != nil {
		return err
	}
	var opv any
	if !op.IsZero() {
		opv = op.String()
	}
	tag, err := t.Exec(ctx, `INSERT INTO guild_membership_events(player_id,guild_id,event_kind,actor_player_id,occurred_at,policy_revision,operation_id) VALUES($1,$2,$3,$4,$5,$6,$7)`, int64(e.PlayerID), int64(e.GuildID), string(e.Kind), int64(e.ActorPlayerID), e.OccurredAt.UTC(), e.PolicyRevision, opv)
	if err != nil {
		return err
	}
	return one(tag, "membership event")
}
func (Store) LatestMembershipEventTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (guild.MembershipEvent, bool, error) {
	if q == nil || !pid.Valid() {
		return guild.MembershipEvent{}, false, errors.New("invalid membership-event lookup")
	}
	var e guild.MembershipEvent
	var playerID, guildID, actorID int64
	var kind string
	err := q.QueryRow(ctx, `SELECT event_id,player_id,guild_id,event_kind,occurred_at,actor_player_id,policy_revision FROM guild_membership_events WHERE player_id=$1 ORDER BY event_id DESC LIMIT 1`, int64(pid)).Scan(&e.EventID, &playerID, &guildID, &kind, &e.OccurredAt, &actorID, &e.PolicyRevision)
	if noRows(err) {
		return guild.MembershipEvent{}, false, nil
	}
	e.PlayerID = identity.PlayerID(playerID)
	e.GuildID = guild.ID(guildID)
	e.Kind = guild.MembershipEventKind(kind)
	e.ActorPlayerID = identity.PlayerID(actorID)
	if err == nil {
		err = e.Validate()
	}
	if err == nil && e.EventID <= 0 {
		err = errors.New("invalid membership-event identity")
	}
	return e, err == nil, err
}

func (Store) CountJoinsSinceTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, since time.Time) (int64, error) {
	var n int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM guild_membership_events WHERE player_id=$1 AND event_kind='JOIN' AND occurred_at >= $2`, int64(pid), since.UTC()).Scan(&n)
	return n, err
}
func (Store) LastDepartureTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (guild.ID, guild.MembershipEventKind, time.Time, bool, error) {
	var gid int64
	var k string
	var at time.Time
	err := q.QueryRow(ctx, `SELECT guild_id,event_kind,occurred_at FROM guild_membership_events WHERE player_id=$1 AND event_kind IN ('LEAVE','KICK','DISSOLVE') ORDER BY occurred_at DESC,event_id DESC LIMIT 1`, int64(pid)).Scan(&gid, &k, &at)
	if noRows(err) {
		return 0, "", time.Time{}, false, nil
	}
	if err != nil {
		return 0, "", time.Time{}, false, err
	}
	return guild.ID(gid), guild.MembershipEventKind(k), at.UTC(), true, nil
}
func (Store) MembershipEpochTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (int64, error) {
	var n int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM guild_membership_events WHERE player_id=$1`, int64(pid)).Scan(&n)
	return n + 1, err
}

func (Store) FindApplicationTx(ctx context.Context, q tx.Queryer, gid guild.ID, pid identity.PlayerID) (guild.Application, bool, error) {
	var a guild.Application
	var rgid, rpid int64
	err := q.QueryRow(ctx, `SELECT guild_id,player_id,application_generation,created_at,state_version FROM guild_applications WHERE guild_id=$1 AND player_id=$2`, int64(gid), int64(pid)).Scan(&rgid, &rpid, &a.Generation, &a.CreatedAt, &a.StateVersion)
	if noRows(err) {
		return guild.Application{}, false, nil
	}
	a.GuildID = guild.ID(rgid)
	a.PlayerID = identity.PlayerID(rpid)
	if err == nil {
		err = a.Validate()
	}
	return a, err == nil, err
}
func (Store) InsertApplicationTx(ctx context.Context, t tx.Tx, a guild.Application) error {
	if err := a.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `INSERT INTO guild_applications(guild_id,player_id,application_generation,created_at,state_version) VALUES($1,$2,$3,$4,$5)`, int64(a.GuildID), int64(a.PlayerID), a.Generation, a.CreatedAt.UTC(), a.StateVersion)
	if err != nil {
		return err
	}
	return one(tag, "insert application")
}
func (Store) DeleteApplicationTx(ctx context.Context, t tx.Tx, gid guild.ID, pid identity.PlayerID) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_applications WHERE guild_id=$1 AND player_id=$2`, int64(gid), int64(pid))
	return err
}
func (Store) CountOutgoingApplicationsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (int64, error) {
	var n int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM guild_applications WHERE player_id=$1`, int64(pid)).Scan(&n)
	return n, err
}
func (Store) CountGuildApplicationsTx(ctx context.Context, q tx.Queryer, gid guild.ID) (int64, error) {
	var n int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM guild_applications WHERE guild_id=$1`, int64(gid)).Scan(&n)
	return n, err
}

func (Store) FindInviteTx(ctx context.Context, q tx.Queryer, gid guild.ID, pid identity.PlayerID) (guild.Invite, bool, error) {
	var i guild.Invite
	var rgid, rpid, inviter int64
	err := q.QueryRow(ctx, `SELECT guild_id,invited_player_id,invite_generation,inviter_player_id,created_at,expires_at,state_version FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2`, int64(gid), int64(pid)).Scan(&rgid, &rpid, &i.Generation, &inviter, &i.CreatedAt, &i.ExpiresAt, &i.StateVersion)
	if noRows(err) {
		return guild.Invite{}, false, nil
	}
	i.GuildID = guild.ID(rgid)
	i.InvitedPlayerID = identity.PlayerID(rpid)
	i.InviterPlayerID = identity.PlayerID(inviter)
	if err == nil {
		err = i.Validate()
	}
	return i, err == nil, err
}
func (Store) UpsertInviteTx(ctx context.Context, t tx.Tx, i guild.Invite) error {
	if err := i.Validate(); err != nil {
		return err
	}
	_, err := t.Exec(ctx, `INSERT INTO guild_invites(guild_id,invited_player_id,invite_generation,inviter_player_id,created_at,expires_at,state_version) VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(guild_id,invited_player_id) DO UPDATE SET invite_generation=EXCLUDED.invite_generation,inviter_player_id=EXCLUDED.inviter_player_id,created_at=EXCLUDED.created_at,expires_at=EXCLUDED.expires_at,state_version=guild_invites.state_version+1`, int64(i.GuildID), int64(i.InvitedPlayerID), i.Generation, int64(i.InviterPlayerID), i.CreatedAt.UTC(), i.ExpiresAt.UTC(), i.StateVersion)
	return err
}
func (Store) DeleteInviteTx(ctx context.Context, t tx.Tx, gid guild.ID, pid identity.PlayerID) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2`, int64(gid), int64(pid))
	return err
}
func (Store) CountInvitesSinceTx(ctx context.Context, q tx.Queryer, inviter identity.PlayerID, since time.Time) (int64, error) {
	var n int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM guild_invite_send_events WHERE inviter_player_id=$1 AND occurred_at >= $2`, int64(inviter), since.UTC()).Scan(&n)
	return n, err
}
func (Store) AppendInviteSendTx(ctx context.Context, t tx.Tx, gid guild.ID, inviter, target identity.PlayerID, at time.Time, policyRevision string, op ids.UUID) error {
	var opv any
	if !op.IsZero() {
		opv = op.String()
	}
	tag, err := t.Exec(ctx, `INSERT INTO guild_invite_send_events(guild_id,inviter_player_id,invited_player_id,occurred_at,policy_revision,operation_id) VALUES($1,$2,$3,$4,$5,$6)`, int64(gid), int64(inviter), int64(target), at.UTC(), policyRevision, opv)
	if err != nil {
		return err
	}
	return one(tag, "invite send event")
}

func (Store) AppendAuditTx(ctx context.Context, t tx.Tx, gid guild.ID, kind string, actor, subject identity.PlayerID, at time.Time, policyRevision string, op ids.UUID, details string) error {
	var seq int64
	if err := t.QueryRow(ctx, `SELECT COALESCE(max(sequence),0)+1 FROM guild_audit_log WHERE guild_id=$1`, int64(gid)).Scan(&seq); err != nil {
		return err
	}
	var actorv, subjectv, opv any
	if actor.Valid() {
		actorv = int64(actor)
	}
	if subject.Valid() {
		subjectv = int64(subject)
	}
	if !op.IsZero() {
		opv = op.String()
	}
	if details == "" {
		details = "{}"
	}
	tag, err := t.Exec(ctx, `INSERT INTO guild_audit_log(guild_id,sequence,event_kind,actor_player_id,subject_player_id,occurred_at,policy_revision,operation_id,details) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb)`, int64(gid), seq, kind, actorv, subjectv, at.UTC(), policyRevision, opv, details)
	if err != nil {
		return err
	}
	return one(tag, "guild audit")
}

// DeleteApplicationsForPlayerTx clears obsolete application state after a
// canonical membership is established. Applications are discovery workflow,
// never durable membership authority.
func (Store) DeleteApplicationsForPlayerTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_applications WHERE player_id=$1`, int64(pid))
	return err
}

func (s Store) ListGuilds(ctx context.Context, server identity.LogicalServerID, limit int) ([]guild.Guild, error) {
	if s.Queryer == nil || !server.Valid() {
		return nil, errors.New("invalid guild list query")
	}
	if limit <= 0 || limit > 200 {
		limit = 200
	}
	var raw string
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
		'ID',guild_id,'LogicalServerID',logical_server_id,'Name',name,'Icon',icon,'IconFrame',icon_frame,
		'Description',des,'ApplyType',apply_type,'MinAllowLevel',min_allow_level,'Vitality',vitality,
		'PolicyRevision',policy_revision,'StateVersion',state_version,'CreatedAt',created_at,'UpdatedAt',updated_at,
		'RetiredAt',retired_at) ORDER BY guild_id),'[]'::jsonb)::text
		FROM (SELECT * FROM guilds WHERE logical_server_id=$1 AND retired_at IS NULL ORDER BY guild_id LIMIT $2) g`, int32(server), limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var out []guild.Guild
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	for _, g := range out {
		if err := g.Validate(); err != nil {
			return nil, err
		}
	}
	return out, nil
}

func (Store) LockApplicationTx(ctx context.Context, t tx.Tx, gid guild.ID, pid identity.PlayerID) (guild.Application, bool, error) {
	var a guild.Application
	var rgid, rpid int64
	err := t.QueryRow(ctx, `SELECT guild_id,player_id,application_generation,created_at,state_version FROM guild_applications WHERE guild_id=$1 AND player_id=$2 FOR UPDATE`, int64(gid), int64(pid)).Scan(&rgid, &rpid, &a.Generation, &a.CreatedAt, &a.StateVersion)
	if noRows(err) {
		return guild.Application{}, false, nil
	}
	a.GuildID, a.PlayerID = guild.ID(rgid), identity.PlayerID(rpid)
	if err == nil {
		err = a.Validate()
	}
	return a, err == nil, err
}

func (Store) LockInviteTx(ctx context.Context, t tx.Tx, gid guild.ID, pid identity.PlayerID) (guild.Invite, bool, error) {
	var i guild.Invite
	var rgid, rpid, inviter int64
	err := t.QueryRow(ctx, `SELECT guild_id,invited_player_id,invite_generation,inviter_player_id,created_at,expires_at,state_version FROM guild_invites WHERE guild_id=$1 AND invited_player_id=$2 FOR UPDATE`, int64(gid), int64(pid)).Scan(&rgid, &rpid, &i.Generation, &inviter, &i.CreatedAt, &i.ExpiresAt, &i.StateVersion)
	if noRows(err) {
		return guild.Invite{}, false, nil
	}
	i.GuildID, i.InvitedPlayerID, i.InviterPlayerID = guild.ID(rgid), identity.PlayerID(rpid), identity.PlayerID(inviter)
	if err == nil {
		err = i.Validate()
	}
	return i, err == nil, err
}

func (s Store) ListGuildApplications(ctx context.Context, gid guild.ID) ([]guild.Application, error) {
	if s.Queryer == nil || gid <= 0 {
		return nil, errors.New("invalid guild application list")
	}
	var raw string
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('GuildID',guild_id,'PlayerID',player_id,'Generation',application_generation,'CreatedAt',created_at,'StateVersion',state_version) ORDER BY created_at,player_id),'[]'::jsonb)::text FROM guild_applications WHERE guild_id=$1`, int64(gid)).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var out []guild.Application
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	for _, a := range out {
		if err := a.Validate(); err != nil {
			return nil, err
		}
	}
	return out, nil
}
func (s Store) ListPlayerApplications(ctx context.Context, pid identity.PlayerID) ([]guild.Application, error) {
	if s.Queryer == nil || !pid.Valid() {
		return nil, errors.New("invalid player application list")
	}
	var raw string
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('GuildID',guild_id,'PlayerID',player_id,'Generation',application_generation,'CreatedAt',created_at,'StateVersion',state_version) ORDER BY created_at,guild_id),'[]'::jsonb)::text FROM guild_applications WHERE player_id=$1`, int64(pid)).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var out []guild.Application
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	for _, a := range out {
		if err := a.Validate(); err != nil {
			return nil, err
		}
	}
	return out, nil
}
func (s Store) ListMemberships(ctx context.Context, gid guild.ID) ([]guild.Membership, error) {
	if s.Queryer == nil || gid <= 0 {
		return nil, errors.New("invalid membership list")
	}
	var raw string
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('PlayerID',player_id,'GuildID',guild_id,'Role',role,'JoinedAt',joined_at,'MembershipVersion',membership_version,'StateVersion',state_version,'UpdatedAt',updated_at) ORDER BY player_id),'[]'::jsonb)::text FROM guild_memberships WHERE guild_id=$1`, int64(gid)).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var out []guild.Membership
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	for _, m := range out {
		if err := m.Validate(); err != nil {
			return nil, err
		}
	}
	return out, nil
}

func (Store) DeleteGuildApplicationsTx(ctx context.Context, t tx.Tx, gid guild.ID) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_applications WHERE guild_id=$1`, int64(gid))
	return err
}
func (Store) DeleteGuildInvitesTx(ctx context.Context, t tx.Tx, gid guild.ID) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_invites WHERE guild_id=$1`, int64(gid))
	return err
}

// ListMembershipsTx retains source-time membership closure in the caller's
// snapshot. Fetch one beyond the finite source cap to detect corrupt overflow.
func (Store) ListMembershipsTx(ctx context.Context, q tx.Queryer, gid guild.ID) ([]guild.Membership, error) {
	if q == nil || gid <= 0 {
		return nil, errors.New("invalid tx membership list")
	}
	var raw string
	e := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('PlayerID',player_id,'GuildID',guild_id,'Role',role,'JoinedAt',joined_at,'MembershipVersion',membership_version,'StateVersion',state_version,'UpdatedAt',updated_at) ORDER BY player_id),'[]'::jsonb)::text FROM (SELECT * FROM guild_memberships WHERE guild_id=$1 ORDER BY player_id LIMIT 51) members`, int64(gid)).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var out []guild.Membership
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	for _, m := range out {
		if e = m.Validate(); e != nil {
			return nil, e
		}
	}
	return out, nil
}
