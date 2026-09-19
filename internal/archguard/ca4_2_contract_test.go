package archguard

import (
	"os"
	"path/filepath"
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
	if !strings.Contains(main, "[]uint16{49, 51, 52, 54, 55, 57, 58, 62, 63, 67, 89, 304}") {
		t.Error("CA4-5 MID54/MID62 are not in the production Hero registration set")
	}
}
