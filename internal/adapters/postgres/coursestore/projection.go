package coursestore

import (
	"context"
	"gxb.local/backend/v2/internal/application/course"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type ActiveReader interface {
	CourseInputsActiveTx(context.Context, tx.Queryer) (string, bool, error)
}
type BootstrapProjection struct {
	Service course.Service
	Content ActiveReader
}

func (BootstrapProjection) Name() string     { return "i7c2e.course-attendance" }
func (BootstrapProjection) Claims() []string { return []string{"2137", "2139"} }
func (b BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, a identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	rev, on, e := b.Content.CourseInputsActiveTx(ctx, q)
	if e != nil || !on {
		return e
	}
	v, e := b.Service.RoomWireTx(ctx, q, course.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: at})
	if e != nil {
		return e
	}
	detail["2137"] = v
	detail["2139"] = map[string]any{"is_has_gift": int64(0)}
	return nil
}
