package i5

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type preparedMissionKey struct{}
type preparedMission struct {
	scope       MissionScope
	transaction tx.Tx
	operation   operation.Context
}

func (f ObjectiveFacts) PrepareTx(ctx context.Context, t tx.Tx, player identity.PlayerID, timed gen.TimedOperation) (context.Context, error) {
	if f.Owner.Missions == nil {
		return ctx, nil
	}
	scope, err := missionScope(player, timed)
	if err != nil {
		return ctx, err
	}
	view, err := f.Owner.Missions.MaterializeTx(ctx, t, scope)
	if err != nil {
		return ctx, err
	}
	if f.Open == nil {
		return ctx, errors.New("objective lock port unavailable")
	}
	if _, _, err := f.Open.LockOpenObjectivesTx(ctx, t, player); err != nil {
		return ctx, err
	}
	changes.Missions(ctx, MissionProjection(view, scope.DecisionAt, 0))
	return context.WithValue(ctx, preparedMissionKey{}, preparedMission{scope: scope, transaction: t, operation: timed.Operation()}), nil
}

func (f ObjectiveFacts) recordMission(ctx context.Context, t tx.Tx, op operation.Context, fact objective.Fact) error {
	prepared, ok := ctx.Value(preparedMissionKey{}).(preparedMission)
	if !ok || prepared.transaction != t || prepared.operation.ID != op.ID || prepared.scope.PlayerID != fact.PlayerID {
		return errors.New("mission fact was not prepared in this transaction")
	}
	sourceRevision, err := requireContentRevision(op)
	if err != nil {
		return err
	}
	if sourceRevision != prepared.scope.ContentRevision {
		return ErrContentRevisionConflict
	}
	key, err := fact.Key()
	if err != nil {
		return err
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(fact.PlayerID), Domain: "objective", Operation: "mission-source-fact", SemanticKey: key}
	fingerprint, err := receipt.FingerprintRequest(fact)
	if err != nil {
		return err
	}
	if prior, ok, err := f.Owner.Receipts.FindTx(ctx, t, id); err != nil {
		return err
	} else if ok {
		if prior.RequestFingerprint != fingerprint {
			return &receipt.ConflictError{Identity: id}
		}
		return nil
	}
	view, err := f.Owner.Missions.MaterializeTx(ctx, t, prepared.scope)
	if err != nil {
		return err
	}
	catalogs := map[string][]objective.MissionDefinition{}
	for _, instance := range view.Instances {
		if instance.ClaimState == objective.Claimed {
			continue
		}
		definitions, ok := catalogs[instance.ContentRevision]
		if !ok {
			definitions, err = f.Owner.Missions.Catalog.MissionDefinitionsTx(ctx, t, instance.ContentRevision)
			if err != nil {
				return err
			}
			catalogs[instance.ContentRevision] = definitions
		}
		var definition objective.MissionDefinition
		for _, d := range definitions {
			if d.ObjectiveID == instance.ObjectiveID && d.ProgramID == instance.ProgramID {
				definition = d
				break
			}
		}
		if definition.ObjectiveID == 0 {
			return ErrObjectiveNotFound
		}
		consumerFact := fact
		if definition.Presentation.Condition == 105 && fact.Kind == "CAMPAIGN_CHALLENGE_WIN" {
			consumerFact.Kind = definition.AcceptedFactKind
		}
		if definition.Strategy != "COMMITTED_DELTA" || definition.AcceptedFactKind != consumerFact.Kind || definition.Presentation.DeferredUntil != "" {
			continue
		}
		core, err := definition.Definition()
		if err != nil {
			return err
		}
		if _, _, err = f.Owner.applyMissionFactTx(ctx, t, ObjectiveDefinition{Family: definition.Family, Definition: core, Reward: definition.Reward, Huoyue: definition.Huoyue}, instance, consumerFact, op, prepared.scope.DecisionAt); err != nil {
			return err
		}
	}
	rr, err := receipt.New(op, id, "I5_OBJECTIVE_FACT", "gxb.i5.mission-source-fact.v1", json.RawMessage(`{"consumed":true}`), fingerprint)
	if err != nil {
		return err
	}
	if _, err = f.Owner.Receipts.PutTx(ctx, t, rr); err != nil {
		return err
	}
	view, err = f.Owner.Missions.MaterializeTx(ctx, t, prepared.scope)
	if err != nil {
		return err
	}
	changes.Missions(ctx, MissionProjection(view, prepared.scope.DecisionAt, 0))
	return nil
}
