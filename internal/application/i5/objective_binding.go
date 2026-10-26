package i5

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const missionContentPolicyRefName = "objective-instance-content"

func isMissionInstance(instance objective.Instance, definition ObjectiveDefinition) bool {
	return instance.DefinitionRevision == "I9_MISSIONS_V1" && instance.ProgramID == fmt.Sprintf("mission:%d", definition.Family)
}

func (s Service) applyMissionFactTx(ctx context.Context, t tx.Tx, definition ObjectiveDefinition, instance objective.Instance, fact objective.Fact, source operation.Context, at time.Time) (objective.Instance, bool, error) {
	if !isMissionInstance(instance, definition) {
		return objective.Instance{}, false, errors.New("mission fact requires exact mission instance")
	}
	if err := validateContentRevision(instance.ContentRevision); err != nil {
		return objective.Instance{}, false, err
	}
	if existing, ok := source.Policies.Get(missionContentPolicyRefName); ok {
		if existing != instance.ContentRevision {
			return objective.Instance{}, false, ErrContentRevisionConflict
		}
	} else {
		refs := append(source.Policies.Refs(), policy.Ref{Name: missionContentPolicyRefName, Version: instance.ContentRevision})
		bound, err := policy.NewSet(refs...)
		if err != nil {
			return objective.Instance{}, false, err
		}
		source.Policies = bound
	}
	return s.applyObjectiveFactAtTx(ctx, t, definition, instance, fact, source, at, instance.ContentRevision)
}

func validateObjectivePair(inst objective.Instance, def ObjectiveDefinition) error {
	if def.Definition.ProgramID != inst.ProgramID || def.Definition.ObjectiveID != inst.ObjectiveID || def.Definition.DefinitionRevision != inst.DefinitionRevision {
		return errors.New("objective instance/definition mismatch")
	}
	if err := def.Definition.Validate(); err != nil {
		return err
	}
	return nil
}

func (s Service) resolveObjectiveDefinition(ctx context.Context, inst objective.Instance, legacy ObjectiveDefinition) (ObjectiveDefinition, error) {
	if inst.ContentRevision == "" {
		if err := validateObjectivePair(inst, legacy); err != nil {
			return ObjectiveDefinition{}, err
		}
		return legacy, nil
	}
	if err := validateContentRevision(inst.ContentRevision); err != nil {
		return ObjectiveDefinition{}, err
	}
	if s.Content == nil {
		return ObjectiveDefinition{}, errors.New("I5 content runtime unavailable")
	}
	def, err := s.Content.ResolveObjective(ctx, inst.ContentRevision, inst.ProgramID, inst.ObjectiveID, inst.DefinitionRevision)
	if err != nil {
		return ObjectiveDefinition{}, err
	}
	def.GenerationID = inst.GenerationID
	if err := validateObjectivePair(inst, def); err != nil {
		return ObjectiveDefinition{}, err
	}
	return def, nil
}

func (s Service) resolveObjectiveDefinitionTx(ctx context.Context, q tx.Queryer, inst objective.Instance, legacy ObjectiveDefinition) (ObjectiveDefinition, error) {
	if inst.ContentRevision == "" {
		if err := validateObjectivePair(inst, legacy); err != nil {
			return ObjectiveDefinition{}, err
		}
		return legacy, nil
	}
	if err := validateContentRevision(inst.ContentRevision); err != nil {
		return ObjectiveDefinition{}, err
	}
	if s.Content == nil {
		return ObjectiveDefinition{}, errors.New("I5 content runtime unavailable")
	}
	def, err := s.Content.ResolveObjectiveTx(ctx, q, inst.ContentRevision, inst.ProgramID, inst.ObjectiveID, inst.DefinitionRevision)
	if err != nil {
		return ObjectiveDefinition{}, err
	}
	def.GenerationID = inst.GenerationID
	if err := validateObjectivePair(inst, def); err != nil {
		return ObjectiveDefinition{}, err
	}
	return def, nil
}
