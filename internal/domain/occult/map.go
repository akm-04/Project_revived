package occult

import "slices"

// RoomCampaigns are the campaigns one room plays: its chapter and type.
func (c Catalog) RoomCampaigns(chapterID, campaignType int64) []Campaign {
	var campaigns []Campaign
	for _, campaign := range c.Campaigns {
		if campaign.ChapterID == chapterID && campaign.CampaignType == campaignType {
			campaigns = append(campaigns, campaign)
		}
	}
	return campaigns
}

// Final is the chapter's last fight campaign: not a start point, unlocking nothing.
func (c Campaign) Final() bool { return !c.StartPoint && len(c.UnlockIDs) == 0 }

// BindRoom creates the monster stages of every fight campaign of the room.
// shortcut: stage HP is percent of the stage, 100 per fight, because a solo
// fight is simulated by the client and the server holds no monster stats.
func (s *RunState) BindRoom(catalog Catalog) error {
	for _, campaign := range catalog.RoomCampaigns(s.ChapterID, s.CampaignType) {
		if len(campaign.FightIDs) == 0 {
			continue
		}
		totals := make([]int64, len(campaign.FightIDs))
		for index := range totals {
			totals[index] = FullStatus
		}
		if err := s.BindStages(campaign.ID, totals); err != nil {
			return err
		}
	}
	return nil
}

// Reachable reports whether a campaign can be entered: a start point always,
// any other once a campaign unlocking it is cleared.
func (s RunState) Reachable(catalog Catalog, campaign Campaign) bool {
	if campaign.StartPoint {
		return true
	}
	for _, other := range catalog.RoomCampaigns(s.ChapterID, s.CampaignType) {
		if slices.Contains(other.UnlockIDs, campaign.ID) && (other.StartPoint || s.Cleared(other.ID)) {
			return true
		}
	}
	return false
}

func (s RunState) ChapterCleared(catalog Catalog) bool {
	for _, campaign := range catalog.RoomCampaigns(s.ChapterID, s.CampaignType) {
		if campaign.Final() {
			return s.Cleared(campaign.ID)
		}
	}
	return false
}

func (s RunState) StagesOf(campaignID int64) []StageState { return s.Stages[key(campaignID)] }

// ChangePosition moves a player to one of the room's start points.
func (s *RunState) ChangePosition(catalog Catalog, playerID, campaignID int64) error {
	for _, campaign := range catalog.RoomCampaigns(s.ChapterID, s.CampaignType) {
		if campaign.ID != campaignID || !campaign.StartPoint {
			continue
		}
		if s.StayPositions == nil {
			s.StayPositions = map[string]int64{}
		}
		s.StayPositions[key(playerID)] = campaignID
		return nil
	}
	return ErrRefused
}

func (s RunState) StayPosition(playerID int64) int64 { return s.StayPositions[key(playerID)] }

// RoutesOf are the awakening routes the chapter feeds.
func (c Catalog) RoutesOf(chapterID int64) []Route {
	var routes []Route
	for _, route := range c.AwakeningRoutes {
		if route.ChapterID == chapterID {
			routes = append(routes, route)
		}
	}
	return routes
}

// HeroCounts are the dispatched and dead heroes of a player, for hero_stat.
func (s RunState) HeroCounts(playerID int64) (dispatched, dead int64) {
	for _, status := range s.HeroStatus[key(playerID)] {
		dispatched++
		if status.HP == 0 {
			dead++
		}
	}
	return dispatched, dead
}

// Seat puts a player on the room's first start point.
func (s *RunState) Seat(catalog Catalog, playerID int64) error {
	for _, campaign := range catalog.RoomCampaigns(s.ChapterID, s.CampaignType) {
		if campaign.StartPoint {
			return s.ChangePosition(catalog, playerID, campaign.ID)
		}
	}
	return ErrInvalid
}
