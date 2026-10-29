package i5

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type CharacterFunctionObservation struct {
	Player            identity.PlayerID
	Revision          string
	ObservedAt        time.Time
	PopulationVersion int64
	OwnedGirls        int64
	EmblemReady       bool
}
type CharacterFunctionReader interface {
	ReadCharacterFunctionPrerequisitesTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (CharacterFunctionObservation, error)
}
type CharacterFunctionOpener interface {
	PrepareCharacterFunctionsTx(context.Context, tx.Tx, identity.PlayerID) error
	OpenCharacterFunctionsTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) ([]int64, error)
}

func characterFunctionEligibility(policy FunctionGatePolicy, observation CharacterFunctionObservation, level int64, at time.Time) []player.FunctionEligibility {
	eligible := []player.FunctionEligibility{}
	for _, gate := range policy.Gates {
		allowed := gate.FunctionID == 16 && gate.RawOpenValue == "6|55|15" && level >= 55 && observation.OwnedGirls >= 15 || gate.FunctionID == 37 && gate.RawOpenValue == "6|60|5" && level >= 60 && observation.OwnedGirls >= 5 || gate.FunctionID == 45 && gate.RawOpenValue == "7|100" && observation.EmblemReady
		if allowed {
			eligible = append(eligible, player.FunctionEligibility{PlayerID: observation.Player, FunctionID: gate.FunctionID, ContentRevision: policy.Revision, SourceFactKey: gate.SourceFactKey, EligibleAt: at.UTC()})
		}
	}
	return eligible
}

// Prepare precedes scalar/stack debits; the shared progression lock orders concurrent level and Character producers.
func (service Service) PrepareCharacterFunctionsTx(requestContext context.Context, transaction tx.Tx, player identity.PlayerID) error {
	if service.CharacterFunctions == nil {
		return nil
	}
	if transaction == nil || !player.Valid() || service.Store == nil {
		return errors.New("character function preparation unavailable")
	}
	if err := service.Store.LockEconomyOwnerTx(requestContext, transaction, player); err != nil {
		return err
	}
	_, err := service.Store.LockProgressionTx(requestContext, transaction, player)
	return err
}
func (service Service) OpenCharacterFunctionsTx(requestContext context.Context, transaction tx.Tx, player identity.PlayerID, revision string, at time.Time) ([]int64, error) {
	if service.CharacterFunctions == nil {
		return nil, nil
	}
	if transaction == nil || !player.Valid() || service.Store == nil || service.Content == nil || len(revision) != 64 || at.IsZero() {
		return nil, errors.New("character function opening unavailable")
	}
	progression, err := service.Store.LockProgressionTx(requestContext, transaction, player)
	if err != nil {
		return nil, err
	}
	observation, err := service.CharacterFunctions.ReadCharacterFunctionPrerequisitesTx(requestContext, transaction, player, revision, at)
	if err != nil {
		return nil, fmt.Errorf("Character prerequisite observation: %w", err)
	}
	if observation.Player != player || observation.Revision != revision || !observation.ObservedAt.Equal(at) || observation.PopulationVersion < 1 || observation.OwnedGirls < 0 {
		return nil, errors.New("unqualified character function observation")
	}
	policy, err := service.Content.ResolveFunctionGatePolicyTx(requestContext, transaction, revision)
	if err != nil {
		return nil, fmt.Errorf("Character function catalog %s: %w", revision, err)
	}
	eligible := characterFunctionEligibility(policy, observation, progression.Level, at)
	if len(eligible) == 0 {
		return nil, nil
	}
	version, err := service.Store.LockFunctionStateTx(requestContext, transaction, player)
	if err != nil {
		return nil, err
	}
	return insertOpeningsTx(requestContext, service.Store, transaction, player, version, eligible, "i9-7d:function-character:v1", at)
}
