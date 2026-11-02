package arena

import (
	"cmp"
	"math"
	"math/big"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const (
	TournamentContractIdentifier = "I9_PVP_TOURNAMENT_CASUAL_V1"
	TournamentPolicyIdentifier   = "I9_PVP_TOURNAMENT_CASUAL_POLICY_V1"
	TournamentEntrantLimit       = 32
	TournamentQualificationRank  = 50
	TournamentGroupSize          = 4
	TournamentGroupCount         = TournamentEntrantLimit / TournamentGroupSize
	TournamentSupportLevel       = 60
	TournamentSupportMaximum     = 16
	TournamentAdvancementLimit   = 5
	CasualQueueLifetime          = time.Minute
	SelectionTurnLifetime        = 30 * time.Second
)

type TournamentRules struct {
	StageOffsetsSeconds [8]int64 `json:"stage_offsets_seconds"`
	SupportCoefficients [3]int64 `json:"support_coefficients"`
}

func (rules TournamentRules) Validate() error {
	if rules.StageOffsetsSeconds[0] != 0 {
		return ErrInvalid
	}
	for index := 1; index < len(rules.StageOffsetsSeconds); index++ {
		if rules.StageOffsetsSeconds[index] <= rules.StageOffsetsSeconds[index-1] {
			return ErrInvalid
		}
	}
	if rules.StageOffsetsSeconds[7] > math.MaxInt64/int64(time.Second) {
		return ErrInvalid
	}
	for _, coefficient := range rules.SupportCoefficients {
		if coefficient <= 0 {
			return ErrInvalid
		}
	}
	return nil
}

type TournamentCalendar struct {
	Season int64
	Stages [8]time.Time
}

func (rules TournamentRules) Calendar(season Season) (TournamentCalendar, error) {
	if rules.Validate() != nil || season.Number <= 0 || !season.ClosesAt.After(season.OpensAt) {
		return TournamentCalendar{}, ErrInvalid
	}
	localClose := season.ClosesAt.In(time.FixedZone("GMT+8", 8*3600))
	registration := time.Date(localClose.Year(), localClose.Month(), localClose.Day(), 8, 0, 0, 0, localClose.Location())
	if registration.Before(season.ClosesAt) {
		return TournamentCalendar{}, ErrInvalid
	}
	calendar := TournamentCalendar{Season: season.Number}
	for index, seconds := range rules.StageOffsetsSeconds {
		calendar.Stages[index] = registration.Add(time.Duration(seconds) * time.Second).UTC()
	}
	return calendar, nil
}

func (calendar TournamentCalendar) StageAt(at time.Time) int {
	for index := len(calendar.Stages) - 1; index >= 0; index-- {
		if !at.Before(calendar.Stages[index]) {
			return index + 1
		}
	}
	return 0
}

func (rules TournamentRules) SupportReward(level int64, advancements int) (int64, error) {
	if rules.Validate() != nil || level < TournamentSupportLevel || advancements < 0 || advancements > TournamentAdvancementLimit {
		return 0, ErrInvalid
	}
	if advancements == 0 {
		return 0, nil
	}
	value := new(big.Int).Mul(big.NewInt(level), big.NewInt(level))
	value.Mul(value, big.NewInt(rules.SupportCoefficients[0]))
	value.Sub(value, new(big.Int).Mul(big.NewInt(level), big.NewInt(rules.SupportCoefficients[1])))
	value.Add(value, big.NewInt(rules.SupportCoefficients[2]))
	if !value.IsInt64() || value.Sign() < 0 {
		return 0, ErrInvalid
	}
	base := value.Int64()
	multiplier := int64(1) << (advancements - 1)
	if base > math.MaxInt64/multiplier {
		return 0, ErrInvalid
	}
	return base * multiplier, nil
}

type TournamentEnrollment struct {
	PlayerID             identity.PlayerID `json:"player_id"`
	PreviousSeasonRank   int64             `json:"previous_season_rank"`
	RegistrationSequence int64             `json:"registration_sequence"`
}

func QualifiedTournamentEntrants(enrollments []TournamentEnrollment) ([]TournamentEnrollment, error) {
	players := map[identity.PlayerID]bool{}
	sequences := map[int64]bool{}
	for _, enrollment := range enrollments {
		if !enrollment.PlayerID.Valid() || enrollment.PreviousSeasonRank < 1 || enrollment.PreviousSeasonRank > TournamentQualificationRank || enrollment.RegistrationSequence < 1 || players[enrollment.PlayerID] || sequences[enrollment.RegistrationSequence] {
			return nil, ErrInvalid
		}
		players[enrollment.PlayerID] = true
		sequences[enrollment.RegistrationSequence] = true
	}
	qualified := slices.Clone(enrollments)
	slices.SortFunc(qualified, func(left, right TournamentEnrollment) int {
		if order := cmp.Compare(left.PreviousSeasonRank, right.PreviousSeasonRank); order != 0 {
			return order
		}
		return cmp.Compare(left.RegistrationSequence, right.RegistrationSequence)
	})
	return qualified[:min(len(qualified), TournamentEntrantLimit)], nil
}

func TournamentGroups(enrollments []TournamentEnrollment, entropy operation.Context) ([TournamentGroupCount][TournamentGroupSize]identity.PlayerID, error) {
	groups := [TournamentGroupCount][TournamentGroupSize]identity.PlayerID{}
	qualified, err := QualifiedTournamentEntrants(enrollments)
	if err != nil || len(qualified) < 2 {
		return groups, ErrInvalid
	}
	// Sorting independent derived keys keeps retries stable without modulo-biased draws.
	type draw struct {
		enrollment TournamentEnrollment
		key        [32]byte
	}
	draws := make([]draw, len(qualified))
	for index, enrollment := range qualified {
		draws[index] = draw{enrollment: enrollment, key: entropy.Derive("arena.playoffs.groups/v1", uint64(enrollment.PlayerID))}
	}
	slices.SortFunc(draws, func(left, right draw) int {
		if order := slices.Compare(left.key[:], right.key[:]); order != 0 {
			return order
		}
		return cmp.Compare(left.enrollment.PlayerID, right.enrollment.PlayerID)
	})
	for index, entry := range draws {
		groups[index%len(groups)][index/len(groups)] = entry.enrollment.PlayerID
	}
	return groups, nil
}

func TournamentGroupPairings(round int) ([2][2]int, error) {
	pairings := [3][2][2]int{{{0, 1}, {2, 3}}, {{0, 2}, {1, 3}}, {{0, 3}, {1, 2}}}
	if round < 1 || round > len(pairings) {
		return [2][2]int{}, ErrInvalid
	}
	return pairings[round-1], nil
}

type TournamentGroupStanding struct {
	Enrollment TournamentEnrollment
	Wins       int64
}

func OrderTournamentGroup(standings []TournamentGroupStanding) []TournamentGroupStanding {
	ordered := slices.Clone(standings)
	slices.SortFunc(ordered, func(left, right TournamentGroupStanding) int {
		if order := cmp.Compare(right.Wins, left.Wins); order != 0 {
			return order
		}
		return cmp.Compare(left.Enrollment.RegistrationSequence, right.Enrollment.RegistrationSequence)
	})
	return ordered
}

type CasualPeriod struct {
	WeekDay  int64
	OpensAt  time.Time
	ClosesAt time.Time
}

func CasualPeriodAt(at time.Time) CasualPeriod {
	saturday := modes.WeekStart(at) + 5
	opens := modes.DayBegins(saturday).Add(13 * time.Hour)
	return CasualPeriod{WeekDay: saturday, OpensAt: opens, ClosesAt: opens.Add(2 * time.Hour)}
}

func (period CasualPeriod) Open(at time.Time) bool {
	return !at.Before(period.OpensAt) && at.Before(period.ClosesAt)
}

type CasualStanding struct {
	PlayerID identity.PlayerID
	Points   int64
	PointsAt time.Time
	Battles  int64
}

func OrderCasualStandings(standings []CasualStanding) []CasualStanding {
	ordered := slices.DeleteFunc(slices.Clone(standings), func(standing CasualStanding) bool { return standing.Battles <= 0 })
	slices.SortFunc(ordered, func(left, right CasualStanding) int {
		if order := cmp.Compare(right.Points, left.Points); order != 0 {
			return order
		}
		if order := left.PointsAt.Compare(right.PointsAt); order != 0 {
			return order
		}
		return cmp.Compare(left.PlayerID, right.PlayerID)
	})
	return ordered
}
