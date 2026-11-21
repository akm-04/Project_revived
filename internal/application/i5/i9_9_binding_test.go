package i5

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/objective"
)

func TestShippedI9NineProducersActivateTheirPinnedRows(t *testing.T) {
	m := MissionMaterializer{}
	for _, kind := range []string{"GUILD_ACTIVITY", "TEA_PARTY_DONATED"} {
		d := objective.MissionDefinition{AcceptedFactKind: kind, Presentation: objective.MissionPresentation{DeferredUntil: "I9-9"}}
		if !m.bindingAvailable(d) {
			t.Fatalf("shipped I9-9 producer %s stayed deferred", kind)
		}
	}
	for _, kind := range []string{"HERO_LENT", "LESSON_ATTENDED"} {
		d := objective.MissionDefinition{AcceptedFactKind: kind, Presentation: objective.MissionPresentation{DeferredUntil: "I9-9"}}
		if m.bindingAvailable(d) {
			t.Fatalf("unshipped I9-9 producer %s was activated", kind)
		}
	}
}

func TestDeferredQuizProducerStaysInactive(t *testing.T) {
	m := MissionMaterializer{}
	d := objective.MissionDefinition{AcceptedFactKind: "COURSE_QUIZ", Presentation: objective.MissionPresentation{DeferredUntil: "I9-10"}}
	if m.bindingAvailable(d) {
		t.Fatal("course quiz has no producer but its row was activated")
	}
}
