package i5

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type MissionBootstrap struct{ Owner Service }

func (MissionBootstrap) Name() string     { return "i5.missions" }
func (MissionBootstrap) Claims() []string { return []string{"160"} }
func (m MissionBootstrap) ReconcileCharacterLogin(ctx context.Context, t tx.Tx, actor identity.ActorContext, op operation.Context, at time.Time) error {
	bound, err := m.Owner.bindActiveContentTx(ctx, t, op)
	if err != nil {
		return err
	}
	revision, err := requireContentRevision(bound)
	if err != nil {
		return err
	}
	_, err = m.Owner.Missions.MaterializeTx(ctx, t, MissionScope{PlayerID: actor.PlayerID, ContentRevision: revision, DecisionAt: at})
	return err
}
func (m MissionBootstrap) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, at time.Time, detail map[string]any) error {
	root, err := m.Owner.Missions.Store.ReadMissionRootTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	instances, err := m.Owner.Missions.Store.ListMissionInstancesTx(ctx, q, actor.PlayerID)
	if err != nil {
		return err
	}
	revision, err := m.Owner.Content.ActiveRevision(ctx, q)
	if err != nil {
		return err
	}
	definitions, err := m.Owner.Missions.Catalog.MissionDefinitionsTx(ctx, q, revision)
	if err != nil {
		return err
	}
	view := MissionView{Root: root, Instances: instances, Definitions: definitions}
	if m.Owner.Missions.Activity != nil {
		activity, err := m.Owner.Missions.Activity.MissionActivityCatalogTx(ctx, q, revision)
		if err != nil {
			return err
		}
		view.Activity = activity
	}
	if m.Owner.Missions.Awakening != nil {
		a, err := m.Owner.Missions.Awakening.ReadAwakeningTx(ctx, q, actor.PlayerID)
		if err != nil {
			return err
		}
		view.AwakeningReady = awakeningReady(a)
	}
	detail["160"] = MissionProjection(view, at, 0)
	return nil
}
