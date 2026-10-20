package ranking

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (s Service) ReadBoard(c context.Context, b d.Board, a identity.ActorContext, o operation.Context) (d.BoardSnapshot, error) {
	snapshot, e := s.RefreshBoard(c, b, a, o)
	if e != nil {
		return d.BoardSnapshot{}, e
	}
	if _, e = s.SettlePendingBoard(c, b, a.LogicalServerID, o); e != nil {
		return d.BoardSnapshot{}, e
	}
	return snapshot, nil
}
