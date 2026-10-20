package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"

	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errModeCatalog = errors.New("contentstore: mode catalog unavailable")

// readModeCatalog strictly decodes a game-mode catalog of the caller-pinned
// immutable revision after checking its capability and manifest artifact hash.
func readModeCatalog(ctx context.Context, q tx.Queryer, revision, capability, table, artifact string, out any) error {
	var manifest, raw string
	if e := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); e != nil {
		return e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return e
	}
	good, e := manifestHasCapability([]byte(manifest), revision, capability)
	if e != nil {
		return e
	}
	if !good {
		return errModeCatalog
	}
	if e = q.QueryRow(ctx, `SELECT payload::text FROM `+table+` WHERE revision_id=$1`, revision).Scan(&raw); e != nil {
		return e
	}
	var generic any
	if e = json.Unmarshal([]byte(raw), &generic); e != nil {
		return e
	}
	canonical, e := json.Marshal(generic)
	if e != nil {
		return e
	}
	hash := sha256.Sum256(append(canonical, 10))
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s[artifact] {
		return errModeCatalog
	}
	dec := json.NewDecoder(bytes.NewBufferString(raw))
	dec.DisallowUnknownFields()
	if e = dec.Decode(out); e != nil {
		return e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return errModeCatalog
	}
	return nil
}
