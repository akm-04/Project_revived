package arena

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"testing"
)

func TestSelectionKeysFenceTeamIdentity(t *testing.T) {
	identifier, _ := ids.NewUUID()
	for team := 1; team <= SelectionTeamCount; team++ {
		room := TournamentRoom{Identifier: identifier, Selection: SelectionRoom{Team: team}}
		parsed, actual, err := ParseSelectionKey(room.SelectionKey())
		if err != nil || parsed != identifier || actual != team {
			t.Fatal(parsed, actual, err)
		}
	}
	for _, suffix := range []string{"0", "4", "01", "1/2", "", "+1"} {
		if _, _, err := ParseSelectionKey(identifier.String() + "/" + suffix); err == nil {
			t.Fatal("ambiguous team accepted", suffix)
		}
	}
}

func TestPlayedRoundsExcludeForfeitsAndUnsimulatedRounds(t *testing.T) {
	first, _ := ids.NewUUID()
	second, _ := ids.NewUUID()
	room := TournamentRoom{Attempts: []ids.UUID{{}, first, second}, RoundResults: [3]int{RoundFirstWin, RoundSecondWin, RoundSecondWin}}
	rounds := room.PlayedRounds()
	if len(rounds) != 2 || rounds[0] != 1 || rounds[1] != 2 {
		t.Fatal(rounds)
	}
	room = TournamentRoom{Attempts: []ids.UUID{first, second, {}}, RoundResults: [3]int{RoundFirstWin, RoundFirstWin, RoundSecondWin}}
	if rounds = room.PlayedRounds(); len(rounds) != 2 {
		t.Fatal("unused third counted", rounds)
	}
}
