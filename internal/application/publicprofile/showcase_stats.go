package publicprofile

import (
	"context"
	"fmt"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type ShowcaseStatProvider interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
	PetTx(context.Context, ca.CoherentReadScope, character.PetRef, publicstats.View) (publicstats.Result, error)
}
type SelectedShowcaseStats struct {
	Character SelectedShowcase
	Stats     publicstats.Result
}

// ReadSelectedStatsTx extends the accepted privacy-checked read component.
// It does not activate MID1838 or manufacture the remaining rich wire fields.
func (s ShowcaseReader) ReadSelectedStatsTx(c context.Context, sc tx.Scope, a identity.ActorContext, target identity.PlayerID, index int, rev string, at time.Time, p ShowcaseStatProvider) (SelectedShowcaseStats, error) {
	var out SelectedShowcaseStats
	v, e := s.ReadSelectedTx(c, sc, a, target, index, rev, at)
	if e != nil {
		return out, e
	}
	if p == nil {
		return out, ErrShowcaseUnavailable
	}
	coherent, e := ca.NewCoherentReadScope(sc, rev, at)
	if e != nil {
		return out, e
	}
	view := publicstats.View{Kind: publicstats.Foreign, Viewer: a.PlayerID}
	if a.PlayerID == target {
		view.Kind = publicstats.Self
	}
	var r publicstats.Result
	var version int64
	var actor string
	expectedModel := "Pet"
	if v.Hero != nil {
		b := v.Hero.Base
		expectedModel = "NormalHero"
		if b.Kind == character.SuperHero {
			expectedModel = "SuperHero"
		}
		version = b.StateVersion
		actor = fmt.Sprintf("OWNED/HERO/%d/%d/v%d", target, b.Ref.PartnerID, version)
		r, e = p.HeroTx(c, coherent, b.Ref, view)
	} else if v.Pet != nil {
		b := v.Pet.Base
		version = b.StateVersion
		actor = fmt.Sprintf("OWNED/PET/%d/%d/v%d", target, b.Ref.PetID, version)
		r, e = p.PetTx(c, coherent, b.Ref, view)
	} else {
		return out, ErrSelection
	}
	if e != nil {
		return out, e
	}
	if r.Stats.Model != expectedModel || r.Stats.PolicyID != statrules.PolicyID || r.Stats.ObservationID != fmt.Sprint(sc.Operation.ID) || r.View != view || r.OwnerStateVersion != version || r.Stats.ActorReference != actor || r.Stats.ContentRevision != rev || !r.Stats.ObservedAt.Equal(at) {
		return out, ErrSelection
	}
	return SelectedShowcaseStats{Character: v, Stats: r}, nil
}
