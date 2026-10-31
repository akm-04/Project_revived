package illusion

import (
	"time"

	"gxb.local/backend/v2/internal/domain/modes"
)

type Phase string

const (
	PhaseWaiting    Phase = "WAITING"
	PhaseOpen       Phase = "OPEN"
	PhaseClosed     Phase = "CLOSED"
	PhaseSettlement Phase = "SETTLEMENT"
	PhaseRest       Phase = "REST"
)

// Occurrence is the one shared boss of a logical server. The cycle advances
// inside the row after the rest day, so a terminal campaign id never surfaces.
type Occurrence struct {
	LogicalServerID int64 `json:"logical_server_id"`
	CampaignID      int64 `json:"campaign_id"`
	PoolHP          int64 `json:"pool_hp"`
	PoolHurt        int64 `json:"pool_hurt"`
	OpenDay         int64 `json:"open_day"`
	SettledOpenDay  int64 `json:"settled_open_day"`
}

func NewOccurrence(serverID, campaignID, openDay int64) Occurrence {
	return Occurrence{LogicalServerID: serverID, CampaignID: campaignID, PoolHP: DefaultPoolHP, OpenDay: openDay}
}

func (o Occurrence) Validate() error {
	if o.LogicalServerID <= 0 || o.CampaignID < FirstCampaignID || o.CampaignID > LastCampaignID || o.PoolHP <= 0 || o.PoolHurt < 0 || o.PoolHurt > o.PoolHP || o.OpenDay < 0 || o.SettledOpenDay < 0 {
		return ErrInvalid
	}
	return nil
}

func (o Occurrence) RemainingPool() int64 {
	remaining := o.PoolHP - o.PoolHurt
	if remaining < 0 {
		return 0
	}
	return remaining
}

func (o Occurrence) Done() bool { return o.PoolHurt >= o.PoolHP }

// Accept clamps reported damage to the damage cap and pool left, then adds it
// to the shared pool.
func (o *Occurrence) Accept(reported int64) int64 {
	accepted := ClampDamage(o.PoolHP, o.PoolHurt, reported)
	o.PoolHurt += accepted
	return accepted
}

// PhaseAt reports where at sits in the occurrence's two-day cycle.
func (o Occurrence) PhaseAt(at time.Time) Phase {
	day := modes.Day(at)
	second := SecondOfDay(at)
	switch {
	case day < o.OpenDay:
		return PhaseWaiting
	case day == o.OpenDay:
		switch {
		case second < OpenSecond:
			return PhaseWaiting
		case second < CloseSecond:
			return PhaseOpen
		case second < SettleSecond:
			return PhaseClosed
		default:
			return PhaseSettlement
		}
	case day == o.OpenDay+RestDays:
		return PhaseRest
	default:
		return PhaseWaiting
	}
}

// CanStart refuses new chances and buys outside the open window.
func (o Occurrence) CanStart(at time.Time) bool {
	return o.PhaseAt(at) == PhaseOpen
}

// Settle marks the occurrence settled once. A late read after midnight still
// settles the occurrence it missed.
func (o *Occurrence) Settle(at time.Time) bool {
	if o.SettledOpenDay == o.OpenDay {
		return false
	}
	day := modes.Day(at)
	if day < o.OpenDay || day == o.OpenDay && SecondOfDay(at) < SettleSecond {
		return false
	}
	o.SettledOpenDay = o.OpenDay
	return true
}

// SettlementDue reports whether the 22:00 settlement of OpenDay is owed. A
// missed settlement is still owed during the rest day and until the next
// occurrence's 08:00 opening, after which Roll has moved the row on.
// shortcut: a settlement missed past that opening is lost with the single
// occurrence row, add occurrence history only if servers may be down two days.
func (o Occurrence) SettlementDue(at time.Time) bool {
	if o.SettledOpenDay == o.OpenDay {
		return false
	}
	day, second := modes.Day(at), SecondOfDay(at)
	switch {
	case day < o.OpenDay:
		return false
	case day == o.OpenDay:
		return second >= SettleSecond
	case day < o.OpenDay+CycleDays:
		return true
	default:
		return day == o.OpenDay+CycleDays && second < OpenSecond
	}
}

