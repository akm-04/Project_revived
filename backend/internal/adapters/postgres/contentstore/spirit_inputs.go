package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	spirit "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"sync"
)

// SpiritCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
var spiritCatalogs sync.Map

func (s Store) SpiritCatalogTx(ctx context.Context, q tx.Queryer, revision string) (spirit.Catalog, error) {
	return memoCatalog(&spiritCatalogs, revision, func() (spirit.Catalog, error) { return s.spiritCatalogTx(ctx, q, revision) })
}

func (s Store) spiritCatalogTx(ctx context.Context, q tx.Queryer, revision string) (spirit.Catalog, error) {
	var out spirit.Catalog
	if q == nil || len(revision) != 64 {
		return out, spirit.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "SPIRIT_INPUTS_I7C2H")
	if e != nil {
		return out, e
	}
	if !good {
		return out, spirit.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_spirit_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return out, e
	}
	var generic any
	if e = json.Unmarshal([]byte(raw), &generic); e != nil {
		return out, e
	}
	canonical, e := json.Marshal(generic)
	if e != nil {
		return out, e
	}
	hash := sha256.Sum256(append(canonical, 10))
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["spirit_input_catalog.json"] {
		return out, spirit.ErrUnqualified
	}
	var dto builtin.SpiritInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, spirit.ErrUnqualified
	}
	return spiritCatalogDomain(dto)
}
func spiritCatalogDomain(d builtin.SpiritInputCatalog) (spirit.Catalog, error) {
	if e := d.Validate(); e != nil {
		return spirit.Catalog{}, e
	}
	return spirit.NewCatalog(d.SchemaVersion, d.PolicyID, d.Tables)
}
func (Store) InsertSpiritInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_spirit_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.SpiritInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifySpiritInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_spirit_input_catalogs WHERE revision_id=$1`

func (s Store) SpiritInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, spirit.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "SPIRIT_INPUTS_I7C2H")
	return a.Activation.RevisionID, good, e
}

func (Store) SpiritInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "SPIRIT_INPUTS_I7C2H")
}

func (s Store) SpiritInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "SPIRIT_INPUTS_I7C2H")
	return a.Activation.RevisionID, good, e
}
