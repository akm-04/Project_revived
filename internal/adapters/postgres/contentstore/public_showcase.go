package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

func (Store) InsertPublicShowcase(c context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(c, `INSERT INTO content_public_showcase_policies(revision_id,payload) VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.PublicShowcaseJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}
func (Store) ReadPublicShowcasePolicy(c context.Context, q tx.Queryer, rev string) (app.ShowcaseContentPolicy, error) {
	out := app.ShowcaseContentPolicy{Revision: rev}
	if q == nil {
		return out, app.ErrContent
	}
	var manifest, raw string
	if e := q.QueryRow(c, contentqueries.ReadContentRevisionManifest, rev).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil || m.RevisionID != rev {
		return out, app.ErrContent
	}
	// Retained content must match its canonical manifest identity, as required
	// by the existing immutable Content contract.
	if m.RevisionDigestScope != "canonical_manifest_without_revision_id" {
		return out, app.ErrContent
	}
	var basis map[string]any
	if e = json.Unmarshal([]byte(manifest), &basis); e != nil {
		return out, e
	}
	delete(basis, "revision_id")
	canonical, e := json.Marshal(basis)
	if e != nil {
		return out, e
	}
	identity := sha256.Sum256(canonical)
	if hex.EncodeToString(identity[:]) != rev {
		return out, app.ErrContent
	}
	good, e := manifestHasCapability([]byte(manifest), rev, "PUBLIC_PROFILE_SHOWCASE_SELECTION_I7B3A")
	if e != nil || !good {
		return out, app.ErrContent
	}
	if e = q.QueryRow(c, `SELECT payload::text FROM content_public_showcase_policies WHERE revision_id=$1`, rev).Scan(&raw); e != nil {
		return out, e
	}
	var normalized any
	if e = json.Unmarshal([]byte(raw), &normalized); e != nil {
		return out, e
	}
	data, e := json.Marshal(normalized)
	if e != nil {
		return out, e
	}
	sum := sha256.Sum256(append(data, 10))
	if hex.EncodeToString(sum[:]) != m.ArtifactSHA256s["public_showcase_policy.json"] {
		return out, app.ErrContent
	}
	var p builtin.PublicShowcasePolicy
	d := json.NewDecoder(bytes.NewReader([]byte(raw)))
	d.DisallowUnknownFields()
	if e = d.Decode(&p); e != nil {
		return out, e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return out, app.ErrContent
	}
	out.Policy = p
	return out, out.Validate()
}
func (Store) HasPublicShowcaseCapabilityTx(c context.Context, q tx.Queryer, rev string) (bool, error) {
	if q == nil {
		return false, app.ErrContent
	}
	var raw string
	if e := q.QueryRow(c, contentqueries.ReadContentRevisionManifest, rev).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), rev, "PUBLIC_PROFILE_SHOWCASE_SELECTION_I7B3A")
}

const verifyPublicShowcaseSQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_public_showcase_policies WHERE revision_id=$1`
