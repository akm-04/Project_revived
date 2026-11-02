// Package occult owns the Sorcery War room run, its timers, stage state, hero
// status authority, rewards and best scores. Tickets live in I5 as scalars.
package occult

import (
	"errors"
	"slices"
)

const (
	ContractID    = "I9_OCCULT_V1"
	PolicyID      = "I9_OCCULT_POLICY_V1"
	PolicyVersion = 1

	FunctionID       = 67
	OpenAcademyLevel = 85
	EnergyPerTicket  = 3000
	TicketCap        = 2
	RoomCapacity     = 3
	LevelBand        = 5
	RoomSeconds      = 3000
	SelectionSeconds = 60
	FightSeconds     = 150
	ReentrySeconds   = 120
	DispatchLimit    = 30
	EventPercent     = 30
	EventDispatch    = 3
	SweepPercent     = 60

	MultiCampaignType  = 1
	SingleCampaignType = 2

	LockPlayerRank uint16 = 605
	LockRoomRank   uint16 = 607
)

var (
	ErrInvalid     = errors.New("occult invalid request")
	ErrRefused     = errors.New("occult refused")
	ErrUnavailable = errors.New("occult unavailable")
)

type Chapter struct {
	ID          int64    `json:"id"`
	TableID     int64    `json:"table_id"`
	ModelID     int64    `json:"model_id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	BuffID      int64    `json:"buff_id"`
	Mana        int64    `json:"mana"`
	ItemIDs     []int64  `json:"item_ids"`
	ItemRates   []string `json:"item_rates"`
	ItemDisplay []int64  `json:"item_display"`
}

type Campaign struct {
	ID           int64   `json:"id"`
	CampaignType int64   `json:"campaign_type"`
	ChapterID    int64   `json:"chapter_id"`
	Name         string  `json:"name"`
	Description  string  `json:"description"`
	StartPoint   bool    `json:"start_point"`
	UnlockIDs    []int64 `json:"unlock_ids"`
	FightIDs     []int64 `json:"fight_ids"`
	// StageTotalHP is the maximum aggregate monster HP of each fight. Absolute
	// HP, compiled from the campaign's battle data.
	StageTotalHP []int64 `json:"stage_total_hp"`
	EventID      int64   `json:"event_id"`
	Dialogue     string  `json:"dialogue"`
	X            string  `json:"x"`
	Y            string  `json:"y"`
	ModelID      int64   `json:"model_id"`
}

// Route is one stage-1 ordinary awakening mission fed by a chapter; the
// fragment item is the only thing the mode grants for it.
type Route struct {
	MissionID    int64 `json:"mission_id"`
	ChapterID    int64 `json:"chapter_id"`
	FragmentItem int64 `json:"fragment_item"`
}

type Catalog struct {
	Schema            int        `json:"schema_version"`
	Contract          string     `json:"contract_id"`
	PolicyID          string     `json:"policy_id"`
	PolicyVersion     int        `json:"policy_version"`
	OpenAcademyLevel  int64      `json:"open_academy_level"`
	EnergyPerTicket   int64      `json:"energy_per_ticket"`
	TicketCap         int64      `json:"ticket_cap"`
	RoomCapacity      int64      `json:"room_capacity"`
	LevelBand         int64      `json:"level_band"`
	RoomSeconds       int64      `json:"room_seconds"`
	SelectionSeconds  int64      `json:"selection_seconds"`
	FightSeconds      int64      `json:"fight_seconds"`
	ReentrySeconds    int64      `json:"reentry_seconds"`
	DispatchHeroLimit int64      `json:"dispatch_hero_limit"`
	EventPercent      int64      `json:"event_percent"`
	EventDispatch     int64      `json:"event_dispatch"`
	SurvivalParameter string     `json:"survival_parameter"`
	DispatchParameter string     `json:"dispatch_parameter"`
	ScheduleParameter string     `json:"schedule_parameter"`
	TimeParameter     string     `json:"time_parameter"`
	SweepPercent      int64      `json:"sweep_percent"`
	Chapters          []Chapter  `json:"chapters"`
	Campaigns         []Campaign `json:"campaigns"`
	AwakeningRoutes   []Route    `json:"awakening_routes"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != ContractID || c.PolicyID != PolicyID || c.PolicyVersion != PolicyVersion {
		return ErrUnavailable
	}
	sourceProfile := c.OpenAcademyLevel == OpenAcademyLevel && c.EnergyPerTicket == EnergyPerTicket && c.TicketCap == TicketCap && c.RoomCapacity == RoomCapacity && c.LevelBand == LevelBand
	timerProfile := c.RoomSeconds == RoomSeconds && c.SelectionSeconds == SelectionSeconds && c.FightSeconds == FightSeconds && c.ReentrySeconds == ReentrySeconds
	eventProfile := c.DispatchHeroLimit == DispatchLimit && c.EventPercent == EventPercent && c.EventDispatch == EventDispatch && c.SweepPercent == SweepPercent
	if !sourceProfile || !timerProfile || !eventProfile {
		return ErrUnavailable
	}
	if len(c.Chapters) != 6 || len(c.Campaigns) != 118 || len(c.AwakeningRoutes) != 22 {
		return ErrUnavailable
	}
	for index, chapter := range c.Chapters {
		if chapter.ID != int64(index+1) || len(chapter.ItemDisplay) == 0 {
			return ErrUnavailable
		}
	}
	for _, campaign := range c.Campaigns {
		if _, ok := c.Chapter(campaign.ChapterID); !ok || (campaign.CampaignType != MultiCampaignType && campaign.CampaignType != SingleCampaignType) {
			return ErrUnavailable
		}
		if len(campaign.StageTotalHP) != len(campaign.FightIDs) {
			return ErrUnavailable
		}
		for index, total := range campaign.StageTotalHP {
			if campaign.FightIDs[index] > 0 && total <= 0 {
				return ErrUnavailable
			}
		}
	}
	for _, route := range c.AwakeningRoutes {
		if _, ok := c.Chapter(route.ChapterID); !ok || route.MissionID <= 0 || route.FragmentItem <= 0 {
			return ErrUnavailable
		}
	}
	return nil
}

func (c Catalog) Chapter(id int64) (Chapter, bool) {
	index := slices.IndexFunc(c.Chapters, func(chapter Chapter) bool { return chapter.ID == id })
	if index < 0 {
		return Chapter{}, false
	}
	return c.Chapters[index], true
}

func (c Catalog) Campaign(id int64) (Campaign, bool) {
	index := slices.IndexFunc(c.Campaigns, func(campaign Campaign) bool { return campaign.ID == id })
	if index < 0 {
		return Campaign{}, false
	}
	return c.Campaigns[index], true
}

// RouteFor answers the awakening route of a mission only when the chapter being
// played is the chapter that feeds it.
func (c Catalog) RouteFor(missionID, chapterID int64) (Route, bool) {
	index := slices.IndexFunc(c.AwakeningRoutes, func(route Route) bool { return route.MissionID == missionID && route.ChapterID == chapterID })
	if index < 0 {
		return Route{}, false
	}
	return c.AwakeningRoutes[index], true
}
