package arena

import (
	"slices"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func bracketFixture(size int) TournamentPeriod {
	period := TournamentPeriod{}
	for index := range size {
		period.Entrants = append(period.Entrants, TournamentEntrant{TournamentEnrollment: TournamentEnrollment{PlayerID: identity.PlayerID(index + 1), PreviousSeasonRank: int64(index + 1), RegistrationSequence: int64(index + 1)}})
	}
	return period
}

func TestTournamentBracketRequiresRealResultsAndAssignsEveryPlacement(t *testing.T) {
	period := bracketFixture(32)
	if err := period.LockRoster(operation.Context{EntropySeed: [32]byte{7}}); err != nil {
		t.Fatal(err)
	}
	groups := period.Groups
	if err := period.LockRoster(operation.Context{EntropySeed: [32]byte{99}}); err != nil || period.Groups != groups {
		t.Fatal("roster rerolled")
	}
	if err := period.AdvanceBracket(8); err != nil || period.hasStage(4) {
		t.Fatal("advanced through unplayed group matches")
	}
	for step := 0; step < 10 && !period.ChampionPrizeOwed; step++ {
		for index, contest := range period.Contests {
			if contest.Complete {
				continue
			}
			winner := contest.Players[0]
			if err := period.CompleteContest(index, winner); err != nil {
				t.Fatal(err)
			}
			if err := period.CompleteContest(index, winner); err != nil {
				t.Fatal("result replay failed", err)
			}
		}
		if err := period.AdvanceBracket(8); err != nil {
			t.Fatal(err)
		}
	}
	placements := []int64{}
	for _, entrant := range period.Entrants {
		placements = append(placements, entrant.Placement)
		if entrant.GroupWins > 3 {
			t.Fatal("replayed win incremented")
		}
	}
	slices.Sort(placements)
	for index, placement := range placements {
		if placement != int64(index+1) {
			t.Fatal("placement gap/duplicate", placements)
		}
	}
	finals, complete := period.stageContests(7)
	if !complete || len(finals) != 2 || !period.ChampionPrizeOwed {
		t.Fatal("best of three did not stop after two wins", finals)
	}
}

func TestSparseTournamentByesNeverBecomePlayerIdentities(t *testing.T) {
	for _, size := range []int{0, 1, 2, 7, 31} {
		period := bracketFixture(size)
		if err := period.LockRoster(operation.Context{EntropySeed: [32]byte{3}}); err != nil {
			t.Fatal(size, err)
		}
		if size < 2 {
			if !period.Cancelled || !period.Settled || period.ChampionPrizeOwed || len(period.Contests) != 0 {
				t.Fatal("cancelled tournament created prize/matches", period)
			}
			continue
		}
		for step := 0; step < 10 && !period.ChampionPrizeOwed; step++ {
			for index, contest := range period.Contests {
				for _, player := range contest.Players {
					if player < 0 || player > identity.PlayerID(size) {
						t.Fatal("synthetic participant", player)
					}
				}
				if contest.Complete {
					continue
				}
				if contest.Players[0] == 0 || contest.Players[1] == 0 {
					t.Fatal("bye scheduled a real fight")
				}
				if err := period.CompleteContest(index, contest.Players[0]); err != nil {
					t.Fatal(err)
				}
			}
			if err := period.AdvanceBracket(8); err != nil {
				t.Fatal(err)
			}
		}
		if !period.ChampionPrizeOwed {
			t.Fatal("sparse bracket stranded", size)
		}
	}
}

func TestEntirelyForfeitedTournamentCancelsWithoutInventedChampion(t *testing.T) {
	period := bracketFixture(32)
	if err := period.LockRoster(operation.Context{EntropySeed: [32]byte{1}}); err != nil {
		t.Fatal(err)
	}
	for step := 0; step < 10 && !period.Settled; step++ {
		for index, contest := range period.Contests {
			if !contest.Complete {
				if err := period.CompleteContest(index, 0); err != nil {
					t.Fatal(err)
				}
			}
		}
		if err := period.AdvanceBracket(8); err != nil {
			t.Fatal(err)
		}
	}
	if !period.Cancelled || !period.Settled || period.ChampionPrizeOwed {
		t.Fatal("empty field stranded or fabricated champion")
	}
}
