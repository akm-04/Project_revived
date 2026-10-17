package playerdisplay

import "gxb.local/backend/v2/internal/domain/player"

// HeroEligibility is shared by selection and the read-only fact provider. Raw
// color >=7, Super star >=2, current/beforeAwaken and collection are distinct
// source predicates, not a metric/count reduction.
func HeroEligibility(v player.Cosmetic, category int64, hs []HeroFacet, p player.DisplayCatalog) []HeroFacet {
	skins := map[int64]bool{}
	matched := []HeroFacet{}
	for _, h := range hs {
		for _, id := range h.Skins {
			skins[id] = true
		}
		if v.Type == 2 && ((category == 2 && (h.TableID == v.PartnerID && h.Color >= 7 || h.Awakened && h.BeforeAwaken == v.PartnerID)) || (category == 3 && h.Super && h.Star >= 2 && h.TableID == v.PartnerID)) || v.Type == 3 && h.Awakened && h.TableID == v.PartnerID {
			matched = append(matched, h)
		}
	}
	if v.Type == 7 && skins[v.PartnerID] {
		return hs
	}
	if v.Type == 11 && v.ID == 110006002 && len(p.Collection) == 4 {
		for _, id := range p.Collection {
			row, ok := p.Find("avatar", id)
			if !ok || !skins[row.PartnerID] {
				return nil
			}
		}
		return hs
	}
	return matched
}
