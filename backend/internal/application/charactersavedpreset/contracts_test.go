package charactersavedpreset

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

func testAggregate() character.SavedPresetAggregate {
	now := time.Unix(100, 0).UTC()
	pet := character.PetRef{PlayerID: 7, PetID: 4}
	return character.SavedPresetAggregate{
		Root: character.SavedPresetRoot{PlayerID: identity.PlayerID(7), StateVersion: 2, CreatedAt: now, UpdatedAt: now},
		Lanes: []character.SavedPresetLane{
			{Name: "Alpha", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 2}, {PlayerID: 7, PartnerID: 9}}, Pet: &pet},
			{Name: "", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 3}}},
		},
	}
}

func TestProjectWireUsesOneAlignedLaneOrdering(t *testing.T) {
	w, err := ProjectWire(testAggregate())
	if err != nil {
		t.Fatal(err)
	}
	if w.SaveTeam != "2|9:3" || w.SaveTeamName != "Alpha|||" || w.SavePet != "4|0" {
		t.Fatalf("projection=%+v", w)
	}
	empty := testAggregate()
	empty.Lanes = nil
	w, err = ProjectWire(empty)
	if err != nil {
		t.Fatal(err)
	}
	if w != (WireProjection{}) {
		t.Fatalf("empty projection=%+v", w)
	}
}

func TestReferenceSetDetectsLockedRereadExpansionBeforeSuccessorMutation(t *testing.T) {
	old := []character.SavedPresetLane{{Name: "old", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 1}}}}
	desired := []character.SavedPresetLane{{Name: "new", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 2}}}}
	planned := UnionReferences(CollectReferences(old), CollectReferences(desired))
	lockedSame := CollectReferences([]character.SavedPresetLane{{Name: "same", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 1}}}})
	if !planned.Covers(lockedSame) {
		t.Fatal("planned old∪desired unexpectedly failed to cover stable locked reread")
	}
	lockedExpanded := CollectReferences([]character.SavedPresetLane{{Name: "race", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 1}, {PlayerID: 7, PartnerID: 3}}}})
	if planned.Covers(lockedExpanded) {
		t.Fatal("locked reread introduced unplanned Hero ref but coverage remained true")
	}
}
