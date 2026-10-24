package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
)

func (Store) InsertPlayerDisplay(c context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	tag, e := t.Exec(c, `INSERT INTO content_player_display_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, b.RevisionID(), string(b.PlayerDisplayJSON()))
	if e != nil {
		return 0, e
	}
	return tag.RowsAffected(), nil
}

const verifyPlayerDisplaySQL = `SELECT count(*)=1 AND COALESCE(bool_and(payload=$2::jsonb),false),count(*) FROM content_player_display_catalogs WHERE revision_id=$1`

func (s Store) ReadPlayerDisplayCatalogTx(c context.Context, q tx.Queryer, rev string) (player.DisplayCatalog, error) {
	var out player.DisplayCatalog
	// This existing exact reader verifies the canonical manifest identity; it does
	// not discover active content or time, or start a transaction.
	if _, e := s.ReadPublicProfilePolicy(c, q, rev); e != nil {
		return out, e
	}
	var manifest, raw string
	if e := q.QueryRow(c, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, rev).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(manifest), rev, "PLAYER_DISPLAY_I7B6A")
	if e != nil || !good {
		return out, player.ErrDisplayUnavailable
	}
	if e = q.QueryRow(c, `SELECT payload::text FROM content_player_display_catalogs WHERE revision_id=$1`, rev).Scan(&raw); e != nil {
		return out, e
	}
	var normalized any
	if e = json.Unmarshal([]byte(raw), &normalized); e != nil {
		return out, e
	}
	canonical, e := json.Marshal(normalized)
	if e != nil {
		return out, e
	}
	sum := sha256.Sum256(append(canonical, 10))
	if hex.EncodeToString(sum[:]) != m.ArtifactSHA256s["player_display_catalog.json"] {
		return out, player.ErrDisplayUnavailable
	}
	d := json.NewDecoder(bytes.NewReader([]byte(raw)))
	d.DisallowUnknownFields()
	if e = d.Decode(&out); e != nil {
		return out, e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return out, player.ErrDisplayUnavailable
	}
	return out, out.Validate()
}
