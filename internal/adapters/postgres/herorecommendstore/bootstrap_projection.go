package herorecommendstore

import (
	"context"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	app "gxb.local/backend/v2/internal/application/herorecommend"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BootstrapProjection contributes MID1 detail "2501", the flat origin-id score
// map the HeroRecommend model stores itself. It reads the latest accepted
// snapshot and never builds one during login.
type BootstrapProjection struct{ Service app.Service }

func (BootstrapProjection) Name() string     { return "i9-11.hero-recommend-scores" }
func (BootstrapProjection) Claims() []string { return []string{"2501"} }

func (b BootstrapProjection) OverlayMID1(c context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	if q == nil || detail == nil || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || at.IsZero() {
		return d.ErrUnavailable
	}
	scores, e := b.Service.ScoresTx(c, q, a.LogicalServerID, at)
	if e != nil {
		return e
	}
	detail["2501"] = scores
	return nil
}

var _ appboot.MID1DetailContributor = BootstrapProjection{}
