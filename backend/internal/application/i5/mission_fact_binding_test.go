package i5

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/policy"
)

func TestMissionFactKeepsSourceAndPinnedConsumerContentDistinct(t *testing.T) {
	actor := testActor(t)
	store, receipts := &testStore{}, newMemoryReceipts()
	svc := Service{Store: store, Receipts: receipts}
	definition := ObjectiveDefinition{Family: objective.GrowMain, Definition: objective.Definition{ProgramID: "mission:2", ObjectiveID: 70003, DefinitionRevision: "I9_MISSIONS_V1", Strategy: objective.CommittedDeltaFact, AcceptedFactKind: "SUMMON", Target: 1}}
	instance := objective.Instance{PlayerID: actor.PlayerID, ProgramID: "mission:2", ObjectiveID: 70003, GenerationID: "lifetime", DefinitionRevision: "I9_MISSIONS_V1", ContentRevision: testContentRevisionA, ClaimState: objective.Unclaimed, StateVersion: 1}
	source := testOperation(210)
	refs, err := policy.NewSet(policy.Ref{Name: contentPolicyRefName, Version: testContentRevisionB})
	if err != nil {
		t.Fatal(err)
	}
	source.Policies = refs
	fact := objective.Fact{PlayerID: actor.PlayerID, SourceDomain: "summon", SourceBusinessKey: "pull-1", Kind: "SUMMON", Delta: 1}
	ctx := context.Background()
	if _, _, err := svc.ApplyObjectiveFactTx(ctx, &testTx{}, definition, instance, fact, source); !errors.Is(err, ErrContentRevisionConflict) {
		t.Fatalf("existing strict path relaxed: %v", err)
	}
	at := source.StartedAt.Add(time.Second)
	next, changed, err := svc.applyMissionFactTx(ctx, &testTx{}, definition, instance, fact, source, at)
	if err != nil || !changed || next.Progress != 1 || next.CompletedAt == nil || !next.CompletedAt.Equal(at) {
		t.Fatalf("mission fact %+v %v %v", next, changed, err)
	}
	if _, changed, err := svc.applyMissionFactTx(ctx, &testTx{}, definition, next, fact, source, at); err != nil || changed || store.saveObjectiveCalls != 1 {
		t.Fatalf("fact replay changed progress: %v %v", changed, err)
	}
	if _, exists := source.Policies.Get(missionContentPolicyRefName); exists {
		t.Fatal("consumer binding mutated source operation")
	}
	if len(receipts.m) != 1 {
		t.Fatalf("receipt count %d", len(receipts.m))
	}
	for _, r := range receipts.m {
		active, sourceOK := r.OperationPolicyRefs.Get(contentPolicyRefName)
		pinned, consumerOK := r.OperationPolicyRefs.Get(missionContentPolicyRefName)
		if !sourceOK || !consumerOK || active != testContentRevisionB || pinned != testContentRevisionA || !r.OperationStartedAt.Equal(source.StartedAt) {
			t.Fatalf("receipt binding %+v", r)
		}
	}
}
