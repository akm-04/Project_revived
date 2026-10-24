package guildinvitestore

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) SourceSetThroughCursorTx(c context.Context, q tx.Queryer, m gi.Marker, cursor int64) (gi.SetWitness, error) {
	var out gi.SetWitness
	if q == nil || m.Validate() != nil || cursor < 0 || cursor > m.MaxIssueSerial {
		return out, gi.ErrEvidence
	}
	var digest string
	e := q.QueryRow(c, `SELECT count(*),encode(sha256(convert_to(COALESCE(string_agg(source_id::text||':'||source_fingerprint||E'\n','' ORDER BY source_id),''),'UTF8')),'hex') FROM guild_invite_projection_sources WHERE source_serial<=$1 AND (($2='JOIN' AND recipient_player_id=$3 AND last_join_event_id<$4) OR ($2='RETIRE' AND guild_id=$5))`, cursor, string(m.Kind), int64(m.Subject), m.EventID, int64(m.GuildID)).Scan(&out.Count, &digest)
	if e != nil {
		return out, e
	}
	raw, e := hex.DecodeString(digest)
	if e != nil || len(raw) != 32 {
		return out, gi.ErrEvidence
	}
	copy(out.Digest[:], raw)
	return out, out.Validate()
}

func (s Store) LockMarkerTx(c context.Context, t tx.Tx, id ids.UUID) (gi.Marker, gi.MarkerProgress, bool, error) {
	var raw string
	e := t.QueryRow(c, `SELECT marker_id::text FROM guild_invite_projection_markers WHERE marker_id=$1::uuid FOR UPDATE`, id.String()).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return gi.Marker{}, gi.MarkerProgress{}, false, nil
	}
	if e != nil {
		return gi.Marker{}, gi.MarkerProgress{}, false, e
	}
	return s.ReadMarkerTx(c, t, id)
}

func (Store) AdvanceProvenMarkerTx(c context.Context, t tx.Tx, old gi.MarkerProgress, p gi.CursorProof) error {
	if t == nil || old.Validate() != nil || old.Complete || p.ReceiptID.IsZero() || p.Request.MarkerID != old.MarkerID || p.Request.From != old.CursorSerial || p.Request.To < old.CursorSerial || p.Request.To > old.MaxIssueSerial || p.DecisionAt.Before(old.LastEnqueueAt) {
		return gi.ErrEvidence
	}
	raw, e := json.Marshal(p)
	if e != nil {
		return e
	}
	state := "PENDING"
	var done any
	if p.Request.Complete {
		if p.Request.To != old.MaxIssueSerial {
			return gi.ErrEvidence
		}
		state = "COMPLETE"
		done = p.DecisionAt
	}
	tag, e := t.Exec(c, `UPDATE guild_invite_projection_markers SET cursor_serial=$2,state=$3,last_enqueue_at=$4,next_wakeup_at=$5,completed_at=$6,cursor_receipt_id=$9::uuid,cursor_proof=$10::jsonb WHERE marker_id=$1::uuid AND state='PENDING' AND cursor_serial=$7 AND max_issue_serial=$8`, old.MarkerID.String(), p.Request.To, state, p.DecisionAt, p.DecisionAt.Add(time.Minute), done, old.CursorSerial, old.MaxIssueSerial, p.ReceiptID.String(), string(raw))
	return one(tag, e)
}

// A lifecycle decision is bound before waiting for the global recipient fence.
// Refuse a newly observed later issue; do not resample DecisionAt after locking.
func (Store) LatestMarkerSourceDecisionTx(c context.Context, q tx.Queryer, kind gi.MarkerKind, gid guild.ID, pid identity.PlayerID, high int64) (time.Time, bool, error) {
	if q == nil || high < 0 || kind != gi.Join && kind != gi.Retire {
		return time.Time{}, false, gi.ErrEvidence
	}
	var at time.Time
	var present bool
	e := q.QueryRow(c, `SELECT COALESCE(max(decision_at),'epoch'::timestamptz),count(*)>0 FROM guild_invite_projection_sources WHERE source_serial<=$1 AND (($2='JOIN' AND recipient_player_id=$3) OR ($2='RETIRE' AND guild_id=$4))`, high, string(kind), int64(pid), int64(gid)).Scan(&at, &present)
	return at, present, e
}

func (Store) CoveredSourcePayloadsTx(c context.Context, q tx.Queryer, m gi.Marker, cursor int64) (gi.OwnerPayloadSet, error) {
	var out gi.OwnerPayloadSet
	var digest, raw string
	if m.Validate() != nil || cursor < 0 || cursor > m.MaxIssueSerial {
		return out, gi.ErrEvidence
	}
	e := q.QueryRow(c, `SELECT count(*),encode(sha256(convert_to(COALESCE(string_agg(source_id::text||':'||((to_jsonb(s)-ARRAY['decision_at','expires_at'])||jsonb_build_object('decision_at',to_char(s.decision_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'expires_at',to_char(s.expires_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"')))::text||E'\n','' ORDER BY source_id),''),'UTF8')),'hex'),COALESCE(jsonb_agg(core_receipt_id::text ORDER BY core_receipt_id),'[]'::jsonb)::text FROM guild_invite_projection_sources s WHERE source_serial<=$1 AND (($2='JOIN' AND recipient_player_id=$3 AND last_join_event_id<$4) OR ($2='RETIRE' AND guild_id=$5))`, cursor, string(m.Kind), int64(m.Subject), m.EventID, int64(m.GuildID)).Scan(&out.Payloads.Count, &digest, &raw)
	if e != nil {
		return out, e
	}
	b, e := hex.DecodeString(digest)
	if e != nil || len(b) != 32 {
		return out, gi.ErrEvidence
	}
	copy(out.Payloads.Digest[:], b)
	var keys []string
	if e = json.Unmarshal([]byte(raw), &keys); e != nil {
		return out, e
	}
	for _, key := range keys {
		id, e := ids.ParseUUID(key)
		if e != nil || id.IsZero() {
			return out, gi.ErrEvidence
		}
		out.ReceiptIDs = append(out.ReceiptIDs, id)
	}
	return out, out.Payloads.Validate()
}
