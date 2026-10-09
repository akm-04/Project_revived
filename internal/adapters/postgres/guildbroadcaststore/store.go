package guildbroadcaststore

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/guild"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func one(tag tx.CommandTag, e error) error {
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return nil
}
func (Store) InsertSourceTx(c context.Context, t tx.Tx, s gb.Source, receiptID ids.UUID) error {
	if t == nil || receiptID.IsZero() {
		return gb.ErrSource
	}
	if e := s.Validate(); e != nil {
		return e
	}
	fp, e := s.Fingerprint()
	if e != nil {
		return e
	}
	refs, e := policy.MarshalCanonicalJSON(s.Operation.Policies)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO guild_broadcast_sources(source_id,guild_id,logical_server_id,leader_player_id,leader_name,name_snapshot_changed_at,operation_started_at,operation_started_at_exact,entropy_seed,policy_refs,decision_at,content_revision,guild_core_revision,policy_id,title,body,source_fingerprint,recipient_count,source_receipt_id) VALUES($1::uuid,$2,$3,$4,$5,$6,$7,$8,$9,$10::jsonb,$11,$12,$13,$14,$15,$16,$17,$18,$19::uuid)`, s.Operation.ID.String(), int64(s.GuildID), int32(s.Server), int64(s.LeaderID), s.LeaderName, s.NameSnapshotChangedAt, s.Operation.StartedAt.UTC(), s.Operation.StartedAt.UTC().Format(time.RFC3339Nano), s.Operation.EntropySeed[:], string(refs), s.DecisionAt, s.ContentRevision, s.GuildCoreRevision, s.PolicyID, s.Request.Title, s.Request.Content, hex.EncodeToString(fp[:]), len(s.Recipients), receiptID.String())
	return one(tag, e)
}
func (Store) InsertBindingTx(c context.Context, t tx.Tx, b gb.Binding, m gb.Member) error {
	if t == nil || b.Validate() != nil || b.State != gb.Pending || m.PlayerID != b.RecipientID || m.JoinEventID <= 0 || m.JoinedAt.IsZero() {
		return gb.ErrSource
	}
	tag, e := t.Exec(c, `INSERT INTO guild_broadcast_recipients(source_id,recipient_player_id,join_event_id,joined_at,state,last_enqueue_at,next_wakeup_at) VALUES($1::uuid,$2,$3,$4,'PENDING',$5,$6)`, b.SourceID.String(), int64(b.RecipientID), m.JoinEventID, m.JoinedAt, b.LastEnqueueAt, b.NextWakeupAt)
	return one(tag, e)
}
func (Store) ReadSourceTx(c context.Context, q tx.Queryer, id ids.UUID) (gb.Source, bool, error) {
	var s gb.Source
	if q == nil || id.IsZero() {
		return s, false, gb.ErrSource
	}
	s.Operation.ID = id
	var gid, pid int64
	var sid int32
	var seed []byte
	var refs, fp, exact string
	var projectedStart time.Time
	var count int
	e := q.QueryRow(c, `SELECT guild_id,logical_server_id,leader_player_id,leader_name,name_snapshot_changed_at,operation_started_at,operation_started_at_exact,entropy_seed,policy_refs::text,decision_at,content_revision,guild_core_revision,policy_id,title,body,source_fingerprint,recipient_count FROM guild_broadcast_sources WHERE source_id=$1::uuid`, id.String()).Scan(&gid, &sid, &pid, &s.LeaderName, &s.NameSnapshotChangedAt, &projectedStart, &exact, &seed, &refs, &s.DecisionAt, &s.ContentRevision, &s.GuildCoreRevision, &s.PolicyID, &s.Request.Title, &s.Request.Content, &fp, &count)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return s, false, nil
	}
	if e != nil {
		return s, false, e
	}
	s.GuildID = guild.ID(gid)
	s.Server = identity.LogicalServerID(sid)
	s.LeaderID = identity.PlayerID(pid)
	if len(seed) != 32 {
		return s, false, app.ErrConflict
	}
	copy(s.Operation.EntropySeed[:], seed)
	s.Operation.StartedAt, e = time.Parse(time.RFC3339Nano, exact)
	if e != nil || s.Operation.StartedAt.UnixMicro() != projectedStart.UnixMicro() {
		return s, false, app.ErrConflict
	}
	s.Operation.Policies, e = policy.ParseCanonicalJSON([]byte(refs))
	if e != nil {
		return s, false, e
	}
	s.DecisionAt = s.DecisionAt.UTC()
	s.NameSnapshotChangedAt = s.NameSnapshotChangedAt.UTC()
	var raw string
	e = q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('PlayerID',recipient_player_id,'JoinEventID',join_event_id,'JoinedAt',joined_at) ORDER BY recipient_player_id),'[]'::jsonb)::text FROM guild_broadcast_recipients WHERE source_id=$1::uuid`, id.String()).Scan(&raw)
	if e != nil {
		return s, false, e
	}
	if e = json.Unmarshal([]byte(raw), &s.Recipients); e != nil {
		return s, false, e
	}
	for i := range s.Recipients {
		s.Recipients[i].JoinedAt = s.Recipients[i].JoinedAt.UTC()
	}
	if len(s.Recipients) != count {
		return s, false, app.ErrConflict
	}
	computed, e := s.Fingerprint()
	if e != nil || hex.EncodeToString(computed[:]) != fp {
		return s, false, app.ErrConflict
	}
	return s, true, nil
}
func (Store) ReadSourceReceiptIDTx(c context.Context, q tx.Queryer, id ids.UUID) (ids.UUID, error) {
	var raw string
	if q == nil {
		return ids.UUID{}, gb.ErrSource
	}
	if e := q.QueryRow(c, `SELECT source_receipt_id::text FROM guild_broadcast_sources WHERE source_id=$1::uuid`, id.String()).Scan(&raw); e != nil {
		return ids.UUID{}, e
	}
	return ids.ParseUUID(raw)
}
func (Store) ReadBindingTx(c context.Context, q tx.Queryer, id ids.UUID, pid identity.PlayerID) (gb.Binding, bool, error) {
	b := gb.Binding{SourceID: id, RecipientID: pid}
	if q == nil || id.IsZero() || !pid.Valid() {
		return b, false, gb.ErrSource
	}
	var state string
	var rid, mailID *string
	e := q.QueryRow(c, `SELECT state,target_receipt_id::text,mail_uuid::text,COALESCE(wire_id,0),acknowledged_at,last_enqueue_at,next_wakeup_at FROM guild_broadcast_recipients WHERE source_id=$1::uuid AND recipient_player_id=$2`, id.String(), int64(pid)).Scan(&state, &rid, &mailID, &b.WireID, &b.AcknowledgedAt, &b.LastEnqueueAt, &b.NextWakeupAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return b, false, nil
	}
	if e != nil {
		return b, false, e
	}
	b.State = gb.State(state)
	if rid != nil {
		b.TargetReceiptID, e = ids.ParseUUID(*rid)
		if e != nil {
			return b, false, e
		}
	}
	if mailID != nil {
		b.MailID, e = ids.ParseUUID(*mailID)
		if e != nil {
			return b, false, e
		}
	}
	return b, true, b.Validate()
}

