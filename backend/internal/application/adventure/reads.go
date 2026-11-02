package adventure

import (
	"context"
	"strconv"
	"time"

	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var eventTypes = [...]int64{d.EventDefense, d.EventFavor, d.EventShop, d.EventBattle, d.EventSummon, d.EventIllusion}

// List answers 2416 from canonical occurrences; absent event types are empty
// objects, so the stock model can rebuild every type on each reload.
func (s Mode) List(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	revision, _ := op.Policies.Get("content")
	catalog, err := s.Content.AdventureCatalogTx(c, s.Fresh, revision)
	if err != nil {
		return nil, err
	}
	if err = s.admit(c, s.Fresh, a, catalog, at); err != nil {
		return nil, err
	}
	return s.listBody(c, s.Fresh, a, at)
}

func (s Mode) listBody(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time) (map[string]any, error) {
	occurrences, err := s.Store.ListOccurrencesTx(c, q, a.LogicalServerID, a.PlayerID, at, listLimit)
	if err != nil {
		return nil, err
	}
	listed := make(map[int64]d.Occurrence, len(eventTypes))
	for _, occurrence := range occurrences {
		if !occurrence.Active(at) {
			continue
		}
		if _, seen := listed[occurrence.EventType]; !seen {
			listed[occurrence.EventType] = occurrence
		}
	}
	list := make(map[string]any, len(eventTypes))
	for _, eventType := range eventTypes {
		list[strconv.FormatInt(eventType, 10)] = map[string]any{}
	}
	for eventType, occurrence := range listed {
		list[strconv.FormatInt(eventType, 10)] = eventBody(occurrence)
	}
	return map[string]any{"adventure_list": map[string]any{"list": list}}, nil
}

func eventBody(occurrence d.Occurrence) map[string]any {
	return map[string]any{
		"table_id":     occurrence.EventType,
		"special_data": occurrence.SpecialData,
		"end_time":     occurrence.EndTime.Unix(),
		"extra_data":   int64(0),
	}
}

// Info answers 2417 with the event-shaped detail; an expired or finished
// occurrence refuses 35029 (C3).
func (s Mode) Info(c context.Context, a identity.ActorContext, tableID int64, op operation.Context) (map[string]any, error) {
	if _, known := d.Profile(tableID); !known {
		return nil, d.ErrInvalid
	}
	if tableID == d.EventDefense {
		return s.DefenseInfo(c, a, op)
	}
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	revision, _ := op.Policies.Get("content")
	catalog, err := s.Content.AdventureCatalogTx(c, s.Fresh, revision)
	if err != nil {
		return nil, err
	}
	if err = s.admit(c, s.Fresh, a, catalog, at); err != nil {
		return nil, err
	}
	occurrence, err := s.activeOccurrence(c, s.Fresh, a.PlayerID, tableID, at)
	if err != nil {
		return nil, err
	}
	detail, err := s.detail(c, a, catalog, occurrence, at, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{"detail": detail}, nil
}

func (s Mode) detail(c context.Context, a identity.ActorContext, catalog d.Catalog, occurrence d.Occurrence, at time.Time, op operation.Context) (map[string]any, error) {
	switch occurrence.EventType {
	case d.EventBattle:
		enemy, err := s.opponent(c, s.Fresh, a, catalog, eventOrdinal(op, "adventure.pvp.info/v1", occurrence.SourceKey))
		if err != nil {
			return nil, err
		}
		info, err := s.enemyInfo(c, enemy, at)
		if err != nil {
			return nil, err
		}
		return map[string]any{"enemy_infos": info}, nil
	case d.EventFavor:
		gifts := catalog.Limits.FavorGiftRandom
		if len(gifts) == 0 {
			return map[string]any{}, nil
		}
		return map[string]any{"gift_item": gifts[eventOrdinal(op, "adventure.favor.info/v1", occurrence.SourceKey)%uint64(len(gifts))]}, nil
	default:
		return map[string]any{}, nil
	}
}

// enemyInfo is the single 10004 opponent object the battle window draws: the
// player fields, the hero rows, the pet row and the robot flag.
func (s Mode) enemyInfo(c context.Context, enemy Opponent, at time.Time) (map[string]any, error) {
	info := map[string]any{"player_id": int64(0), "player_name": "", "lev": int64(0), "heroes": []any{}, "is_robot": int64(0)}
	if len(enemy.TemplateHeroes) > 0 {
		info["is_robot"] = int64(1)
		heroes := make([]any, 0, len(enemy.TemplateHeroes))
		for _, participant := range enemy.TemplateHeroes {
			if participant.TemplateParams != nil {
				heroes = append(heroes, participant.TemplateParams)
			}
		}
		info["heroes"] = heroes
		return info, nil
	}
	if !enemy.PlayerID.Valid() {
		return info, nil
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, enemy.PlayerID)
	if err != nil {
		return nil, err
	}
	if !found {
		return info, nil
	}
	info["player_id"], info["player_name"], info["lev"] = int64(profile.PlayerID), profile.Name, profile.Level
	info["avatar_id"], info["avatar_frame_id"] = profile.AvatarID, profile.AvatarFrameID
	roster, err := s.heroRows(c, s.Fresh, enemy.PlayerID, at)
	if err != nil {
		return nil, err
	}
	heroes := make([]any, 0, len(enemy.Heroes))
	for _, heroID := range enemy.Heroes {
		if row, ok := roster[strconv.FormatInt(heroID, 10)]; ok {
			heroes = append(heroes, row)
		}
	}
	info["heroes"] = heroes
	if enemy.PetID > 0 {
		pets, err := s.petRows(c, s.Fresh, enemy.PlayerID, at)
		if err != nil {
			return nil, err
		}
		if row, ok := pets[strconv.FormatInt(enemy.PetID, 10)]; ok {
			info["pet"] = row
		}
	}
	return info, nil
}

func (s Mode) opponent(c context.Context, q tx.Queryer, a identity.ActorContext, catalog d.Catalog, ordinal uint64) (Opponent, error) {
	enemy, found, err := s.Opponents.ArenaOpponentTx(c, q, a.PlayerID, catalog.Limits.PVPRankingSection, ordinal)
	if err != nil || found {
		return enemy, err
	}
	enemy, found, err = s.Opponents.RobotOpponentTx(c, q, ordinal)
	if err != nil {
		return Opponent{}, err
	}
	if !found {
		return Opponent{}, errNoOpponent
	}
	return enemy, nil
}
