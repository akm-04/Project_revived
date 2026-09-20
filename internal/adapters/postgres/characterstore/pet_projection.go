package characterstore

import (
	"context"
	"errors"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	petproj "gxb.local/backend/v2/internal/projection/pet"
)

type PetBootstrapContent interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	AppearanceRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	characterasset.AppearanceTxContent
}

type PetBootstrapProjection struct {
	Content PetBootstrapContent
}

func (PetBootstrapProjection) Name() string     { return "ca3.pet-core" }
func (PetBootstrapProjection) Claims() []string { return []string{"780"} }
func (p PetBootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if q == nil || p.Content == nil || detail == nil || observedAt.IsZero() || !actor.PlayerID.Valid() {
		return errors.New("character pet bootstrap: invalid projection input")
	}
	revision, err := p.Content.ActiveRevision(ctx, q)
	if err != nil {
		return err
	}
	active, err := p.Content.AppearanceRevisionTx(ctx, q, revision)
	if err != nil {
		return err
	}
	if !active {
		return nil
	}
	store := Store{}
	if _, err := store.ReadPetRootTx(ctx, q, actor.PlayerID); err != nil {
		return err
	}
	pets, err := store.ListPetsTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	views := make([]petproj.RosterPetView, 0, len(pets))
	for _, pet := range pets {
		styles, err := store.ListPetStyleEntitlementsTx(ctx, q, actor.PlayerID, pet.PetID)
		if err != nil {
			return err
		}
		appearance, err := characterasset.BuildEffectivePetAppearanceTx(ctx, q, revision, pet, styles, observedAt, p.Content)
		if err != nil {
			return err
		}
		views = append(views, petproj.RosterPetView{Pet: pet, Appearance: petproj.AppearanceView{OwnerStateVersion: appearance.OwnerStateVersion, ActiveStyle: appearance.ActiveStyle, OwnedStyles: append([]int64(nil), appearance.OwnedStyles...)}})
	}
	body, err := petproj.StockRosterView(views)
	if err != nil {
		return err
	}
	detail["780"] = body
	return nil
}

var _ appboot.MID1DetailContributor = PetBootstrapProjection{}
