package characterstore

import (
	"context"
	"errors"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

type HeroBootstrapContent interface {
	apphero.HeroRosterTxContent
	HeroCoreActiveTx(context.Context, tx.Queryer) (string, bool, error)
	HeroEquipmentRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	HeroFumoRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	AppearanceRevisionTx(context.Context, tx.Queryer, string) (bool, error)
}

// HeroBootstrapProjection repairs MID1 key49 with canonical owner state while
// preserving the frozen inactive baseline when Hero projection capabilities are
// legitimately inactive. It is read-only and executes entirely through the
// caller-owned MID1 transaction/queryer.
type LibraryRosterOverlay interface {
	OverlayRosterTx(context.Context, tx.Queryer, identity.ActorContext, string, time.Time, map[string]any) error
}
type HeroBootstrapProjection struct {
	Book    LibraryRosterOverlay
	Dorm    LibraryRosterOverlay
	Library LibraryRosterOverlay
	Content HeroBootstrapContent
}

func (HeroBootstrapProjection) Name() string     { return "ca6.hero-bootstrap" }
func (HeroBootstrapProjection) Claims() []string { return []string{"49"} }
func (p HeroBootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if q == nil || p.Content == nil || detail == nil || observedAt.IsZero() || !actor.PlayerID.Valid() {
		return errors.New("character hero bootstrap: invalid projection input")
	}
	revision, active, err := p.Content.HeroCoreActiveTx(ctx, q)
	if err != nil {
		return err
	}
	if !active {
		return nil
	}
	equipmentActive, err := p.Content.HeroEquipmentRevisionTx(ctx, q, revision)
	if err != nil {
		return err
	}
	if !equipmentActive {
		return nil
	}
	fumoActive, err := p.Content.HeroFumoRevisionTx(ctx, q, revision)
	if err != nil {
		return err
	}
	if !fumoActive {
		return nil
	}

	appearanceActive, err := p.Content.AppearanceRevisionTx(ctx, q, revision)
	if err != nil {
		return err
	}
	if !appearanceActive {
		return nil
	}

	store := Store{}
	root, err := store.ReadRootTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	heroes, err := store.ListHeroesTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	views, err := apphero.BuildRosterViewsTx(ctx, q, revision, heroes, observedAt, store, p.Content)
	if err != nil {
		return err
	}
	stockViews := make([]heroproj.RosterHeroView, 0, len(views))
	for _, view := range views {
		stockViews = append(stockViews, heroproj.RosterHeroView{Hero: view.Hero, FumoLevels: view.FumoLevels, Appearance: heroproj.AppearanceView{OwnerStateVersion: view.Appearance.OwnerStateVersion, CurrentSkinID: view.Appearance.CurrentSkinID, IllusionSkinID: view.Appearance.IllusionSkinID, Skins: func() []heroproj.QualifiedSkinView {
			out := make([]heroproj.QualifiedSkinView, 0, len(view.Appearance.Skins))
			for _, x := range view.Appearance.Skins {
				out = append(out, heroproj.QualifiedSkinView{ModelID: x.ModelID, ExpiresAt: x.ExpiresAt})
			}
			return out
		}(), LIVE: func() []heroproj.QualifiedLIVEView {
			out := make([]heroproj.QualifiedLIVEView, 0, len(view.Appearance.LIVE))
			for _, x := range view.Appearance.LIVE {
				out = append(out, heroproj.QualifiedLIVEView{ModelID: x.ModelID, IsShow: x.IsShow})
			}
			return out
		}()}})
	}
	body, err := heroproj.StockRosterView(root.SortType, stockViews)
	if err != nil {
		return err
	}
	if p.Library != nil {
		if err = p.Library.OverlayRosterTx(ctx, q, actor, revision, observedAt, body); err != nil {
			return err
		}
	}
	if p.Dorm != nil {
		if err = p.Dorm.OverlayRosterTx(ctx, q, actor, revision, observedAt, body); err != nil {
			return err
		}
	}
	if p.Book != nil {
		if err = p.Book.OverlayRosterTx(ctx, q, actor, revision, observedAt, body); err != nil {
			return err
		}
	}
	detail["49"] = body
	return nil
}

var _ appboot.MID1DetailContributor = HeroBootstrapProjection{}
