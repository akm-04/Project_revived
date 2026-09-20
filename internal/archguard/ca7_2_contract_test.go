package archguard

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

func TestCA73HeroAppearanceActivationPreservesLaterStageFences(t *testing.T) {
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
	for _, forbidden := range []string{"68", "69", "1893", "1894", "1895"} {
		if regexp.MustCompile(`\b` + forbidden + `\b`).MatchString(heroMIDs) {
			t.Fatalf("later-stage appearance MID %s leaked into production Hero registration", forbidden)
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
	combined := hero + "\n" + string(petDispatcher)
	for _, forbidden := range []string{"case 68:", "case 69:", "case 1893:", "case 1894:", "case 1895:"} {
		if strings.Contains(combined, forbidden) {
			t.Fatalf("CA7-4/5 mutation route prematurely implemented %q", forbidden)
		}
	}

	storeBytes, err := os.ReadFile("../adapters/postgres/characterstore/appearance.go")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(storeBytes), "SaveHeroAppearanceMutationTx") {
		t.Fatal("CA7-3 cohesive Hero appearance CAS missing")
	}
	materializerBytes, err := os.ReadFile("../application/characterhero/appearance_materializer.go")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(materializerBytes), "TxPermanentSkinMaterializer") || !strings.Contains(string(materializerBytes), "GrantPermanentSkinTx") {
		t.Fatal("CA7-3 typed future-Commerce permanent-skin materialization seam missing")
	}
}
