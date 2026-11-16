package illusion

import (
	"fmt"
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
	OpenDay         int64 `json:"open_day"`
	SettledOpenDay  int64 `json:"settled_open_day"`
}

func NewOccurrence(serverID, campaignID, openDay int64) Occurrence {
	return Occurrence{LogicalServerID: serverID, CampaignID: campaignID, OpenDay: openDay}
}

func (o Occurrence) Validate() error {
	if o.LogicalServerID <= 0 || o.CampaignID < FirstCampaignID || o.CampaignID > LastCampaignID || o.OpenDay < 0 || o.SettledOpenDay < 0 {
		return ErrInvalid
	}
	return nil
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

// BoardDay is the day the rank board shows: the settled board stays frozen until
// the next occurrence opens and clears it.
func (o Occurrence) BoardDay(at time.Time) int64 {
	if o.SettledOpenDay > 0 && o.PhaseAt(at) == PhaseWaiting {
		return o.SettledOpenDay
	}
	return o.OpenDay
}

// CanStart refuses new chances and buys outside the open window.
func (o Occurrence) CanStart(at time.Time) bool {
	return o.PhaseAt(at) == PhaseOpen
}

// SettlementDue reports whether the 22:00 settlement of OpenDay is owed. Only
// the settlement advances the row, so downtime delays rewards and never skips them.
func (o Occurrence) SettlementDue(at time.Time) bool {
	day := modes.Day(at)
	return day > o.OpenDay || day == o.OpenDay && SecondOfDay(at) >= SettleSecond
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
	o.OpenDay += CycleDays
	return true
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
	Killed   bool  `json:"killed"`
}

// Record keeps only the personal best (D428): a kill beats any loss, between
// kills the shorter time wins, and between losses the higher damage, then the
// shorter time.
func (r *Result) Record(hurt, costTime int64, killed bool) {
	better := hurt > r.Hurt || hurt == r.Hurt && costTime < r.CostTime
	if killed && r.Killed {
		better = costTime < r.CostTime
	}
	if killed != r.Killed {
		better = killed
	}
	if better {
		r.Hurt, r.CostTime, r.Killed = hurt, costTime, killed
	}
}

// AttemptGeneration is the occurrence an attempt's frozen Combat START names;
// a late result credits only this occurrence.
type AttemptGeneration struct {
	LogicalServerID int64 `json:"logical_server_id"`
	OpenDay         int64 `json:"open_day"`
	CampaignID      int64 `json:"campaign_id"`
}

func (g AttemptGeneration) Validate() error {
	if g.LogicalServerID <= 0 || g.OpenDay < 0 || g.CampaignID < FirstCampaignID || g.CampaignID > LastCampaignID {
		return ErrInvalid
	}
	return nil
}

// Reference is the Combat generation_ref a solo START freezes.
func (g AttemptGeneration) Reference() string {
	return fmt.Sprintf("ILLUSION/%d/%d/%d", g.LogicalServerID, g.OpenDay, g.CampaignID)
}

// Matches reports whether the frozen generation still belongs to the current
// occurrence.
func (g AttemptGeneration) Matches(o Occurrence) bool {
	return g.LogicalServerID == o.LogicalServerID && g.OpenDay == o.OpenDay && g.CampaignID == o.CampaignID
}

// ParseAttemptGeneration reads a solo START's generation_ref.
func ParseAttemptGeneration(reference string) (AttemptGeneration, bool) {
	var g AttemptGeneration
	read, err := fmt.Sscanf(reference, "ILLUSION/%d/%d/%d", &g.LogicalServerID, &g.OpenDay, &g.CampaignID)
	if err != nil || read != 3 || g.Validate() != nil || g.Reference() != reference {
		return AttemptGeneration{}, false
	}
	return g, true
}

func SecondOfDay(at time.Time) int64 {
	second := (at.Unix() + 8*3600) % SecondsPerDay
	if second < 0 {
		second += SecondsPerDay
	}
	return second
}
