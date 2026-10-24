package characterhero

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
)

type RawSkillObservationReader struct {
	Store   BaseObservationStore
	Content SkillChoiceContent
}

func (r RawSkillObservationReader) HeroRawSkillsTx(c context.Context, sc characterasset.CoherentReadScope, ref character.HeroRef) (characterasset.HeroRawSkillObservation, error) {
	var out characterasset.HeroRawSkillObservation
	if r.Store == nil || r.Content == nil || sc.Validate() != nil || ref.Validate() != nil {
		return out, ErrSkillChoiceRequest
	}
	h, e := r.Store.ReadHeroByPartnerIDTx(c, sc.Queryer(), ref.PlayerID, ref.PartnerID)
	if e != nil {
		return out, e
	}
	if h.Ref() != ref || h.ValidatePersistent() != nil {
		return out, ErrSkillChoiceRequest
	}
	catalog, e := r.Content.HeroSkillCatalogTx(c, sc.Queryer(), sc.ContentRevision, h.TableID)
	if e != nil {
		return out, e
	}
	if catalog.ContentRevision != sc.ContentRevision {
		return out, ErrSkillChoiceRequest
	}
	ids, e := catalog.ResolveRawIDs(h)
	if e != nil {
		return out, e
	}
	return characterasset.HeroRawSkillObservation{Ref: ref, Facts: h.RawSkills, ResolvedIDs: ids, StateVersion: h.StateVersion, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}, nil
}

var _ characterasset.HeroRawSkillObservationProvider = RawSkillObservationReader{}
