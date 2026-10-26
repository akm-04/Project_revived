package i5

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type MissionScope struct {
	PlayerID        identity.PlayerID
	ContentRevision string
	DecisionAt      time.Time
}

type MissionCatalog interface {
	MissionDefinitionsTx(context.Context, tx.Queryer, string) ([]objective.MissionDefinition, error)
}

type MissionStore interface {
	LockMissionRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (objective.MissionRoot, error)
	ReadMissionRootTx(context.Context, tx.Queryer, identity.PlayerID) (objective.MissionRoot, error)
	SaveMissionRootTx(context.Context, tx.Tx, objective.MissionRoot, int64) error
	DeletePreviousDailyMissionsTx(context.Context, tx.Tx, identity.PlayerID, string) error
	InsertMissionInstanceTx(context.Context, tx.Tx, objective.Instance) error
	ListMissionInstancesTx(context.Context, tx.Queryer, identity.PlayerID) ([]objective.Instance, error)
	SaveObjectiveTx(context.Context, tx.Tx, objective.Instance, int64) error
}

type MissionObservation struct {
	GatePassed bool
	Value      int64
}

// MissionObservations composes owning read ports; it never reads another owner's tables directly.
type MissionObservations interface {
	MissionPartnerTemplatesTx(context.Context, tx.Queryer, MissionScope) ([]int64, error)
	ObserveMissionTx(context.Context, tx.Queryer, MissionScope, objective.MissionDefinition, int64) (MissionObservation, error)
}

type MissionMaterializer struct {
	Awakening    AwakeningStore
	Activity     MissionActivityCatalog
	Store        MissionStore
	Catalog      MissionCatalog
	Observations MissionObservations
}

type MissionView struct {
	AwakeningReady bool
	Activity       *objective.ActivityCatalog
	Root           objective.MissionRoot
	Instances      []objective.Instance
	Definitions    []objective.MissionDefinition
}

func (m MissionMaterializer) MaterializeTx(ctx context.Context, t tx.Tx, scope MissionScope) (MissionView, error) {
	if m.Store == nil || m.Catalog == nil || m.Observations == nil || t == nil || !scope.PlayerID.Valid() || scope.DecisionAt.IsZero() {
		return MissionView{}, errors.New("mission materialization ports/scope incomplete")
	}
	if err := validateContentRevision(scope.ContentRevision); err != nil {
		return MissionView{}, err
	}
	root, err := m.Store.LockMissionRootTx(ctx, t, scope.PlayerID, scope.DecisionAt)
	if err != nil {
		return MissionView{}, err
	}
	next, changed, err := root.Rollover(scope.DecisionAt)
	if err != nil {
		return MissionView{}, err
	}
	if changed {
		if err := m.Store.SaveMissionRootTx(ctx, t, next, root.StateVersion); err != nil {
			return MissionView{}, err
		}
	}
	root = next
	daily := objective.MissionDefinition{GenerationKind: "DAY"}
	generation, err := daily.MissionGeneration(scope.DecisionAt, 0)
	if err != nil {
		return MissionView{}, err
	}
	if err := m.Store.DeletePreviousDailyMissionsTx(ctx, t, scope.PlayerID, generation); err != nil {
		return MissionView{}, err
	}
	definitions, err := m.Catalog.MissionDefinitionsTx(ctx, t, scope.ContentRevision)
	if err != nil {
		return MissionView{}, err
	}
	catalogs := map[string][]objective.MissionDefinition{scope.ContentRevision: definitions}
	instances, err := m.Store.ListMissionInstancesTx(ctx, t, scope.PlayerID)
	if err != nil {
		return MissionView{}, err
	}
	byOccurrence := make(map[string]objective.Instance, len(instances))
	for _, instance := range instances {
		byOccurrence[missionOccurrence(instance.ObjectiveID, instance.GenerationID)] = instance
	}
	heroes, err := m.Observations.MissionPartnerTemplatesTx(ctx, t, scope)
	if err != nil {
		return MissionView{}, err
	}
	heroes = slices.Clone(heroes)
	slices.Sort(heroes)
	heroes = slices.Compact(heroes)
	for _, definition := range definitions {
		if err := definition.Validate(); err != nil {
			return MissionView{}, err
		}
		bindings := []int64{0}
		if definition.Family == objective.Partner {
			bindings = heroes
		}
		for _, hero := range bindings {
			if definition.Family == objective.Partner && hero <= 0 {
				return MissionView{}, errors.New("invalid partner mission template identity")
			}
			instance, exists, err := m.materializeOne(ctx, t, scope, definition, hero, byOccurrence, catalogs)
			if err != nil {
				return MissionView{}, err
			}
			if exists {
				byOccurrence[missionOccurrence(instance.ObjectiveID, instance.GenerationID)] = instance
			}
		}
	}
	instances = make([]objective.Instance, 0, len(byOccurrence))
	for _, instance := range byOccurrence {
		instances = append(instances, instance)
	}
	slices.SortFunc(instances, func(a, b objective.Instance) int {
		if a.ObjectiveID < b.ObjectiveID {
			return -1
		}
		if a.ObjectiveID > b.ObjectiveID {
			return 1
		}
		return slices.Compare([]byte(a.GenerationID), []byte(b.GenerationID))
	})
	view := MissionView{Root: root, Instances: instances, Definitions: definitions}
	if m.Activity != nil {
		activity, err := m.Activity.MissionActivityCatalogTx(ctx, t, scope.ContentRevision)
		if err != nil {
			return MissionView{}, err
		}
		view.Activity = activity
	}
	if m.Awakening != nil {
		a, err := m.Awakening.ReadAwakeningTx(ctx, t, scope.PlayerID)
		if err != nil {
			return MissionView{}, err
		}
		view.AwakeningReady = awakeningReady(a)
	}
	return view, nil
}

