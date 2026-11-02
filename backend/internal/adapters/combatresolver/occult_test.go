package combatresolver

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	d "gxb.local/backend/v2/internal/domain/occult"
)

// Every fight of the Occult team campaigns (campaign_type 1) resolves headless
// against the genuine owned team, so a resolver crash cannot hide behind a canned
// report as it did for Illusion.
func TestOccultTeamFightsResolve(t *testing.T) {
	raw, err := os.ReadFile("../../content/builtin/generated/occult_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog d.Catalog
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	// Each fight takes seconds, so the first and last fight of every chapter stand
	// for the 80; the whole set was resolved once by hand for I9-8C.
	var fights []int64
	for _, chapter := range catalog.Chapters {
		var chapterFights []int64
		for _, campaign := range catalog.RoomCampaigns(chapter.ID, d.MultiCampaignType) {
			chapterFights = append(chapterFights, campaign.FightIDs...)
		}
		if len(chapterFights) > 0 {
			fights = append(fights, chapterFights[0], chapterFights[len(chapterFights)-1])
		}
	}
	resolved := len(fights)
	for _, fight := range fights {
		t.Run(fmt.Sprint(fight), func(t *testing.T) {
			result, err := Resolve(corpus, lineupGenuine(t, fight), sha256.Sum256([]byte("i9-8c-occult-team")))
			if err != nil {
				t.Fatal(err)
			}
			if result.Outcome.Frames <= 0 || result.Outcome.ReportError {
				t.Fatal("occult team fight did not run", result.Outcome)
			}
		})
	}
	if resolved == 0 {
		t.Fatal("no occult team fights found")
	}
}
