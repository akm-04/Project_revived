package combatresolver

import (
	"bytes"
	"crypto/sha256"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

// The job popup needs an automatic outcome, without opening the legacy raid UI.
func TestWorkplaceAutomaticRivalUsesDetachedServerReport(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	snapshot := templateSnapshot(t,
		[]combat.Actor{TemplateHero(t, 10001001, 3, 40, 3)},
		[]combat.Actor{TemplateHero(t, 10001002, 1, 20, 2)})
	snapshot.Battle.CampaignType = 6
	snapshot.Battle.BattleID = 113001
	root := sha256.Sum256([]byte("workplace.automatic-rival/v1"))
	first, err := Resolve(corpus, snapshot, root)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Resolve(corpus, snapshot, root)
	if err != nil {
		t.Fatal(err)
	}
	if first.Outcome.Frames <= 0 || first.Outcome.ReportError || len(first.Report) == 0 || !bytes.Equal(first.Report, second.Report) || first.Outcome != second.Outcome {
		t.Fatalf("invalid or nonrepeatable automatic job result: %+v / %+v", first.Outcome, second.Outcome)
	}
	t.Logf("actual source engine outcome %+v; report bytes %d", first.Outcome, len(first.Report))
}
