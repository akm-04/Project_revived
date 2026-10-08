package contentstore

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ResolveEmoticonTx(c context.Context, t tx.Tx, revision string, id int64) (dm.EmoticonDefinition, error) {
	out := dm.EmoticonDefinition{ID: id, Revision: revision}
	if t == nil || len(revision) != 64 || id < 1 {
		return out, dm.ErrUnavailable
	}
	var raw string
	if e := t.QueryRow(c, contentqueries.ReadContentRevisionManifest, revision).Scan(&raw); e != nil {
		return out, e
	}
	good, e := manifestHasCapability([]byte(raw), revision, "FRIEND_DM_EMOTICON_I7A6A")
	if e != nil {
		return out, e
	}
	if !good {
		return out, dm.ErrUnavailable
	}
	e = t.QueryRow(c, contentqueries.ReadContentEmoticon, revision, id).Scan(&out.ItemID)
	if e != nil {
		return out, e
	}
	if out.ItemID < 0 {
		return out, dm.ErrUnavailable
	}
	return out, nil
}

var _ dm.EmoticonContentReader = Store{}
