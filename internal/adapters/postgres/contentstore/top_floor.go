package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"sync"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const topFloorCapability = "TOP_FLOOR_MODE_I7C5B"

// Installed revisions are immutable, so a catalog verified once against its
// revision manifest stays valid for that revision.
var topFloorCatalogs sync.Map

// TopFloorCatalogTx reads only the caller-pinned immutable revision.
func (s Store) TopFloorCatalogTx(ctx context.Context, q tx.Queryer, revision string) (topfloor.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return topfloor.Catalog{}, topfloor.ErrUnavailable
	}
	if cached, ok := topFloorCatalogs.Load(revision); ok {
		return cached.(topfloor.Catalog), nil
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return topfloor.Catalog{}, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return topfloor.Catalog{}, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, topFloorCapability)
	if e != nil {
		return topfloor.Catalog{}, e
	}
	if !good {
		return topfloor.Catalog{}, topfloor.ErrUnavailable
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_top_floor_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return topfloor.Catalog{}, e
	}
	var generic any
	if e = json.Unmarshal([]byte(raw), &generic); e != nil {
		return topfloor.Catalog{}, e
	}
	canonical, e := json.Marshal(generic)
	if e != nil {
		return topfloor.Catalog{}, e
	}
	hash := sha256.Sum256(append(canonical, 10))
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["top_floor_catalog.json"] {
		return topfloor.Catalog{}, topfloor.ErrUnavailable
	}
	var out topfloor.Catalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&out); e != nil {
		return topfloor.Catalog{}, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return topfloor.Catalog{}, topfloor.ErrUnavailable
	}
	if e = out.Validate(); e != nil {
		return topfloor.Catalog{}, e
	}
	topFloorCatalogs.Store(revision, out)
	return out, nil
}

func (Store) InsertTopFloor(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_top_floor_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.TopFloorJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyTopFloorSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_top_floor_catalogs WHERE revision_id=$1`
