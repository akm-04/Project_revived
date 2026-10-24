package librarylocal

import "time"

// ApplyGift calculates the state effect only. The application service must
// compose the qualified I5 debit and this effect in the same transaction.
func (f HeroFacts) ApplyGift(template TemplateRule, gift GiftRule, now time.Time) (HeroFacts, bool, error) {
	if err := f.Validate(); err != nil {
		return HeroFacts{}, false, err
	}
	if !template.DialogEnabled || template.TableID <= 0 || template.RelationshipSourceID <= 0 {
		return HeroFacts{}, false, ErrUnqualified
	}
	if gift.ItemID <= 0 {
		return HeroFacts{}, false, ErrInvalidGift
	}
	if gift.Ring {
		if gift.ItemID != 50001112 {
			return HeroFacts{}, false, ErrUnqualified
		}
		if f.Married {
			return f, false, nil
		}
		if f.Favor != FavorLimit {
			return HeroFacts{}, false, ErrMarriageGate
		}
		f.Married = true
	} else {
		if gift.BaseFavor <= 0 || gift.BaseFavor > FavorLimit || gift.Category <= 0 {
			return HeroFacts{}, false, ErrInvalidGift
		}
		gain := gift.BaseFavor
		if gift.Category == template.GiftLikeType {
			gain += 5
		} else if gift.Category == template.GiftDislikeType {
			gain -= 3
		}
		if gain < 0 {
			gain = 0
		}
		f.Favor += gain
		if f.Favor > FavorLimit {
			f.Favor = FavorLimit
		}
	}
	f.StateVersion++
	f.UpdatedAt = now
	return f, true, f.Validate()
}

// FavorBonusBP follows the selected client stages; it is a raw Library input.
func (f HeroFacts) FavorBonusBP() (int64, error) {
	if err := f.Validate(); err != nil {
		return 0, err
	}
	switch {
	case f.Married:
		return 500, nil
	case f.Favor <= 100:
		return 0, nil
	case f.Favor <= 300:
		return 50, nil
	case f.Favor <= 800:
		return 100, nil
	default:
		return 300, nil
	}
}
