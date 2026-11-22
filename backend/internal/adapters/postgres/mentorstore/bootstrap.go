package mentorstore

import (
	"context"
	"errors"
	"time"

	mentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BootstrapProjection feeds the login-embedded 1856 record from real mentor
// state. It performs no writes and never invents a relation.
type BootstrapProjection struct {
	Service mentor.Service
}

func (BootstrapProjection) Name() string     { return "i9.10f.mentor" }
func (BootstrapProjection) Claims() []string { return []string{"1856"} }

func (projection BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if detail == nil || observedAt.IsZero() || !actor.PlayerID.Valid() {
		return errors.New("mentor bootstrap: invalid projection input")
	}
	transaction, ok := q.(tx.Tx)
	if !ok {
		return errors.New("mentor bootstrap: transaction required")
	}
	body, err := projection.Service.ProjectClassInfo(ctx, transaction, actor.PlayerID, observedAt.UTC())
	if err != nil {
		return err
	}
	detail["1856"] = body
	return nil
}
