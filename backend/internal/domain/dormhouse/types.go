// Package dormhouse owns raw Dorm facts. Character owns Hero progression and
// I5 owns stock: neither EXP nor furniture quantities are duplicated here.
package dormhouse

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"time"
)

const (
	RootLockRank    uint16 = 500
	LoungeType      int64  = 1
	LoungeTemplate  int64  = 1000001
	MaxWireID       int64  = 1<<53 - 1
	LoungePolicy           = "C2C_LOUNGE_EXP_V1"
	RandomKeyPolicy        = "C2C_RANDOM_KEY_V1"
)

var (
	ErrUnqualified   = errors.New("dorm: unqualified owner or content")
	ErrInvalidFacts  = errors.New("dorm: invalid facts")
	ErrInvalidLayout = errors.New("dorm: wrong_key")
	ErrStaleTime     = errors.New("dorm: stale captured time")
	ErrInUse         = errors.New("dorm: Hero or furniture in use")
	ErrCooldown      = errors.New("dorm: resident change cooldown")
)

// Attributes are percent * 100, exactly representable as basis points. The
// future stat compositor divides by10000, matching the source percent/100.
type AttributesBP [3]int64

type GrowthTier struct {
	Comfort    int64
	Attributes AttributesBP
}
type RoomRule struct {
	TableID, MainType, AttributeType, Length, Width, Height, Dresser int64
	Growth                                                           []GrowthTier
}
type TypeRule struct{ MainType, Residents, MaxExpansion int64 }
type KeyRule struct {
	ItemID, MainType int64
	Templates        []int64
}
type ExpansionRule struct {
	Level, Area, Comfort, DurationSeconds int64
	CostItems, CostCounts                 []int64
	Attributes                            [3]AttributesBP
}
type EquipmentRule struct {
	TemplateID int64
	Items      [5]int64
}
type Catalog struct {
	ExchangeRates  map[int64]int64
	Furniture      map[int64]FurnitureRule
	EquipmentLevel map[int64]int64
	Rooms          map[int64]RoomRule
	Types          map[int64]TypeRule
	Keys           map[int64]KeyRule
	Expansions     map[int64]ExpansionRule
	Equipment      map[int64]EquipmentRule
}

type Root struct {
	Player                    identity.PlayerID
	NextHouseID, StateVersion int64
	CreatedAt, UpdatedAt      time.Time
}

func (r Root) Validate() error {
	if !r.Player.Valid() || r.NextHouseID < 2 || r.NextHouseID > MaxWireID || r.StateVersion < 1 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return ErrInvalidFacts
	}
	return nil
}

// Pending expansion is not an applied growth or area level. Its immutable
// revision/duration/occurrence survives later content activation and retries.
type Expansion struct {
	Occurrence, ContentRevision string
	NextLevel, DurationSeconds  int64
	StartedAt                   time.Time
}
type Room struct {
	MainType                                                            int64
	CreationRevision                                                    string
	LastEnterAt                                                         time.Time
	Player                                                              identity.PlayerID
	ID, TableID, Floor, Position, Comfort, ExpansionLevel, StateVersion int64
	Layout                                                              map[string]string
	Residents                                                           []int64
	Pending                                                             *Expansion
	CreatedAt, UpdatedAt                                                time.Time
}
type HeroFacts struct {
	Player                           identity.PlayerID
	PartnerID, HouseID, StateVersion int64
	Equipment                        [5]int64
	LoungeAnchor                     time.Time
	// Fraction is an EXP numerator over an hour in nanoseconds. This is the
	// approved numerator/3600 rule with subsecond precision preserved exactly.
	LoungeFraction int64
	UpdatedAt      time.Time
}

type FurnitureRule struct {
	ItemID, Comfort, Floor, PaperItem, SpecialType, Length, Width, Height int64
	CanRotate, CanPile, CanBePile, PileLimit                              bool
	Panels                                                                []int64
	PileStart, PileEnd                                                    []int64
}
