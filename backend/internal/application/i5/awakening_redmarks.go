package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func awakeningReady(root objective.AwakeRoot) bool {
	for _, a := range root.Active {
		if a.Mission > 0 && a.Complete {
			return true
		}
	}
	return false
}

// Read-only composition after a mission mutation; no late root locks or clock reads.
func (s Service) awakeningRedmarksTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, revision string, body map[string]any) error {
	if s.Missions == nil || s.Missions.Awakening == nil {
		return nil
	}
	root, err := s.Missions.Store.ReadMissionRootTx(ctx, q, pid)
	if err != nil {
		return err
	}
	instances, err := s.Missions.Store.ListMissionInstancesTx(ctx, q, pid)
	if err != nil {
		return err
	}
	definitions, err := s.Missions.Catalog.MissionDefinitionsTx(ctx, q, revision)
	if err != nil {
		return err
	}
	awake, err := s.Missions.Awakening.ReadAwakeningTx(ctx, q, pid)
	if err != nil {
		return err
	}
	view := MissionView{Root: root, Instances: instances, Definitions: definitions, AwakeningReady: awakeningReady(awake)}
	if s.Missions.Activity != nil {
		catalog, err := s.Missions.Activity.MissionActivityCatalogTx(ctx, q, revision)
		if err != nil {
			return err
		}
		view.Activity = catalog
	}
	// Only badges are selected: no time-dependent projection is returned here.
	body["redmarks_"] = MissionProjection(view, time.Time{}, 0)["redmarks_"]
	return nil
}
