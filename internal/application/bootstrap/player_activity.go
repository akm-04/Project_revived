package bootstrap

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrPlayerActivity = errors.New("bootstrap: invalid canonical player activity")

type PlayerActivityObservation struct {
	PlayerID         identity.PlayerID
	LogicalServerID  identity.LogicalServerID
	LastLoginAt      time.Time
	LatestActivityAt time.Time
	ObservedAt       time.Time
	StateVersion     int64
}

func (observation PlayerActivityObservation) Validate() error {
	if !observation.PlayerID.Valid() || !observation.LogicalServerID.Valid() || logicalserver.PlayerRegion(observation.PlayerID) != observation.LogicalServerID || observation.LastLoginAt.IsZero() || observation.LatestActivityAt.Before(observation.LastLoginAt) || observation.ObservedAt.IsZero() || observation.LatestActivityAt.After(observation.ObservedAt) || observation.StateVersion < 1 {
		return ErrPlayerActivity
	}
	return nil
}

type PlayerActivityReader interface {
	ReadPlayerActivityTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (PlayerActivityObservation, bool, error)
}
