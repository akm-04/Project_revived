package guildinvitestore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

func (Store) ListDueInviteForUpdateTx(c context.Context, t tx.Tx, at time.Time, limit int) ([]app.DueReference, error) {
	if at.IsZero() || limit < 1 || limit > 1000 {
		return nil, gi.ErrEvidence
	}
	var raw string
	e := t.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('id',id::text,'marker',marker) ORDER BY next_wakeup_at,id),'[]'::jsonb)::text FROM (SELECT source_id AS id,false AS marker,next_wakeup_at FROM guild_invite_projection_deliveries WHERE state='PENDING' AND next_wakeup_at<=$1 UNION ALL SELECT marker_id,true,next_wakeup_at FROM guild_invite_projection_markers WHERE state='PENDING' AND next_wakeup_at<=$1 ORDER BY next_wakeup_at,id LIMIT $2) due`, at.UTC(), limit).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var refs []struct {
		ID     string `json:"id"`
		Marker bool   `json:"marker"`
	}
	if e = json.Unmarshal([]byte(raw), &refs); e != nil {
		return nil, e
	}
	// The oldest due finite prefix supplies fairness. Lock its members in one
	// stable UUID order; another scanner skips currently owned rows.
	sort.Slice(refs, func(i, j int) bool { return refs[i].ID < refs[j].ID })
	out := make([]app.DueReference, 0, len(refs))
	for _, ref := range refs {
		id, e := ids.ParseUUID(ref.ID)
		if e != nil {
			return nil, e
		}
		d := app.DueReference{ID: id, Marker: ref.Marker}
		sql := `SELECT last_enqueue_at,next_wakeup_at FROM guild_invite_projection_deliveries WHERE source_id=$1::uuid AND state='PENDING' AND next_wakeup_at<=$2 FOR UPDATE SKIP LOCKED`
		if ref.Marker {
			sql = `SELECT last_enqueue_at,next_wakeup_at FROM guild_invite_projection_markers WHERE marker_id=$1::uuid AND state='PENDING' AND next_wakeup_at<=$2 FOR UPDATE SKIP LOCKED`
		}
		e = t.QueryRow(c, sql, id.String(), at.UTC()).Scan(&d.Last, &d.Next)
		if errors.Is(e, kernelstore.ErrNoRows) {
			continue
		}
		if e != nil {
			return nil, e
		}
		out = append(out, d)
	}
	return out, nil
}
func (Store) RescheduleInviteTx(c context.Context, t tx.Tx, d app.DueReference, at time.Time) error {
	if d.ID.IsZero() || at.IsZero() || d.Last.After(at) || d.Next.After(at) {
		return gi.ErrEvidence
	}
	sql := `UPDATE guild_invite_projection_deliveries SET last_enqueue_at=$2,next_wakeup_at=$3 WHERE source_id=$1::uuid AND state='PENDING' AND last_enqueue_at=$4 AND next_wakeup_at=$5`
	if d.Marker {
		sql = `UPDATE guild_invite_projection_markers SET last_enqueue_at=$2,next_wakeup_at=$3 WHERE marker_id=$1::uuid AND state='PENDING' AND last_enqueue_at=$4 AND next_wakeup_at=$5`
	}
	tag, e := t.Exec(c, sql, d.ID.String(), at.UTC(), at.UTC().Add(time.Minute), d.Last, d.Next)
	return one(tag, e)
}

var _ app.ReconcileStore = Store{}
