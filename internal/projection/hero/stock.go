package hero

import (
	"errors"
	"strconv"

	"gxb.local/backend/v2/internal/domain/character"
)

type RosterHeroView struct {
	Hero       character.Hero
	FumoLevels character.HeroFumoSlots
}

func StockHero(h character.Hero) (map[string]any, error) {
	if err := h.Validate(); err != nil {
		return nil, err
	}
	skills := []any{int64(1), int64(1), int64(1), int64(1), int64(1), int64(1)}
	zero6 := []any{int64(0), int64(0), int64(0), int64(0), int64(0), int64(0)}
	equips := make([]any, character.HeroEquipmentSlotCount)
	fumos := make([]any, character.HeroEquipmentSlotCount)
	for i, v := range h.Equipment {
		equips[i] = v
		fumos[i] = h.Fumo[i]
	}
	out := map[string]any{
		"partner_id": h.PartnerID, "table_id": h.TableID, "star": h.Star, "lev": h.Level, "exp": h.Exp, "color": h.Color,
		"skills": skills, "skill_ids": append([]any(nil), zero6...), "equips": equips, "fumos": fumos,
		"practice_attr": []any{h.Practice[0], h.Practice[1], h.Practice[2]},
	}
	if h.Kind == character.SuperHero {
		out["partner_type"] = int64(2)
	}
	if _, ok := out["spirit_item"]; ok {
		return nil, errors.New("hero projection: spirit_item must be omitted")
	}
	return out, nil
}
func StockHeroWithFumoLevels(h character.Hero, levels character.HeroFumoSlots) (map[string]any, error) {
	out, err := StockHero(h)
	if err != nil {
		return nil, err
	}
	if h.Kind != character.NormalHero {
		return out, nil
	}
	if err := levels.Validate(); err != nil {
		return nil, err
	}
	wireLevels := make([]any, character.HeroEquipmentSlotCount)
	for i, v := range levels {
		wireLevels[i] = v
	}
	out["fumo_levels"] = wireLevels
	return out, nil
}

func StockRosterView(sortType int64, views []RosterHeroView) (map[string]any, error) {
	if sortType < 0 || sortType > character.MaxSortType {
		return nil, errors.New("hero projection: invalid sort type")
	}
	rows := make(map[string]any, len(views))
	for _, view := range views {
		m, err := StockHeroWithFumoLevels(view.Hero, view.FumoLevels)
		if err != nil {
			return nil, err
		}
		rows[strconv.FormatInt(view.Hero.PartnerID, 10)] = m
	}
	return map[string]any{"sort_type": sortType, "heros": rows}, nil
}

func StockRoster(sortType int64, heroes []character.Hero) (map[string]any, error) {
	if sortType < 0 || sortType > character.MaxSortType {
		return nil, errors.New("hero projection: invalid sort type")
	}
	rows := make(map[string]any, len(heroes))
	for _, h := range heroes {
		m, err := StockHero(h)
		if err != nil {
			return nil, err
		}
		rows[strconv.FormatInt(h.PartnerID, 10)] = m
	}
	return map[string]any{"sort_type": sortType, "heros": rows}, nil
}
