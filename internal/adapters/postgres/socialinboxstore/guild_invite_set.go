package socialinboxstore

import (
	"context"
	"encoding/hex"
	"encoding/json"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadInviteInvalidationSetTx(c context.Context, q tx.Queryer, m gi.Marker, cursor int64) (gi.SetWitness, []identity.PlayerID, error) {
	var out gi.SetWitness
	fp, e := m.Fingerprint()
	if e != nil || q == nil || cursor < 0 || cursor > m.MaxIssueSerial {
		return out, nil, gi.ErrEvidence
	}
	var digest, holes string
	var bad int64
	e = q.QueryRow(c, `WITH selected AS (
 SELECT i.*,n.notice_id AS found_notice,n.active AS notice_active,n.notice_type,n.source_kind,n.source_key AS notice_source,n.state_version AS notice_version,n.dismissed_at
 FROM social_guild_invite_invalidations i
 LEFT JOIN social_notices n ON n.recipient_player_id=i.recipient_player_id AND n.notice_id=i.notice_id
 WHERE i.marker_id=$1::uuid AND i.source_serial<=$2
), checked AS (
 SELECT *, marker_fingerprint<>$3 OR
 NOT(target_payload ?& ARRAY['MarkerID','SourceID','Recipient','MarkerFingerprint','SourceFingerprint','ReceiptID','NoticeID','RootVersion','NoticeStateVersion','SourceSerial','SourceKey','Consumed','DecisionAt']) OR
 target_payload-ARRAY['MarkerID','SourceID','Recipient','MarkerFingerprint','SourceFingerprint','ReceiptID','NoticeID','RootVersion','NoticeStateVersion','SourceSerial','SourceKey','Consumed','DecisionAt']<>'{}'::jsonb OR
 (target_payload->>'MarkerID') IS DISTINCT FROM marker_id::text OR
 (target_payload->>'SourceID') IS DISTINCT FROM source_id::text OR
 (target_payload->>'ReceiptID') IS DISTINCT FROM receipt_id::text OR
 (target_payload->>'Recipient')::bigint IS DISTINCT FROM recipient_player_id OR
 (target_payload->>'SourceSerial')::bigint IS DISTINCT FROM source_serial OR
 (target_payload->>'SourceKey') IS DISTINCT FROM source_key OR
 (target_payload->>'NoticeID')::bigint IS DISTINCT FROM COALESCE(notice_id,0) OR
 (target_payload->>'RootVersion')::bigint IS DISTINCT FROM root_version OR
 (target_payload->>'Consumed')::boolean IS DISTINCT FROM consumed OR
 (target_payload->>'DecisionAt')::timestamptz IS DISTINCT FROM decision_at OR
 (target_payload->'MarkerFingerprint') IS DISTINCT FROM (SELECT jsonb_agg(get_byte(decode(marker_fingerprint,'hex'),b)) FROM generate_series(0,31)b) OR
 (target_payload->'SourceFingerprint') IS DISTINCT FROM (SELECT jsonb_agg(get_byte(decode(source_fingerprint,'hex'),b)) FROM generate_series(0,31)b) OR
 (notice_id IS NULL AND (target_payload->>'NoticeStateVersion')::bigint<>0) OR
 (found_notice IS NOT NULL AND (notice_active OR notice_type<>10 OR source_kind<>'guild.invite.v1' OR notice_source<>source_key OR notice_version IS DISTINCT FROM (target_payload->>'NoticeStateVersion')::bigint OR consumed AND dismissed_at IS DISTINCT FROM decision_at)) AS invalid
 FROM selected
), missing AS (
 SELECT DISTINCT recipient_player_id FROM selected WHERE notice_id IS NOT NULL AND found_notice IS NULL ORDER BY recipient_player_id LIMIT 33
)
SELECT (SELECT count(*) FROM checked),
 (SELECT encode(sha256(convert_to(COALESCE(string_agg(source_id::text||':'||source_fingerprint||E'\n','' ORDER BY source_id),''),'UTF8')),'hex') FROM checked),
 (SELECT count(*) FROM checked WHERE invalid IS DISTINCT FROM false),
 COALESCE((SELECT jsonb_agg(recipient_player_id ORDER BY recipient_player_id)::text FROM missing),'[]')`, m.Operation.ID.String(), cursor, hex.EncodeToString(fp[:])).Scan(&out.Count, &digest, &bad, &holes)
	if e != nil {
		return out, nil, e
	}
	if bad != 0 {
		return out, nil, gi.ErrEvidence
	}
	raw, e := hex.DecodeString(digest)
	if e != nil || len(raw) != 32 {
		return out, nil, gi.ErrEvidence
	}
	copy(out.Digest[:], raw)
	var missing []identity.PlayerID
	if e = json.Unmarshal([]byte(holes), &missing); e != nil {
		return out, nil, e
	}
	if len(missing) > 32 {
		return out, nil, gi.ErrEvidence
	}
	return out, missing, out.Validate()
}
