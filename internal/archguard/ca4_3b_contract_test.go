package archguard

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestCA43BProductionWiringAndSharedEquipmentBoundary(t *testing.T) {
	dispatcher, err := os.ReadFile("../adapters/stockruntime/hero_dispatcher.go")
	if err != nil {
		t.Fatal(err)
	}
	d := string(dispatcher)
	for _, need := range []string{"case 51:", "PowerUpHero(ctx, actor", "case 57:", "OneClickJinjie(ctx, actor", "heroPromotionResponse(got)", "RosterView(ctx, actor)", "StockRosterView"} {
		if !strings.Contains(d, need) {
			t.Fatalf("CA4-3B dispatcher missing %q", need)
		}
	}
	mainBytes, err := os.ReadFile("../../cmd/gxb-api/main_postgres.go")
	if err != nil {
		t.Fatal(err)
	}
	m := string(mainBytes)
	for _, need := range []string{"Promotion: contentDB", "PromotionResources: i5svc", "StrictRestoration: i5svc", "MaxHeroColorPolicy: maxHeroColorPolicy", "RosterProjection: contentDB"} {
		if !strings.Contains(m, need) {
			t.Fatalf("CA4-3B production composition missing %q", need)
		}
	}
	re := regexp.MustCompile(`(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, heroD\)`)
	match := re.FindStringSubmatch(m)
	if len(match) != 2 {
		t.Fatal("Hero production route set not found")
	}
	set := match[1]
	for _, need := range []string{"51", "57", "58"} {
		if !strings.Contains(set, need) {
			t.Fatalf("required Hero MID %s not registered: %s", need, set)
		}
	}
	manifestBytes, err := os.ReadFile(filepath.Join(repoRoot(t), "internal", "content", "builtin", "generated", "manifest.json"))
	if err != nil {
		t.Fatal(err)
	}
	ca45 := strings.Contains(string(manifestBytes), `"SUPER_EQUIPMENT_CA4_5"`)
	parts := regexp.MustCompile(`[0-9]+`).FindAllString(set, -1)
	for _, mid := range []string{"54", "62"} {
		present := false
		for _, p := range parts {
			if p == mid {
				present = true
				break
			}
		}
		if ca45 && !present {
			t.Fatalf("CA4-5 shared Hero MID %s not activated: %s", mid, set)
		}
		if !ca45 && present {
			t.Fatalf("deferred shared Hero MID %s activated before CA4-5: %s", mid, set)
		}
	}
}
