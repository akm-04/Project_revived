package campaign

import (
	"context"

	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MainChainStarsTx is 100010's owner fact (RULING_I9-11E_100010_STARS): the
// sum of each playable Normal, Super and Challenge node's best star, matching
// "Clear all campaigns and earn %d stars". Non-battle MapType 1 nodes do not
// count; the content ceiling is 155+155+144 nodes x 3.
func (s Mode) MainChainStarsTx(c context.Context, q tx.Queryer, p identity.PlayerID, revision string) (int64, error) {
	if s.Store == nil || s.Content == nil {
		return 0, d.ErrUnavailable
	}
	catalog, e := s.Content.CampaignCatalogTx(c, q, revision)
	if e != nil {
		return 0, e
	}
	record, e := s.Store.ReadTx(c, q, p)
	if e != nil {
		return 0, e
	}
	var stars int64
	for _, kind := range []int64{d.Normal, d.Super, d.Challenge} {
		stars += catalog.TotalStars(record.Progress, kind)
	}
	return stars, nil
}
