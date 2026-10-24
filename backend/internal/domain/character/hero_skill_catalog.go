package character

import "errors"

type HeroSkillOption struct {
	ID         int64
	BookItemID int64
}
type HeroSkillCatalog struct {
	TableID         int64
	ContentRevision string
	Choices         [6][]HeroSkillOption
}

func (c HeroSkillCatalog) Validate() error {
	if c.TableID <= 0 || len(c.ContentRevision) != 64 {
		return errors.New("character Hero skill catalog identity")
	}
	for _, slot := range c.Choices {
		if len(slot) == 0 {
			return errors.New("character Hero skill catalog absent slot")
		}
		for _, x := range slot {
			if x.ID < 0 || x.BookItemID < 0 {
				return errors.New("character Hero skill catalog invalid ID")
			}
		}
	}
	return nil
}
func (c HeroSkillCatalog) ResolveRawIDs(h Hero) ([6]int64, error) {
	var out [6]int64
	if c.Validate() != nil || h.ValidatePersistent() != nil || h.TableID != c.TableID {
		return out, errors.New("character Hero raw skill observation mismatch")
	}
	special := h.TableID == 10001144 || h.TableID == 11001144
	for i, slot := range c.Choices {
		out[i] = slot[0].ID
		if special && h.RawSkills.ChoiceIDs[i] != 0 {
			found := false
			for _, x := range slot {
				if x.ID == h.RawSkills.ChoiceIDs[i] {
					out[i] = x.ID
					found = true
					break
				}
			}
			if !found {
				return out, errors.New("character Hero skill override not qualified by content")
			}
		}
	}
	return out, nil
}
