package arena

import (
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const (
	StatusStarted  = "STARTED"
	StatusFighting = "FIGHTING"
	StatusSettled  = "SETTLED"
	StatusClosed   = "CLOSED"
)

// Fighter is one frozen lineup girl: the saved table id with the owner's
// season award at START.
type Fighter struct {
	TableID int64 `json:"table_id"`
	AddStar int64 `json:"add_star"`
	Awake   bool  `json:"is_awake"`
	Summon  bool  `json:"is_summon"`
}

type Outcome struct {
	Win        bool  `json:"win"`
	Forfeit    bool  `json:"forfeit"`
	StarBefore int64 `json:"star_before"`
	Star       int64 `json:"star"`
	Point      int64 `json:"point"`
	Coins      int64 `json:"coins"`
	Kills      int64 `json:"kills"`
	Damage     int64 `json:"damage"`
}

// Match is one Arena fight: START binds the offered opponent and freezes the
// defender lineup; FIGHT adds the attacker formation and one Combat attempt.
type Match struct {
	ID            ids.UUID
	Attacker      identity.PlayerID
	Defender      identity.PlayerID
	Season        int64
	Practice      bool
	DefenseHeroes []Fighter
	DefensePet    int64
	StartedAt     time.Time
	Formation     []Fighter
	AttackPet     int64
	AttemptID     ids.UUID
	Fingerprint   string
	Status        string
	Outcome       *Outcome
	SettledAt     *time.Time
	StateVersion  int64
}

// Lineup freezes a player's saved girls with their season awards; base maps a
// table id to its pre-awaken id (Character content).
func (p Player) Lineup(tableIDs []int64, base func(int64) int64) []Fighter {
	out := make([]Fighter, 0, len(tableIDs))
	for _, id := range tableIDs {
		a, _ := p.Award(base(id))
		out = append(out, Fighter{TableID: id, AddStar: a.AddStar, Awake: a.Awake, Summon: a.Summon})
	}
	return out
}

// ValidFormation is 1..5 distinct girls by table id; distinctness is by base
// id so a girl and her awakened form never fight twice.
func ValidFormation(tableIDs []int64, base func(int64) int64, exact bool) bool {
	if len(tableIDs) < 1 || len(tableIDs) > TeamSize || exact && len(tableIDs) != TeamSize {
		return false
	}
	seen := []int64{}
	for _, id := range tableIDs {
		b := base(id)
		if id <= 0 || slices.Contains(seen, b) {
			return false
		}
		seen = append(seen, b)
	}
	return true
}

// Abandoned is a started match without FIGHT for AbandonSeconds (user
// decision 2026-10-20: counts as a loss).
func (m Match) Abandoned(at time.Time) bool {
	return m.Status == StatusStarted && !at.Before(m.StartedAt.Add(AbandonSeconds*time.Second))
}

// Record is one retained fight seen from its owner; Win is the owner's result.
type Record struct {
	ID      int64
	Owner   identity.PlayerID
	MatchID ids.UUID
	Attack  bool
	Win     bool
	At      time.Time
}
