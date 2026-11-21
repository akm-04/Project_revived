package dormhouse

import (
	"errors"
	"math"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

var ErrGlueDailyLimit = errors.New("dorm: daily glue purchase limit reached")

type GluePurchases struct {
	Player                       identity.PlayerID
	GameDay, Count, StateVersion int64
	UpdatedAt                    time.Time
}

func (purchases GluePurchases) Validate() error {
	if !purchases.Player.Valid() || purchases.Count < 1 || purchases.Count > MaxWireID || purchases.StateVersion < 1 || purchases.UpdatedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

func EffectiveGluePurchaseCount(previous *GluePurchases, player identity.PlayerID, gameDay int64, at time.Time) (int64, error) {
	if !player.Valid() || at.IsZero() {
		return 0, ErrInvalidFacts
	}
	if previous == nil {
		return 0, nil
	}
	if previous.Validate() != nil || previous.Player != player {
		return 0, ErrInvalidFacts
	}
	// A backward day step stays on the stored day: no second daily reset and no
	// refusal for the already-counted purchases.
	if previous.GameDay >= gameDay {
		return previous.Count, nil
	}
	return 0, nil
}

func (rules GlueRules) PlanPurchase(previous *GluePurchases, player identity.PlayerID, vipLevel, gameDay int64, at time.Time) (GluePurchases, int64, error) {
	count, err := EffectiveGluePurchaseCount(previous, player, gameDay, at)
	if err != nil {
		return GluePurchases{}, 0, err
	}
	limit, known := rules.VIPDailyCap(vipLevel)
	if !known || limit < 0 || limit > MaxWireID || rules.PurchaseAmount <= 0 || rules.PurchaseStartLimit <= 0 {
		return GluePurchases{}, 0, ErrUnqualified
	}
	if count >= limit {
		return GluePurchases{}, 0, ErrGlueDailyLimit
	}
	cost, known := rules.PurchaseCost(count + 1)
	if !known || cost <= 0 {
		return GluePurchases{}, 0, ErrUnqualified
	}
	version := int64(1)
	if previous != nil {
		if previous.StateVersion == math.MaxInt64 {
			return GluePurchases{}, 0, ErrInvalidFacts
		}
		version = previous.StateVersion + 1
	}
	stamp := at.UTC()
	if previous != nil && previous.UpdatedAt.After(stamp) {
		stamp = previous.UpdatedAt
	}
	day := gameDay
	if previous != nil && previous.GameDay > day {
		day = previous.GameDay
	}
	return GluePurchases{Player: player, GameDay: day, Count: count + 1, StateVersion: version, UpdatedAt: stamp}, cost, nil
}
