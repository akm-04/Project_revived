package archguard

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestCA45SharedEquipmentWiresAreProductionRegistered(t *testing.T) {
	root := repoRoot(t)
	dispatcher, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "stockruntime", "hero_dispatcher.go"))
	if err != nil {
		t.Fatal(err)
	}
	d := string(dispatcher)
	for _, need := range []string{"case 54:", "case 62:", "error_code", "30001", `CurrentScalar(ctx, actor.PlayerID, "mana"`, `"equips": equips`, `"economy_"`} {
		if !strings.Contains(d, need) {
			t.Errorf("CA4-5 shared dispatcher missing %q", need)
		}
	}
	mainBytes, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	main := string(mainBytes)
	for _, need := range []string{"HeroEquipmentResourceDebiter", "Equipment: contentDB", "EquipmentResources: heroEquipmentResources", "Economy: heroEconomyProjection", "54", "62"} {
		if !strings.Contains(main, need) {
			t.Errorf("CA4-5 production composition missing %q", need)
		}
	}
	registration := regexp.MustCompile(`for _, mid := range \[]uint16\{([^}]*)\} \{\n\t\tmustRegister\(mid, heroD\)`).FindStringSubmatch(main)
	if len(registration) != 2 {
		t.Fatal("could not resolve production Hero registration set")
	}
	for _, need := range []string{"54", "62"} {
		if !regexp.MustCompile(`\b` + need + `\b`).MatchString(registration[1]) {
			t.Errorf("CA4-5 MID%s is not in the production Hero registration set", need)
		}
	}
}
