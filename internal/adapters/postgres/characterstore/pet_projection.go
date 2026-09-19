package characterstore

import (
	"context"
	"errors"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	petproj "gxb.local/backend/v2/internal/projection/pet"
)

type PetBootstrapProjection struct{}

func (PetBootstrapProjection) Name() string     { return "ca3.pet-core" }
func (PetBootstrapProjection) Claims() []string { return []string{"780"} }
func (PetBootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if q == nil || detail == nil || observedAt.IsZero() || !actor.PlayerID.Valid() {
		return errors.New("character pet bootstrap: invalid projection input")
	}
	store := Store{}
	if _, err := store.ReadPetRootTx(ctx, q, actor.PlayerID); err != nil {
		return err
	}
	pets, err := store.ListPetsTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	body, err := petproj.StockRoster(pets)
	if err != nil {
		return err
	}
	detail["780"] = body
	return nil
}

var _ appboot.MID1DetailContributor = PetBootstrapProjection{}
