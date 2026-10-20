package arena

import (
	"encoding/binary"
	"hash/fnv"
	"slices"
	"time"
)

// roll is a deterministic draw in [0, n) for the given identity parts (C5D
// policy: replayable without stored randomness).
func roll(n int64, parts ...int64) int64 {
	h := fnv.New64a()
	for _, p := range parts {
		_ = binary.Write(h, binary.BigEndian, p)
	}
	return int64(h.Sum64() % uint64(n))
}

// Refill fills empty mission slots once mission_time + 72000 s has passed
// (RegionArenaWindow countdown); a new player starts with full slots.
func (c Catalog) Refill(p Player, at time.Time, initial bool) Player {
	due := !at.Before(p.MissionTime.Add(time.Duration(c.MissionRefillSeconds) * time.Second))
	if len(p.Missions) >= Missions || !(initial || due) {
		return p
	}
	slots := append([]MissionSlot{}, p.Missions...)
	for len(slots) < Missions {
		p.MissionDraws++
		slots = append(slots, MissionSlot{MissionID: c.draw(slots, int64(p.PlayerID), p.MissionDraws)})
	}
	p.Missions, p.MissionTime = slots, at
	return p
}

// draw picks a region_mission row by weight among ids not already held (C5D policy).
func (c Catalog) draw(held []MissionSlot, parts ...int64) int64 {
	free := []MissionRule{}
	var total int64
	for _, m := range c.Missions {
		if !slices.ContainsFunc(held, func(s MissionSlot) bool { return s.MissionID == m.MissionID }) {
			free, total = append(free, m), total+m.Weight
		}
	}
	point := roll(total, parts...)
	for _, m := range free {
		if point < m.Weight {
			return m.MissionID
		}
		point -= m.Weight
	}
	return free[len(free)-1].MissionID
}

// Progress applies one ranked attack: kills and damage accumulate, the
// streak mission follows the current attack win streak, wins accumulate.
func (c Catalog) Progress(p Player, kills, damage int64, win bool) Player {
	slots := append([]MissionSlot{}, p.Missions...)
	for i, s := range slots {
		rule, ok := c.Mission(s.MissionID)
		if !ok || s.Complete {
			continue
		}
		switch rule.Kind {
		case MissionKills:
			s.Current += kills
		case MissionDamage:
			s.Current += damage
		case MissionStreak:
			s.Current = p.KeepWin
		case MissionWins:
			if win {
				s.Current++
			}
		}
		s.Current = min(s.Current, rule.Target)
		s.Complete = s.Current >= rule.Target
		slots[i] = s
	}
	p.Missions = slots
	return p
}

func (p Player) withoutMission(id int64, at time.Time) (Player, MissionSlot, bool) {
	i := slices.IndexFunc(p.Missions, func(s MissionSlot) bool { return s.MissionID == id })
	if i < 0 {
		return p, MissionSlot{}, false
	}
	slot := p.Missions[i]
	p.Missions = slices.Delete(append([]MissionSlot{}, p.Missions...), i, i+1)
	p.MissionTime = at
	return p, slot, true
}

// Claim empties a completed mission slot for its king_coin reward.
func (c Catalog) Claim(p Player, id int64, at time.Time) (Player, int64, error) {
	next, slot, ok := p.withoutMission(id, at)
	rule, known := c.Mission(id)
	if !ok || !known || !slot.Complete {
		return p, 0, ErrRefused
	}
	return next, rule.KingCoin, nil
}

// GiveUp empties an incomplete mission slot (REGION_AREAN_GIVE_UP_MISSION_TIP).
func (c Catalog) GiveUp(p Player, id int64, at time.Time) (Player, error) {
	next, slot, ok := p.withoutMission(id, at)
	if !ok || slot.Complete {
		return p, ErrRefused
	}
	return next, nil
}

// Girl is what the Character owner knows about one base table id for an
// exchange: the template and the player's strongest owned copy.
type Girl struct {
	Known       bool
	Super       bool
	Owned       bool
	Star        int64
	InitialStar int64
	CanAwaken   bool
	Awakened    bool
}

// MaxStars is xyd.MAX_STAR_LEVEL or, for super girls, SUPER_HERO_TOTAL_STARS.
func MaxStars(super bool) int64 {
	if super {
		return maxSuperStars
	}
	return maxNormalStars
}

// Exchange applies one RegionArenaHeroShop purchase and returns its king_coin
// cost; the award is keyed by the base table id.
func (c Catalog) Exchange(p Player, exchangeType, baseTableID int64, g Girl) (Player, Award, int64, error) {
	cost, ok := c.ExchangeCost(exchangeType, p.ExchangeTimes[max(0, min(exchangeType, 3)-1)])
	award, index := p.Award(baseTableID)
	available := g.Owned || award.Summon
	if !ok || !g.Known {
		return p, award, 0, ErrInvalid
	}
	star := g.InitialStar
	if g.Owned {
		star = g.Star
	}
	maxStar := MaxStars(g.Super)
	switch exchangeType {
	case ExchangeStar:
		if !available || star+award.AddStar >= maxStar {
			return p, award, 0, ErrRefused
		}
		award.AddStar++
	case ExchangeAwaken:
		if !available || !g.CanAwaken || g.Awakened || award.Awake {
			return p, award, 0, ErrRefused
		}
		award.Awake = true
	case ExchangeSummon:
		if available {
			return p, award, 0, ErrRefused
		}
		award.Summon = true
	}
	p = p.withAward(award, index)
	p.ExchangeTimes[exchangeType-1]++
	return p, award, cost, nil
}

// Template is one hero template's lineage: Base is the pre-awaken (origin) id.
type Template struct {
	Base        int64
	Super       bool
	Awakened    bool
	InitialStar int64
}

// Templates maps every hero template id of a content revision to its lineage.
type Templates map[int64]Template

func (t Templates) Base(id int64) int64 {
	if x, ok := t[id]; ok {
		return x.Base
	}
	return id
}

// CanAwaken reports whether the base girl has an awakened template.
func (t Templates) CanAwaken(base int64) bool {
	for _, x := range t {
		if x.Base == base && x.Awakened {
			return true
		}
	}
	return false
}
