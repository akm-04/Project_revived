package occult

import "slices"

// EventType numbers follow the client's OccultEventType.
type EventType int64

const (
	EventAutoPass         EventType = 1
	EventRecoverHP        EventType = 2
	EventRecoverMP        EventType = 3
	EventReviveHero       EventType = 4
	EventIncreaseDispatch EventType = 5
	// EventExtraPoint is the creats_campaign bonus-score event (extra_integral).
	EventExtraPoint EventType = 6
)

// CampaignHero is one girl a campaign's accepted battles fielded.
type CampaignHero struct {
	PlayerID int64 `json:"player_id"`
	HeroID   int64 `json:"hero_id"`
}

// EventOutcome is what the room pushes for one applied event.
type EventOutcome struct {
	Type          EventType
	DispatchLimit int64
	ExtraPoints   int64
}

// prepareEvent is the event the client text runs when the level's Battle button
// is tapped: the auto pass and the room-wide dispatch expansion.
func prepareEvent(eventType EventType) bool {
	return eventType == EventAutoPass || eventType == EventIncreaseDispatch
}

// clearEvent is the event the client text grants after the level is cleared.
func clearEvent(eventType EventType) bool {
	return eventType == EventRecoverHP || eventType == EventRecoverMP || eventType == EventReviveHero || eventType == EventExtraPoint
}

// TriggerEvent fires a campaign's prepare event the first time the campaign is
// prepared; a clear-result event waits for ClearEvents.
// shortcut: trigger odds are unknown (D367 item 4), so the listed event fires.
func (s *RunState) TriggerEvent(catalog Catalog, campaign Campaign) []EventOutcome {
	if campaign.EventID == 0 || slices.Contains(s.EventsDone, campaign.ID) {
		return nil
	}
	eventType := EventType(campaign.EventID)
	if !prepareEvent(eventType) {
		return nil
	}
	s.EventsDone = append(s.EventsDone, campaign.ID)
	switch eventType {
	case EventAutoPass:
		stages := s.Stages[key(campaign.ID)]
		for index := range stages {
			stages[index].HP = 0
			stages[index].InBattle = 0
		}
	case EventIncreaseDispatch:
		s.DispatchLimit += catalog.EventDispatch
	}
	return []EventOutcome{{Type: eventType, DispatchLimit: s.DispatchLimit}}
}

// ClearEvents applies a campaign's clear-result event once its last stage fell,
// to the frozen team of the accepted final fight. Event 6 counts every girl the
// campaign's accepted battles fielded against the row's event_condition and is
// consumed with the clearance even when the count misses it. The caller records
// the same result's team with RecordCampaignHeroes first.
func (s *RunState) ClearEvents(catalog Catalog, campaign Campaign, finalTeam []CampaignHero) []EventOutcome {
	if campaign.EventID == 0 || slices.Contains(s.EventsDone, campaign.ID) {
		return nil
	}
	eventType := EventType(campaign.EventID)
	if !clearEvent(eventType) || !s.Cleared(campaign.ID) {
		return nil
	}
	s.EventsDone = append(s.EventsDone, campaign.ID)
	if eventType == EventExtraPoint {
		if int64(len(s.CampaignHeroes[key(campaign.ID)])) > campaign.EventCondition {
			return nil
		}
		s.ExtraPoints += campaign.ExtraIntegral
		s.Points += campaign.ExtraIntegral
		return []EventOutcome{{Type: EventExtraPoint, ExtraPoints: campaign.ExtraIntegral}}
	}
	s.applyTeamEvent(catalog, eventType, finalTeam)
	return []EventOutcome{{Type: eventType, DispatchLimit: s.DispatchLimit}}
}

// applyTeamEvent changes only the girls the clear-result event names.
func (s *RunState) applyTeamEvent(catalog Catalog, eventType EventType, finalTeam []CampaignHero) {
	for _, hero := range finalTeam {
		statuses := s.HeroStatus[key(hero.PlayerID)]
		status, recorded := statuses[key(hero.HeroID)]
		if !recorded {
			continue
		}
		switch eventType {
		case EventRecoverHP:
			if status.HP > 0 {
				status.HP = min(status.HP+percentOf(status.LimitHP, catalog.EventPercent), status.LimitHP)
			}
		case EventRecoverMP:
			status.MP = min(status.MP+percentOf(MaxEnergy, catalog.EventPercent), MaxEnergy)
		case EventReviveHero:
			if status.HP == 0 {
				status.HP = percentOf(status.LimitHP, catalog.EventPercent)
			}
		}
		statuses[key(hero.HeroID)] = status
	}
}

// RecordCampaignHeroes adds the frozen team of one accepted fight to the
// campaign's all-battles participant set, once per girl.
func (s *RunState) RecordCampaignHeroes(campaignID int64, heroes []CampaignHero) {
	participants := s.CampaignHeroes[key(campaignID)]
	recorded := make(map[CampaignHero]bool, len(participants)+len(heroes))
	for _, hero := range participants {
		recorded[hero] = true
	}
	for _, hero := range heroes {
		if hero.HeroID <= 0 || recorded[hero] {
			continue
		}
		recorded[hero] = true
		participants = append(participants, hero)
	}
	if len(participants) == 0 {
		return
	}
	if s.CampaignHeroes == nil {
		s.CampaignHeroes = map[string][]CampaignHero{}
	}
	s.CampaignHeroes[key(campaignID)] = participants
}

func percentOf(limit, percent int64) int64 { return limit * percent / 100 }
