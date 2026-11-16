package campaign

import (
	"context"

	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// NormalStarsTx is 100010's owner fact: the client's own normal-campaign star
// total (MapWindow.lua:689-690 reads normal_stars), the sum of each Normal
// node's best star, which excludes the non-battle MapType 1 nodes.
func (s Mode) NormalStarsTx(c context.Context, q tx.Queryer, p identity.PlayerID, revision string) (int64, error) {
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
	return catalog.TotalStars(record.Progress, d.Normal), nil
}
