package march

import "gxb.local/backend/v2/internal/domain/character"

// HeroColorLevels[c] is the minimum Hero level at which a girl can hold colour
// c. A promotion into colour c requires every ordinary equipment position of
// each lower colour (characterhero.PowerUpHero), and an item cannot be equipped
// below its source required level (characterhero.EquipItem). Colour 1 has no
// promotion history.
type HeroColorLevels [17]int64

// HeroColorLevelsFromColorRequiredLevels derives the cumulative table from the
// highest ordinary-equipment required level of each colour.
func HeroColorLevelsFromColorRequiredLevels(requiredByColor map[int64]int64) (HeroColorLevels, error) {
	var out HeroColorLevels
	highest := int64(0)
	for color := int64(1); color <= 16; color++ {
		required, present := requiredByColor[color]
		if present && (required < 0 || required > character.MaxHeroLevel) {
			return out, ErrInvalid
		}
		out[color] = highest
		if required > highest {
			highest = required
		}
	}
	return out, nil
}

// CoherentColor returns the highest colour not above color whose level rule the
// fitted level allows. It never raises the colour and never goes below floor.
func CoherentColor(levels HeroColorLevels, level, color, floor int64) (int64, error) {
	if level < 1 || level > character.MaxHeroLevel || color < 1 || color > 16 || floor < 1 || floor > color {
		return 0, ErrInvalid
	}
	for candidate := color; candidate > floor; candidate-- {
		required := levels[candidate]
		if required < 0 || required > character.MaxHeroLevel {
			return 0, ErrInvalid
		}
		if required <= level {
			return candidate, nil
		}
	}
	return floor, nil
}
