package combatresolver

import (
	"crypto/sha256"
	"encoding/json"
	"os"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

// A recorded Top Floor arena battle in which the robot's Manchong (table
// 10001208) mirrors an owned team-A hero. Before the fix the server branch
// left the mirrored NormalHero.selfPlayer nil and the resolver failed
// permanently in getWhiteAlbumAttr.
func TestManchongMirrorOfOwnedHeroResolves(t *testing.T) {
	raw, err := os.ReadFile("testdata/i9_10_topfloor_manchong_mirror.json")
	if err != nil {
		t.Fatal(err)
	}
	var snapshot combat.Snapshot
	if err = json.Unmarshal(raw, &snapshot); err != nil {
		t.Fatal(err)
	}
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	result, err := Resolve(corpus, snapshot, sha256.Sum256([]byte("tmp")))
	if err != nil {
		t.Fatalf("mirror battle did not resolve: %v", err)
	}
	var report map[string]any
	if err = json.Unmarshal(result.Report, &report); err != nil {
		t.Fatal(err)
	}
	if report["fighter"] == nil || report["star"] == nil || report["hero_collect_attr"] == nil {
		t.Fatalf("mirror battle report is incomplete: %v", report)
	}
}
