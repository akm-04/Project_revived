package arena

import (
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// AdmissionContext stores provenance; it never substitutes for a live public actor fence.
type AdmissionContext struct {
	AccountID              ids.UUID
	AccountUID             identity.AccountUID
	SessionID              ids.UUID
	ContextID              ids.UUID
	LogicalServerID        identity.LogicalServerID
	PlayerID               identity.PlayerID
	ContextGeneration      int64
	SessionLivenessVersion int64
	ContextLivenessVersion int64
}

func AdmissionFrom(actor identity.ActorContext) AdmissionContext {
	return AdmissionContext{AccountID: actor.AccountID.UUID(), AccountUID: actor.AccountUID, SessionID: actor.SessionID.UUID(), ContextID: actor.ContextID.UUID(), LogicalServerID: actor.LogicalServerID, PlayerID: actor.PlayerID, ContextGeneration: actor.ContextGeneration, SessionLivenessVersion: actor.SessionLivenessVersion, ContextLivenessVersion: actor.ContextLivenessVersion}
}

func (admission AdmissionContext) Actor() (identity.ActorContext, error) {
	account, accountError := identity.AccountIDFrom(admission.AccountID)
	session, sessionError := identity.SessionIDFrom(admission.SessionID)
	contextIdentifier, contextError := identity.ContextIDFrom(admission.ContextID)
	if accountError != nil || sessionError != nil || contextError != nil || !admission.PlayerID.Valid() || !admission.LogicalServerID.Valid() || !admission.AccountUID.Valid() || admission.ContextGeneration < 1 || admission.SessionLivenessVersion < 1 || admission.ContextLivenessVersion < 1 {
		return identity.ActorContext{}, ErrInvalid
	}
	return identity.ActorContext{AccountID: account, AccountUID: admission.AccountUID, SessionID: session, ContextID: contextIdentifier, LogicalServerID: admission.LogicalServerID, PlayerID: admission.PlayerID, ContextGeneration: admission.ContextGeneration, SessionLivenessVersion: admission.SessionLivenessVersion, ContextLivenessVersion: admission.ContextLivenessVersion}, nil
}

type TournamentSupport struct {
	Player       identity.PlayerID `json:"player"`
	Target       identity.PlayerID `json:"target"`
	Level        int64             `json:"level"`
	Advancements int               `json:"advancements"`
	EarnedMana   int64             `json:"earned_mana"`
}

type TournamentEntrant struct {
	TournamentEnrollment
	Actor       AdmissionContext `json:"actor"`
	Declaration string           `json:"declaration"`
	Group       int              `json:"group"`
	GroupWins   int64            `json:"group_wins"`
	Eliminated  bool             `json:"eliminated"`
	Placement   int64            `json:"placement"`
}

type TournamentContest struct {
	Stage    int                  `json:"stage"`
	Substage int                  `json:"substage"`
	Seat     int                  `json:"seat"`
	Players  [2]identity.PlayerID `json:"players"`
	Room     ids.UUID             `json:"room"`
	Complete bool                 `json:"complete"`
	Winner   identity.PlayerID    `json:"winner"`
}

type TournamentPeriod struct {
	SettledAt             time.Time                                                    `json:"settled_at"`
	ChampionPrizeOperator string                                                       `json:"champion_prize_operator"`
	ChampionPrizeReason   string                                                       `json:"champion_prize_reason"`
	Groups                [TournamentGroupCount][TournamentGroupSize]identity.PlayerID `json:"groups"`
	Contests              []TournamentContest                                          `json:"contests"`
	ChampionPrizeOwed     bool                                                         `json:"champion_prize_owed"`
	ChampionPrizeChosen   int64                                                        `json:"champion_prize_chosen"`
	Season                int64                                                        `json:"season"`
	ContentRevision       string                                                       `json:"content_revision"`
	Calendar              TournamentCalendar                                           `json:"calendar"`
	Entrants              []TournamentEntrant                                          `json:"entrants"`
	Supporters            []TournamentSupport                                          `json:"supporters"`
	RosterLocked          bool                                                         `json:"roster_locked"`
	Cancelled             bool                                                         `json:"cancelled"`
	Settled               bool                                                         `json:"settled"`
	StateVersion          int64                                                        `json:"state_version"`
}

func (period TournamentPeriod) Validate() error {
	if period.Season < 1 || period.Calendar.Season != period.Season || len(period.ContentRevision) != 64 || period.StateVersion < 1 || len(period.Entrants) > TournamentQualificationRank {
		return ErrConflict
	}
	for index, stage := range period.Calendar.Stages {
		if stage.IsZero() || index > 0 && !stage.After(period.Calendar.Stages[index-1]) {
			return ErrConflict
		}
	}
	enrollments := make([]TournamentEnrollment, len(period.Entrants))
	for index, entrant := range period.Entrants {
		if _, err := entrant.Actor.Actor(); err != nil {
			return ErrConflict
		}
		enrollments[index] = entrant.TournamentEnrollment
		if entrant.Actor.PlayerID != entrant.PlayerID || entrant.Actor.ContextID.IsZero() || entrant.Group < 0 || entrant.Group > TournamentGroupCount || entrant.GroupWins < 0 || entrant.GroupWins > 3 || entrant.Placement < 0 || entrant.Placement > TournamentEntrantLimit {
			return ErrConflict
		}
	}
	if _, err := QualifiedTournamentEntrants(enrollments); err != nil {
		return err
	}
	seen := map[identity.PlayerID]bool{}
	for _, support := range period.Supporters {
		_, targetExists := period.Entrant(support.Target)
		if !support.Player.Valid() || seen[support.Player] || !targetExists || support.Level < TournamentSupportLevel || support.Advancements < 0 || support.Advancements > TournamentAdvancementLimit || support.EarnedMana < 0 {
			return ErrConflict
		}
		seen[support.Player] = true
	}
	return nil
}

func (period TournamentPeriod) Entrant(player identity.PlayerID) (TournamentEntrant, bool) {
	for _, entrant := range period.Entrants {
		if entrant.PlayerID == player {
			return entrant, true
		}
	}
	return TournamentEntrant{}, false
}

const (
	QueueWaiting   = "WAITING"
	QueueMatched   = "MATCHED"
	QueueCancelled = "CANCELLED"
	QueueExpired   = "EXPIRED"
	QueueFinished  = "FINISHED"
	RoomPreparing  = "PREPARING"
	RoomSelecting  = "SELECTING"
	RoomFighting   = "FIGHTING"
	RoomSettled    = "SETTLED"
)

type CasualEntry struct {
	Identifier   ids.UUID         `json:"identifier"`
	WeekDay      int64            `json:"week_day"`
	Actor        AdmissionContext `json:"actor"`
	Status       string           `json:"status"`
	Room         ids.UUID         `json:"room"`
	AdmittedAt   time.Time        `json:"admitted_at"`
	ExpiresAt    time.Time        `json:"expires_at"`
	StateVersion int64            `json:"state_version"`
}

func (entry CasualEntry) Validate() error {
	validStatus := slices.Contains([]string{QueueWaiting, QueueMatched, QueueCancelled, QueueExpired, QueueFinished}, entry.Status)
	matched := entry.Status == QueueMatched || entry.Status == QueueFinished
	if entry.Identifier.IsZero() || !entry.Actor.PlayerID.Valid() || entry.Actor.ContextID.IsZero() || !validStatus || entry.AdmittedAt.IsZero() || !entry.ExpiresAt.Equal(entry.AdmittedAt.Add(CasualQueueLifetime)) || entry.StateVersion < 1 || matched == entry.Room.IsZero() {
		return ErrConflict
	}
	period := CasualPeriodAt(entry.AdmittedAt)
	if period.WeekDay != entry.WeekDay || !period.Open(entry.AdmittedAt) {
		return ErrConflict
	}
	return nil
}

const (
	RoundUnresolved = iota
	RoundFirstWin
	RoundSecondWin
	RoundBothEmpty
)

type TournamentRoom struct {
	NoticeVersion   int64                        `json:"notice_version"`
	SelectionHeroes [2]map[string]map[string]any `json:"selection_heroes"`
	SelectionPets   [2]map[string]map[string]any `json:"selection_pets"`
	Faces           [2]Face                      `json:"faces"`
	RoundResults    [SelectionTeamCount]int      `json:"round_results"`
	GenuineBattles  int                          `json:"genuine_battles"`
	SettledAt       time.Time                    `json:"settled_at"`
	Identifier      ids.UUID                     `json:"identifier"`
	Season          int64                        `json:"season"`
	CasualWeekDay   int64                        `json:"casual_week_day"`
	Casual          bool                         `json:"casual"`
	Stage           int                          `json:"stage"`
	Substage        int                          `json:"substage"`
	Contest         int                          `json:"contest"`
	Actors          [2]AdmissionContext          `json:"actors"`
	Ready           [2]bool                      `json:"ready"`
	Acknowledged    [2]int64                     `json:"acknowledged"`
	Selection       SelectionRoom                `json:"selection"`
	Status          string                       `json:"status"`
	StartsAt        time.Time                    `json:"starts_at"`
	ContentRevision string                       `json:"content_revision"`
	Attempts        []ids.UUID                   `json:"attempts"`
	Wins            [2]int                       `json:"wins"`
	Winner          identity.PlayerID            `json:"winner"`
	StateVersion    int64                        `json:"state_version"`
}

func (room TournamentRoom) Validate() error {

	if len(room.Attempts) != 0 && len(room.Attempts) != SelectionTeamCount || room.GenuineBattles < 0 || room.GenuineBattles > SelectionTeamCount {
		return ErrConflict
	}
	if (room.Status == RoomFighting || room.Status == RoomSettled) && !room.Selection.Complete() {
		return ErrConflict
	}
	if room.Status == RoomSettled && (room.SettledAt.IsZero() || room.SettledAt.Before(room.StartsAt) || len(room.Attempts) != SelectionTeamCount) {
		return ErrConflict
	}
	attempts := map[ids.UUID]bool{}
	for _, attempt := range room.Attempts {
		if !attempt.IsZero() && attempts[attempt] {
			return ErrConflict
		}
		attempts[attempt] = true
	}
	for _, result := range room.RoundResults {
		if result < RoundUnresolved || result > RoundBothEmpty {
			return ErrConflict
		}
	}
	if room.Identifier.IsZero() || room.StateVersion < 1 || len(room.ContentRevision) != 64 || room.StartsAt.IsZero() || room.Selection.Validate() != nil || room.Contest < 1 || room.Contest > 3 || len(room.Attempts) > SelectionTeamCount {
		return ErrConflict
	}
	if !slices.Contains([]string{RoomPreparing, RoomSelecting, RoomFighting, RoomSettled}, room.Status) || !room.Casual && (room.Season < 1 || room.Stage < 3 || room.Stage > 7) {
		return ErrConflict
	}
	for side, actor := range room.Actors {
		if _, err := actor.Actor(); err != nil {
			return ErrConflict
		}
		if len(room.Attempts) != 0 && room.Faces[side].Player != actor.PlayerID {
			return ErrConflict
		}
		if actor.PlayerID != room.Selection.Players[side] || actor.ContextID.IsZero() || room.Wins[side] < 0 || room.Wins[side] > 2 || room.Acknowledged[side] < 0 || room.Acknowledged[side] > room.StateVersion {
			return ErrConflict
		}
	}
	if room.Winner != 0 && !slices.Contains(room.Selection.Players[:], room.Winner) {
		return ErrConflict
	}
	return nil
}

type CasualSession struct {
	Period          CasualPeriod `json:"period"`
	ContentRevision string       `json:"content_revision"`
	Settled         bool         `json:"settled"`
	StateVersion    int64        `json:"state_version"`
}

func (session CasualSession) Validate() error {
	expected := CasualPeriodAt(session.Period.OpensAt)
	if session.Period != expected || session.StateVersion < 1 || len(session.ContentRevision) != 64 {
		return ErrConflict
	}
	return nil
}

func (room TournamentRoom) PlayedRounds() []int {
	rounds := []int{}
	wins := [2]int{}
	for index, result := range room.RoundResults {
		if wins[0] >= 2 || wins[1] >= 2 {
			break
		}
		if result == RoundUnresolved {
			break
		}
		if index < len(room.Attempts) && !room.Attempts[index].IsZero() {
			rounds = append(rounds, index)
		}
		if result == RoundFirstWin || result == RoundSecondWin {
			wins[result-1]++
		}
	}
	return rounds
}
