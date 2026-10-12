package characterstore

import (
	"context"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

// Character-owned adapter consumes canonical Hero and skin state through the
// existing owner store. No Player-domain SQL is introduced here.
type DisplayReader struct {
	Store   Store
	Content DisplayContent
}

// Preserve the accepted Character immutable kind provenance; current display
// policy still supplies the caller-pinned beforeAwaken mapping.
type DisplayContent interface {
	app.Content
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
}

func (r DisplayReader) PrepareDisplayHeroesTx(c context.Context, t tx.Tx, pid identity.PlayerID) error {
	if _, e := r.Store.LockRootTx(c, t, pid); e != nil {
		return e
	}
	hs, e := r.Store.ListHeroesTx(c, t, pid)
	if e != nil {
		return e
	}
	sort.Slice(hs, func(i, j int) bool { return hs[i].PartnerID < hs[j].PartnerID })
	for _, h := range hs {
		if _, e = r.Store.LockHeroByPartnerIDTx(c, t, pid, h.PartnerID); e != nil {
			return e
		}
	}
	return nil
}
func (r DisplayReader) ReadDisplayHeroesTx(c context.Context, q tx.Queryer, pid identity.PlayerID, rev string, at time.Time) ([]app.HeroFacet, error) {
	if r.Content == nil || q == nil || !pid.Valid() || at.IsZero() {
		return nil, app.ErrUnavailable
	}
	p, e := r.Content.ReadPlayerDisplayCatalogTx(c, q, rev)
	if e != nil {
		return nil, e
	}
	hs, e := r.Store.ListHeroesTx(c, q, pid)
	if e != nil {
		return nil, e
	}
	out := make([]app.HeroFacet, 0, len(hs))
	for _, h := range hs {
		if h.ValidatePersistent() != nil || h.PlayerID != pid {
			return nil, app.ErrConflict
		}
		f := app.HeroFacet{PlayerID: pid, PartnerID: h.PartnerID, TableID: h.TableID, Version: h.StateVersion, Color: h.Color, Star: h.Star, Skins: []int64{}}
		found := false
		for _, tmpl := range p.HeroTemplates {
			if tmpl.TableID == h.TableID {
				f.BeforeAwaken = tmpl.BeforeAwaken
				kind, e := r.Content.HeroKindTx(c, q, h.CreationContentRevision, h.TableID)
				if e != nil {
					return nil, e
				}
				f.Super = kind == character.SuperHero
				f.Awakened = kind == character.NormalHero && tmpl.BeforeAwaken > 0
				found = true
				break
			}
		}
		if !found {
			return nil, app.ErrUnavailable
		}
		skins, e := r.Store.ListHeroSkinEntitlementsTx(c, q, pid, h.PartnerID)
		if e != nil {
			return nil, e
		}
		for _, skin := range skins {
			if skin.Validate() != nil || skin.PlayerID != pid || skin.PartnerID != h.PartnerID {
				return nil, app.ErrConflict
			}
			if skin.EffectiveAt(at) {
				f.Skins = append(f.Skins, skin.ModelID)
			}
		}
		out = append(out, f)
	}
	return out, nil
}

var _ app.CharacterReader = DisplayReader{}
