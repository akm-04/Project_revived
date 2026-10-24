package archguard

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

func TestCA75AppearanceActivationPreservesOwnerAndSuccessorFences(t *testing.T) {
	migration, err := os.ReadFile("../../migrations/00030_ca7_2_appearance_foundation.sql")
	if err != nil {
		t.Fatal(err)
	}
	m := string(migration)
	for _, need := range []string{
		"ADD COLUMN current_skin_id",
		"ADD COLUMN illusion_skin_id",
		"ADD COLUMN active_style",
		"CREATE TABLE player_hero_skin_entitlements",
		"CREATE TABLE player_hero_live_entitlements",
		"CREATE TABLE player_pet_style_entitlements",
		"CREATE TABLE gxb_content_appearance_skins",
		"CREATE TABLE gxb_content_appearance_skin_items",
		"CREATE TABLE gxb_content_appearance_live",
		"CREATE TABLE gxb_content_appearance_pet_styles",
	} {
		if !strings.Contains(m, need) {
			t.Fatalf("CA7-2 foundation migration missing %q", need)
		}
	}

	mainBytes, err := os.ReadFile("../../cmd/gxb-api/main_postgres.go")
	if err != nil {
		t.Fatal(err)
	}
	main := string(mainBytes)
	registration := regexp.MustCompile(`for _, mid := range \[]uint16\{([^}]*)\} \{\n\t\tmustRegister\(mid, heroD\)`).FindStringSubmatch(main)
	if len(registration) != 2 {
		t.Fatal("could not resolve production Hero registration set")
	}
	heroMIDs := registration[1]
	for _, required := range []string{"60", "61", "2979"} {
		if !regexp.MustCompile(`\b` + required + `\b`).MatchString(heroMIDs) {
			t.Fatalf("CA7-3 Hero MID %s is not registered in production", required)
		}
	}
	for _, required := range []string{"68", "69"} {
		if !regexp.MustCompile(`\b` + required + `\b`).MatchString(heroMIDs) {
			t.Fatalf("CA7-4 Hero MID %s is not registered in production", required)
		}
	}
	for _, forbidden := range []string{"1893", "1894", "1895"} {
		if regexp.MustCompile(`\b` + forbidden + `\b`).MatchString(heroMIDs) {
			t.Fatalf("Pet-owned CA7-5 MID %s leaked into production Hero registration", forbidden)
		}
	}

	petRegistration := regexp.MustCompile(`for _, mid := range \[]uint16\{([^}]*)\} \{\n\t\tmustRegister\(mid, petD\)`).FindStringSubmatch(main)
	if len(petRegistration) != 2 {
		t.Fatal("could not resolve production Pet registration set")
	}
	petMIDs := petRegistration[1]
	for _, required := range []string{"1893", "1894", "1895"} {
		if !regexp.MustCompile(`\b` + required + `\b`).MatchString(petMIDs) {
			t.Fatalf("CA7-5 Pet MID %s is not registered in production", required)
		}
	}

	heroDispatcher, err := os.ReadFile("../adapters/stockruntime/hero_dispatcher.go")
	if err != nil {
		t.Fatal(err)
	}
	petDispatcher, err := os.ReadFile("../adapters/stockruntime/pet_dispatcher.go")
	if err != nil {
		t.Fatal(err)
	}
	hero := string(heroDispatcher)
	for _, required := range []string{"case 60:", "case 61:", "case 2979:"} {
		if !strings.Contains(hero, required) {
			t.Fatalf("CA7-3 missing Hero mutation route %q", required)
		}
	}
	pet := string(petDispatcher)
	for _, required := range []string{"case 68:", "case 69:"} {
		if !strings.Contains(hero, required) {
			t.Fatalf("CA7-4 missing Hero LIVE mutation route %q", required)
		}
	}
	for _, required := range []string{"case 1893:", "case 1894:", "case 1895:"} {
		if !strings.Contains(pet, required) {
			t.Fatalf("CA7-5 missing Pet home-style mutation route %q", required)
		}
		if strings.Contains(hero, required) {
			t.Fatalf("CA7-5 Pet home-style route leaked into Hero dispatcher %q", required)
		}
	}

	storeBytes, err := os.ReadFile("../adapters/postgres/characterstore/appearance.go")
	if err != nil {
		t.Fatal(err)
	}
	store := string(storeBytes)
	if !strings.Contains(store, "SaveHeroAppearanceMutationTx") {
		t.Fatal("CA7-3 cohesive Hero appearance CAS missing")
	}
	for _, required := range []string{"SavePetAppearanceMutationTx", "SavePetActiveStyleTx"} {
		if !strings.Contains(store, required) {
			t.Fatalf("CA7-5 Pet-owned appearance CAS seam missing %q", required)
		}
	}
	materializerBytes, err := os.ReadFile("../application/characterhero/appearance_materializer.go")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(materializerBytes), "TxPermanentSkinMaterializer") || !strings.Contains(string(materializerBytes), "GrantPermanentSkinTx") {
		t.Fatal("CA7-3 typed future-Commerce permanent-skin materialization seam missing")
	}
}
