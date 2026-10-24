package characterstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/characterqueries"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) SaveHeroBookmarkTx(c context.Context, t tx.Tx, h character.Hero, old int64) error {
	if t == nil || h.ValidatePersistent() != nil || old < 1 || h.StateVersion != old+1 {
		return errors.New("character store: invalid bookmark CAS")
	}
	tag, e := t.Exec(c, characterqueries.SaveHeroBookmark, int64(h.PlayerID), h.PartnerID, h.IsLike, h.UpdatedAt.UTC(), old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("character store: bookmark CAS lost race")
	}
	return nil
}
