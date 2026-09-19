package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCA54ActivatesOnlyReferenceGuardAndImmutableReferenceState(t *testing.T) {
	root := repoRoot(t)
	dto, err := os.ReadFile(filepath.Join(root, "internal", "application", "characterasset", "saved_preset_reference_state.go"))
	if err != nil {
		t.Fatal(err)
	}
	ds := string(dto)
	for _, need := range []string{"SavedPresetReferenceState", "StateVersion", "SavedPresetReferenceLoadout", "[]character.HeroRef", "*character.PetRef", "Clone()"} {
		if !strings.Contains(ds, need) {
			t.Errorf("CA5-4 reference DTO missing %q", need)
		}
	}
	for _, bad := range []string{"Name string", "Formation", "Mode", "BattleStat", "Selected"} {
		if strings.Contains(ds, bad) {
			t.Errorf("CA5-4 reference DTO leaked non-reference authority %q", bad)
		}
	}

	guard, err := os.ReadFile(filepath.Join(root, "internal", "application", "charactersavedpreset", "reference_guard.go"))
	if err != nil {
		t.Fatal(err)
	}
	gs := string(guard)
	for _, need := range []string{
		`SavedPresetReferenceGuardProviderID = "ca5.saved-presets"`,
		"PreflightHeroRemovalTx", "PreflightPetRemovalTx", "SavedPresetRootLockKey",
		"LockReferenceGuardKeyTx", "SavedPresetReferencesHeroTx", "SavedPresetReferencesPetTx", "ErrReferenceInUse",
	} {
		if !strings.Contains(gs, need) {
			t.Errorf("CA5-4 guard missing %q", need)
		}
	}
	for _, bad := range []string{"DELETE FROM", "player_heroes", "player_pets", "Detach", "RemoveHero", "RemovePet"} {
		if strings.Contains(gs, bad) {
			t.Errorf("CA5-4 guard leaked destructive/foreign-owner marker %q", bad)
		}
	}
}

func TestCA54QueriesRemainSavedPresetOwnedAndSchemaFree(t *testing.T) {
	root := repoRoot(t)
	preset, err := os.ReadFile(filepath.Join(root, "sql", "character", "preset.sql"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(preset)
	for _, need := range []string{"SavedPresetReferencesHero", "SavedPresetReferencesPet", "player_saved_preset_heroes", "player_saved_preset_lanes", "SELECT EXISTS"} {
		if !strings.Contains(s, need) {
			t.Errorf("CA5-4 preset query surface missing %q", need)
		}
	}
	for _, bad := range []string{"player_heroes", "player_pets", "DELETE FROM player_heroes", "DELETE FROM player_pets"} {
		if strings.Contains(s, bad) {
			t.Errorf("CA5-4 preset queries leaked owner SQL %q", bad)
		}
	}
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		name := strings.ToLower(e.Name())
		if strings.Contains(name, "ca5_4") {
			t.Fatalf("CA5-4 introduced unauthorized phase-owned schema migration %s", e.Name())
		}
	}
}

func TestCA54PreservesDestructiveFormationAndModeNegativeScopes(t *testing.T) {
	root := repoRoot(t)
	stock := filepath.Join(root, "internal", "adapters", "stockruntime")
	forbidden := []string{"case 66:", "case 208:", "case 209:"}
	err := filepath.WalkDir(stock, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") {
			return err
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for _, bad := range forbidden {
			if strings.Contains(string(b), bad) {
				t.Errorf("CA5-4 activated forbidden stock marker %q in %s", bad, path)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	main, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	ms := string(main)
	for _, bad := range []string{"mustRegister(66", "mustRegister(208", "mustRegister(209"} {
		if strings.Contains(ms, bad) {
			t.Errorf("CA5-4 registered forbidden MID %q", bad)
		}
	}
	proj, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "characterstore", "saved_preset_projection.go"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(proj), "17.formation") {
		t.Fatal("CA5-4 claimed unresolved 17.formation")
	}

	for _, rel := range []string{"sql/character/hero.sql", "sql/character/pet.sql"} {
		b, err := os.ReadFile(filepath.Join(root, rel))
		if err != nil {
			t.Fatal(err)
		}
		s := string(b)
		if strings.Contains(s, "DELETE FROM player_heroes") || strings.Contains(s, "DELETE FROM player_pets") {
			t.Errorf("CA5-4 activated destructive source-owner SQL in %s", rel)
		}
	}
}
