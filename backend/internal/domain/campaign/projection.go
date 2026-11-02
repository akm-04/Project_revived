package campaign

// ChapterInfo is the eight-field cursor block of worldMapEvent_ and worldMapLoginEvent_ (C2).
type ChapterInfo struct {
	NormalChapterID  int64
	NormalCampaignID int64
	SuperChapterID   int64
	SuperCampaignID  int64
	NormalStars      int64
	NormalBonusID    int64
	SuperStars       int64
	SuperBonusID     int64
}

// Fields is the wire block of the eight cursor fields.
func (i ChapterInfo) Fields() map[string]any {
	return map[string]any{"normal_chapter_id": i.NormalChapterID, "normal_campaign_id": i.NormalCampaignID, "super_chapter_id": i.SuperChapterID,
		"super_campaign_id": i.SuperCampaignID, "normal_stars": i.NormalStars, "normal_bonus_id": i.NormalBonusID, "super_stars": i.SuperStars, "super_bonus_id": i.SuperBonusID}
}

// Row is one wire campaign row; is_partner_drop exists on Normal rows only.
func (c Catalog) Row(p Progress, id, day int64) map[string]any {
	n, _ := c.Node(id)
	s := p.State(id)
	row := map[string]any{"campaign_id": id, "star": s.Star, "daily_limit": c.Remaining(p, n, day), "reset_count": s.Resets.In(day).Used}
	if n.Type == Normal {
		row["is_partner_drop"] = flag(s.PartnerDrop)
	}
	return row
}

func flag(b bool) int64 {
	if b {
		return 1
	}
	return 0
}

func (c Catalog) rows(p Progress, ids []int64, day int64) []any {
	out := make([]any, 0, len(ids))
	for _, id := range ids {
		out = append(out, c.Row(p, id, day))
	}
	return out
}

// Info places each cursor on the last opened node of its chain and sums the
// cumulative stars of that type; a closed Super chain answers zeros (V1).
func (c Catalog) Info(p Progress, superOpen bool) ChapterInfo {
	info := ChapterInfo{NormalBonusID: c.BonusCursor(p, Normal), SuperBonusID: c.BonusCursor(p, Super)}
	info.NormalCampaignID, info.NormalChapterID, info.NormalStars = c.cursor(p, Normal, superOpen)
	info.SuperCampaignID, info.SuperChapterID, info.SuperStars = c.cursor(p, Super, superOpen)
	return info
}

func (c Catalog) cursor(p Progress, kind int64, superOpen bool) (int64, int64, int64) {
	opened := c.Opened(p, kind, superOpen)
	if len(opened) == 0 {
		return 0, 0, 0
	}
	frontier, _ := c.Node(opened[len(opened)-1])
	return frontier.ID, frontier.Chapter, c.TotalStars(p, kind)
}

// World is the one projection behind 112 and MID1 detail["112"] (C2, F13): the
// chapter_info fields are written nested and at the top level for both readers.
func (c Catalog) World(p Progress, superOpen bool, day int64) map[string]any {
	info := c.Info(p, superOpen).Fields()
	body := map[string]any{"normal": c.rows(p, c.Opened(p, Normal, superOpen), day), "super": c.rows(p, c.Opened(p, Super, superOpen), day),
		"challenge": c.rows(p, c.Opened(p, Challenge, superOpen), day), "chapter_events": c.ChapterEvents(p), "chapter_info": info}
	for key, value := range info {
		body[key] = value
	}
	return body
}
