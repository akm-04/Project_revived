package contentstore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"sync"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const compatMessagePushCapability = "COMPAT_MESSAGE_PUSH_I9_11D"

var compatMessagePushCatalogs sync.Map

func (s Store) MessagePushCatalogTx(ctx context.Context, q tx.Queryer, revision string) (d.Catalog, error) {
	return memoCatalog(&compatMessagePushCatalogs, revision, func() (d.Catalog, error) {
		return s.messagePushCatalogTx(ctx, q, revision)
	})
}

func (s Store) messagePushCatalogTx(ctx context.Context, q tx.Queryer, revision string) (d.Catalog, error) {
	if q == nil || len(revision) != 64 {
		return d.Catalog{}, d.ErrUnavailable
	}
	var manifest, raw string
	var version int16
	if err := q.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifest); err != nil {
		return d.Catalog{}, err
	}
	m, err := registry.DecodeManifestStrict([]byte(manifest))
	if err != nil {
		return d.Catalog{}, err
	}
	good, err := manifestHasCapability([]byte(manifest), revision, compatMessagePushCapability)
	if err != nil || !good {
		return d.Catalog{}, d.ErrUnavailable
	}
	if err := q.QueryRow(ctx, `SELECT payload::text, payload_version FROM content_compat_catalogs WHERE revision_id=$1`, revision).Scan(&raw, &version); err != nil {
		return d.Catalog{}, err
	}
	var generic any
	if err := json.Unmarshal([]byte(raw), &generic); err != nil {
		return d.Catalog{}, err
	}
	canonical, err := json.Marshal(generic)
	if err != nil {
		return d.Catalog{}, err
	}
	hash := sha256.Sum256(append(canonical, '\n'))
	if hex.EncodeToString(hash[:]) != m.ArtifactSHA256s["compat_message_push_catalog.json"] {
		return d.Catalog{}, d.ErrUnavailable
	}
	var dto builtin.CompatMessagePushCatalog
	if err := payload.Decode("content_compat_catalogs", version, []byte(raw), &dto); err != nil {
		return d.Catalog{}, err
	}
	if err := dto.Validate(); err != nil {
		return d.Catalog{}, d.ErrUnavailable
	}
	catalog := d.Catalog{Revision: revision, MessagePushIDs: make(map[int64]struct{}, len(dto.IDs))}
	for _, id := range dto.IDs {
		catalog.MessagePushIDs[id] = struct{}{}
	}
	return catalog, nil
}

func (Store) InsertCompatMessagePush(ctx context.Context, t tx.Tx, b registry.Bundle) (int64, error) {
	if t == nil {
		return 0, errors.New("content store: nil transaction")
	}
	tag, err := t.Exec(ctx, `INSERT INTO content_compat_catalogs(revision_id,payload,payload_version)VALUES($1,$2::jsonb,$3)`, b.RevisionID(), string(b.CompatMessagePushJSON()), payload.Current)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}
