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

// EventOutcome is what the room pushes for one applied event.
type EventOutcome struct {
	Type          EventType
	DispatchLimit int64
	ExtraPoints   int64
}

// ApplyEvents applies the status events of a campaign in ascending event order,
// once each. Event 6 is scored by TriggerEvent because it needs the campaign row.
// shortcut: trigger odds are unknown (D367 item 4), so every listed event fires.
func (s *RunState) ApplyEvents(catalog Catalog, campaignID int64, eventIDs []int64) []EventOutcome {
	ordered := slices.Clone(eventIDs)
	slices.Sort(ordered)
	ordered = slices.Compact(ordered)
	var outcomes []EventOutcome
	for _, eventID := range ordered {
		eventType := EventType(eventID)
		if eventType < EventAutoPass || eventType > EventIncreaseDispatch {
			continue
		}
		s.applyEvent(catalog, campaignID, eventType)
		outcomes = append(outcomes, EventOutcome{Type: eventType, DispatchLimit: s.DispatchLimit})
	}
	return outcomes
}

func (s *RunState) applyEvent(catalog Catalog, campaignID int64, eventType EventType) {
	switch eventType {
	case EventAutoPass:
		stages := s.Stages[key(campaignID)]
		for index := range stages {
			stages[index].HP = 0
			stages[index].InBattle = 0
		}
	case EventRecoverHP:
		s.eachHero(func(status *HeroStatus) {
			if status.HP > 0 {
				status.HP = min(status.HP+percentOf(status.LimitHP, catalog.EventPercent), status.LimitHP)
			}
		})
	case EventRecoverMP:
		s.eachHero(func(status *HeroStatus) {
			status.MP = min(status.MP+percentOf(MaxEnergy, catalog.EventPercent), MaxEnergy)
		})
	case EventReviveHero:
		s.eachHero(func(status *HeroStatus) {
			if status.HP == 0 {
				status.HP = percentOf(status.LimitHP, catalog.EventPercent)
			}
		})
	case EventIncreaseDispatch:
		s.DispatchLimit += catalog.EventDispatch
	}
}

func percentOf(limit, percent int64) int64 { return limit * percent / 100 }

func (s *RunState) eachHero(change func(*HeroStatus)) {
	for _, heroes := range s.HeroStatus {
		for heroKey, status := range heroes {
			change(&status)
			heroes[heroKey] = status
		}
	}
}

// TriggerEvent fires a campaign's event the first time the campaign is
// prepared; a repeated prepare of the same campaign changes nothing. Event 6
// credits its extra_integral; the configured event_condition is not used by any
// client path, so its gate is UNKNOWN and not applied.
func (s *RunState) TriggerEvent(catalog Catalog, campaign Campaign) []EventOutcome {
	if campaign.EventID == 0 || slices.Contains(s.EventsDone, campaign.ID) {
		return nil
	}
	s.EventsDone = append(s.EventsDone, campaign.ID)
	if EventType(campaign.EventID) == EventExtraPoint {
		if campaign.ExtraIntegral <= 0 {
			return nil
		}
		s.ExtraPoints += campaign.ExtraIntegral
		return []EventOutcome{{Type: EventExtraPoint, ExtraPoints: campaign.ExtraIntegral}}
	}
	return s.ApplyEvents(catalog, campaign.ID, []int64{campaign.EventID})
}
