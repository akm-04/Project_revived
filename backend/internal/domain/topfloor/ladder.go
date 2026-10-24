package topfloor

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const (
	CampaignType int64 = 3
	BattleID     int64 = 111001
	// Wire player ids are table_id + region*100000.
	RegionStride int64 = 100000
)

// Occupant is exactly one robot team or one player.
type Occupant struct {
	Robot  int64             `json:"robot,omitempty"`
	Player identity.PlayerID `json:"player,omitempty"`
}

func (o Occupant) Valid() bool {
	robot := o.Robot >= 1 && o.Robot <= RobotTeams && o.Player == 0
	player := o.Robot == 0 && o.Player.Valid()
	return robot || player
}

func (o Occupant) IsRobot() bool { return o.Robot > 0 }

// TableID is the source wire table_id: the robot team id, or the player's id within its region.
func (o Occupant) TableID() int64 {
	if o.IsRobot() {
		return o.Robot
	}
	return int64(o.Player) % RegionStride
}

func (o Occupant) String() string {
	if o.IsRobot() {
		return fmt.Sprintf("robot:%d", o.Robot)
	}
	return fmt.Sprintf("player:%d", o.Player)
}

type Ranked struct {
	Rank     int64
	Occupant Occupant
}

type Ladder struct {
	Server          identity.LogicalServerID
	ContentRevision string
	Size            int64
	SettledDay      int64
	StateVersion    int64
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func (l Ladder) Validate() error {
	if !l.Server.Valid() || len(l.ContentRevision) != 64 || l.Size < RobotTeams || l.StateVersion < 1 || l.CreatedAt.IsZero() || l.UpdatedAt.Before(l.CreatedAt) {
		return ErrConflict
	}
	return nil
}

// NewLadder seeds rank r with robot team RobotTeams+1-r (private policy) and
// treats every cutoff before creation as having nothing to settle.
func (c Catalog) NewLadder(server identity.LogicalServerID, revision string, at time.Time) (Ladder, []Ranked) {
	ranks := make([]Ranked, 0, RobotTeams)
	for r := int64(1); r <= RobotTeams; r++ {
		ranks = append(ranks, Ranked{Rank: r, Occupant: Occupant{Robot: RobotTeams + 1 - r}})
	}
	return Ladder{Server: server, ContentRevision: revision, Size: RobotTeams, SettledDay: c.LatestCutoffDay(at), StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}, ranks
}

// Unsettled reports the cutoff days the ladder still owes, oldest first.
func (c Catalog) Unsettled(l Ladder, at time.Time) []int64 {
	out := []int64{}
	for day := l.SettledDay + 1; day <= c.LatestCutoffDay(at); day++ {
		out = append(out, day)
	}
	return out
}

type Player struct {
	PlayerID        identity.PlayerID
	Server          identity.LogicalServerID
	ContentRevision string
	BestRank        int64
	TicketDay       int64
	TicketsLeft     int64
	Purchases       int64
	LastMatchAt     *time.Time
	RefreshCount    int64
	OfferedDay      int64
	Offered         []Occupant
	Defense         []int64
	DefensePet      int64
	DefenseSetAt    *time.Time
	Fights          int64
	Wins            int64
	StateVersion    int64
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func (p Player) Validate() error {
	if !p.PlayerID.Valid() || !p.Server.Valid() || int64(p.PlayerID)/RegionStride != int64(p.Server) || len(p.ContentRevision) != 64 || p.BestRank < 1 || p.TicketsLeft < 0 || p.Purchases < 0 ||
		p.RefreshCount < 0 || len(p.Offered) > 3 || len(p.Defense) > DefenseSlots || p.DefensePet < 0 || p.Fights < 0 || p.Wins < 0 || p.Wins > p.Fights || p.StateVersion < 1 || p.CreatedAt.IsZero() || p.UpdatedAt.Before(p.CreatedAt) {
		return ErrConflict
	}
	seen := map[int64]bool{}
	for _, id := range p.Defense {
		if id <= 0 || seen[id] {
			return ErrConflict
		}
		seen[id] = true
	}
	for _, o := range p.Offered {
		if !o.Valid() {
			return ErrConflict
		}
	}
	return nil
}

func (c Catalog) NewPlayer(pid identity.PlayerID, server identity.LogicalServerID, revision string, rank int64, at time.Time) Player {
	return Player{PlayerID: pid, Server: server, ContentRevision: revision, BestRank: rank, TicketDay: TicketDay(at), TicketsLeft: c.FreeTickets, OfferedDay: TicketDay(at), Defense: []int64{}, Offered: []Occupant{}, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
}

// Rolled applies the 05:00 GMT+8 daily ticket and purchase reset.
func (c Catalog) Rolled(p Player, at time.Time) Player {
	if day := TicketDay(at); day != p.TicketDay {
		p.TicketDay, p.TicketsLeft, p.Purchases = day, c.FreeTickets, 0
	}
	return p
}

// CoolingUntil is the end of the post-fight cooldown, which applies only while 0 < tickets < free tickets.
func (c Catalog) CoolingUntil(p Player) (time.Time, bool) {
	if p.LastMatchAt == nil || p.TicketsLeft <= 0 || p.TicketsLeft >= c.FreeTickets {
		return time.Time{}, false
	}
	return p.LastMatchAt.Add(time.Duration(c.CooldownSeconds) * time.Second), true
}

func (c Catalog) Cooling(p Player, at time.Time) bool {
	until, ok := c.CoolingUntil(p)
	return ok && at.Before(until)
}

// AdmitStart applies the source ticket, cooldown and settlement-freeze gates and consumes one ticket.
func (c Catalog) AdmitStart(p Player, at time.Time) (Player, error) {
	p = c.Rolled(p, at)
	if c.Frozen(at) || p.TicketsLeft <= 0 || c.Cooling(p, at) {
		return p, ErrRefused
	}
	stamp := at.UTC()
	p.TicketsLeft--
	p.LastMatchAt = &stamp
	return p, nil
}

// Buy restores tickets once they are exhausted, within the VIP purchase allowance.
func (c Catalog) Buy(p Player, privilege VIP, at time.Time) (Player, int64, error) {
	p = c.Rolled(p, at)
	if p.TicketsLeft > 0 || p.Purchases >= privilege.Purchases {
		return p, 0, ErrRefused
	}
	p.Purchases++
	p.TicketsLeft = c.BuyRestore
	return p, c.BuyCost(p.Purchases), nil
}

// ResetTimer clears an active cooldown for VIP arena_reset or a monthly card holder.
func (c Catalog) ResetTimer(p Player, privilege VIP, monthly bool, at time.Time) (Player, int64, error) {
	p = c.Rolled(p, at)
	allowed := privilege.Reset == 1 || monthly
	if !allowed || !c.Cooling(p, at) {
		return p, 0, ErrRefused
	}
	p.LastMatchAt = nil
	return p, c.ResetCost, nil
}

func ceilPercent(rank, hundredths int64) int64 {
	return (rank*hundredths + 99) / 100
}

// Bands are the three better-rank bands set by arena_match_param 0.98/0.5/0.3, best band last.
func (c Catalog) Bands(rank int64) [][2]int64 {
	bands := [][2]int64{}
	high := rank - 1
	for i := 2; i >= 0; i-- {
		low := min(ceilPercent(rank, c.MatchHundredths[i]), high)
		if low >= 1 && low <= high {
			bands = append(bands, [2]int64{low, high})
		}
		high = low - 1
	}
	return bands
}

// RevengeRange is the private-policy match range [ceil(0.3r), r-1].
func (c Catalog) RevengeRange(rank int64) (int64, int64) {
	return ceilPercent(rank, c.MatchHundredths[0]), rank - 1
}

// AvengeType is the source record avenge_type: 0 within range, 3 when the
// opponent now ranks lower, 4 when the opponent is beyond the match range.
func (c Catalog) AvengeType(selfRank, opponentRank int64) int64 {
	low, high := c.RevengeRange(selfRank)
	if opponentRank > high {
		return 3
	}
	if opponentRank < low {
		return 4
	}
	return 0
}

// OfferSeed deterministically orders a band for one player, ticket day and refresh.
func OfferSeed(server identity.LogicalServerID, player identity.PlayerID, day, refresh int64, band int) uint64 {
	sum := sha256.Sum256(fmt.Appendf(nil, "%s|%d|%d|%d|%d|%d", PolicyID, server, player, day, refresh, band))
	return binary.BigEndian.Uint64(sum[:8])
}

// OfferRanks lists candidate ranks per band in the private-policy probe order;
// callers take the first eligible occupant of each band, then nearest others.
func (c Catalog) OfferRanks(server identity.LogicalServerID, player identity.PlayerID, rank, day, refresh int64) [][]int64 {
	out := [][]int64{}
	for i, band := range c.Bands(rank) {
		size := band[1] - band[0] + 1
		start := int64(OfferSeed(server, player, day, refresh, i) % uint64(size))
		probe := make([]int64, 0, size)
		for k := int64(0); k < size; k++ {
			probe = append(probe, band[0]+(start+k)%size)
		}
		out = append(out, probe)
	}
	near := []int64{}
	for step := int64(1); len(near) < 3 && step < 8; step++ {
		for _, r := range []int64{rank - step, rank + step} {
			if r >= 1 {
				near = append(near, r)
			}
		}
	}
	return append(out, near)
}

// Outcome applies a resolved fight to the current ranks: the challenger takes the
// defender's rank only when it won (source is_win = star > 0) against a better rank.
type Outcome struct {
	Win              bool
	ChallengerBefore int64
	DefenderBefore   int64
	ChallengerAfter  int64
	DefenderAfter    int64
	BestBefore       int64
	BestAfter        int64
	AwardCrystal     int64
}

func (c Catalog) Decide(star int64, challengerRank, defenderRank, best int64) Outcome {
	o := Outcome{Win: star > 0, ChallengerBefore: challengerRank, DefenderBefore: defenderRank, ChallengerAfter: challengerRank, DefenderAfter: defenderRank, BestBefore: best, BestAfter: best}
	if o.Win && defenderRank < challengerRank {
		o.ChallengerAfter, o.DefenderAfter = defenderRank, challengerRank
	}
	if o.ChallengerAfter < best {
		o.BestAfter = o.ChallengerAfter
		o.AwardCrystal = c.BestRankReward(best, o.ChallengerAfter)
	}
	return o
}
