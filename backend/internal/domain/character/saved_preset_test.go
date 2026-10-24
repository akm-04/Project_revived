package character

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func validPresetRoot() SavedPresetRoot {
	now := time.Unix(100, 0).UTC()
	return SavedPresetRoot{PlayerID: identity.PlayerID(7), StateVersion: 1, CreatedAt: now, UpdatedAt: now}
}

func TestSavedPresetAggregateAllowsEmptyAndDuplicateReferencesButRejectsCrossPlayer(t *testing.T) {
	if err := (SavedPresetAggregate{Root: validPresetRoot()}).Validate(); err != nil {
		t.Fatalf("empty aggregate: %v", err)
	}
	ref := HeroRef{PlayerID: 7, PartnerID: 9}
	agg := SavedPresetAggregate{Root: validPresetRoot(), Lanes: []SavedPresetLane{{Name: "A", Heroes: []HeroRef{ref, ref}}}}
	if err := agg.Validate(); err != nil {
		t.Fatalf("duplicate refs must remain representable: %v", err)
	}
	agg.Lanes[0].Heroes[1] = HeroRef{PlayerID: 8, PartnerID: 9}
	if err := agg.Validate(); err == nil {
		t.Fatal("cross-player Hero reference accepted")
	}
}

func TestSavedPresetLaneRejectsEmptyHeroListAndWireDelimiter(t *testing.T) {
	root := validPresetRoot()
	for _, lane := range []SavedPresetLane{
		{Name: "empty", Heroes: nil},
		{Name: "bad|||name", Heroes: []HeroRef{{PlayerID: 7, PartnerID: 1}}},
	} {
		if err := (SavedPresetAggregate{Root: root, Lanes: []SavedPresetLane{lane}}).Validate(); err == nil {
			t.Fatalf("invalid lane accepted: %+v", lane)
		}
	}
}
