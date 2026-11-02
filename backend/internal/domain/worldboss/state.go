package worldboss

import (
	"time"

	"gxb.local/backend/v2/internal/domain/modes"
)

type Occurrence struct {
	LogicalServerID int64 `json:"logical_server_id"`
	Generation      int64 `json:"generation"`
	CurrentBoss     int64 `json:"current_boss"`
	Courage         int64 `json:"courage"`
	CourageDay      int64 `json:"courage_day"`
}

// Board names one boss's damage ranking inside one occurrence generation.
type Board struct {
	LogicalServerID int64
	Generation      int64
	BossID          int64
}

// Board is the ranking the current boss's damage counts toward.
func (o Occurrence) Board() Board {
	return Board{LogicalServerID: o.LogicalServerID, Generation: o.Generation, BossID: o.CurrentBoss}
}

func (o Occurrence) Validate() error {
	if o.LogicalServerID <= 0 || o.Generation <= 0 || o.CurrentBoss < FirstBossID || o.CurrentBoss > LastBossID || o.Courage < 0 {
		return ErrInvalid
	}
	return nil
}

// Accept clamps reported damage against the current boss and adds it to courage.
func (o *Occurrence) Accept(c Catalog, reported int64) (int64, error) {
	boss, ok := c.Boss(o.CurrentBoss)
	if !ok {
		return 0, ErrUnavailable
	}
	accepted := ClampDamage(o.Courage, boss.NeedBrave, reported)
	o.Courage += accepted
	return accepted, nil
}

// Defeat advances every crossed boss threshold and reports the defeated ids in
// order. The terminal boss starts a new occurrence at the cycle head.
func (o *Occurrence) Defeat(c Catalog) ([]int64, bool) {
	defeated := []int64{}
	for {
		boss, ok := c.Boss(o.CurrentBoss)
		if !ok || o.Courage < boss.NeedBrave {
			return defeated, false
		}
		defeated = append(defeated, boss.ID)
		if boss.NextID == 0 {
			o.Generation++
			o.CurrentBoss = FirstBossID
			o.Courage = 0
			return defeated, true
		}
		o.CurrentBoss = boss.NextID
	}
}

type Player struct {
	PlayerID      int64 `json:"player_id"`
	Day           int64 `json:"day"`
	Attempts      int64 `json:"attempts"`
	Bought        int64 `json:"bought"`
	SweptDay      int64 `json:"swept_day"`
	BestHit       int64 `json:"best_hit"`
	BestHitAt     int64 `json:"best_hit_at"`
	ChallengedDay int64 `json:"challenged_day"`
}

func (p Player) Validate() error {
	if p.PlayerID <= 0 || p.Day < 0 || p.Attempts < 0 || p.Bought < 0 || p.BestHit < 0 {
		return ErrInvalid
	}
	return nil
}

// Reset lazily applies the modes.Day counter reset.
func (p *Player) Reset(day int64) bool {
	if p.Day == day {
		return false
	}
	p.Day = day
	p.Attempts = AttemptsPerDay
	p.Bought = 0
	p.SweptDay = 0
	return true
}

func (p *Player) RecordHit(damage, at int64) {
	if damage > p.BestHit {
		p.BestHit = damage
		p.BestHitAt = at
	}
}

func (p Player) CanSweep() bool {
	return p.BestHit > 0 && p.SweptDay != p.Day && p.Attempts > 0
}

type Total struct {
	Board       Board
	PlayerID    int64 `json:"player_id"`
	Hurt        int64 `json:"hurt"`
	FirstHurtAt int64 `json:"first_hurt_at"`
}

func (t *Total) AddHurt(damage, at int64) {
	if t.Hurt == 0 && damage > 0 {
		t.FirstHurtAt = at
	}
	t.Hurt += damage
}

type RankEntry struct {
	PlayerID    int64
	TotalHurt   int64
	FirstHurtAt int64
}

type Attempt struct {
	ID              string `json:"attempt_id"`
	PlayerID        int64  `json:"player_id"`
	LogicalServerID int64  `json:"logical_server_id"`
	Generation      int64  `json:"generation"`
	CampaignID      int64  `json:"campaign_id"`
	Formation       string `json:"formation"`
	FrozenAt        int64  `json:"frozen_at"`
	Resolved        bool   `json:"resolved"`
	Damage          int64  `json:"damage"`
}

// Board is the ranking this attempt was frozen to, whatever the boss is now.
func (a Attempt) Board() Board {
	return Board{LogicalServerID: a.LogicalServerID, Generation: a.Generation, BossID: a.CampaignID}
}

func (a Attempt) Validate() error {
	if a.ID == "" || a.PlayerID <= 0 || a.LogicalServerID <= 0 || a.Generation <= 0 || a.CampaignID < FirstBossID || a.CampaignID > LastBossID {
		return ErrInvalid
	}
	return nil
}

// Matches reports whether the attempt still fights the current boss; otherwise
// its result is late and may only reach its own frozen board.
func (a Attempt) Matches(o Occurrence) bool {
	return a.Board() == o.Board()
}

// CourageDayFor is the most recent 22:00 GMT+8 update in modes.Day terms; a
// fresh occurrence starts caught up instead of receiving an owed older update.
func CourageDayFor(at time.Time) int64 {
	day := modes.Day(at)
	second := SecondOfDay(at)
	if second >= 18000 && second < CourageUpdateSecond {
		return day - 1
	}
	return day
}

// SecondOfDay is the GMT+8 seconds-since-midnight used by the source window.
func SecondOfDay(at time.Time) int64 {
	second := (at.Unix() + 8*3600) % SecondsPerDay
	if second < 0 {
		second += SecondsPerDay
	}
	return second
}

// StartAllowed reports whether a new START or sweep may begin; the 21:58-24:00
// window never blocks the result of a fight already started.
func StartAllowed(secondOfDay int64) bool {
	return secondOfDay >= 0 && secondOfDay < ClosedStartSecond
}
