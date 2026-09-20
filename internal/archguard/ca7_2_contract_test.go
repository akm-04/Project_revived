package archguard

import (
	"os"
	"strings"
	"testing"
)

func TestCA72FoundationScopeAndMutationMIDFence(t *testing.T) {
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
			t.Fatalf("CA7-2 migration missing %q", need)
		}
	}

	mainBytes, err := os.ReadFile("../../cmd/gxb-api/main_postgres.go")
	if err != nil {
		t.Fatal(err)
	}
	main := string(mainBytes)
	for _, mid := range []string{"60", "61", "68", "69", "1893", "1894", "1895", "2979"} {
		if strings.Contains(main, "mustRegister("+mid+",") {
			t.Fatalf("CA7-2 prematurely registered appearance MID %s", mid)
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
	combined := string(heroDispatcher) + "\n" + string(petDispatcher)
	for _, mid := range []string{"case 60:", "case 61:", "case 68:", "case 69:", "case 1893:", "case 1894:", "case 1895:", "case 2979:"} {
		if strings.Contains(combined, mid) {
			t.Fatalf("CA7-2 prematurely implemented mutation route %q", mid)
		}
	}
}
