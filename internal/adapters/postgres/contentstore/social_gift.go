package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReadGiftContent pins an immutable complete vector. JSONB whitespace/order is
// normalized back to the compiler's sorted JSON plus newline before hashing.
func (Store) ReadGiftContent(c context.Context, q tx.Queryer, revision string) (sg.Content, error) {
	out := sg.Content{Revision: revision}
	if q == nil || len(revision) != 64 {
		return out, sg.ErrContent
	}
	var manifest, raw string
	if e := q.QueryRow(c, contentqueries.ReadContentRevisionManifest, revision).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil || m.RevisionID != revision {
		return out, sg.ErrContent
	}
	good, e := manifestHasCapability([]byte(manifest), revision, "SOCIAL_GIFT_I7A7A")
	if e != nil || !good {
		return out, sg.ErrContent
	}
	if e = q.QueryRow(c, `SELECT payload::text FROM content_social_gift_catalogs WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return out, e
	}
	var normalized any
	if e = json.Unmarshal([]byte(raw), &normalized); e != nil {
		return out, e
	}
	b, e := json.Marshal(normalized)
	if e != nil {
		return out, e
	}
	h := sha256.Sum256(append(b, byte(10)))
	if hex.EncodeToString(h[:]) != m.ArtifactSHA256s["social_gift_catalog.json"] {
		return out, sg.ErrContent
	}
	decoder := json.NewDecoder(bytes.NewReader([]byte(raw)))
	decoder.DisallowUnknownFields()
	if e = decoder.Decode(&out.Catalog); e != nil {
		return out, e
	}
	return out, out.Validate()
}

var _ sg.ContentReader = Store{}
