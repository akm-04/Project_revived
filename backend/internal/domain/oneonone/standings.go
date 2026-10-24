package oneonone

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"sort"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Standing is one competitor as the ordering needs it.
type Standing struct {
	Player     identity.PlayerID
	Server     identity.LogicalServerID
	HasDefense bool
	Position
}

// Ranked carries the global rank (slot for Master/Senior, split bound plus
// points order for Juniors), the rank inside the group and the server rank.
type Ranked struct {
	Standing
	Global     int64
	InGroup    int64
	ServerRank int64
}

func less(a, b Standing) bool {
	ga, gb := Group(a.Level), Group(b.Level)
	if ga != gb {
		return ga < gb
	}
	if ga != LevelJunior1 {
		return a.Slot < b.Slot
	}
	if a.Points != b.Points {
		return a.Points > b.Points
	}
	if !a.PointsAt.Equal(b.PointsAt) {
		return a.PointsAt.Before(b.PointsAt)
	}
	return a.Player < b.Player
}

// Rank orders every competitor globally.
func (c Catalog) Rank(all []Standing) []Ranked {
	sorted := append([]Standing(nil), all...)
	sort.Slice(sorted, func(i, j int) bool { return less(sorted[i], sorted[j]) })
	out := make([]Ranked, 0, len(sorted))
	servers := map[identity.LogicalServerID]int64{}
	var juniors int64
	for _, s := range sorted {
		r := Ranked{Standing: s, Global: s.Slot, InGroup: s.Slot}
		switch Group(s.Level) {
		case LevelSenior:
			r.InGroup = s.Slot - c.MasterSlots()
		case LevelJunior1:
			juniors++
			r.Global, r.InGroup = c.SplitBound+juniors, juniors
		}
		servers[s.Server]++
		r.ServerRank = servers[s.Server]
		out = append(out, r)
	}
	return out
}

func Find(ranked []Ranked, player identity.PlayerID) (Ranked, bool) {
	for _, r := range ranked {
		if r.Player == player {
			return r, true
		}
	}
	return Ranked{}, false
}

func ceilPercent(rank, hundredths int64) int64 {
	return (rank*hundredths + 99) / 100
}

// Bands are three better in-group rank bands from legend_match_param (the
// "new" parameters at global rank <= legend_match_new_rank), best band last.
func (c Catalog) Bands(inGroup, global int64) [][2]int64 {
	params := c.MatchHundredths
	if global <= c.MatchNewRank {
		params = c.MatchNewHundredths
	}
	bands := [][2]int64{}
	high := ceilPercent(inGroup, params[3]) - 1
	for i := 2; i >= 0; i-- {
		low := min(ceilPercent(inGroup, params[i]), high)
		if low >= 1 && low <= high {
			bands = append(bands, [2]int64{low, high})
		}
		high = low - 1
	}
	return bands
}

// Seed deterministically orders a probe for one player and purpose.
func Seed(player identity.PlayerID, parts ...int64) uint64 {
	sum := sha256.Sum256(fmt.Appendf(nil, "%s|%d|%v", PolicyID, player, parts))
	return binary.BigEndian.Uint64(sum[:8])
}

// Offer picks up to legend_match_num better-ranked members of the player's own
// group with a saved defense, one per band, probing each band from a
// deterministic start (C5C policy). The top of a group has no opponent.
func (c Catalog) Offer(ranked []Ranked, self identity.PlayerID, day, refresh int64) []identity.PlayerID {
	me, ok := Find(ranked, self)
	if !ok {
		return []identity.PlayerID{}
	}
	members := map[int64]Ranked{}
	for _, r := range ranked {
		if Group(r.Level) == Group(me.Level) {
			members[r.InGroup] = r
		}
	}
	out := []identity.PlayerID{}
	for i, band := range c.Bands(me.InGroup, me.Global) {
		size := band[1] - band[0] + 1
		start := int64(Seed(self, day, refresh, int64(i)) % uint64(size))
		for k := int64(0); k < size && int64(len(out)) < c.Candidates; k++ {
			r, ok := members[band[0]+(start+k)%size]
			if ok && r.HasDefense && r.Player != self {
				out = append(out, r.Player)
				break
			}
		}
	}
	return out
}

