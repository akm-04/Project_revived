package arena

import (
	"reflect"
	"slices"
	"testing"
	"time"
)

func selectionRosterFixture(side int) SelectionRoster {
	roster := SelectionRoster{}
	for index := 1; index <= SelectionTeamCount*TeamSize; index++ {
		roster.Heroes = append(roster.Heroes, SelectionHero{Identifier: int64(side*100 + index), TableIdentifier: int64(index)})
	}
	for index := 1; index <= SelectionTeamCount; index++ {
		roster.Pets = append(roster.Pets, int64(side*1000+index))
	}
	return roster
}

func TestSelectionThreeTeamsPreservesTurnsAndOwnedInstances(t *testing.T) {
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	room, err := NewSelectionRoom(1, 2, at)
	if err != nil {
		t.Fatal(err)
	}
	rosters := [2]SelectionRoster{selectionRosterFixture(0), selectionRosterFixture(1)}
	for step := 0; step < 24; step++ {
		before := room
		team, turn, side := room.Team, room.Turn, room.Turn%2
		originalHeroes := slices.Clone(room.Teams[side][team-1].Heroes)
		chosen := SelectedFormation{Heroes: slices.Clone(room.Teams[side][team-1].Heroes)}
		if turn < SelectionPetTurn {
			for len(chosen.Heroes) < selectionHeroCount(turn) {
				chosen.Heroes = append(chosen.Heroes, rosters[side].Heroes[(team-1)*TeamSize+len(chosen.Heroes)].Identifier)
			}
		} else {
			chosen.Pet = rosters[side].Pets[team-1]
		}
		command := SelectionCommand{Player: room.Players[side], Turn: turn, Formation: chosen}
		room, err = room.Select(command, rosters[side], at)
		if err != nil {
			t.Fatal("source selector transition", step, team, turn, err)
		}
		if !slices.Equal(before.Teams[side][team-1].Heroes, originalHeroes) {
			t.Fatal("prior turn was mutated")
		}
		if room.Validate() != nil || !room.Deadline.Equal(at.Add(SelectionTurnLifetime)) {
			t.Fatal("invalid transition", room)
		}
		at = at.Add(time.Second)
	}
	if !room.Complete() {
		t.Fatal("three completed teams did not terminate selection", room)
	}
	for side := range room.Players {
		seen := map[int64]bool{}
		for _, team := range room.Teams[side] {
			if len(team.Heroes) != TeamSize || team.Pet == 0 {
				t.Fatal("team not complete", team)
			}
			for _, identifier := range team.Heroes {
				if seen[identifier] {
					t.Fatal("instance reused across teams", identifier)
				}
				seen[identifier] = true
			}
		}
	}
	if _, err := room.Select(SelectionCommand{Player: 1, Turn: 8}, rosters[0], at); err == nil {
		t.Fatal("terminal selector accepted another choice")
	}
}

func TestSelectionRefusesForgedTurnsOwnershipAndExpiredChoices(t *testing.T) {
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	room, err := NewSelectionRoom(1, 2, at)
	if err != nil {
		t.Fatal(err)
	}
	roster := selectionRosterFixture(0)
	for _, command := range []SelectionCommand{
		{Player: 3, Turn: 0, Formation: SelectedFormation{Heroes: []int64{1}}},
		{Player: 2, Turn: 0, Formation: SelectedFormation{Heroes: []int64{1}}},
		{Player: 1, Turn: 1, Formation: SelectedFormation{Heroes: []int64{1}}},
		{Player: 1, Turn: 0, Formation: SelectedFormation{Heroes: []int64{10001}}},
		{Player: 1, Turn: 0, Formation: SelectedFormation{Heroes: []int64{1, 2}}},
		{Player: 1, Turn: 0, Formation: SelectedFormation{Heroes: []int64{1}, Pet: 1}},
	} {
		if _, err := room.Select(command, roster, at); err == nil {
			t.Fatal("forged selection accepted", command)
		}
	}
	valid := SelectionCommand{Player: 1, Turn: 0, Formation: SelectedFormation{Heroes: []int64{1}}}
	if _, err := room.Select(valid, roster, room.Deadline); err == nil {
		t.Fatal("choice raced past the canonical deadline")
	}
	room.Teams[0][0] = SelectedFormation{Heroes: []int64{1}}
	room.Turn = 2
	if _, err := room.Select(SelectionCommand{Player: 1, Turn: 2, Formation: SelectedFormation{Heroes: []int64{2, 3, 4}}}, roster, at); err == nil {
		t.Fatal("earlier locked choice was replaced")
	}
	roster.Heroes[2].TableIdentifier = roster.Heroes[1].TableIdentifier
	if _, err := room.Select(SelectionCommand{Player: 1, Turn: 2, Formation: SelectedFormation{Heroes: []int64{1, 2, 3}}}, roster, at); err == nil {
		t.Fatal("two instances of the same girl type accepted")
	}
}

