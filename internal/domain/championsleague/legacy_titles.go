package championsleague

import "time"

const LegacyTitlePolicy = "I9_LEAGUE_LEGACY_TITLE_POLICY_V1"

func IsLegacyTitle(identifier int64) bool { return identifier >= 100078 && identifier <= 100080 }
func (catalog Catalog) HasLegacyTitle(identifier int64) bool {
	for _, title := range catalog.LegacyTitles {
		if title.Identifier == identifier {
			return true
		}
	}
	return false
}

type LegacyTitle struct {
	Identifier int64  `json:"id"`
	Name       string `json:"name"`
}

func LegacyTitlePlacementEligible(placement Placement, cutoff, since time.Time) bool {
	return !since.IsZero() && !cutoff.Before(since) && placement.Participated && placement.Group == 3 && placement.Rank >= 1 && placement.Rank <= 10
}
