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
)

// EventOutcome is what the room pushes for one applied event.
type EventOutcome struct {
	Type          EventType
	DispatchLimit int64
}

// ApplyEvents applies the known events of a campaign in ascending event order,
// once each. Event ids outside 1-5 (the unread bonus-points row) do nothing.
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
				status.HP = min(status.HP+catalog.EventPercent, FullStatus)
			}
		})
	case EventRecoverMP:
		s.eachHero(func(status *HeroStatus) { status.MP = min(status.MP+catalog.EventPercent, FullStatus) })
	case EventReviveHero:
		s.eachHero(func(status *HeroStatus) {
			if status.HP == 0 {
				status.HP = catalog.EventPercent
			}
		})
	case EventIncreaseDispatch:
		s.DispatchLimit += catalog.EventDispatch
	}
}

func (s *RunState) eachHero(change func(*HeroStatus)) {
	for _, heroes := range s.HeroStatus {
		for heroKey, status := range heroes {
			change(&status)
			heroes[heroKey] = status
		}
	}
}
