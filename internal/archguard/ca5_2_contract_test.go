package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCA52OwnsOnlySavedPresetPersistenceAndProjection(t *testing.T) {
	root := repoRoot(t)
	mig, err := os.ReadFile(filepath.Join(root, "migrations", "00028_ca5_2_saved_presets.sql"))
	if err != nil {
		t.Fatal(err)
	}
	ms := string(mig)
	for _, need := range []string{"player_saved_preset_roots", "player_saved_preset_lanes", "player_saved_preset_heroes", "player_saved_preset_heroes_hero_ref_idx", "player_saved_preset_lanes_pet_ref_idx"} {
		if !strings.Contains(ms, need) {
			t.Errorf("00028 missing %q", need)
		}
	}
	if strings.Contains(ms, "REFERENCES player_heroes") || strings.Contains(ms, "REFERENCES player_pets") {
		t.Fatal("CA5-2 introduced cross-owner Hero/Pet FK")
	}
	proj, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "characterstore", "saved_preset_projection.go"))
	if err != nil {
		t.Fatal(err)
	}
	ps := string(proj)
	for _, need := range []string{"17.save_team", "17.save_team_name", "17.save_pet"} {
		if !strings.Contains(ps, need) {
			t.Errorf("saved-preset MID1 projection missing %q", need)
		}
	}
	if strings.Contains(ps, "17.formation") {
		t.Fatal("CA5-2 claimed 17.formation")
	}
}

func TestCA52SuccessorKeepsUnqualifiedScopesInactive(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "adapters", "stockruntime")
	forbidden := []string{"case 208:", "case 209:"}
	err := filepath.WalkDir(base, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") {
			return err
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for _, bad := range forbidden {
			if strings.Contains(string(b), bad) {
				t.Errorf("CA5-2 successor boundary activated forbidden MID marker %q in %s", bad, path)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	// MID1793 and its replay classification are intentionally successor-qualified
	// by CA5-3. The CA5-2 owner/schema/projection boundaries above remain live.
}
