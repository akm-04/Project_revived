package kernelstore

import (
	"context"
	"encoding/hex"
	"encoding/json"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
)

func (Store) GuildInviteReceiptSetWitnessTx(c context.Context, q tx.Queryer, input []ids.UUID) (gi.SetWitness, error) {
	var out gi.SetWitness
	keys := []string{}
	seen := map[ids.UUID]bool{}
	for _, id := range input {
		if id.IsZero() {
			return out, gi.ErrEvidence
		}
		if !seen[id] {
			seen[id] = true
			keys = append(keys, id.String())
		}
	}
	sort.Strings(keys)
	raw, e := json.Marshal(keys)
	if e != nil || len(raw) > 16*1024*1024 {
		return out, gi.ErrEvidence
	}
	var digest string
	var missing int64
	e = q.QueryRow(c, `WITH keys AS (SELECT value::uuid AS id FROM jsonb_array_elements_text($1::jsonb)),facts AS (SELECT keys.id,r.receipt_id,((to_jsonb(r)-ARRAY['operation_started_at','recorded_at','retain_until','request_fingerprint'])||jsonb_build_object('operation_started_at',to_char(r.operation_started_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'recorded_at',to_char(r.recorded_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'retain_until',CASE WHEN r.retain_until IS NULL THEN NULL ELSE to_char(r.retain_until AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') END,'request_fingerprint',encode(r.request_fingerprint,'hex')))::text AS payload FROM keys LEFT JOIN gxb_operation_receipts r ON r.receipt_id=keys.id)
 SELECT count(*),encode(sha256(convert_to(COALESCE(string_agg(id::text||':'||payload||E'\n','' ORDER BY id),''),'UTF8')),'hex'),count(*) FILTER(WHERE receipt_id IS NULL) FROM facts`, string(raw)).Scan(&out.Count, &digest, &missing)
	if e != nil {
		return out, e
	}
	if missing != 0 {
		return out, gi.ErrEvidence
	}
	b, e := hex.DecodeString(digest)
	if e != nil || len(b) != 32 {
		return out, gi.ErrEvidence
	}
	copy(out.Digest[:], b)
	return out, out.Validate()
}
