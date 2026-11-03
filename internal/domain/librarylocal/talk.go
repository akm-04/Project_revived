package librarylocal

import "time"

// RaiseFavor applies one settled intimacy reward with the live clamp. A hero at
// the cap keeps its favor and the caller records no improvement.
func (f HeroFacts) RaiseFavor(amount int64, now time.Time) (HeroFacts, bool, error) {
	if err := f.Validate(); err != nil {
		return HeroFacts{}, false, err
	}
	if amount < 0 {
		return HeroFacts{}, false, ErrUnqualified
	}
	if amount == 0 || f.Favor >= FavorLimit {
		return f, false, nil
	}
	next := f
	next.Favor = min(f.Favor+amount, FavorLimit)
	next.StateVersion++
	next.UpdatedAt = now
	return next, true, next.Validate()
}

// RecordTalk applies one 843 request to a dialog row. A reward claim is once
// per dialog; a non-reward choice only records select_id.
func (f DialogFact) RecordTalk(isReward bool, selectID int64, now time.Time) (DialogFact, bool, error) {
	if err := f.Validate(); err != nil {
		return DialogFact{}, false, err
	}
	if selectID < 0 {
		return DialogFact{}, false, ErrUnqualified
	}
	if f.IsAwarded {
		return f, false, nil
	}
	if !isReward {
		if selectID == 0 || f.SelectID == selectID {
			return f, false, nil
		}
		f.SelectID, f.UpdatedAt = selectID, now
		return f, true, f.Validate()
	}
	f.IsAwarded = true
	if selectID > 0 {
		f.SelectID = selectID
	}
	f.UpdatedAt = now
	return f, true, f.Validate()
}