func TestExpiredSelectionIsStableAndCannotConjureMissingRoster(t *testing.T) {
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	room, err := NewSelectionRoom(1, 2, at)
	if err != nil {
		t.Fatal(err)
	}
	roster := selectionRosterFixture(0)
	slices.Reverse(roster.Heroes)
	unchanged, err := room.Expire(roster, room.Deadline.Add(-time.Nanosecond))
	if err != nil || !reflect.DeepEqual(unchanged, room) {
		t.Fatal("undue timer advanced selection", err)
	}
	advanced, err := room.Expire(roster, room.Deadline)
	if err != nil || !slices.Equal(advanced.Teams[0][0].Heroes, []int64{1}) || len(room.Teams[0][0].Heroes) != 0 {
		t.Fatal("fallback is not stable and immutable", advanced, err)
	}
	room.Turn = 6
	room.Teams[0][0].Heroes = []int64{99, 1, 2, 3, 4}
	advanced, err = room.Expire(roster, room.Deadline)
	if err != nil || !slices.Equal(advanced.Teams[0][0].Heroes, []int64{1, 2, 3, 4, 5}) || advanced.Teams[0][0].Pet != 1 {
		t.Fatal("deleted ownership was retained or fallback ignored legal owned replacements", advanced, err)
	}
	if !slices.Equal(room.Teams[0][0].Heroes, []int64{99, 1, 2, 3, 4}) {
		t.Fatal("fallback mutated the retained prior state")
	}
	empty, err := room.Expire(SelectionRoster{}, room.Deadline)
	if err != nil || len(empty.Teams[0][0].Heroes) != 0 || empty.Teams[0][0].Pet != 0 {
		t.Fatal("empty roster conjured a fighter or pet", empty, err)
	}
}

func TestSelectionExcludesEarlierTeamAndRechecksPetOwnership(t *testing.T) {
	at := time.Date(2026, 10, 29, 0, 0, 0, 0, time.UTC)
	room, err := NewSelectionRoom(1, 2, at)
	if err != nil {
		t.Fatal(err)
	}
	roster := selectionRosterFixture(0)
	room.Team = 2
	room.Teams[0][0] = SelectedFormation{Heroes: []int64{1, 2, 3, 4, 5}, Pet: 1}
	if _, err := room.Select(SelectionCommand{Player: 1, Turn: 0, Formation: SelectedFormation{Heroes: []int64{1}}}, roster, at); err == nil {
		t.Fatal("earlier team's girl reused")
	}
	room.Turn = 6
	room.Teams[0][1].Heroes = []int64{6, 7, 8, 9, 10}
	for _, pet := range []int64{0, 1, 9999} {
		if _, err := room.Select(SelectionCommand{Player: 1, Turn: 6, Formation: SelectedFormation{Heroes: []int64{6, 7, 8, 9, 10}, Pet: pet}}, roster, at); err == nil {
			t.Fatal("missing, previously used or foreign pet accepted", pet)
		}
	}
	roster.Heroes = roster.Heroes[1:]
	room.Teams[0][1].Heroes[0] = 1
	if _, err := room.Select(SelectionCommand{Player: 1, Turn: 6, Formation: SelectedFormation{Heroes: []int64{1, 7, 8, 9, 10}, Pet: 2}}, roster, at); err == nil {
		t.Fatal("pet submission retained a no-longer-owned girl")
	}
}
