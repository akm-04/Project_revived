package builtin

import (
	"encoding/json"
	"errors"
)

type OccultCatalog struct {
	Schema            int               `json:"schema_version"`
	Contract          string            `json:"contract_id"`
	PolicyID          string            `json:"policy_id"`
	Policy            int               `json:"policy_version"`
	OpenAcademyLevel  int64             `json:"open_academy_level"`
	EnergyPerTicket   int64             `json:"energy_per_ticket"`
	TicketCap         int64             `json:"ticket_cap"`
	RoomCapacity      int64             `json:"room_capacity"`
	LevelBand         int64             `json:"level_band"`
	RoomSeconds       int64             `json:"room_seconds"`
	SelectionSeconds  int64             `json:"selection_seconds"`
	FightSeconds      int64             `json:"fight_seconds"`
	ReentrySeconds    int64             `json:"reentry_seconds"`
	DispatchHeroLimit int64             `json:"dispatch_hero_limit"`
	EventPercent      int64             `json:"event_percent"`
	EventDispatch     int64             `json:"event_dispatch"`
	SweepPercent      int64             `json:"sweep_percent"`
	Chapters          []json.RawMessage `json:"chapters"`
	Campaigns         []json.RawMessage `json:"campaigns"`
	AwakeningRoutes   []json.RawMessage `json:"awakening_routes"`
}

func (c OccultCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_OCCULT_V1" || c.PolicyID != "I9_OCCULT_POLICY_V1" || c.Policy != 1 {
		return errors.New("occult catalog")
	}
	if c.OpenAcademyLevel != 85 || c.EnergyPerTicket != 3000 || c.TicketCap != 2 || c.RoomCapacity != 3 || c.LevelBand != 5 || c.RoomSeconds != 3000 || c.SelectionSeconds != 60 || c.FightSeconds != 150 || c.ReentrySeconds != 120 {
		return errors.New("occult catalog profile")
	}
	if c.DispatchHeroLimit != 30 || c.EventPercent != 30 || c.EventDispatch != 3 || c.SweepPercent != 60 {
		return errors.New("occult catalog event profile")
	}
	if len(c.Chapters) != 6 || len(c.Campaigns) != 118 || len(c.AwakeningRoutes) != 22 {
		return errors.New("occult catalog census")
	}
	return nil
}
