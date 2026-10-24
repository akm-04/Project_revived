package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	heroevolution "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// EvolutionCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) EvolutionCatalogTx(ctx context.Context, q tx.Queryer, revision string) (heroevolution.Catalog, error) {
	var out heroevolution.Catalog
	if q == nil || len(revision) != 64 {
		return out, heroevolution.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "EVOLUTION_INPUTS_I7C2I")
	if e != nil {
		return out, e
	}
	if !good {
		return out, heroevolution.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_evolution_input_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["evolution_input_catalog.json"] {
		return out, heroevolution.ErrUnqualified
	}
	var dto builtin.EvolutionInputCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, heroevolution.ErrUnqualified
	}
	return heroevolutionCatalogDomain(dto)
}
func heroevolutionCatalogDomain(d builtin.EvolutionInputCatalog) (heroevolution.Catalog, error) {
	if e := d.Validate(); e != nil {
		return heroevolution.Catalog{}, e
	}
	return heroevolution.NewCatalog(d.SchemaVersion, d.PolicyID, d.Tables)
}
func (Store) InsertEvolutionInputs(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_evolution_input_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.EvolutionInputsJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyEvolutionInputsSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_evolution_input_catalogs WHERE revision_id=$1`

func (s Store) EvolutionInputsActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, heroevolution.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "EVOLUTION_INPUTS_I7C2I")
	return a.Activation.RevisionID, good, e
}

func (Store) EvolutionInputsRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "EVOLUTION_INPUTS_I7C2I")
}

func (s Store) EvolutionInputsActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "EVOLUTION_INPUTS_I7C2I")
	return a.Activation.RevisionID, good, e
}
