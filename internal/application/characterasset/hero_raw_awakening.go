package characterasset

import (
	"gxb.local/backend/v2/internal/domain/character"
	"time"
)

// HeroRawAwakeningObservation is a detached Character-owned observation,
// shared without importing numerical consumers into gameplay owners.
type HeroRawAwakeningObservation struct {
	Ref               character.HeroRef
	StateVersion      int64
	ContentRevision   string
	ObservedAt        time.Time
	Known             bool
	RawStage          int64
	ProducerReference string
}
