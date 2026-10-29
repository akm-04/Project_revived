package arena

import (
	"cmp"
	"slices"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (period *TournamentPeriod) LockRoster(entropy operation.Context) error {
	if period.RosterLocked {
		return nil
	}
	enrollments := make([]TournamentEnrollment, len(period.Entrants))
	for index, entrant := range period.Entrants {
		enrollments[index] = entrant.TournamentEnrollment
	}
	qualified, err := QualifiedTournamentEntrants(enrollments)
	if err != nil {
		return err
	}
	period.RosterLocked = true
	if len(qualified) < 2 {
		period.Cancelled, period.Settled = true, true
		return nil
	}
	period.Groups, err = TournamentGroups(qualified, entropy)
	if err != nil {
		return err
	}
	for index := range period.Entrants {
		period.Entrants[index].Eliminated = true
		for group, seats := range period.Groups {
			if slices.Contains(seats[:], period.Entrants[index].PlayerID) {
				period.Entrants[index].Group, period.Entrants[index].Eliminated = group+1, false
			}
		}
	}
	for round := 1; round <= 3; round++ {
		pairings, _ := TournamentGroupPairings(round)
		for group, seats := range period.Groups {
			for index, pair := range pairings {
				period.appendContest(TournamentContest{Stage: 3, Substage: round, Seat: group*2 + index, Players: [2]identity.PlayerID{seats[pair[0]], seats[pair[1]]}})
			}
		}
	}
	return nil
}

func (period *TournamentPeriod) appendContest(contest TournamentContest) {
	if contest.Players[0] == 0 || contest.Players[1] == 0 {
		contest.Complete = true
		contest.Winner = max(contest.Players[0], contest.Players[1])
		if contest.Stage == 3 && contest.Winner != 0 {
			period.addGroupWin(contest.Winner)
		}
	}
	period.Contests = append(period.Contests, contest)
}

func (period *TournamentPeriod) addGroupWin(player identity.PlayerID) {
	for index := range period.Entrants {
		if period.Entrants[index].PlayerID == player {
			period.Entrants[index].GroupWins++
		}
	}
}

func (period *TournamentPeriod) CompleteContest(index int, winner identity.PlayerID) error {
	if index < 0 || index >= len(period.Contests) {
		return ErrInvalid
	}
	contest := &period.Contests[index]
	if contest.Complete {
		if contest.Winner != winner {
			return ErrConflict
		}
		return nil
	}
	if winner != 0 && !slices.Contains(contest.Players[:], winner) {
		return ErrInvalid
	}
	contest.Complete, contest.Winner = true, winner
	if contest.Stage == 3 && winner != 0 {
		period.addGroupWin(winner)
	}
	return nil
}

func (period TournamentPeriod) stageContests(stage int) ([]TournamentContest, bool) {
	contests := []TournamentContest{}
	for _, contest := range period.Contests {
		if contest.Stage != stage {
			continue
		}
		if !contest.Complete {
			return nil, false
		}
		contests = append(contests, contest)
	}
	slices.SortFunc(contests, func(left, right TournamentContest) int {
		if order := cmp.Compare(left.Substage, right.Substage); order != 0 {
			return order
		}
		return cmp.Compare(left.Seat, right.Seat)
	})
	return contests, len(contests) > 0
}

func (period TournamentPeriod) hasStage(stage int) bool {
	return slices.ContainsFunc(period.Contests, func(contest TournamentContest) bool { return contest.Stage == stage })
}

// AdvanceBracket never treats a missing room result as a win or an elapsed deadline as a battle result.
func (period *TournamentPeriod) AdvanceBracket(stage int) error {
	if !period.RosterLocked || period.Cancelled || stage < 4 || period.Settled {
		return nil
	}
	if !period.hasStage(4) {
		if _, complete := period.stageContests(3); !complete {
			return nil
		}
		groups := [TournamentGroupCount][2]identity.PlayerID{}
		eliminated := []identity.PlayerID{}
		for group, seats := range period.Groups {
			standings := []TournamentGroupStanding{}
			for _, player := range seats {
				if player == 0 {
					continue
				}
				entrant, found := period.Entrant(player)
				if !found {
					return ErrConflict
				}
				standings = append(standings, TournamentGroupStanding{Enrollment: entrant.TournamentEnrollment, Wins: entrant.GroupWins})
			}
			for index, standing := range OrderTournamentGroup(standings) {
				if index < 2 {
					groups[group][index] = standing.Enrollment.PlayerID
				} else {
					eliminated = append(eliminated, standing.Enrollment.PlayerID)
				}
			}
		}
		period.place(eliminated, 17)
		for group := 0; group < TournamentGroupCount; group += 2 {
			period.appendContest(TournamentContest{Stage: 4, Seat: group, Players: [2]identity.PlayerID{groups[group][0], groups[group+1][1]}})
			period.appendContest(TournamentContest{Stage: 4, Seat: group + 1, Players: [2]identity.PlayerID{groups[group+1][0], groups[group][1]}})
		}
	}
	for nextStage := 5; nextStage <= min(stage, 7); nextStage++ {
		if period.hasStage(nextStage) {
			continue
		}
		previous, complete := period.stageContests(nextStage - 1)
		if !complete {
			return nil
		}
		winners := []identity.PlayerID{}
		losers := []identity.PlayerID{}
		for _, contest := range previous {
			winners = append(winners, contest.Winner)
			for _, player := range contest.Players {
				if player != 0 && player != contest.Winner {
					losers = append(losers, player)
				}
			}
		}
		period.place(losers, int64(len(previous)+1))
		for index := 0; index < len(winners); index += 2 {
			substage := 0
			if nextStage >= 6 {
				substage = 1
			}
			period.appendContest(TournamentContest{Stage: nextStage, Substage: substage, Seat: index / 2, Players: [2]identity.PlayerID{winners[index], winners[index+1]}})
		}
	}
	finals, complete := period.stageContests(7)
	if stage < 7 || !complete {
		return nil
	}
	wins := map[identity.PlayerID]int{}
	for _, contest := range finals {
		if contest.Winner != 0 {
			wins[contest.Winner]++
		}
	}
	players := finals[0].Players
	if players == ([2]identity.PlayerID{}) {
		period.Cancelled, period.Settled = true, true
		return nil
	}
	var champion identity.PlayerID
	for _, player := range players {
		if player != 0 && (wins[player] >= 2 || players[0] == 0 || players[1] == 0) {
			champion = player
		}
	}
	if champion == 0 && len(finals) < 3 {
		period.appendContest(TournamentContest{Stage: 7, Substage: len(finals) + 1, Players: players})
		return nil
	}
	if champion == 0 && len(finals) == 3 {
		// Equal forfeits have no battle winner; immutable season rank breaks this reconstruction-only tie.
		for _, player := range players {
			entrant, found := period.Entrant(player)
			current, currentFound := period.Entrant(champion)
			if found && (!currentFound || entrant.PreviousSeasonRank < current.PreviousSeasonRank) {
				champion = player
			}
		}
	}
	if champion != 0 {
		period.place([]identity.PlayerID{champion}, 1)
		for _, player := range players {
			if player != 0 && player != champion {
				period.place([]identity.PlayerID{player}, 2)
			}
		}
		period.ChampionPrizeOwed = true
	}
	return nil
}

func (period *TournamentPeriod) place(players []identity.PlayerID, firstRank int64) {
	slices.SortFunc(players, func(left, right identity.PlayerID) int {
		first, _ := period.Entrant(left)
		second, _ := period.Entrant(right)
		return cmp.Compare(first.PreviousSeasonRank, second.PreviousSeasonRank)
	})
	for offset, player := range players {
		for index := range period.Entrants {
			if period.Entrants[index].PlayerID == player {
				period.Entrants[index].Placement = firstRank + int64(offset)
				period.Entrants[index].Eliminated = firstRank != 1
			}
		}
	}
}
