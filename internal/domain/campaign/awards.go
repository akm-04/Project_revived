package campaign

// BonusCursor treats zero as a new player's first tier. Unknown nonzero
// successors remain exhausted; the source's terminal successor has no row.
func (c Catalog) BonusCursor(p Progress, kind int64) int64 {
	id := p.NormalBonusID
	if kind == Super {
		id = p.SuperBonusID
	}
	if id != 0 {
		return id
	}
	for _, b := range c.StarBonus {
		if b.Type == kind {
			return b.ID
		}
	}
	return 0
}

func (c Catalog) TotalStars(p Progress, kind int64) int64 {
	var stars int64
	for _, id := range c.Chain(kind) {
		n, _ := c.Node(id)
		if n.MapType != 1 {
			stars += p.State(id).Star
		}
	}
	return stars
}

func (c Catalog) ClaimBonus(p Progress, kind int64) (Progress, StarBonus, error) {
	if kind != Normal && kind != Super {
		return p, StarBonus{}, ErrInvalid
	}
	// Legacy content lacks source map sizes; it can be read but cannot qualify new bonus claims.
	for _, n := range c.Nodes {
		if n.Type == kind && n.MapType == 0 {
			return p, StarBonus{}, ErrUnavailable
		}
	}
	id := c.BonusCursor(p, kind)
	for _, b := range c.StarBonus {
		if b.ID != id || b.Type != kind {
			continue
		}
		if c.TotalStars(p, kind) < b.StarNum {
			return p, StarBonus{}, ErrRefused
		}
		if kind == Normal {
			p.NormalBonusID = b.NextID
		} else {
			p.SuperBonusID = b.NextID
		}
		return p, b, nil
	}
	return p, StarBonus{}, ErrRefused
}

// ChapterEvent is the stock MapWindow/ChapterGachaWindow projection. D115:
// each cleared indexed condition earns one corresponding fixed gift.
func (c Catalog) ChapterEvent(p Progress, chapter int64) map[string]any {
	for _, ch := range c.Chapters {
		if ch.ID != chapter || ch.EventType != 1 {
			continue
		}
		claimed, earned := p.ChapterClaims[ch.ID], int64(0)
		for _, condition := range ch.EventCondition {
			if p.State(condition).Star == 0 {
				break
			}
			earned++
		}
		left := max(0, min(earned, ch.EventOpenTimes)-claimed)
		return map[string]any{"chapter_id": ch.ID, "is_open": flag(left > 0), "open_times": claimed, "left_times": left, "val": 0, "cost": 0}
	}
	return nil
}

func (c Catalog) ChapterEvents(p Progress) []any {
	rows := []any{}
	for _, ch := range c.Chapters {
		if event := c.ChapterEvent(p, ch.ID); event != nil {
			rows = append(rows, event)
		}
	}
	return rows
}

func (c Catalog) ClaimChapter(p Progress, chapter int64) (Progress, [][2]int64, error) {
	e := c.ChapterEvent(p, chapter)
	if e == nil {
		return p, nil, ErrInvalid
	}
	if e["left_times"].(int64) <= 0 {
		return p, nil, ErrRefused
	}
	for _, ch := range c.Chapters {
		if ch.ID != chapter {
			continue
		}
		claimed := p.ChapterClaims[chapter]
		if claimed < 0 || claimed >= int64(len(ch.EventGift)) {
			return p, nil, ErrUnavailable
		}
		for _, g := range c.ChapterGifts {
			if g.ID != ch.EventGift[claimed] {
				continue
			}
			counts := make(map[int64]int64, len(p.ChapterClaims)+1)
			for id, count := range p.ChapterClaims {
				counts[id] = count
			}
			counts[chapter] = claimed + 1
			p.ChapterClaims = counts
			return p, g.Items, nil
		}
	}
	return p, nil, ErrUnavailable
}
