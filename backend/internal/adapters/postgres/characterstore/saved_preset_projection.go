package characterstore

import (
	"context"
	"errors"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/charactersavedpreset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type SavedPresetBootstrapProjection struct{}

func (SavedPresetBootstrapProjection) Name() string { return "ca5.saved-presets" }
func (SavedPresetBootstrapProjection) Claims() []string {
	return []string{"17.save_team", "17.save_team_name", "17.save_pet"}
}
func (SavedPresetBootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if q == nil || detail == nil || observedAt.IsZero() || !actor.PlayerID.Valid() {
		return errors.New("character saved preset bootstrap: invalid projection input")
	}
	mid17, ok := detail["17"].(map[string]any)
	if !ok {
		return errors.New("character saved preset bootstrap: MID17 frozen baseline missing")
	}
	agg, err := (Store{}).ReadSavedPresetAggregateTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	wire, err := charactersavedpreset.ProjectWire(agg)
	if err != nil {
		return err
	}
	mid17["save_team"] = wire.SaveTeam
	mid17["save_team_name"] = wire.SaveTeamName
	mid17["save_pet"] = wire.SavePet
	return nil
}

var _ appboot.MID1DetailContributor = SavedPresetBootstrapProjection{}