var _ app.SourceStore = Store{}

func (s Store) LockBindingTx(c context.Context, t tx.Tx, id ids.UUID, pid identity.PlayerID) (gb.Binding, bool, error) {
	var oneID int64
	e := t.QueryRow(c, `SELECT recipient_player_id FROM guild_broadcast_recipients WHERE source_id=$1::uuid AND recipient_player_id=$2 FOR UPDATE`, id.String(), int64(pid)).Scan(&oneID)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gb.Binding{}, false, nil
	}
	if e != nil {
		return gb.Binding{}, false, e
	}
	return s.ReadBindingTx(c, t, id, pid)
}
func (Store) AcknowledgeBindingTx(c context.Context, t tx.Tx, p gb.TargetProof, at time.Time) error {
	if p.Validate() != nil || at.IsZero() {
		return gb.ErrSource
	}
	var mid, wire any
	if p.State == gb.Delivered {
		mid = p.MailID.String()
		wire = p.WireID
	}
	tag, e := t.Exec(c, `UPDATE guild_broadcast_recipients SET state=$3,target_receipt_id=$4::uuid,mail_uuid=$5::uuid,wire_id=$6,acknowledged_at=$7 WHERE source_id=$1::uuid AND recipient_player_id=$2 AND state='PENDING'`, p.SourceID.String(), int64(p.RecipientID), string(p.State), p.ReceiptID.String(), mid, wire, at.UTC())
	return one(tag, e)
}

