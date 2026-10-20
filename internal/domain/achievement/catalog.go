package achievement

import "time"

// I7C-4 full stage A (C4F_ACHIEVEMENT_CATALOG_AND_AP_V1). The nine owned-state
// achievements are high-water tiers over a current owner count (step 0 profiles).
const OwnedStatePolicy = "C4F_OWNED_STATE_COUNT_V1"
const (
	NormalHeroesID   int64 = 100013
	AwakenedHeroesID int64 = 100015
	PetsID           int64 = 100017
	TextbooksID      int64 = 100019
	RegionsID        int64 = 100021
	SubjectsID       int64 = 100023
	SuitsID          int64 = 100025
	RoomsID          int64 = 100029
	ExpandedRoomsID  int64 = 100030
)

var OwnedStateIDs = []int64{NormalHeroesID, AwakenedHeroesID, PetsID, TextbooksID, RegionsID, SubjectsID, SuitsID, RoomsID, ExpandedRoomsID}

type Status string

const (
	Qualified    Status = "QUALIFIED"
	ModeNotLive  Status = "MODE_NOT_LIVE"
	OwnerUnknown Status = "OWNER_UNKNOWN"
	// StageC marks 100016 (skins), bound with metric 1003 after I7C-6.
	StageC Status = "STAGE_C_PENDING"
)

var unavailable = map[int64]Status{
	100004: ModeNotLive, 100005: ModeNotLive, 100006: ModeNotLive, 100007: ModeNotLive, 100008: ModeNotLive,
	100009: ModeNotLive, 100010: ModeNotLive, 100011: ModeNotLive, 100012: ModeNotLive, 100018: ModeNotLive,
	100020: ModeNotLive, 100022: ModeNotLive, 100024: ModeNotLive, 100026: ModeNotLive, 100027: ModeNotLive,
	100031: OwnerUnknown, 100033: OwnerUnknown, 100016: StageC,
}

// StatusOf is the explicit per-definition producer coverage; it is never
// inferred from visibility or from the absence of rows.
func StatusOf(id int64) Status {
	if status, listed := unavailable[id]; listed {
		return status
	}
	_, streak := streakProfiles[id]
	if id == SelectedID || streak {
		return Qualified
	}
	return OwnerUnknown
}

// Tiers maps an achievement id to its earned tier instants.
type Tiers map[int64][3]*time.Time

// Points is the C4F_POINT_LEVEL_AWARDS_V1 sum of earned tier points; reached is
// the instant the current total was reached (tiers are never revoked).
func (c Catalog) Points(earned Tiers) (total int64, reached time.Time) {
	for _, row := range c.Rows {
		for i, at := range earned[row.ID] {
			if at == nil {
				continue
			}
			total += row.Points[i]
			if at.After(reached) {
				reached = *at
			}
		}
	}
	return total, reached
}

// PointLevel is the highest level whose point condition the total meets.
func (c Catalog) PointLevel(total int64) int64 {
	level := int64(0)
	for _, l := range c.Levels {
		if l.PointCondition <= total {
			level = l.ID
		}
	}
	return level
}

// AwardStatus is the stock award_status per level: -1 claimed (and the
// itemless first level), 1 reached and unclaimed, 0 not reached.
func (c Catalog) AwardStatus(total int64, claimed map[int64]bool) []int64 {
	out := make([]int64, 0, len(c.Levels))
	for _, l := range c.Levels {
		switch {
		case len(l.Items) == 0 || claimed[l.ID]:
			out = append(out, -1)
		case l.PointCondition <= total:
			out = append(out, 1)
		default:
			out = append(out, 0)
		}
	}
	return out
}

// NextClaim is the lowest reached unclaimed level with items.
func (c Catalog) NextClaim(total int64, claimed map[int64]bool) (Level, bool) {
	for _, l := range c.Levels {
		if len(l.Items) > 0 && !claimed[l.ID] && l.PointCondition <= total {
			return l, true
		}
	}
	return Level{}, false
}
