package occult

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ClearedChapterCountTx is 100027's owner fact: the catalog chapters with a
// recorded clear score (score above zero unlocks the chapter's sweep).
func (s Mode) ClearedChapterCountTx(c context.Context, q tx.Queryer, p identity.PlayerID, revision string) (int64, error) {
	if s.Store == nil || s.Content == nil {
		return 0, d.ErrUnavailable
	}
	catalog, e := s.Content.OccultCatalogTx(c, q, revision)
	if e != nil {
		return 0, e
	}
	scores, e := s.Store.ReadScoresTx(c, q, p)
	if e != nil {
		return 0, e
	}
	cleared := int64(0)
	for _, chapter := range catalog.Chapters {
		if scores.SweepUnlocked(chapter.ID) {
			cleared++
		}
	}
	return cleared, nil
}
