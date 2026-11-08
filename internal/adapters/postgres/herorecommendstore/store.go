// Package herorecommendstore owns the derived Hero Recommendation snapshot.
package herorecommendstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) LatestSnapshotTx(c context.Context, q tx.Queryer, server identity.LogicalServerID) (d.Snapshot, bool, error) {
	var out d.Snapshot
	if q == nil || !server.Valid() {
		return out, false, d.ErrUnavailable
	}
	var raw string
	var observed time.Time
	e := q.QueryRow(c, `SELECT payload::text,observed_at FROM hero_recommend_snapshots WHERE logical_server_id=$1 ORDER BY generation DESC LIMIT 1`, int64(server)).Scan(&raw, &observed)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return out, false, nil
	}
	if e != nil {
		return out, false, e
	}
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return out, true, e
	}
	if out.Validate() != nil || out.Server != int64(server) || !out.ObservedAt.Equal(observed) {
		return out, true, d.ErrUnavailable
	}
	return out, true, nil
}

func (Store) InsertSnapshotTx(c context.Context, t tx.Tx, s d.Snapshot) error {
	if t == nil || s.Validate() != nil {
		return d.ErrUnavailable
	}
	raw, e := s.Encode()
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO hero_recommend_snapshots(logical_server_id,generation,content_revision,observed_at,digest,payload)VALUES($1,$2,$3,$4,$5,$6::jsonb) ON CONFLICT(logical_server_id,generation) DO NOTHING`,
		s.Server, s.Generation, s.Revision, s.ObservedAt, s.Digest, string(raw))
	return e
}
