package hero

import (
	"errors"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
)

type QualifiedSkinView struct {
	ModelID   int64
	ExpiresAt *time.Time
}

type QualifiedLIVEView struct {
	ModelID int64
	IsShow  bool
}

type AppearanceView struct {
	OwnerStateVersion int64
	CurrentSkinID     int64
	IllusionSkinID    int64
	Skins             []QualifiedSkinView
	LIVE              []QualifiedLIVEView
}

type RosterHeroView struct {
	Hero       character.Hero
	FumoLevels character.HeroFumoSlots
	Appearance AppearanceView
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
		"is_like":       h.IsLike,
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

func applyAppearance(out map[string]any, h character.Hero, appearance AppearanceView) error {
	if out == nil || appearance.OwnerStateVersion <= 0 || appearance.OwnerStateVersion != h.StateVersion || appearance.CurrentSkinID < 0 || appearance.IllusionSkinID < -1 {
		return errors.New("hero projection: invalid effective appearance")
	}
	skins := make(map[string]any, len(appearance.Skins))
	for _, skin := range appearance.Skins {
		value := int64(-1)
		if skin.ExpiresAt != nil {
			value = skin.ExpiresAt.UTC().Unix()
			if value <= 0 {
				return errors.New("hero projection: invalid timed skin expiry")
			}
		}
		skins[strconv.FormatInt(skin.ModelID, 10)] = value
	}
	out["current_skin_id"] = appearance.CurrentSkinID
	out["illusion_skin_id"] = appearance.IllusionSkinID
	out["skin_ids"] = skins
	if h.Kind == character.NormalHero {
		models := make([]string, 0, len(appearance.LIVE))
		states := make([]string, 0, len(appearance.LIVE))
		for _, live := range appearance.LIVE {
			models = append(models, strconv.FormatInt(live.ModelID, 10))
			if live.IsShow {
				states = append(states, "1")
			} else {
				states = append(states, "0")
			}
		}
		out["unlocked_dynamic_card"] = strings.Join(models, "|")
		out["dynamic_card_state"] = strings.Join(states, "|")
	}
	return nil
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
		if err := applyAppearance(m, view.Hero, view.Appearance); err != nil {
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