// Advance moves a settled occurrence to the next campaign after its rest day.
// The settled day stays recorded on the old row; the new OpenDay is a future
// instant, so a repeated reconcile cannot settle it early.
func (o *Occurrence) Advance(c Catalog) bool {
	next := c.NextCampaignID(o.CampaignID)
	if next == 0 {
		return false
	}
	o.SettledOpenDay = o.OpenDay
	o.CampaignID = next
	o.PoolHP = DefaultPoolHP
	o.PoolHurt = 0
	o.OpenDay += CycleDays
	return true
}

// Roll advances a missed cycle: the next campaign opens at 08:00 two days after
// the previous occurrence day, after one rest day.
func (o *Occurrence) Roll(c Catalog, at time.Time) bool {
	changed := false
	for {
		day := modes.Day(at)
		second := SecondOfDay(at)
		if day < o.OpenDay+CycleDays || day == o.OpenDay+CycleDays && second < OpenSecond {
			return changed
		}
		next := c.NextCampaignID(o.CampaignID)
		if next == 0 {
			return changed
		}
		o.CampaignID = next
		o.PoolHP = DefaultPoolHP
		o.PoolHurt = 0
		o.OpenDay += CycleDays
		o.SettledOpenDay = 0
		changed = true
	}
}

type Player struct {
	PlayerID int64 `json:"player_id"`
	Day      int64 `json:"day"`
	Chances  int64 `json:"chances"`
	Bought   int64 `json:"bought"`
	BestHit  int64 `json:"best_hit"`
	BestTime int64 `json:"best_time"`
}

func (p Player) Validate() error {
	if p.PlayerID <= 0 || p.Day < 0 || p.Chances < 0 || p.Bought < 0 || p.BestHit < 0 || p.BestTime < 0 {
		return ErrInvalid
	}
	return nil
}

// Reset lazily applies the modes.Day counter reset; the personal best is daily.
func (p *Player) Reset(day int64) bool {
	if p.Day == day {
		return false
	}
	p.Day = day
	p.Chances = FreeChances
	p.Bought = 0
	p.BestHit = 0
	p.BestTime = 0
	return true
}

func (p *Player) ConsumeChance() error {
	if p.Chances < 1 {
		return ErrRefused
	}
	p.Chances--
	return nil
}

// Buy purchases the next block of chances at buy_paradise_cost(bought+1) while
// vip.paradise_buy_num still allows it.
func (p *Player) Buy(c Catalog, vip int64) (int64, error) {
	if p.Bought >= c.BuyCap(vip) {
		return 0, ErrRefused
	}
	cost, ok := c.BuyCost(p.Bought + 1)
	if !ok {
		return 0, ErrRefused
	}
	p.Bought++
	p.Chances += c.ChancesPerBuy
	return cost, nil
}

// RecordHit keeps the best hit, replacing an equal hit with a shorter time.
func (p *Player) RecordHit(hurt, costTime int64) {
	if hurt <= 0 || costTime < 0 {
		return
	}
	if hurt > p.BestHit || hurt == p.BestHit && costTime < p.BestTime {
		p.BestHit = hurt
		p.BestTime = costTime
	}
}

type Result struct {
	PlayerID int64 `json:"player_id"`
	Hurt     int64 `json:"hurt"`
	CostTime int64 `json:"cost_time"`
}

// Attempt is frozen to the occurrence it started against; room_id stays zero
// for a solo chance.
type Attempt struct {
	ID              string `json:"attempt_id"`
	PlayerID        int64  `json:"player_id"`
	LogicalServerID int64  `json:"logical_server_id"`
	OpenDay         int64  `json:"open_day"`
	CampaignID      int64  `json:"campaign_id"`
	RoomID          int64  `json:"room_id"`
	Formation       string `json:"formation"`
	FrozenAt        int64  `json:"frozen_at"`
	Resolved        bool   `json:"resolved"`
	Damage          int64  `json:"damage"`
}

func (a Attempt) Validate() error {
	if a.ID == "" || a.PlayerID <= 0 || a.LogicalServerID <= 0 || a.OpenDay < 0 || a.CampaignID < FirstCampaignID || a.CampaignID > LastCampaignID {
		return ErrInvalid
	}
	return nil
}

// Matches reports whether the attempt still belongs to the current occurrence;
// a late result may credit only its own frozen results row.
func (a Attempt) Matches(o Occurrence) bool {
	return a.LogicalServerID == o.LogicalServerID && a.OpenDay == o.OpenDay && a.CampaignID == o.CampaignID
}

func SecondOfDay(at time.Time) int64 {
	second := (at.Unix() + 8*3600) % SecondsPerDay
	if second < 0 {
		second += SecondsPerDay
	}
	return second
}
