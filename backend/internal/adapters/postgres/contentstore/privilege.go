package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	privilege "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// PrivilegeCatalogTx reads only the caller-pinned immutable revision. Registration
// and controlled deployment/backfill must complete before activation.
func (s Store) PrivilegeCatalogTx(ctx context.Context, q tx.Queryer, revision string) (privilege.Catalog, error) {
	var out privilege.Catalog
	if q == nil || len(revision) != 64 {
		return out, privilege.ErrUnavailable
	}
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "COSMETIC_PRIVILEGE_I7C4A")
	if e != nil {
		return out, e
	}
	if !good {
		return out, privilege.ErrUnavailable
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM content_privilege_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
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
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["privilege_catalog.json"] {
		return out, privilege.ErrUnavailable
	}
	var dto builtin.PrivilegeCatalog
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&dto); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, privilege.ErrUnavailable
	}
	return privilegeCatalogDomain(dto)
}
func privilegeCatalogDomain(d builtin.PrivilegeCatalog) (privilege.Catalog, error) {
	if e := d.Validate(); e != nil {
		return privilege.Catalog{}, e
	}
	out := privilege.Catalog{SchemaVersion: d.SchemaVersion, PolicyID: d.PolicyID}
	for _, r := range d.Rows {
		out.Rows = append(out.Rows, privilege.Threshold{Level: r.Level, Charge: r.Charge, SkillCap: r.SkillCap})
	}
	return out, out.Validate()
}
func (Store) InsertPrivilege(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(ctx, `INSERT INTO content_privilege_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.PrivilegeJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyPrivilegeSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_privilege_catalogs WHERE revision_id=$1`

func (s Store) PrivilegeActive(ctx context.Context) (string, bool, error) {
	if s.Queryer == nil {
		return "", false, privilege.ErrUnavailable
	}
	a, ok, e := s.ReadActiveSummary(ctx, s.Queryer)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "COSMETIC_PRIVILEGE_I7C4A")
	return a.Activation.RevisionID, good, e
}

func (Store) PrivilegeRevisionTx(ctx context.Context, q tx.Queryer, revision string) (bool, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), revision, "COSMETIC_PRIVILEGE_I7C4A")
}

func (s Store) PrivilegeActiveTx(ctx context.Context, q tx.Queryer) (string, bool, error) {
	a, ok, e := s.ReadActiveSummary(ctx, q)
	if e != nil || !ok {
		return "", false, e
	}
	good, e := manifestHasCapability(a.ManifestJSON, a.Activation.RevisionID, "COSMETIC_PRIVILEGE_I7C4A")
	return a.Activation.RevisionID, good, e
}
