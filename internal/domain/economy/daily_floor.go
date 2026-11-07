package economy

import (
	"errors"
	"math"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

var ErrInvalidDailyFloor = errors.New("invalid scalar daily floor")

type ScalarDailyFloor struct {
	PlayerID     identity.PlayerID
	ResourceKey  string
	GameDay      int64
	StateVersion int64
	UpdatedAt    time.Time
}

func (anchor ScalarDailyFloor) Validate() error {
	if !anchor.PlayerID.Valid() || anchor.ResourceKey == "" || anchor.StateVersion <= 0 || anchor.UpdatedAt.IsZero() {
		return ErrInvalidDailyFloor
	}
	return nil
}

type DailyFloorPlan struct {
	Balance ScalarBalance
	Anchor  ScalarDailyFloor
	Credit  int64
	Changed bool
}

func (balance ScalarBalance) PlanDailyFloor(previous *ScalarDailyFloor, gameDay, minimum int64, at time.Time) (DailyFloorPlan, error) {
	if err := balance.Validate(); err != nil {
		return DailyFloorPlan{}, err
	}
	if minimum < 0 || at.IsZero() || at.Before(balance.UpdatedAt) {
		return DailyFloorPlan{}, ErrInvalidDailyFloor
	}
	anchor := ScalarDailyFloor{PlayerID: balance.PlayerID, ResourceKey: balance.ResourceKey, GameDay: gameDay, StateVersion: 1, UpdatedAt: at.UTC()}
	if previous != nil {
		if err := previous.Validate(); err != nil {
			return DailyFloorPlan{}, err
		}
		if previous.PlayerID != balance.PlayerID || previous.ResourceKey != balance.ResourceKey || previous.GameDay > gameDay || at.Before(previous.UpdatedAt) {
			return DailyFloorPlan{}, ErrInvalidDailyFloor
		}
		if previous.GameDay == gameDay {
			return DailyFloorPlan{Balance: balance, Anchor: *previous}, nil
		}
		if previous.StateVersion == math.MaxInt64 {
			return DailyFloorPlan{}, ErrInvalidDailyFloor
		}
		anchor.StateVersion = previous.StateVersion + 1
	}
	result := DailyFloorPlan{Balance: balance, Anchor: anchor, Changed: true}
	if balance.Amount >= minimum {
		return result, nil
	}
	if balance.StateVersion == math.MaxInt64 {
		return DailyFloorPlan{}, ErrInvalidDailyFloor
	}
	result.Credit = minimum - balance.Amount
	credited, err := balance.Credit(result.Credit, at)
	if err != nil {
		return DailyFloorPlan{}, err
	}
	result.Balance = credited
	return result, nil
}
