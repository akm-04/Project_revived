package characterasset

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// HeroLevelPopulation is the narrow CharacterHero read for invitation mission
// type 3. It exposes only the current owned-hero count and highest hero level.
type HeroLevelPopulation struct {
	PlayerID     identity.PlayerID
	Revision     string
	ObservedAt   time.Time
	RootVersion  int64
	OwnedCount   int64
	HighestLevel int64
}

type HeroLevelReader interface {
	ReadHeroLevelsTx(context.Context, CoherentReadScope, identity.PlayerID) (HeroLevelPopulation, error)
}
