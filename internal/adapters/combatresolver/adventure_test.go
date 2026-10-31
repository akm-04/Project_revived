package combatresolver

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	ad "gxb.local/backend/v2/internal/domain/adventure"
	il "gxb.local/backend/v2/internal/domain/illusion"
)

// One sample of each Adventure battle shape resolves headless against the
// genuine owned team: a defense campaign position and the illusion co-op boss.
func TestAdventureBattleShapesResolve(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	fights := map[string]int64{"defense": 981001}
	raw, err := os.ReadFile("../../content/builtin/generated/illusion_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var fantasy il.Catalog
	if err = json.Unmarshal(raw, &fantasy); err != nil {
		t.Fatal(err)
	}
	campaign, found := fantasy.Campaign(ad.IllusionHiddenBoss)
	if !found {
		t.Fatal("adventure illusion campaign missing")
	}
	fights["illusion-coop"] = campaign.FightID
	for name, fight := range fights {
		t.Run(name, func(t *testing.T) {
			result, err := Resolve(corpus, lineupGenuine(t, fight), sha256.Sum256([]byte("i9-8d-adventure-"+fmt.Sprint(fight))))
			if err != nil {
				t.Fatal(err)
			}
			if result.Outcome.Frames <= 0 || result.Outcome.ReportError {
				t.Fatal("adventure fight did not run", result.Outcome)
			}
		})
	}
}