// Opening is the promotion opening: vacancy moves and promotion entrants.
type Opening struct {
	Moves    map[identity.PlayerID]Position
	Entrants map[identity.PlayerID][]identity.PlayerID
}

// OpenPromotion fills empty Master then Senior slots with the best eligible
// players of the group below (user decision 2026-10-19), keeps each group
// contiguous, and puts the remaining eligible players into promotion mode with
// candidates from the full upper group's bottom pool (source challenge_num /
// match_num and LEGEND_ARENA_RULE_TEXT).
func (c Catalog) OpenPromotion(ranked []Ranked, week int64) Opening {
	o := Opening{Moves: map[identity.PlayerID]Position{}, Entrants: map[identity.PlayerID][]identity.PlayerID{}}
	var masters, seniors, juniors []Standing
	for _, r := range ranked {
		switch {
		case r.Level == LevelMaster:
			masters = append(masters, r.Standing)
		case r.Level == LevelSenior:
			seniors = append(seniors, r.Standing)
		case r.Level == LevelJunior1:
			juniors = append(juniors, r.Standing)
		}
	}
	masters, seniors, upperS := c.fill(o, masters, seniors, LevelMaster, 0)
	seniors, _, upperJ := c.fill(o, seniors, juniors, LevelSenior, c.MasterSlots())
	c.enter(o, upperS, masters, c.Level(LevelMaster).PromotionPool, week)
	c.enter(o, upperJ, seniors, c.Level(LevelSenior).PromotionPool, week)
	return o
}

// fill moves the best eligible lower players into the upper group's vacancies
// and returns the upper group, the remaining lower group and the eligible
// players left over when the upper group is full.
func (c Catalog) fill(o Opening, upper, lower []Standing, level, firstSlot int64) ([]Standing, []Standing, []Standing) {
	capacity := c.Level(level).Bound - firstSlot
	eligible := lower[:min(int64(len(lower)), c.Level(level+1).PromotionEntrants)]
	moved := min(max(capacity-int64(len(upper)), 0), int64(len(eligible)))
	for i, s := range eligible[:moved] {
		s.Level, s.Slot = level, firstSlot+int64(len(upper))+1
		o.Moves[s.Player] = s.Position
		upper = append(upper, s)
		eligible[i] = s
	}
	remaining := lower[moved:]
	if level+1 == LevelSenior {
		for i := range remaining {
			if slot := c.MasterSlots() + int64(i) + 1; remaining[i].Slot != slot {
				remaining[i].Slot = slot
				o.Moves[remaining[i].Player] = remaining[i].Position
			}
		}
	}
	if int64(len(upper)) < capacity {
		return upper, remaining, nil
	}
	return upper, remaining, eligible[moved:]
}

func (c Catalog) enter(o Opening, entrants, upper []Standing, pool, week int64) {
	if len(upper) == 0 {
		return
	}
	bottom := upper[max(int64(len(upper))-pool, 0):]
	for _, e := range entrants {
		size := int64(len(bottom))
		start := int64(Seed(e.Player, week) % uint64(size))
		picks := []identity.PlayerID{}
		for k := int64(0); k < size && int64(len(picks)) < c.Candidates; k++ {
			picks = append(picks, bottom[(start+k)%size].Player)
		}
		o.Entrants[e.Player] = picks
	}
}

// Award is one competitor's settlement entitlement.
type Award struct {
	Ranked
	Reward *Reward
	Title  *Title
}

// Awards maps a settlement snapshot to legend_reward rows by server rank and,
// on Sundays, titles by global rank (C5C policy cadence).
func (c Catalog) Awards(ranked []Ranked, day int64) []Award {
	out := []Award{}
	for _, r := range ranked {
		a := Award{Ranked: r}
		if reward, ok := c.RewardFor(r.ServerRank); ok {
			a.Reward = &reward
		}
		if title, ok := c.TitleFor(r.Global); ok && Weekday(day) == 7 {
			a.Title = &title
		}
		out = append(out, a)
	}
	return out
}
