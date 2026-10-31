package builtin

import (
	"encoding/json"
	"errors"
)

type AdventureCatalog struct {
	Schema           int               `json:"schema_version"`
	Contract         string            `json:"contract_id"`
	PolicyID         string            `json:"policy_id"`
	PolicyVersion    int               `json:"policy_version"`
	OpenAcademyLevel int64             `json:"open_academy_level"`
	FantasyOpenLevel int64             `json:"fantasy_open_level"`
	Events           []json.RawMessage `json:"events"`
	Shop             []json.RawMessage `json:"shop"`
	Cards            []json.RawMessage `json:"cards"`
	Campaigns        []json.RawMessage `json:"campaigns"`
	Limits           json.RawMessage   `json:"limits"`
}

func (c AdventureCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_ADVENTURE_V1" || c.PolicyID != "I9_ADVENTURE_POLICY_V1" || c.PolicyVersion != 1 {
		return errors.New("adventure catalog")
	}
	if c.OpenAcademyLevel != 11 || c.FantasyOpenLevel != 65 {
		return errors.New("adventure catalog profile")
	}
	if len(c.Events) != 6 || len(c.Shop) != 7 || len(c.Cards) != 72 || len(c.Campaigns) != 19 {
		return errors.New("adventure catalog census")
	}
	type eventProfile struct {
		ID               int64 `json:"id"`
		Rate             int64 `json:"rate"`
		TimeLimitSeconds int64 `json:"time_limit_seconds"`
	}
	wantEvents := [...]eventProfile{
		{10001, 3, 10800}, {10002, 1, 3600}, {10003, 6, 3600},
		{10004, 7, 7200}, {10005, 4, 3600}, {10006, 10, 10800},
	}
	for index, raw := range c.Events {
		var event eventProfile
		if err := json.Unmarshal(raw, &event); err != nil || event != wantEvents[index] {
			return errors.New("adventure catalog event profile")
		}
	}
	var limits struct {
		DefenseTriesPerPosition int64 `json:"defense_tries_per_position"`
		DefenseLevelBand        int64 `json:"defense_level_band"`
		DefenseRoomCapacity     int64 `json:"defense_room_capacity"`
		PVPRankingSection       int64 `json:"pvp_ranking_section"`
		FavorLimit              int64 `json:"favor_limit"`
	}
	if err := json.Unmarshal(c.Limits, &limits); err != nil {
		return errors.New("adventure catalog limits")
	}
	if limits.DefenseTriesPerPosition != 3 || limits.DefenseLevelBand != 5 || limits.DefenseRoomCapacity != 6 || limits.PVPRankingSection != 3 || limits.FavorLimit != 2000 {
		return errors.New("adventure catalog limits profile")
	}
	return nil
}
