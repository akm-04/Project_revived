package dormhouse

func (c Catalog) GrowthBP(tableID, comfort, expansionLevel int64) (AttributesBP, error) {
	r, ok := c.Rooms[tableID]
	if !ok || comfort < 0 || expansionLevel < 0 {
		return AttributesBP{}, ErrUnqualified
	}
	t, ok := c.Types[r.MainType]
	if !ok || expansionLevel > t.MaxExpansion || len(r.Growth) == 0 {
		return AttributesBP{}, ErrUnqualified
	}
	var out AttributesBP
	found := false
	for _, tier := range r.Growth {
		if comfort >= tier.Comfort {
			out = tier.Attributes
			found = true
		}
	}
	if !found {
		return AttributesBP{}, ErrUnqualified
	}
	// NormalHero/SuperHero both choose the greatest applied expansion tier whose
	// comfort threshold is met; below it the normal house tier still applies.
	for level := expansionLevel; level > 0; level-- {
		e, ok := c.Expansions[level]
		if !ok {
			return AttributesBP{}, ErrUnqualified
		}
		if comfort >= e.Comfort {
			if r.AttributeType < 1 || r.AttributeType > 3 {
				return AttributesBP{}, ErrUnqualified
			}
			out = e.Attributes[r.AttributeType-1]
			break
		}
	}
	return out, nil
}
func (c Catalog) RoomSize(tableID, appliedLevel int64) (int64, int64, int64, error) {
	r, ok := c.Rooms[tableID]
	if !ok || appliedLevel < 0 {
		return 0, 0, 0, ErrUnqualified
	}
	t, ok := c.Types[r.MainType]
	if !ok || appliedLevel > t.MaxExpansion {
		return 0, 0, 0, ErrUnqualified
	}
	if appliedLevel > 0 {
		e, ok := c.Expansions[appliedLevel]
		if !ok {
			return 0, 0, 0, ErrUnqualified
		}
		return e.Area, e.Area, r.Height, nil
	}
	return r.Length, r.Width, r.Height, nil
}
