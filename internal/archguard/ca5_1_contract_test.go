package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCA51ReferenceFoundationDoesNotActivateFeatureState(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "characterasset")
	b, err := os.ReadFile(filepath.Join(base, "references.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{
		"SavedPresetRootLockRank", "character.saved-preset-root", "HeroReferenceOwner", "PetReferenceOwner",
		"ReferenceGuardPlan", "HeroRemovalGuard", "PetRemovalGuard", "ErrReferenceInUse",
	} {
		if !strings.Contains(s, need) {
			t.Errorf("CA5-1 reference foundation missing %q", need)
		}
	}
	for _, bad := range []string{
		"save_team", "save_team_name", "save_pet", "MID1793", "MID208", "MID209",
		"replaycatalog", "receipt.", "player_saved_presets", "gxb_content_", "database/sql", "github.com/jackc/pgx",
	} {
		if strings.Contains(s, bad) {
			t.Errorf("CA5-1 reference foundation contains forbidden activation marker %q", bad)
		}
	}
}

func TestCA51SharedFoundationRemainsSchemaFreeInCumulativeTree(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "internal", "application", "characterasset", "references.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, bad := range []string{"CREATE TABLE", "player_saved_preset_roots", "player_saved_preset_lanes", "player_saved_preset_heroes", "characterqueries"} {
		if strings.Contains(s, bad) {
			t.Fatalf("CA5-1 shared foundation absorbed CA5-2 persistence marker %q", bad)
		}
	}
}

func TestCA51SuccessorKeepsUnqualifiedFormationMIDsInactive(t *testing.T) {
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
		s := string(b)
		for _, bad := range forbidden {
			if strings.Contains(s, bad) {
				t.Errorf("CA5-1 successor boundary activated forbidden MID marker %q in %s", bad, path)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestCA51CharacterAssetBoundaryDoesNotOwnHeroPetPersistence(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "characterasset")
	forbidden := []string{"player_heroes", "player_pets", "LockHeroByPartnerIDTx", "LockPetByIDTx", "characterqueries"}
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
				t.Errorf("shared CA5-1 boundary leaks owner persistence marker %q in %s", bad, path)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
