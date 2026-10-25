package campaign

import "gxb.local/backend/v2/internal/domain/modes"

func Cloud(kind int64) bool { return kind >= 40 && kind <= 42 }

type TrialGroup struct {
	ID         int64   `json:"id"`
	Nodes      []int64 `json:"nodes"`
	DailyLimit int64   `json:"daily_limit"`
	Weekdays   []int64 `json:"weekdays"`
	NextID     int64   `json:"next_id"`
	LastID     int64   `json:"last_id"`
	ConsumeID  int64   `json:"consume_id"`
}

type DailyConsume struct {
	ID    int64 `json:"id"`
	Cost  int64 `json:"cost"`
	Limit int64 `json:"limit"`
	Value int64 `json:"value"`
}

func (c Catalog) Group(kind int64) (TrialGroup, bool) {
	for _, g := range c.TrialGroups {
		if g.ID == kind {
			return g, true
		}
	}
	return TrialGroup{}, false
}

// Prophecy follows the source successor cycle; its epoch anchor is private policy D124.
func (c Catalog) Prophecy(day int64) int64 {
	id := int64(16)
	for n := ((day % 6) + 6) % 6; n > 0; n-- {
		g, ok := c.Group(id)
		if !ok {
			return 0
		}
		id = g.NextID
	}
	return id
}

func (g TrialGroup) Scheduled(c Catalog, day int64) bool {
	if g.NextID != 0 {
		return c.Prophecy(day) == g.ID
	}
	weekday := ((day+3)%7+7)%7 + 1
	for _, w := range g.Weekdays {
		if w == weekday {
			return true
		}
	}
	return false
}

// TrialRemaining fails closed on a backwards game day instead of resetting future uses.
func (c Catalog) TrialRemaining(p Progress, g TrialGroup, day, buys int64) int64 {
	counter := p.TrialWins[g.ID]
	if counter.Period > day || buys < 0 || buys > 1 {
		return 0
	}
	return max(0, g.DailyLimit+buys-counter.In(day).Used)
}

func (c Catalog) TrialRow(p Progress, g TrialGroup, day, buys int64, functionOpen bool) map[string]any {
	return map[string]any{"id": g.ID, "left_times": c.TrialRemaining(p, g, day, buys), "is_open": flag(functionOpen && g.Scheduled(c, day)), "max_times": g.DailyLimit + buys, "last_id": g.LastID}
}

func (c Catalog) AdmitTrial(p Progress, kind, id, level, day, buys int64, functionOpen bool) (Node, error) {
	g, ok := c.Group(kind)
	n, found := c.Node(id)
	if !ok || !found || n.Type != kind {
		return Node{}, ErrInvalid
	}
	if !functionOpen || !g.Scheduled(c, day) || level < n.OpenLevel || id > g.LastID || c.TrialRemaining(p, g, day, buys) <= 0 {
		return Node{}, ErrRefused
	}
	for i, nid := range g.Nodes {
		if nid != id {
			continue
		}
		if kind >= 40 && i > 0 && p.State(g.Nodes[i-1]).Star == 0 {
			return Node{}, ErrRefused
		}
		return n, nil
	}
	return Node{}, ErrInvalid
}

func (c Catalog) AllowFaction(kind, tableID int64) bool {
	if kind < 11 || kind > 13 {
		return true
	}
	f, ok := c.HeroFactions[tableID]
	return ok && (kind == 11 && f != 3 || kind == 12 && f != 2 || kind == 13 && (f == 2 || f == 3))
}

func (p Progress) withTrialWin(kind, day int64) (Progress, error) {
	old := p.TrialWins[kind]
	if old.Period > day {
		return p, ErrRefused
	}
	wins := make(map[int64]modes.Counter, len(p.TrialWins)+1)
	for k, v := range p.TrialWins {
		wins[k] = v
	}
	counter := old.In(day)
	counter.Used++
	wins[kind] = counter
	p.TrialWins = wins
	return p, nil
}
