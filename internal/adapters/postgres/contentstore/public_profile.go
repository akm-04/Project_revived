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

func (Store) InsertPublicProfile(c context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(c, `INSERT INTO content_public_profile_policies(revision_id,payload) VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.PublicProfileJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}
func (Store) ReadPublicProfilePolicy(c context.Context, q tx.Queryer, rev string) (app.ContentPolicy, error) {
	out := app.ContentPolicy{Revision: rev}
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
	good, e := manifestHasCapability([]byte(manifest), rev, "PUBLIC_PROFILE_PREFERENCES_I7B2B")
	if e != nil || !good {
		return out, app.ErrContent
	}
	if e = q.QueryRow(c, `SELECT payload::text FROM content_public_profile_policies WHERE revision_id=$1`, rev).Scan(&raw); e != nil {
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
	if hex.EncodeToString(sum[:]) != m.ArtifactSHA256s["public_profile_policy.json"] {
		return out, app.ErrContent
	}
	var p builtin.PublicProfilePolicy
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
func (Store) HasPublicProfileCapabilityTx(c context.Context, q tx.Queryer, rev string) (bool, error) {
	if q == nil {
		return false, app.ErrContent
	}
	var raw string
	if e := q.QueryRow(c, contentqueries.ReadContentRevisionManifest, rev).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), rev, "PUBLIC_PROFILE_PREFERENCES_I7B2B")
}
