package ranking

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (s Service) ReadGirls(c context.Context, a identity.ActorContext, o operation.Context) (d.GirlsSnapshot, error) {
	snapshot, e := s.RefreshGirls(c, a, o)
	if e != nil {
		return d.GirlsSnapshot{}, e
	}
	if _, e = s.SettlePendingGirls(c, a.LogicalServerID, o); e != nil {
		return d.GirlsSnapshot{}, e
	}
	return snapshot, nil
}
