package guildinvitestore

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"time"
)

type Store struct{}

func one(tag tx.CommandTag, e error) error {
	if e != nil {
		return e
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return gi.ErrEvidence
	}
	return nil
}
func (Store) LockCursorTx(c context.Context, t tx.Tx, gid guild.ID, pid identity.PlayerID) (int64, int64, error) {
	if t == nil || (gi.Tuple{GuildID: gid, Recipient: pid, Generation: 1}).Validate() != nil {
		return 0, 0, gi.ErrEvidence
	}
	var n, v int64
	e := t.QueryRow(c, `SELECT last_generation,state_version FROM guild_invite_projection_cursors WHERE guild_id=$1 AND recipient_player_id=$2 FOR UPDATE`, int64(gid), int64(pid)).Scan(&n, &v)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return 0, 0, nil
	}
	if e != nil {
		return 0, 0, e
	}
	if n < 1 || v < 1 || v == math.MaxInt64 {
		return 0, 0, gi.ErrEvidence
	}
	return n, v, nil
}
func (Store) AdvanceCursorTx(c context.Context, t tx.Tx, tuple gi.Tuple, oldVersion int64, at time.Time) error {
	if t == nil || tuple.Validate() != nil || oldVersion < 0 || oldVersion == math.MaxInt64 || at.IsZero() {
		return gi.ErrEvidence
	}
	if oldVersion == 0 {
		tag, e := t.Exec(c, `INSERT INTO guild_invite_projection_cursors(guild_id,recipient_player_id,last_generation,state_version,updated_at) VALUES($1,$2,$3,1,$4)`, int64(tuple.GuildID), int64(tuple.Recipient), tuple.Generation, at.UTC())
		return one(tag, e)
	}
	tag, e := t.Exec(c, `UPDATE guild_invite_projection_cursors SET last_generation=$3,state_version=state_version+1,updated_at=$5 WHERE guild_id=$1 AND recipient_player_id=$2 AND state_version=$4 AND last_generation<$3 AND updated_at<=$5`, int64(tuple.GuildID), int64(tuple.Recipient), tuple.Generation, oldVersion, at.UTC())
	return one(tag, e)
}
func (Store) PrepareScopeTx(c context.Context, t tx.Tx, gid guild.ID) error {
	if t == nil || gid <= 0 {
		return gi.ErrEvidence
	}
	// Transaction-only rank350 projection fence. It is independent of the
	// process owner lease and does not admit another worker or transaction.
	_, e := t.Exec(c, `SELECT pg_advisory_xact_lock(hashtextextended($1,0))`, fmt.Sprintf("gxb.guild-projection.350:%d", gid))
	return e
}
func (Store) NextIssueSerialTx(c context.Context, q tx.Queryer) (int64, error) {
	var n int64
	e := q.QueryRow(c, `SELECT nextval('guild_invite_projection_sources_source_serial_seq')`).Scan(&n)
	if e == nil && n < 1 {
		e = gi.ErrEvidence
	}
	return n, e
}
func (Store) IssueHighWaterTx(c context.Context, q tx.Queryer) (int64, error) {
	var n int64
	e := q.QueryRow(c, `SELECT COALESCE(max(source_serial),0) FROM guild_invite_projection_sources`).Scan(&n)
	return n, e
}

