package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCA53ActivatesOnlyNarrowSavedPresetMutationSurface(t *testing.T) {
	root := repoRoot(t)
	main, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	ms := string(main)
	for _, need := range []string{
		"SavedPresetDispatcher", "mustRegister(1793, savedPresetD)",
		"MutationService", "ReferenceOwners{Heroes: heroDB, Pets: heroDB}",
	} {
		if !strings.Contains(ms, need) {
			t.Errorf("CA5-3 production composition missing %q", need)
		}
	}
	for _, bad := range []string{"mustRegister(208", "mustRegister(209"} {
		if strings.Contains(ms, bad) {
			t.Errorf("CA5-3 activated unqualified MID registration %q", bad)
		}
	}

	dispatch, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "stockruntime", "saved_preset_dispatcher.go"))
	if err != nil {
		t.Fatal(err)
	}
	ds := string(dispatch)
	for _, need := range []string{
		"req.Envelope.MID != 1793", "team_str", "team_name_str", "pet_str",
		"PetPresent", `"save_team"`, `"save_team_name"`, `"save_pet"`,
	} {
		if !strings.Contains(ds, need) {
			t.Errorf("CA5-3 dispatcher missing %q", need)
		}
	}
	if strings.Contains(ds, "error_code") {
		t.Fatal("CA5-3 invented preset-specific stock error_code")
	}
}

func TestCA53ReusesQualifiedTransactionReferenceAndReplayFoundations(t *testing.T) {
	root := repoRoot(t)
	service, err := os.ReadFile(filepath.Join(root, "internal", "application", "charactersavedpreset", "service.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(service)
	for _, need := range []string{
		"tx.Options{Isolation: tx.ReadCommitted}", "FenceActorTx", "RetryDefiniteAbort: true", "CollectReferences", "UnionReferences", ".Covers(",
		"HeroReferenceLockKey", "PetReferenceLockKey", "LockSavedPresetRootTx", "MarkDefiniteAbort",
		"character-saved-preset", "SemanticKey: op.ID.String()", "pet_present", "gxb.ca5.saved-preset-replace.v1",
	} {
		if !strings.Contains(s, need) {
			t.Errorf("CA5-3 service missing reused contract marker %q", need)
		}
	}
	if strings.Contains(s, "tx.Options{Isolation: tx.Serializable}") {
		t.Fatal("CA5-3 regressed to SERIALIZABLE despite explicit Hero/Pet/root lock closure")
	}
	for _, bad := range []string{"player_heroes", "player_pets", "DecisionAt", "17.formation"} {
		if strings.Contains(s, bad) {
			t.Errorf("CA5-3 service leaked forbidden ownership/time marker %q", bad)
		}
	}

	catalog, err := os.ReadFile(filepath.Join(root, "internal", "foundation", "replaycatalog", "catalog.go"))
	if err != nil {
		t.Fatal(err)
	}
	cs := string(catalog)
	for _, need := range []string{"ca5.saved-preset-replace", "CurrentStateConvergence", "stock nonce absent", "gxb.ca5.saved-preset-replace.v1"} {
		if !strings.Contains(cs, need) {
			t.Errorf("CA5-3 replay catalog missing %q", need)
		}
	}
}

func TestCA53PreservesCA52PersistenceAndProjectionBoundaries(t *testing.T) {
	root := repoRoot(t)
	proj, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "characterstore", "saved_preset_projection.go"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(proj), "17.formation") {
		t.Fatal("CA5-3 claimed unresolved 17.formation")
	}
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		name := strings.ToLower(e.Name())
		if strings.Contains(name, "ca5_3") {
			t.Fatalf("CA5-3 introduced unauthorized phase-owned schema migration %s", e.Name())
		}
	}
}
