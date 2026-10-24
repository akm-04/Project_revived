package i5

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type openObjectives struct {
	instances   []objective.Instance
	definitions []ObjectiveDefinition
}

func (o *openObjectives) LockOpenObjectivesTx(context.Context, tx.Tx, identity.PlayerID) ([]objective.Instance, []ObjectiveDefinition, error) {
	return o.instances, o.definitions, nil
}

// Wave-I fixture 53: a duplicated objective fact advances progress once.
func TestObjectiveFactsAdvanceMatchingKindOncePerFact(t *testing.T) {
	actor := testActor(t)
	store := &testStore{}
	receipts := newMemoryReceipts()
	definition := func(id int64, kind string) ObjectiveDefinition {
		return ObjectiveDefinition{Family: objective.Daily, Definition: objective.Definition{ProgramID: "daily", ObjectiveID: id, DefinitionRevision: "r1", Strategy: objective.CommittedDeltaFact, AcceptedFactKind: kind, Target: 3}}
	}
	instance := func(id int64) objective.Instance {
		return objective.Instance{PlayerID: actor.PlayerID, ProgramID: "daily", ObjectiveID: id, GenerationID: "day", DefinitionRevision: "r1", ClaimState: objective.Unclaimed, StateVersion: 1}
	}
	open := &openObjectives{instances: []objective.Instance{instance(10006), instance(10002)}, definitions: []ObjectiveDefinition{definition(10006, objective.PVPFightKind), definition(10002, "CAMPAIGN_NORMAL_CLEAR")}}
	port := ObjectiveFacts{Owner: Service{Store: store, Receipts: receipts, ReceiptRead: receipts}, Open: open}
	fact := objective.Fact{PlayerID: actor.PlayerID, SourceDomain: "top-floor", SourceBusinessKey: "attempt-1", Kind: objective.PVPFightKind, Delta: 1}
	for attempt := byte(0); attempt < 2; attempt++ {
		if err := port.RecordTx(context.Background(), &testTx{}, testOperation(80+attempt), fact); err != nil {
			t.Fatal(err)
		}
		open.instances[0] = store.objectiveInst
	}
	if store.saveObjectiveCalls != 1 || store.objectiveInst.ObjectiveID != 10006 || store.objectiveInst.Progress != 1 {
		t.Fatalf("saves %d last %+v", store.saveObjectiveCalls, store.objectiveInst)
	}
}