func (Store) InsertIssueTx(c context.Context, t tx.Tx, s gi.Issue, d gi.Delivery) error {
	fp, e := s.Fingerprint()
	if e != nil || d.Validate() != nil || d.State != gi.Pending || d.SourceID != s.Operation.ID || d.Recipient != s.Tuple.Recipient || !d.LastEnqueueAt.Equal(s.DecisionAt) {
		return gi.ErrEvidence
	}
	raw, e := json.Marshal(s)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO guild_invite_projection_sources(source_id,source_serial,guild_id,logical_server_id,recipient_player_id,inviter_player_id,invite_generation,source_payload,source_fingerprint,core_receipt_id,decision_at,expires_at,last_join_event_id) VALUES($1::uuid,$2,$3,$4,$5,$6,$7,$8::jsonb,$9,$10::uuid,$11,$12,$13)`, s.Operation.ID.String(), s.Serial, int64(s.Tuple.GuildID), int32(s.Server), int64(s.Tuple.Recipient), int64(s.Inviter), s.Tuple.Generation, string(raw), hex.EncodeToString(fp[:]), s.Core.ID.String(), s.DecisionAt, s.ExpiresAt, s.LastJoinEventID)
	if e = one(tag, e); e != nil {
		return e
	}
	tag, e = t.Exec(c, `INSERT INTO guild_invite_projection_deliveries(source_id,recipient_player_id,state,last_enqueue_at,next_wakeup_at) VALUES($1::uuid,$2,'PENDING',$3,$4)`, d.SourceID.String(), int64(d.Recipient), d.LastEnqueueAt, d.NextWakeupAt)
	return one(tag, e)
}
func (Store) ReadIssueTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.Issue, bool, error) {
	if q == nil || id.IsZero() {
		return gi.Issue{}, false, gi.ErrEvidence
	}
	var raw, fp, rr string
	var serial, gid, pid, inviter, gen, join int64
	var sid int32
	var at, expires time.Time
	e := q.QueryRow(c, `SELECT source_payload::text,source_fingerprint,source_serial,guild_id,logical_server_id,recipient_player_id,inviter_player_id,invite_generation,core_receipt_id::text,decision_at,expires_at,last_join_event_id FROM guild_invite_projection_sources WHERE source_id=$1::uuid`, id.String()).Scan(&raw, &fp, &serial, &gid, &sid, &pid, &inviter, &gen, &rr, &at, &expires, &join)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gi.Issue{}, false, nil
	}
	if e != nil {
		return gi.Issue{}, false, e
	}
	s, e := gi.DecodeIssue([]byte(raw), fp)
	if e != nil || s.Operation.ID != id || s.Serial != serial || int64(s.Tuple.GuildID) != gid || int32(s.Server) != sid || int64(s.Tuple.Recipient) != pid || int64(s.Inviter) != inviter || s.Tuple.Generation != gen || s.Core.ID.String() != rr || s.DecisionAt.UnixMicro() != at.UnixMicro() || s.ExpiresAt.UnixMicro() != expires.UnixMicro() || s.LastJoinEventID != join {
		return gi.Issue{}, false, gi.ErrEvidence
	}
	return s, true, nil
}
func (s Store) ReadIssueTupleTx(c context.Context, q tx.Queryer, tuple gi.Tuple) (gi.Issue, bool, error) {
	if tuple.Validate() != nil {
		return gi.Issue{}, false, gi.ErrEvidence
	}
	var raw string
	e := q.QueryRow(c, `SELECT source_id::text FROM guild_invite_projection_sources WHERE guild_id=$1 AND recipient_player_id=$2 AND invite_generation=$3`, int64(tuple.GuildID), int64(tuple.Recipient), tuple.Generation).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gi.Issue{}, false, nil
	}
	if e != nil {
		return gi.Issue{}, false, e
	}
	id, e := ids.ParseUUID(raw)
	if e != nil {
		return gi.Issue{}, false, e
	}
	return s.ReadIssueTx(c, q, id)
}
func (Store) InsertMarkerTx(c context.Context, t tx.Tx, m gi.Marker, p gi.MarkerProgress) error {
	fp, e := m.Fingerprint()
	if e != nil || p.Validate() != nil || p.MarkerID != m.Operation.ID || p.MaxIssueSerial != m.MaxIssueSerial || p.CursorSerial != 0 || p.Complete || !p.LastEnqueueAt.Equal(m.DecisionAt) {
		return gi.ErrEvidence
	}
	raw, e := json.Marshal(m)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO guild_invite_projection_markers(marker_id,marker_kind,guild_id,subject_player_id,event_id,max_issue_serial,source_payload,source_fingerprint,core_receipt_id,decision_at,state,cursor_serial,last_enqueue_at,next_wakeup_at) VALUES($1::uuid,$2,$3,$4,$5,$6,$7::jsonb,$8,$9::uuid,$10,'PENDING',0,$11,$12)`, m.Operation.ID.String(), string(m.Kind), int64(m.GuildID), int64(m.Subject), m.EventID, m.MaxIssueSerial, string(raw), hex.EncodeToString(fp[:]), m.Core.ID.String(), m.DecisionAt, p.LastEnqueueAt, p.NextWakeupAt)
	return one(tag, e)
}
func (Store) ReadMarkerTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.Marker, gi.MarkerProgress, bool, error) {
	var p gi.MarkerProgress
	var raw, fp, kind, rr, state string
	var cursorRaw, cursorReceipt *string
	var gid, pid, event int64
	var at time.Time
	if q == nil || id.IsZero() {
		return gi.Marker{}, p, false, gi.ErrEvidence
	}
	e := q.QueryRow(c, `SELECT source_payload::text,source_fingerprint,marker_kind,guild_id,subject_player_id,event_id,max_issue_serial,core_receipt_id::text,decision_at,state,cursor_serial,last_enqueue_at,next_wakeup_at,completed_at,cursor_proof::text,cursor_receipt_id::text FROM guild_invite_projection_markers WHERE marker_id=$1::uuid`, id.String()).Scan(&raw, &fp, &kind, &gid, &pid, &event, &p.MaxIssueSerial, &rr, &at, &state, &p.CursorSerial, &p.LastEnqueueAt, &p.NextWakeupAt, &p.CompletedAt, &cursorRaw, &cursorReceipt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gi.Marker{}, p, false, nil
	}
	if e != nil {
		return gi.Marker{}, p, false, e
	}
	m, e := gi.DecodeMarker([]byte(raw), fp)
	p.MarkerID = id
	p.Complete = state == "COMPLETE"
	if cursorRaw != nil {
		proof, decodeErr := gi.DecodeCursorProof([]byte(*cursorRaw), m)
		if decodeErr != nil || cursorReceipt == nil || proof.ReceiptID.String() != *cursorReceipt {
			return gi.Marker{}, p, false, gi.ErrEvidence
		}
		p.CursorProof = &proof
	} else if cursorReceipt != nil {
		return gi.Marker{}, p, false, gi.ErrEvidence
	}

	if e != nil || p.Validate() != nil || state != "PENDING" && state != "COMPLETE" || m.Operation.ID != id || string(m.Kind) != kind || int64(m.GuildID) != gid || int64(m.Subject) != pid || m.EventID != event || m.MaxIssueSerial != p.MaxIssueSerial || m.Core.ID.String() != rr || m.DecisionAt.UnixMicro() != at.UnixMicro() {
		return gi.Marker{}, p, false, gi.ErrEvidence
	}
	return m, p, true, nil
}
func (Store) ReadDeliveryTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.Delivery, bool, error) {
	d := gi.Delivery{SourceID: id}
	var pid int64
	var rr *string
	var state string
	e := q.QueryRow(c, `SELECT recipient_player_id,state,target_receipt_id::text,COALESCE(notice_id,0),acknowledged_at,last_enqueue_at,next_wakeup_at FROM guild_invite_projection_deliveries WHERE source_id=$1::uuid`, id.String()).Scan(&pid, &state, &rr, &d.NoticeID, &d.AcknowledgedAt, &d.LastEnqueueAt, &d.NextWakeupAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d, false, nil
	}
	if e != nil {
		return d, false, e
	}
	d.Recipient = identity.PlayerID(pid)
	d.State = gi.DeliveryState(state)
	if rr != nil {
		d.ReceiptID, e = ids.ParseUUID(*rr)
		if e != nil {
			return d, false, e
		}
	}
	return d, true, d.Validate()
}
func (s Store) LockDeliveryTx(c context.Context, t tx.Tx, id ids.UUID) (gi.Delivery, bool, error) {
	var raw string
	e := t.QueryRow(c, `SELECT source_id::text FROM guild_invite_projection_deliveries WHERE source_id=$1::uuid FOR UPDATE`, id.String()).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gi.Delivery{}, false, nil
	}
	if e != nil {
		return gi.Delivery{}, false, e
	}
	return s.ReadDeliveryTx(c, t, id)
}
func (Store) AcknowledgeDeliveryTx(c context.Context, t tx.Tx, p gi.TargetProof, at time.Time) error {
	if p.Validate() != nil || at.Before(p.DecisionAt) {
		return gi.ErrEvidence
	}
	var notice any
	if p.State == gi.Materialized {
		notice = p.NoticeID
	}
	tag, e := t.Exec(c, `UPDATE guild_invite_projection_deliveries SET state=$3,target_receipt_id=$4::uuid,notice_id=$5,acknowledged_at=$6 WHERE source_id=$1::uuid AND recipient_player_id=$2 AND state='PENDING' AND last_enqueue_at<=$6`, p.SourceID.String(), int64(p.Recipient), string(p.State), p.ReceiptID.String(), notice, at.UTC())
	return one(tag, e)
}
func (s Store) ReadMarkerPageTx(c context.Context, q tx.Queryer, m gi.Marker, p gi.MarkerProgress, limit int) ([]gi.Issue, error) {
	if m.Validate() != nil || p.Validate() != nil || p.MarkerID != m.Operation.ID || p.MaxIssueSerial != m.MaxIssueSerial || p.Complete || limit < 1 || limit > 1000 {
		return nil, gi.ErrEvidence
	}
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(source_id::text ORDER BY source_serial),'[]'::jsonb)::text FROM (SELECT source_id,source_serial FROM guild_invite_projection_sources WHERE source_serial>$1 AND source_serial<=$2 AND (($3='JOIN' AND recipient_player_id=$4 AND last_join_event_id<$5) OR ($3='RETIRE' AND guild_id=$6)) ORDER BY source_serial LIMIT $7) page`, p.CursorSerial, p.MaxIssueSerial, string(m.Kind), int64(m.Subject), m.EventID, int64(m.GuildID), limit).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var refs []string
	if e = json.Unmarshal([]byte(raw), &refs); e != nil {
		return nil, e
	}
	out := make([]gi.Issue, 0, len(refs))
	prev := p.CursorSerial
	for _, ref := range refs {
		id, e := ids.ParseUUID(ref)
		if e != nil {
			return nil, e
		}
		v, ok, e := s.ReadIssueTx(c, q, id)
		if e != nil {
			return nil, e
		}
		applies, ae := m.AppliesTo(v)
		if !ok || ae != nil || !applies || v.Serial <= prev {
			return nil, gi.ErrEvidence
		}
		prev = v.Serial
		out = append(out, v)
	}
	return out, nil
}

var _ app.Store = Store{}