var _ app.AckStore = Store{}

// Due rows advance their durable not-before time in the same transaction as
// enqueue. Ordered missing-progress scheduling prevents a lost-job prefix from
// starving later recipients; terminal rows are excluded by the owner predicate.
func (s Store) ListDuePendingForUpdateTx(c context.Context, t tx.Tx, at time.Time, limit int) ([]gb.Binding, error) {
	if at.IsZero() || limit < 1 || limit > 1000 {
		return nil, gb.ErrSource
	}
	var raw string
	e := t.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('source',source_id::text,'recipient',recipient_player_id) ORDER BY next_wakeup_at,source_id,recipient_player_id),'[]'::jsonb)::text FROM (SELECT source_id,recipient_player_id,next_wakeup_at FROM guild_broadcast_recipients WHERE state='PENDING' AND next_wakeup_at<=$1 ORDER BY next_wakeup_at,source_id,recipient_player_id LIMIT $2 FOR UPDATE SKIP LOCKED) due`, at.UTC(), limit).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var refs []struct {
		Source    string `json:"source"`
		Recipient int64  `json:"recipient"`
	}
	if e = json.Unmarshal([]byte(raw), &refs); e != nil {
		return nil, e
	}
	out := make([]gb.Binding, 0, len(refs))
	for _, ref := range refs {
		id, e := ids.ParseUUID(ref.Source)
		if e != nil {
			return nil, e
		}
		b, ok, e := s.ReadBindingTx(c, t, id, identity.PlayerID(ref.Recipient))
		if e != nil {
			return nil, e
		}
		if !ok || b.State != gb.Pending {
			return nil, app.ErrConflict
		}
		out = append(out, b)
	}
	return out, nil
}
func (Store) ReschedulePendingTx(c context.Context, t tx.Tx, b gb.Binding, at time.Time) error {
	if b.Validate() != nil || b.State != gb.Pending || at.IsZero() || b.NextWakeupAt.After(at) || b.LastEnqueueAt.After(at) {
		return gb.ErrSource
	}
	tag, e := t.Exec(c, `UPDATE guild_broadcast_recipients SET last_enqueue_at=$3,next_wakeup_at=$4 WHERE source_id=$1::uuid AND recipient_player_id=$2 AND state='PENDING' AND last_enqueue_at=$5 AND next_wakeup_at=$6`, b.SourceID.String(), int64(b.RecipientID), at.UTC(), at.UTC().Add(time.Minute), b.LastEnqueueAt, b.NextWakeupAt)
	return one(tag, e)
}

var _ app.ReconcileStore = Store{}

// ValidateSchema checks the exact owner columns without inventing empty rows or
// mutating schema. Readiness must precede HTTP exposure and worker admission.
func (Store) ValidateSchema(c context.Context, q tx.Queryer) error {
	if q == nil {
		return gb.ErrSource
	}
	var count int64
	e := q.QueryRow(c, `SELECT count(*) FROM (SELECT s.source_id,s.guild_id,s.logical_server_id,s.leader_player_id,s.leader_name,s.name_snapshot_changed_at,s.operation_started_at,s.operation_started_at_exact,s.entropy_seed,s.policy_refs,s.decision_at,s.content_revision,s.guild_core_revision,s.policy_id,s.title,s.body,s.source_fingerprint,s.recipient_count,s.source_receipt_id,r.recipient_player_id,r.join_event_id,r.joined_at,r.state,r.target_receipt_id,r.mail_uuid,r.wire_id,r.acknowledged_at,r.last_enqueue_at,r.next_wakeup_at FROM guild_broadcast_sources s LEFT JOIN guild_broadcast_recipients r ON r.source_id=s.source_id LIMIT 0) checked`).Scan(&count)
	return e
}
