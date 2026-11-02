package i5

import (
	"gxb.local/backend/v2/internal/domain/objective"
	"testing"
)

func TestMarchProducerActivatesOldPinnedDefinitionOnly(t *testing.T) {
	m := MissionMaterializer{}
	d := objective.MissionDefinition{AcceptedFactKind: "MARCH_FINISHED", Presentation: objective.MissionPresentation{DeferredUntil: "I9-5"}}
	if !m.bindingAvailable(d) {
		t.Fatal("old pinned March mission remained deferred")
	}
	for _, kind := range []string{"TREASURE_FINISHED", "PET_CAMPAIGN_FINISHED", "SUMMON"} {
		d.AcceptedFactKind = kind
		if m.bindingAvailable(d) {
			t.Fatal("unimplemented producer activated", kind)
		}
	}
	d.AcceptedFactKind = "MARCH_FINISHED"
	d.Presentation.DeferredUntil = "I10"
	if m.bindingAvailable(d) {
		t.Fatal("unrelated deferral bypassed")
	}
}
