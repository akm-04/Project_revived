package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	inscription "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// InscriptionCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) InscriptionCatalogTx(ctx context.Context, q tx.Queryer, revision string) (inscription.Catalog, error) {
	var out inscription.Catalog
	if q == nil || len(revision) != 64 {
		return out, inscription.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "INSCRIPTION_INPUTS_I7C2F")
	if e != nil {
		return out, e
	}
	if !good {
		return out, inscription.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_inscription_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["inscription_input_catalog.json"] {
		return out, inscription.ErrUnqualified
	}
	var dto builtin.InscriptionInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, inscription.ErrUnqualified
	}
	return inscriptionCatalogDomain(dto)
}
func inscriptionCatalogDomain(d builtin.InscriptionInputCatalog) (inscription.Catalog, error) {
	var out inscription.Catalog
	if e := d.Validate(); e != nil {
		return out, e
	}
	raw, e := json.Marshal(d)
	if e != nil {
		return out, e
	}
	if e = json.Unmarshal(raw, &out); e != nil {
		return out, e
	}
	return out, out.Validate()
}
func (Store) InsertInscriptionInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_inscription_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.InscriptionInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyInscriptionInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_inscription_input_catalogs WHERE revision_id=$1`

func (s Store) InscriptionInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, inscription.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "INSCRIPTION_INPUTS_I7C2F")
	return a.Activation.RevisionID, good, e
}

func (Store) InscriptionInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "INSCRIPTION_INPUTS_I7C2F")
}

func (s Store) InscriptionInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "INSCRIPTION_INPUTS_I7C2F")
	return a.Activation.RevisionID, good, e
}
