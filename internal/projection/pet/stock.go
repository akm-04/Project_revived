package pet

import (
	"errors"

	"gxb.local/backend/v2/internal/domain/character"
)

func StockPrivate(p character.Pet, includePlayerID bool) (map[string]any, error) {
	if err := p.ValidatePersistent(); err != nil {
		return nil, err
	}
	out := map[string]any{
		"pet_id":        p.PetID,
		"table_id":      p.TableID,
		"star":          p.Star,
		"lev":           p.Level,
		"exp":           p.Exp,
		"color":         p.Color,
		"birthday":      p.Birthday,
		"is_show":       boolInt(p.IsShow),
		"is_born":       int64(0),
		"skills":        []any{p.Skills[0], p.Skills[1], p.Skills[2], p.Skills[3], p.Skills[4]},
		"equips":        []any{p.Equipment[0], p.Equipment[1], p.Equipment[2]},
		"fumos":         []any{p.Fumo[0], p.Fumo[1], p.Fumo[2]},
		"practice_attr": []any{p.Practice[0], p.Practice[1], p.Practice[2]},
	}
	if includePlayerID {
		out["player_id"] = int64(p.PlayerID)
	}
	if _, ok := out["active_style"]; ok {
		return nil, errors.New("pet projection: active_style must be omitted")
	}
	if _, ok := out["pet_styles"]; ok {
		return nil, errors.New("pet projection: pet_styles must be omitted")
	}
	return out, nil
}

func StockRoster(pets []character.Pet) (map[string]any, error) {
	rows := make([]any, 0, len(pets))
	for _, p := range pets {
		m, err := StockPrivate(p, true)
		if err != nil {
			return nil, err
		}
		rows = append(rows, m)
	}
	return map[string]any{"pets": rows}, nil
}

func boolInt(v bool) int64 {
	if v {
		return 1
	}
	return 0
}
