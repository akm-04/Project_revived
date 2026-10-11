package publicprofile

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Character provider is the accepted CA8 facade; tests may supply component providers.
type ShowcaseCharacterReader interface {
	HeroTx(context.Context, characterasset.CoherentReadScope, character.HeroRef) (characterasset.PublicHeroCharacterFacet, error)
	PetTx(context.Context, characterasset.CoherentReadScope, character.PetRef) (characterasset.PublicPetCharacterFacet, error)
}
type ShowcaseSnapshot struct {
	PlayerID        identity.PlayerID
	Selection       Selection
	RootVersion     int64
	ContentRevision string
	ObservedAt      time.Time
}
type SelectedShowcase struct {
	Snapshot ShowcaseSnapshot
	Index    int
	Hero     *characterasset.PublicHeroCharacterFacet
	Pet      *characterasset.PublicPetCharacterFacet
}
type ShowcaseReader struct {
	Basic      BasicReader
	Slots      ShowcaseStore
	Content    ShowcaseContentReader
	Characters ShowcaseCharacterReader
}

func (s ShowcaseReader) ReadSelectionTx(c context.Context, sc tx.Scope, a identity.ActorContext, target identity.PlayerID, rev string, at time.Time) (ShowcaseSnapshot, error) {
	var out ShowcaseSnapshot
	if s.Slots == nil || s.Content == nil {
		return out, ErrShowcaseUnavailable
	}
	// Privacy and all lower locks precede Character provider access.
	basic, e := s.Basic.ReadBasicTx(c, sc, a, target, rev, at)
	if e != nil {
		return out, e
	}
	if !basic.Eligible[1] {
		return out, ErrShowcasePrivate
	}
	cp, e := s.Content.ReadPublicShowcasePolicy(c, sc.Tx, rev)
	if e != nil || cp.Validate() != nil || cp.Revision != rev {
		return out, ErrContent
	}
	slots, e := s.Slots.ReadSelectionTx(c, sc.Tx, target)
	if e != nil {
		return out, e
	}
	if basic.ProfileVersion == 0 && slots != (Selection{}) {
		return out, ErrInvalidState
	}
	return ShowcaseSnapshot{PlayerID: target, Selection: slots, RootVersion: basic.ProfileVersion, ContentRevision: rev, ObservedAt: at.UTC()}, nil
}
func (s ShowcaseReader) ReadSelectedTx(c context.Context, sc tx.Scope, a identity.ActorContext, target identity.PlayerID, index int, rev string, at time.Time) (SelectedShowcase, error) {
	var out SelectedShowcase
	if index < 1 || index > 6 {
		return out, ErrSelection
	}
	snapshot, e := s.ReadSelectionTx(c, sc, a, target, rev, at)
	if e != nil {
		return out, e
	}
	out = SelectedShowcase{Snapshot: snapshot, Index: index}
	id := snapshot.Selection[index-1]
	if id == 0 {
		return out, ErrEmptyShowcase
	}
	if s.Characters == nil {
		return out, ErrShowcaseUnavailable
	}
	coherent, e := characterasset.NewCoherentReadScope(sc, rev, at)
	if e != nil {
		return out, e
	}
	if id > 0 {
		ref := character.HeroRef{PlayerID: target, PartnerID: id}
		f, e := s.Characters.HeroTx(c, coherent, ref)
		if e != nil {
			return out, e
		}
		if f.Origin != characterasset.ActorOriginOwned || f.Base.Ref != ref || f.Base.Validate() != nil {
			return out, ErrSelection
		}
		if e = validateHeroFacet(f, rev, at); e != nil {
			return out, e
		}
		clone, e := cloneFacet(f)
		if e != nil {
			return out, e
		}
		out.Hero = &clone
	} else {
		ref := character.PetRef{PlayerID: target, PetID: -id}
		f, e := s.Characters.PetTx(c, coherent, ref)
		if e != nil {
			return out, e
		}
		if f.Origin != characterasset.ActorOriginOwned || f.Base.Ref != ref || f.Base.Validate() != nil {
			return out, ErrSelection
		}
		if e = validatePetFacet(f, rev, at); e != nil {
			return out, e
		}
		clone, e := cloneFacet(f)
		if e != nil {
			return out, e
		}
		out.Pet = &clone
	}
	return out, nil
}

// SlotRecords is a source-shaped boundary, not an activated stock command.
// A full I7B-6 composer must supply genuinely qualified rich records; nil fails closed.
type ShowcaseRecordBuilder interface {
	RecordTx(context.Context, characterasset.CoherentReadScope, identity.PlayerID, int64) (map[string]any, error)
}

func SlotRecordsTx(c context.Context, sc tx.Scope, s ShowcaseSnapshot, b ShowcaseRecordBuilder) ([6]map[string]any, error) {
	var out [6]map[string]any
	for i := range out {
		out[i] = map[string]any{}
	}
	if b == nil || !s.PlayerID.Valid() || s.Selection.Validate() != nil {
		return out, ErrShowcaseUnavailable
	}
	scope, e := characterasset.NewCoherentReadScope(sc, s.ContentRevision, s.ObservedAt)
	if e != nil {
		return out, e
	}
	for i, id := range s.Selection {
		if id == 0 {
			continue
		}
		v, e := b.RecordTx(c, scope, s.PlayerID, id)
		if e != nil {
			return [6]map[string]any{}, e
		}
		if len(v) == 0 {
			return [6]map[string]any{}, ErrShowcaseUnavailable
		}
		out[i], e = cloneRecord(v)
		if e != nil {
			return [6]map[string]any{}, e
		}
	}
	return out, nil
}

func validateHeroFacet(f characterasset.PublicHeroCharacterFacet, rev string, at time.Time) error {
	composite := characterasset.OwnedHeroComposite{Origin: f.Origin, Base: f.Base, Equipment: f.Equipment, Practice: f.Practice, Appearance: f.Appearance}
	if e := composite.Validate(); e != nil {
		return e
	}
	if f.HeroSkillsDisposition.Validate() != nil {
		return ErrSelection
	}
	if f.Practice.Disposition.Available() && f.Practice.Value.ContentRevision != rev {
		return ErrSelection
	}
	if f.Appearance.Disposition.Available() && (f.Appearance.Value.ContentRevision != rev || !f.Appearance.Value.Appearance.ObservedAt.Equal(at)) {
		return ErrSelection
	}
	return nil
}
func validatePetFacet(f characterasset.PublicPetCharacterFacet, rev string, at time.Time) error {
	composite := characterasset.OwnedPetComposite{Origin: f.Origin, Base: f.Base, Equipment: f.Equipment, Practice: f.Practice, Appearance: f.Appearance}
	if e := composite.Validate(); e != nil {
		return e
	}
	if f.Practice.Disposition.Available() && f.Practice.Value.ContentRevision != rev {
		return ErrSelection
	}
	if f.Appearance.Disposition.Available() && (f.Appearance.Value.ContentRevision != rev || !f.Appearance.Value.Appearance.ObservedAt.Equal(at)) {
		return ErrSelection
	}
	return nil
}
