package events

import (
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/events"
)

// awardFlags positions come from the definition's tier ids, so a sparse gap
// stays a placeholder and an id above 100 is not dropped.
func TestAwardFlagsUsesDefinitionTierIDs(t *testing.T) {
	sparse := events.Definition{Tiers: []events.Tier{{ID: 2}, {ID: 5}}}
	if got := awardFlags(sparse, []Claim{{Tier: 5}}); got != "0|0|0|0|1" {
		t.Fatalf("sparse flags = %q", got)
	}
	if got := awardFlags(sparse, []Claim{{Tier: 3}}); got != "0|0|0|0|0" {
		t.Fatalf("a claim outside the definition must not set a slot: %q", got)
	}
	high := events.Definition{Tiers: []events.Tier{{ID: 101}}}
	got := strings.Split(awardFlags(high, []Claim{{Tier: 101}}), "|")
	if len(got) != 101 || got[100] != "1" {
		t.Fatalf("tier 101 flags = %d entries, last %q", len(got), got[len(got)-1])
	}
}
