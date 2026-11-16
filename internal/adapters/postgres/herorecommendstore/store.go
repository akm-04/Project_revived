// Package herorecommendstore owns the derived Hero Recommendation snapshot.
package herorecommendstore

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) LatestSnapshotTx(c context.Context, q tx.Queryer, server identity.LogicalServerID) (d.Snapshot, bool, error) {
	var out d.Snapshot
	if q == nil || !server.Valid() {
		return out, false, d.ErrUnavailable
	}
	var raw string
	var version int16
	var observed time.Time
	e := q.QueryRow(c, `SELECT payload::text,observed_at,payload_version FROM hero_recommend_snapshots WHERE logical_server_id=$1 ORDER BY generation DESC LIMIT 1`, int64(server)).Scan(&raw, &observed, &version)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return out, false, nil
	}
	if e != nil {
		return out, false, e
	}
	if e = payload.Decode("hero_recommend_snapshots", version, []byte(raw), &out); e != nil {
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
	raw, version, e := payload.Encode(s)
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO hero_recommend_snapshots(logical_server_id,generation,content_revision,observed_at,digest,payload,payload_version)VALUES($1,$2,$3,$4,$5,$6::jsonb,$7) ON CONFLICT(logical_server_id,generation) DO UPDATE SET content_revision=EXCLUDED.content_revision,observed_at=EXCLUDED.observed_at,digest=EXCLUDED.digest,payload=EXCLUDED.payload,payload_version=EXCLUDED.payload_version`,
		s.Server, s.Generation, s.Revision, s.ObservedAt, s.Digest, string(raw), version)
	return e
}
