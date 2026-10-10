package socialinboxstore

import (
	"context"
	"encoding/hex"
	"encoding/json"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadCoveredInvitePayloadsTx(c context.Context, q tx.Queryer, m gi.Marker, cursor int64) (gi.OwnerPayloadSet, error) {
	var out gi.OwnerPayloadSet
	var digest, raw string
	if m.Validate() != nil || cursor < 0 || cursor > m.MaxIssueSerial {
		return out, gi.ErrEvidence
	}
	e := q.QueryRow(c, `WITH selected AS (SELECT i.source_id,((to_jsonb(i)-'decision_at')||jsonb_build_object('decision_at',to_char(i.decision_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))) AS target_payload,i.receipt_id,t.receipt_id AS materialized_receipt,CASE WHEN t.source_id IS NULL THEN NULL ELSE ((to_jsonb(t)-'decision_at')||jsonb_build_object('decision_at',to_char(t.decision_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))) END AS materialized_payload FROM social_guild_invite_invalidations i LEFT JOIN social_guild_invite_materializations t USING(source_id) WHERE i.marker_id=$1::uuid AND i.source_serial<=$2),refs AS (SELECT receipt_id AS id FROM selected UNION SELECT materialized_receipt FROM selected WHERE materialized_receipt IS NOT NULL)
 SELECT (SELECT count(*) FROM selected),(SELECT encode(sha256(convert_to(COALESCE(string_agg(source_id::text||':'||target_payload::text||':'||COALESCE(materialized_payload::text,'null')||E'\n','' ORDER BY source_id),''),'UTF8')),'hex') FROM selected),COALESCE((SELECT jsonb_agg(id::text ORDER BY id)::text FROM refs),'[]')`, m.Operation.ID.String(), cursor).Scan(&out.Payloads.Count, &digest, &raw)
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
