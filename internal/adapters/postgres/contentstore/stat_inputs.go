package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	statinputs "gxb.local/backend/v2/internal/domain/statinputs"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// StatInputCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) StatInputCatalogTx(ctx context.Context, q tx.Queryer, revision string) (statinputs.Catalog, error) {
	var out statinputs.Catalog
	if q == nil || len(revision) != 64 {
		return out, statinputs.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "STAT_INPUTS_I7C3B")
	if e != nil {
		return out, e
	}
	if !good {
		return out, statinputs.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_stat_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["stat_input_catalog.json"] {
		return out, statinputs.ErrUnqualified
	}
	var dto builtin.StatInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, statinputs.ErrUnqualified
	}
	return statinputsCatalogDomain(dto)
}
func statinputsCatalogDomain(d builtin.StatInputCatalog) (statinputs.Catalog, error) {
	if e := d.Validate(); e != nil {
		return statinputs.Catalog{}, e
	}
	return statinputs.NewCatalog(d.SchemaVersion, d.PolicyID, d.Tables)
}
func (Store) InsertStatInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_stat_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.StatInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyStatInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_stat_input_catalogs WHERE revision_id=$1`

func (s Store) StatInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, statinputs.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "STAT_INPUTS_I7C3B")
	return a.Activation.RevisionID, good, e
}

func (Store) StatInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "STAT_INPUTS_I7C3B")
}

func (s Store) StatInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "STAT_INPUTS_I7C3B")
	return a.Activation.RevisionID, good, e
}
