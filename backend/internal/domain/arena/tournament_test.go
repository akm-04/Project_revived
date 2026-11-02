package arena

import (
	"math"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func tournamentRulesFixture() TournamentRules {
	return TournamentRules{
		StageOffsetsSeconds: [8]int64{0, 86400, 185400, 271800, 275400, 358200, 361800, 365400},
		SupportCoefficients: [3]int64{5000, 580000, 18000000},
	}
}

func TestTournamentCalendarPreservesSourceIntervalsAfterSeasonClose(t *testing.T) {
	rules := tournamentRulesFixture()
	calendar, err := rules.Calendar(catalog(t).SeasonNumbered(1))
	if err != nil {
		t.Fatal(err)
	}
	registration := time.Date(2022, 12, 12, 8, 0, 0, 0, gmt8)
	if !calendar.Stages[0].Equal(registration) || !calendar.Stages[7].Equal(time.Date(2022, 12, 16, 13, 30, 0, 0, gmt8)) {
		t.Fatal("private recurrence must preserve the source four-day, five-and-a-half-hour template", calendar)
	}
	for index, stage := range calendar.Stages {
		if calendar.StageAt(stage.Add(-time.Nanosecond)) != index || calendar.StageAt(stage) != index+1 {
			t.Fatal("stage boundary", index, stage)
		}
	}
	if calendar.StageAt(calendar.Stages[7].Add(365*24*time.Hour)) != 8 {
		t.Fatal("finished tournament reopened")
	}
	rules.StageOffsetsSeconds[7] = math.MaxInt64
	if rules.Validate() == nil {
		t.Fatal("duration overflow accepted")
	}
}

func TestTournamentSupportUsesRecoveredPolynomialAndExplicitSixteenLimit(t *testing.T) {
	rules := tournamentRulesFixture()
	for advancements, expected := range []int64{0, 1200000, 2400000, 4800000, 9600000, 19200000} {
		actual, err := rules.SupportReward(60, advancements)
		if err != nil || actual != expected {
			t.Fatal(advancements, actual, expected, err)
		}
	}
	for _, input := range []struct {
		level        int64
		advancements int
	}{{59, 1}, {60, -1}, {60, 6}, {math.MaxInt64, 1}} {
		if _, err := rules.SupportReward(input.level, input.advancements); err == nil {
			t.Fatal("unsafe reward input accepted", input)
		}
	}
}

func TestTournamentQualificationAndGroupingDoNotCreateCompetitors(t *testing.T) {
	enrollments := make([]TournamentEnrollment, 40)
	for index := range enrollments {
		enrollments[index] = TournamentEnrollment{PlayerID: identity.PlayerID(index + 1), PreviousSeasonRank: int64(40 - index), RegistrationSequence: int64(index + 1)}
	}
	qualified, err := QualifiedTournamentEntrants(enrollments)
	if err != nil || len(qualified) != 32 || qualified[0].PlayerID != 40 || qualified[31].PlayerID != 9 {
		t.Fatal("qualification must use prior rank, not enrollment order", qualified, err)
	}
	grouped, err := TournamentGroups(enrollments, operation.Context{EntropySeed: [32]byte{1}})
	if err != nil {
		t.Fatal(err)
	}
	slices.Reverse(enrollments)
	replayed, err := TournamentGroups(enrollments, operation.Context{EntropySeed: [32]byte{1}})
	if err != nil || replayed != grouped {
		t.Fatal("row reload/retry changed the frozen draw", err)
	}
	seen := map[identity.PlayerID]bool{}
	for _, group := range grouped {
		for _, player := range group {
			if player < 9 || player > 40 || seen[player] {
				t.Fatal("unqualified or duplicate contender", player)
			}
			seen[player] = true
		}
	}
	if _, err := QualifiedTournamentEntrants(append(enrollments, enrollments[0])); err == nil {
		t.Fatal("duplicate enrollment accepted")
	}
	sparse, err := TournamentGroups(enrollments[:2], operation.Context{})
	if err != nil {
		t.Fatal(err)
	}
	count := 0
	for _, group := range sparse {
		for _, player := range group {
			if player != 0 {
				count++
			}
		}
	}
	if count != 2 {
		t.Fatal("bye seats became synthetic competitors", count)
	}
	if _, err := TournamentGroups(enrollments[:1], operation.Context{}); err == nil {
		t.Fatal("one entrant created a tournament prize")
	}
}

func TestTournamentGroupScheduleAndRegistrationTie(t *testing.T) {
	seen := map[[2]int]bool{}
	for round := 1; round <= 3; round++ {
		pairings, err := TournamentGroupPairings(round)
		if err != nil {
			t.Fatal(err)
		}
		for _, pair := range pairings {
			if pair[0] == pair[1] || seen[pair] {
				t.Fatal("repeated opponent or self-match", pair)
			}
			seen[pair] = true
		}
	}
	if len(seen) != 6 {
		t.Fatal("not every group pairing appears")
	}
	ordered := OrderTournamentGroup([]TournamentGroupStanding{
		{Enrollment: TournamentEnrollment{PlayerID: 1, RegistrationSequence: 4}, Wins: 2},
		{Enrollment: TournamentEnrollment{PlayerID: 2, RegistrationSequence: 2}, Wins: 2},
		{Enrollment: TournamentEnrollment{PlayerID: 3, RegistrationSequence: 1}, Wins: 1},
	})
	if ordered[0].Enrollment.PlayerID != 2 || ordered[1].Enrollment.PlayerID != 1 {
		t.Fatal("source group tie must use registration order", ordered)
	}
}

func TestCasualWindowAndFirstAttainmentRanking(t *testing.T) {
	for _, date := range []time.Time{
		time.Date(2026, 3, 28, 18, 0, 0, 0, gmt8),
		time.Date(2026, 10, 31, 18, 0, 0, 0, gmt8),
	} {
		period := CasualPeriodAt(date)
		if !period.OpensAt.Equal(date) || !period.Open(date) || period.Open(date.Add(-time.Nanosecond)) || period.Open(date.Add(2*time.Hour)) {
			t.Fatal("active help's Saturday 18:00-20:00 GMT+8 window", period)
		}
	}
	first := time.Date(2026, 10, 31, 10, 0, 0, 0, time.UTC)
	ordered := OrderCasualStandings([]CasualStanding{
		{PlayerID: 1, Points: 100, PointsAt: first},
		{PlayerID: 2, Points: 2, PointsAt: first.Add(time.Second), Battles: 2},
		{PlayerID: 3, Points: 2, PointsAt: first, Battles: 3},
		{PlayerID: 4, Points: 0, PointsAt: first, Battles: 1},
	})
	if len(ordered) != 3 || ordered[0].PlayerID != 3 || ordered[1].PlayerID != 2 || ordered[2].PlayerID != 4 {
		t.Fatal("nonparticipants must not rank; tied points favor first attainment", ordered)
	}
}
