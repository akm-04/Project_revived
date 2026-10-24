package i5

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

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
