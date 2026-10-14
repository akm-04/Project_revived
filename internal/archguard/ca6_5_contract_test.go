package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCA65HeroMID1ProjectionUsesOwnerStateAndCallerQueryer(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "characterstore", "hero_projection.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{
		`Claims() []string { return []string{"49"} }`, "HeroCoreActiveTx", "HeroEquipmentRevisionTx", "HeroFumoRevisionTx",
		"ReadRootTx(ctx, q", "ListHeroesTx(ctx, q", "BuildRosterViewsTx(ctx, q", "StockRosterView", `detail["49"] = body`,
	} {
		if !strings.Contains(s, need) {
			t.Errorf("Hero key49 bootstrap missing %q", need)
		}
	}
	for _, bad := range []string{"Begin(", "INSERT INTO ", "UPDATE ", "DELETE FROM ", "Save"} {
		if strings.Contains(s, bad) {
			t.Errorf("Hero key49 bootstrap leaked write/second-tx marker %q", bad)
		}
	}
}

func TestCA65MID1RegistrationAndLobby124CleanupAreExact(t *testing.T) {
	root := repoRoot(t)
	mainBytes, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	main := string(mainBytes)
	if !strings.Contains(main, "characterstore.HeroBootstrapProjection{Content: contentDB, Library: librarySvc, Dorm: dormSvc, Book: bookSvc, Course: courseSvc}") {
		t.Fatal("Hero key49 bootstrap contributor not registered")
	}
	if !strings.Contains(main, "characterstore.PetBootstrapProjection{Content: contentDB}") {
		t.Fatal("Pet key780 bootstrap contributor changed/missing")
	}

	lobbyBytes, err := os.ReadFile(filepath.Join(root, "internal", "projection", "lobby", "shapes.go"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(lobbyBytes), "case 124:") {
		t.Fatal("stale Lobby MID124 response shape remains")
	}

	practiceBytes, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "stockruntime", "practice_dispatcher.go"))
	if err != nil {
		t.Fatal(err)
	}
	practice := string(practiceBytes)
	for _, need := range []string{"case 124:", "lobby.BootLegitTimer", "d.Tracker.Record"} {
		if !strings.Contains(practice, need) {
			t.Fatalf("Practice MID124 telemetry/owner marker missing %q", need)
		}
	}
}

func TestCA65PracticeContributionSeamIsReadOnlyExactRevisionAndBattleAgnostic(t *testing.T) {
	root := repoRoot(t)
	paths := []string{
		filepath.Join(root, "internal", "application", "characterasset", "practice_contribution.go"),
		filepath.Join(root, "internal", "application", "characterpractice", "contribution.go"),
		filepath.Join(root, "internal", "application", "characterhero", "practice_contribution.go"),
		filepath.Join(root, "internal", "application", "characterpet", "practice_contribution.go"),
	}
	var joined strings.Builder
	for _, path := range paths {
		b, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		joined.Write(b)
	}
	s := joined.String()
	for _, need := range []string{
		"HeroPracticeContributionProvider", "PetPracticeContributionProvider", "PracticeRevisionTx",
		"ReadHeroByPartnerIDTx", "ReadPetByIDTx", "HeroPracticeThresholdsTx", "PetPracticeThresholdsTx",
		"ReduceAppliedPracticeContribution", "HERO_ADDITIVE", "PET_SOURCE_ORDER_OVERWRITE",
	} {
		if !strings.Contains(s, need) {
			t.Errorf("Practice contribution seam missing %q", need)
		}
	}
	for _, bad := range []string{
		"PracticeActive(", "Proposal", "battle mode", "BattleMode", "formation", "suppression", "INSERT INTO ", "UPDATE ", "DELETE FROM ",
	} {
		if strings.Contains(s, bad) {
			t.Errorf("Practice contribution seam leaked forbidden policy/ownership marker %q", bad)
		}
	}

	heroBytes, err := os.ReadFile(filepath.Join(root, "internal", "application", "characterhero", "practice_contribution.go"))
	if err != nil {
		t.Fatal(err)
	}
	hero := string(heroBytes)
	heroStart := strings.Index(hero, "func (r PracticeContributionReader) HeroPracticeContributionTx")
	if heroStart < 0 {
		t.Fatal("Hero Practice contribution method missing")
	}
	heroBody := hero[heroStart:]
	if strings.Index(heroBody, "PracticeRevisionTx") < 0 || strings.Index(heroBody, "ReadHeroByPartnerIDTx") < 0 || strings.Index(heroBody, "PracticeRevisionTx") > strings.Index(heroBody, "ReadHeroByPartnerIDTx") {
		t.Fatal("Hero Practice contribution reads owner before exact revision qualification")
	}
	petBytes, err := os.ReadFile(filepath.Join(root, "internal", "application", "characterpet", "practice_contribution.go"))
	if err != nil {
		t.Fatal(err)
	}
	pet := string(petBytes)
	petStart := strings.Index(pet, "func (r PracticeContributionReader) PetPracticeContributionTx")
	if petStart < 0 {
		t.Fatal("Pet Practice contribution method missing")
	}
	petBody := pet[petStart:]
	if strings.Index(petBody, "PracticeRevisionTx") < 0 || strings.Index(petBody, "ReadPetByIDTx") < 0 || strings.Index(petBody, "PracticeRevisionTx") > strings.Index(petBody, "ReadPetByIDTx") {
		t.Fatal("Pet Practice contribution reads owner before exact revision qualification")
	}
}

func TestCA65UnrelatedHeroPetMutationSQLPreservesPracticeAndAdvancesVersion(t *testing.T) {
	root := repoRoot(t)
	for _, tc := range []struct {
		path        string
		practiceQ   string
		tableMarker string
	}{
		{filepath.Join(root, "sql", "character", "hero.sql"), "SaveHeroPractice", "UPDATE player_heroes"},
		{filepath.Join(root, "sql", "character", "pet.sql"), "SavePetPractice", "UPDATE player_pets"},
	} {
		b, err := os.ReadFile(tc.path)
		if err != nil {
			t.Fatal(err)
		}
		parts := strings.Split(string(b), "-- name: ")
		for _, part := range parts[1:] {
			name := strings.Fields(part)
			if len(name) == 0 || !strings.Contains(part, tc.tableMarker) {
				continue
			}
			if name[0] == tc.practiceQ {
				for _, need := range []string{"practice_str", "practice_int", "practice_agi", "state_version=state_version+1"} {
					if !strings.Contains(part, need) {
						t.Fatalf("%s missing %q", name[0], need)
					}
				}
				continue
			}
			if strings.Contains(part, "practice_") {
				t.Fatalf("unrelated mutation %s writes Practice columns", name[0])
			}
			if !strings.Contains(part, "state_version=state_version+1") {
				t.Fatalf("unrelated mutation %s does not advance actor state_version", name[0])
			}
		}
	}
}

func TestCA65ContributionReadersCannotObservePendingProposalOrWriteState(t *testing.T) {
	root := repoRoot(t)
	for _, rel := range []string{
		filepath.Join("internal", "application", "characterhero", "practice_contribution.go"),
		filepath.Join("internal", "application", "characterpet", "practice_contribution.go"),
	} {
		b, err := os.ReadFile(filepath.Join(root, rel))
		if err != nil {
			t.Fatal(err)
		}
		s := string(b)
		for _, bad := range []string{"Proposal", "Pending", "Save", "Delete", "Insert", "Update", "Receipt", "Root450", "LevelAndScalar"} {
			if strings.Contains(s, bad) {
				t.Fatalf("%s leaked mutation/pending-state marker %q", rel, bad)
			}
		}
	}
}