func missionOccurrence(id int64, generation string) string {
	return fmt.Sprintf("%d:%s", id, generation)
}

func (m MissionMaterializer) materializeOne(ctx context.Context, t tx.Tx, scope MissionScope, definition objective.MissionDefinition, hero int64, instances map[string]objective.Instance, catalogs map[string][]objective.MissionDefinition) (objective.Instance, bool, error) {
	generation, err := definition.MissionGeneration(scope.DecisionAt, hero)
	if err != nil {
		return objective.Instance{}, false, err
	}
	instance, exists := instances[missionOccurrence(definition.ObjectiveID, generation)]
	if exists && instance.ClaimState == objective.Claimed {
		return instance, true, nil
	}
	if exists && instance.ContentRevision != scope.ContentRevision {
		pinned, ok := catalogs[instance.ContentRevision]
		if !ok {
			pinned, err = m.Catalog.MissionDefinitionsTx(ctx, t, instance.ContentRevision)
			if err != nil {
				return objective.Instance{}, false, err
			}
			catalogs[instance.ContentRevision] = pinned
		}
		found := false
		for _, candidate := range pinned {
			if candidate.ObjectiveID == instance.ObjectiveID && candidate.ProgramID == instance.ProgramID && candidate.DefinitionRevision == instance.DefinitionRevision {
				definition, found = candidate, true
				break
			}
		}
		if !found {
			return objective.Instance{}, false, ErrObjectiveNotFound
		}
		if err := definition.Validate(); err != nil {
			return objective.Instance{}, false, err
		}
		scope.ContentRevision = instance.ContentRevision
	}
	if previous := definition.Prerequisite.Previous; !exists && previous != 0 && instances[missionOccurrence(previous, generation)].ClaimState != objective.Claimed {
		return objective.Instance{}, false, nil
	}
	observation, err := m.Observations.ObserveMissionTx(ctx, t, scope, definition, hero)
	if err != nil {
		return objective.Instance{}, false, err
	}
	if observation.Value < 0 {
		return objective.Instance{}, false, errors.New("negative canonical mission observation")
	}
	if !observation.GatePassed {
		return instance, exists, nil
	}
	if !exists {
		instance = objective.Instance{PlayerID: scope.PlayerID, ProgramID: definition.ProgramID, ObjectiveID: definition.ObjectiveID, GenerationID: generation,
			DefinitionRevision: definition.DefinitionRevision, ContentRevision: scope.ContentRevision, ClaimState: objective.Unclaimed, StateVersion: 1}
	}
	core, err := definition.Definition()
	if err != nil {
		return objective.Instance{}, false, err
	}
	next := instance
	if core.Strategy != objective.CommittedDeltaFact && m.bindingAvailable(definition) {
		next, _, err = objective.ApplyFact(instance, core, objective.Fact{PlayerID: scope.PlayerID, SourceDomain: "objective-observation", SourceBusinessKey: missionOccurrence(instance.ObjectiveID, generation), Kind: core.AcceptedFactKind, Value: observation.Value}, scope.DecisionAt)
		if err != nil {
			return objective.Instance{}, false, err
		}
	}
	if !exists {
		err = m.Store.InsertMissionInstanceTx(ctx, t, next)
	} else if next.StateVersion != instance.StateVersion {
		err = m.Store.SaveObjectiveTx(ctx, t, next, instance.StateVersion)
	}
	return next, true, err
}

func (m MissionMaterializer) bindingAvailable(definition objective.MissionDefinition) bool {
	return definition.Presentation.DeferredUntil == "" || m.Activity != nil && definition.Presentation.DeferredUntil == "I9-4B"
}
