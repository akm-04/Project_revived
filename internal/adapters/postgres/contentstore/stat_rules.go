package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	statrules "gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// StatCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) StatCatalogTx(ctx context.Context, q tx.Queryer, revision string) (statrules.Catalog, error) {
	var out statrules.Catalog
	if q == nil || len(revision) != 64 {
		return out, statrules.ErrUnqualified
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "STAT_RULES_I7C3A")
	if e != nil {
		return out, e
	}
	if !good {
		return out, statrules.ErrUnqualified
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_stat_rule_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["stat_rule_catalog.json"] {
		return out, statrules.ErrUnqualified
	}
	var dto builtin.StatRuleCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, statrules.ErrUnqualified
	}
	return statrulesCatalogDomain(dto)
}
func statrulesCatalogDomain(d builtin.StatRuleCatalog) (statrules.Catalog, error) {
	if e := d.Validate(); e != nil {
		return statrules.Catalog{}, e
	}
	raw, err := json.Marshal(d)
	if err != nil {
		return statrules.Catalog{}, err
	}
	var out statrules.Catalog
	if err = json.Unmarshal(raw, &out); err != nil {
		return out, err
	}
	return out, out.Validate()
}
func (Store) InsertStatRules(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_stat_rule_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.StatRulesJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyStatRulesSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_stat_rule_catalogs WHERE revision_id=$1`

func (s Store) StatRulesActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, statrules.ErrUnqualified
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "STAT_RULES_I7C3A")
	return a.Activation.RevisionID, good, e
}

func (Store) StatRulesRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "STAT_RULES_I7C3A")
}

func (s Store) StatRulesActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "STAT_RULES_I7C3A")
	return a.Activation.RevisionID, good, e
}
