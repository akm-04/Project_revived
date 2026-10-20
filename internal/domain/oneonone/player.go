package oneonone

import (
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// CompetitionID names the single competition over all logical servers (C5C policy, user decision 2026-10-19).
const CompetitionID = "GLOBAL"

// Player ids are allocated per logical server from server*100000+1.
const regionStride int64 = 100000

// Competition is the serialization root (lock 602) and the transition markers.
type Competition struct {
	ID              string
	ContentRevision string
	MasterCount     int64
	SeniorCount     int64
	SettledThrough  int64
	OpenedThrough   int64
	ClosedThrough   int64
	StateVersion    int64
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func (r Competition) Validate() error {
	if r.ID != CompetitionID || len(r.ContentRevision) != 64 || r.MasterCount < 0 || r.SeniorCount < 0 || r.ClosedThrough > r.OpenedThrough || r.StateVersion < 1 || r.CreatedAt.IsZero() {
		return ErrConflict
	}
	return nil
}

// NewCompetition owes nothing that happened before it existed.
func (c Catalog) NewCompetition(revision string, at time.Time) Competition {
	week := c.LatestPromotion(at)
	return Competition{ID: CompetitionID, ContentRevision: revision, SettledThrough: c.LatestSettlement(at), OpenedThrough: week, ClosedThrough: week,
		StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
}

type Team struct {
	Heroes []int64 `json:"heroes"`
	Pet    int64   `json:"pet"`
}

// ValidTeams checks the source team shape: count, 1..5 heroes, heroes and pets unique across teams.
func ValidTeams(teams []Team, count int64) bool {
	if int64(len(teams)) != count {
		return false
	}
	heroes, pets := map[int64]bool{}, map[int64]bool{}
	for _, t := range teams {
		if len(t.Heroes) < 1 || len(t.Heroes) > TeamSize || t.Pet < 0 || t.Pet > 0 && pets[t.Pet] {
			return false
		}
		pets[t.Pet] = t.Pet > 0
		for _, h := range t.Heroes {
			if h <= 0 || heroes[h] {
				return false
			}
			heroes[h] = true
		}
	}
	return true
}

// Position is a player's place: Master/Senior hold a slot, Juniors rank by points.
type Position struct {
	Level    int64     `json:"level"`
	Slot     int64     `json:"slot"`
	Points   int64     `json:"points"`
	PointsAt time.Time `json:"points_at"`
}

type Player struct {
	PlayerID        identity.PlayerID
	Server          identity.LogicalServerID
	ContentRevision string
	Position
	TriesDay        int64
	TriesLeft       int64
	Purchases       int64
	LastFightAt     *time.Time
	Teams           []Team
	OfferedDay      int64
	Refreshes       int64
	Offered         []identity.PlayerID
	Mode            int64
	PromotionWeek   int64
	Candidates      []identity.PlayerID
	Opponent        identity.PlayerID
	Challenges      int64
	PromotionWins   int64
	LastPromotionAt *time.Time
	WinStreak       int64
	StateVersion    int64
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func (p Player) Validate() error {
	slotted := p.Level == LevelMaster || p.Level == LevelSenior
	known := slotted || p.Level >= LevelJunior1 && p.Level <= LevelJunior3
	if !p.PlayerID.Valid() || !p.Server.Valid() || int64(p.PlayerID)/regionStride != int64(p.Server) || len(p.ContentRevision) != 64 || !known ||
		slotted != (p.Slot > 0) || p.Points < 0 || p.PointsAt.IsZero() || p.TriesLeft < 0 || p.Purchases < 0 || p.Refreshes < 0 || p.WinStreak < 0 ||
		(p.Mode != ModeNormal && p.Mode != ModePromotion) || (p.Mode == ModePromotion) != (len(p.Candidates) > 0) || p.Challenges < 0 || p.PromotionWins < 0 ||
		p.Opponent != 0 && !slices.Contains(p.Candidates, p.Opponent) || p.StateVersion < 1 || p.CreatedAt.IsZero() {
		return ErrConflict
	}
	return nil
}

// NewPlayer enters Junior 3 with the legend_point_convert minimum (C5C policy).
func (c Catalog) NewPlayer(pid identity.PlayerID, server identity.LogicalServerID, revision string, at time.Time) Player {
	return Player{PlayerID: pid, Server: server, ContentRevision: revision, Position: Position{Level: c.JuniorLevel(c.EntryPoints), Points: c.EntryPoints, PointsAt: at.UTC()},
		TriesDay: TriesDay(at), TriesLeft: c.FreeTries, OfferedDay: TriesDay(at), Teams: []Team{}, Offered: []identity.PlayerID{}, Mode: ModeNormal,
		Candidates: []identity.PlayerID{}, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
}

func (c Catalog) Rolled(p Player, at time.Time) Player {
	if day := TriesDay(at); day != p.TriesDay {
		p.TriesDay, p.TriesLeft, p.Purchases = day, c.FreeTries, 0
	}
	if day := TriesDay(at); day != p.OfferedDay {
		p.OfferedDay, p.Refreshes, p.Offered = day, 0, []identity.PlayerID{}
	}
	return p
}

func (c Catalog) CoolingUntil(p Player) time.Time {
	if p.LastFightAt == nil {
		return time.Time{}
	}
	return p.LastFightAt.Add(time.Duration(c.Level(p.Level).CooldownSeconds) * time.Second)
}

func (c Catalog) PromotionCoolingUntil(p Player) time.Time {
	if p.LastPromotionAt == nil {
		return time.Time{}
	}
	return p.LastPromotionAt.Add(time.Duration(c.PromotionCooldownSeconds) * time.Second)
}

// Admit applies the opening hours, tries and cooldown (normal) or chances and
// promotion cooldown (promotion), consuming one try or one chance.
func (c Catalog) Admit(p Player, at time.Time) (Player, error) {
	p = c.Rolled(p, at)
	if !c.Open(at) {
		return p, ErrClosedHours
	}
	stamp := at.UTC()
	if p.Mode == ModePromotion {
		if p.Challenges >= c.PromotionChances || at.Before(c.PromotionCoolingUntil(p)) {
			return p, ErrRefused
		}
		p.LastPromotionAt = &stamp
		return p, nil
	}
	if p.TriesLeft <= 0 || at.Before(c.CoolingUntil(p)) {
		return p, ErrRefused
	}
	p.TriesLeft--
	p.LastFightAt = &stamp
	return p, nil
}

// Buy restores the free tries once exhausted, within the VIP num_top allowance; it also ends the cooldown.
func (c Catalog) Buy(p Player, privilege VIP, at time.Time) (Player, int64, error) {
	p = c.Rolled(p, at)
	if p.TriesLeft > 0 || p.Purchases >= privilege.Purchases {
		return p, 0, ErrRefused
	}
	p.Purchases++
	p.TriesLeft = c.FreeTries
	p.LastFightAt = nil
	return p, c.BuyCost(p.Purchases), nil
}

// ResetTimer clears an active cooldown for VIP top_reset or a monthly card holder.
func (c Catalog) ResetTimer(p Player, privilege VIP, monthly bool, at time.Time) (Player, int64, error) {
	p = c.Rolled(p, at)
	if !(privilege.Reset == 1 || monthly) || !at.Before(c.CoolingUntil(p)) {
		return p, 0, ErrRefused
	}
	p.LastFightAt = nil
	return p, c.ResetCost, nil
}
