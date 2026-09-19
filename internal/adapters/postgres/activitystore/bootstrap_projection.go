package activitystore

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	activityproj "gxb.local/backend/v2/internal/projection/activity"
)

// BootstrapProjection contributes only the ActivityDirectory-owned MID229
// aggregate. It reuses the caller-owned MID1 queryer and never starts a nested
// transaction.
type BootstrapProjection struct{ Directory appactivity.Directory }

func (BootstrapProjection) Name() string     { return "i6b.activity-directory" }
func (BootstrapProjection) Claims() []string { return []string{"229"} }

func (b BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if detail == nil || observedAt.IsZero() {
		return errors.New("activity bootstrap: invalid projection input")
	}
	at := observedAt.UTC()
	if b.Directory.Registry.Len() > 0 {
		if q == nil {
			return errors.New("activity bootstrap: nil queryer")
		}
		var err error
		at, err = (postgres.AuthoritativeTime{Queryer: q}).Now(ctx)
		if err != nil {
			return err
		}
	}
	rows, err := b.Directory.ListAt(ctx, actor, at)
	if err != nil {
		return err
	}
	detail["229"] = activityproj.List(rows)
	return nil
}

var _ appboot.MID1DetailContributor = BootstrapProjection{}
