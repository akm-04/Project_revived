package charactersavedpreset

import (
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

func presetAggregate(pid identity.PlayerID, lanes ...character.SavedPresetLane) character.SavedPresetAggregate {
	now := time.Unix(100, 0).UTC()
	return character.SavedPresetAggregate{
		Root:  character.SavedPresetRoot{PlayerID: pid, StateVersion: 7, CreatedAt: now, UpdatedAt: now},
		Lanes: lanes,
	}
}

func presetLane(pid identity.PlayerID, name string, heroes []int64, pet int64) character.SavedPresetLane {
	lane := character.SavedPresetLane{Name: name, Heroes: make([]character.HeroRef, len(heroes))}
	for i, id := range heroes {
		lane.Heroes[i] = character.HeroRef{PlayerID: pid, PartnerID: id}
	}
	if pet > 0 {
		ref := character.PetRef{PlayerID: pid, PetID: pet}
		lane.Pet = &ref
	}
	return lane
}

func TestParseFullCommandExactRoundTripAndEmpty(t *testing.T) {
	lanes, err := ParseFullCommand(7, Command{
		TeamString: "2|9:3", TeamNameString: "A|||", PetPresent: true, PetString: "4|0",
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(lanes) != 2 || lanes[0].Name != "A" || lanes[1].Name != "" || lanes[0].Heroes[1].PartnerID != 9 || lanes[0].Pet == nil || lanes[0].Pet.PetID != 4 || lanes[1].Pet != nil {
		t.Fatalf("lanes=%+v", lanes)
	}
	wire, err := projectLanes(7, lanes)
	if err != nil {
		t.Fatal(err)
	}
	if wire != (WireProjection{SaveTeam: "2|9:3", SaveTeamName: "A|||", SavePet: "4|0"}) {
		t.Fatalf("wire=%+v", wire)
	}

	empty, err := ParseFullCommand(7, Command{PetPresent: true})
	if err != nil || len(empty) != 0 {
		t.Fatalf("empty lanes=%v err=%v", empty, err)
	}
}

func TestParseFullCommandRejectsMalformedOrNonCanonicalLiveWire(t *testing.T) {
	cases := []Command{
		{TeamString: "1", TeamNameString: "A", PetPresent: false},
		{TeamString: "", TeamNameString: "A", PetPresent: true, PetString: ""},
		{TeamString: "1:2", TeamNameString: "A", PetPresent: true, PetString: "0|0"},
		{TeamString: "1:2", TeamNameString: "A|||B", PetPresent: true, PetString: "0"},
		{TeamString: "01", TeamNameString: "A", PetPresent: true, PetString: "0"},
		{TeamString: "+1", TeamNameString: "A", PetPresent: true, PetString: "0"},
		{TeamString: "0", TeamNameString: "A", PetPresent: true, PetString: "0"},
		{TeamString: "1||2", TeamNameString: "A", PetPresent: true, PetString: "0"},
		{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: ""},
		{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "00"},
		{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "+2"},
	}
	for _, cmd := range cases {
		if _, err := ParseFullCommand(7, cmd); !errors.Is(err, ErrInvalidCommand) {
			t.Fatalf("cmd=%+v err=%v", cmd, err)
		}
	}
}

func TestParseFullCommandDoesNotInventUIPolicy(t *testing.T) {
	longName := strings.Repeat("n", 32)
	lanes, err := ParseFullCommand(7, Command{
		TeamString: "1|1|2|3|4|5:6", TeamNameString: longName + "|||" + longName,
		PetPresent: true, PetString: "9|9",
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(lanes) != 2 || len(lanes[0].Heroes) != 6 || lanes[0].Heroes[0] != lanes[0].Heroes[1] || lanes[0].Pet == nil || lanes[1].Pet == nil || *lanes[0].Pet != *lanes[1].Pet {
		t.Fatalf("unexpected policy normalization: %+v", lanes)
	}
}

func TestResolveLegacyDeleteConvergesWithoutTouchingPets(t *testing.T) {
	current := presetAggregate(7,
		presetLane(7, "A", []int64{1, 2}, 8),
		presetLane(7, "B", []int64{3}, 9),
	)
	lanes, err := ResolveLegacyDelete(current, Command{TeamString: "1|2:3", TeamNameString: "A|||B"})
	if err != nil {
		t.Fatal(err)
	}
	if !SavedPresetLanesEqual(lanes, current.Lanes) || lanes[0].Pet == nil || lanes[0].Pet.PetID != 8 {
		t.Fatalf("converged=%+v", lanes)
	}
}

func TestResolveLegacyDeleteUniqueResultPreservesPositionalPetAlignment(t *testing.T) {
	current := presetAggregate(7,
		presetLane(7, "A", []int64{1}, 8),
		presetLane(7, "B", []int64{2}, 9),
		presetLane(7, "C", []int64{3}, 10),
	)
	lanes, err := ResolveLegacyDelete(current, Command{TeamString: "1:3", TeamNameString: "A|||C"})
	if err != nil {
		t.Fatal(err)
	}
	if len(lanes) != 2 || lanes[0].Pet == nil || lanes[0].Pet.PetID != 8 || lanes[1].Pet == nil || lanes[1].Pet.PetID != 10 {
		t.Fatalf("resolved=%+v", lanes)
	}
}

func TestResolveLegacyDeleteAcceptsMultipleIndicesOnlyWhenCanonicalResultIdentical(t *testing.T) {
	identical := presetAggregate(7,
		presetLane(7, "A", []int64{1}, 8),
		presetLane(7, "A", []int64{1}, 8),
	)
	lanes, err := ResolveLegacyDelete(identical, Command{TeamString: "1", TeamNameString: "A"})
	if err != nil || len(lanes) != 1 || lanes[0].Pet == nil || lanes[0].Pet.PetID != 8 {
		t.Fatalf("identical result lanes=%+v err=%v", lanes, err)
	}

	ambiguous := presetAggregate(7,
		presetLane(7, "A", []int64{1}, 8),
		presetLane(7, "A", []int64{1}, 9),
	)
	if _, err := ResolveLegacyDelete(ambiguous, Command{TeamString: "1", TeamNameString: "A"}); !errors.Is(err, ErrAmbiguousLegacyDelete) {
		t.Fatalf("ambiguous err=%v", err)
	}
}

func TestResolveLegacyDeleteRejectsStaleOrMalformedShape(t *testing.T) {
	current := presetAggregate(7, presetLane(7, "A", []int64{1}, 8), presetLane(7, "B", []int64{2}, 9))
	if _, err := ResolveLegacyDelete(current, Command{TeamString: "9", TeamNameString: "X"}); !errors.Is(err, ErrStaleLegacyDelete) {
		t.Fatalf("stale err=%v", err)
	}
	for _, cmd := range []Command{
		{TeamString: "1", TeamNameString: "A", PetPresent: true, PetString: "0"},
		{TeamString: "1:2", TeamNameString: "A"},
		{TeamString: "01", TeamNameString: "A"},
		{TeamString: "", TeamNameString: "A"},
	} {
		if _, err := ResolveLegacyDelete(current, cmd); !errors.Is(err, ErrInvalidCommand) {
			t.Fatalf("cmd=%+v err=%v", cmd, err)
		}
	}
}

func TestSavedPresetLanesEqualIgnoresRootMetadataButNotOrderedLaneSemantics(t *testing.T) {
	a := []character.SavedPresetLane{presetLane(7, "A", []int64{1, 2}, 8)}
	b := []character.SavedPresetLane{presetLane(7, "A", []int64{1, 2}, 8)}
	if !SavedPresetLanesEqual(a, b) {
		t.Fatal("equal lanes rejected")
	}
	b[0].Heroes[0], b[0].Heroes[1] = b[0].Heroes[1], b[0].Heroes[0]
	if SavedPresetLanesEqual(a, b) {
		t.Fatal("Hero order ignored")
	}
	b = []character.SavedPresetLane{presetLane(7, "A", []int64{1, 2}, 9)}
	if SavedPresetLanesEqual(a, b) {
		t.Fatal("Pet identity ignored")
	}
}
