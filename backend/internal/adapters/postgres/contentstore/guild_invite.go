package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

// An older active catalog returns inactive without inventing a policy row or
// changing the pointer. Historical qualified revisions remain readable for
// immutable source and target evidence after pointer rollback.
func (Store) ReadInvitePolicy(c context.Context, q tx.Queryer, rev string) (app.ContentPolicy, bool, error) {
	out := app.ContentPolicy{Revision: rev}
	if q == nil {
		return out, false, gi.ErrEvidence
	}
	var manifest, raw string
	if e := q.QueryRow(c, contentqueries.ReadContentRevisionManifest, rev).Scan(&manifest); e != nil {
		return out, false, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil || m.RevisionID != rev {
		return out, false, gi.ErrEvidence
	}
	// Qualified historical content is identified by its complete canonical
	// manifest digest, not a self-declared revision field beside a valid payload.
	if m.RevisionDigestScope != "canonical_manifest_without_revision_id" {
		return out, false, gi.ErrEvidence
	}
	var basis map[string]any
	if e = json.Unmarshal([]byte(manifest), &basis); e != nil {
		return out, false, e
	}
	delete(basis, "revision_id")
	canonical, e := json.Marshal(basis)
	if e != nil {
		return out, false, e
	}
	identity := sha256.Sum256(canonical)
	if hex.EncodeToString(identity[:]) != rev {
		return out, false, gi.ErrEvidence
	}
	has, e := manifestHasCapability([]byte(manifest), rev, "GUILD_INVITE_PRESENTATION_I7A8B")
	if e != nil {
		return out, false, e
	}
	if !has {
		return out, false, nil
	}
	if e = q.QueryRow(c, `SELECT payload::text FROM content_guild_invite_policies WHERE revision_id=$1`, rev).Scan(&raw); e != nil {
		return out, false, e
	}
	var normalized any
	if e = json.Unmarshal([]byte(raw), &normalized); e != nil {
		return out, false, e
	}
	data, e := json.Marshal(normalized)
	if e != nil {
		return out, false, e
	}
	sum := sha256.Sum256(append(data, 10))
	if hex.EncodeToString(sum[:]) != m.ArtifactSHA256s["guild_invite_policy.json"] {
		return out, false, gi.ErrEvidence
	}
	var p builtin.GuildInvitePolicy
	d := json.NewDecoder(bytes.NewReader([]byte(raw)))
	d.DisallowUnknownFields()
	if d.Decode(&p) != nil || d.Decode(new(any)) != io.EOF || p.Validate() != nil {
		return out, false, gi.ErrEvidence
	}
	out.GuildCoreRevision = p.GuildCoreRevision
	out.PolicyID = p.PolicyID
	return out, true, out.Validate()
}

var _ app.ContentReader = Store{}
