package characterasset

import (
	"context"
	"gxb.local/backend/v2/internal/domain/character"
	"time"
)

// Raw facts and source-qualified IDs only. This does not qualify unlocks,
// derived levels, twice-awake effects, or final statistics.
type HeroRawSkillObservation struct {
	Ref             character.HeroRef
	Facts           character.HeroRawSkillFacts
	ResolvedIDs     [6]int64
	StateVersion    int64
	ContentRevision string
	ObservedAt      time.Time
}
type HeroRawSkillObservationProvider interface {
	HeroRawSkillsTx(context.Context, CoherentReadScope, character.HeroRef) (HeroRawSkillObservation, error)
}
