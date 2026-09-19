package archguard

import (
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestCA41CharacterAssetContractsStayMechanismFreeAndFamilyQualified(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "characterasset")
	forbiddenImports := []string{module + "internal/adapters", "github.com/jackc/pgx", "github.com/riverqueue/river", "database/sql", "net/http"}
	forbiddenText := []string{"player_item_stacks", "player_currency_balances", "equipment_items", "maxHeroColor = 5", "MaxHeroColor = 5", "CreateSpirit", "UpgradeSpirit", "LockSpirit", "Horcrux"}
	err := filepath.WalkDir(base, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") {
			return err
		}
		f, e := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if e != nil {
			return e
		}
		for _, im := range f.Imports {
			imp, _ := strconv.Unquote(im.Path.Value)
			for _, bad := range forbiddenImports {
				if imp == bad || strings.HasPrefix(imp, bad+"/") {
					t.Errorf("%s imports forbidden CA4-1 mechanism %s", path, imp)
				}
			}
		}
		b, e := os.ReadFile(path)
		if e != nil {
			return e
		}
		for _, bad := range forbiddenText {
			if strings.Contains(string(b), bad) {
				t.Errorf("%s contains forbidden CA4-1 ownership marker %q", path, bad)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestCA41MigrationIsContentOnlyAndNoUniversalEquipmentOwner(t *testing.T) {
	root := repoRoot(t)
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	var nineteen []string
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), "00019") {
			nineteen = append(nineteen, e.Name())
		}
	}
	if len(nineteen) != 1 || nineteen[0] != "00019_ca4_equipment_primitives.sql" {
		t.Fatalf("CA4-1 migration inventory=%v", nineteen)
	}
	b, err := os.ReadFile(filepath.Join(root, "migrations", nineteen[0]))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{"gxb_content_equipment_primitives", "gxb_content_equipment_recipe_edges", "resource_definition_key", "ordinal"} {
		if !strings.Contains(s, need) {
			t.Errorf("CA4-1 migration missing %s", need)
		}
	}
	for _, bad := range []string{"equipment_items", "player_equipment", "player_hero_equipment", "player_pet_equipment", "player_super_equipment", "spirit_items", "horcrux"} {
		if strings.Contains(strings.ToLower(s), bad) {
			t.Errorf("CA4-1 migration contains forbidden durable owner %q", bad)
		}
	}
}

func TestCA41I5CombinedPortOwnsPlanningAndDoesNotLeakRawLocks(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "internal", "application", "i5", "material_exchange.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{"PrepareMaterialExchangeTx", "ApplyMaterialExchangeTx", "canonicalGrantLockRequirements", "ErrMaterialExchangeResourceCollision", "ErrMaterialExchangeGrantAlreadySettled"} {
		if !strings.Contains(s, need) {
			t.Errorf("combined I5 seam missing %s", need)
		}
	}
	cb, err := os.ReadFile(filepath.Join(root, "internal", "application", "characterasset", "contracts.go"))
	if err != nil {
		t.Fatal(err)
	}
	cs := string(cb)
	for _, bad := range []string{"lockkey.", "grantLockRequirement", "MaterialCostStore", "gxb_content_", "player_item_stacks"} {
		if strings.Contains(cs, bad) {
			t.Errorf("Character Asset leaks I5 mechanism %q", bad)
		}
	}
}

func TestCA41DoesNotActivateFutureCA4MIDHandlers(t *testing.T) {
	root := repoRoot(t)
	// CA4-1 may define contracts/types/content only. Command-specific code for
	// the future stages is not allowed under the shared package.
	base := filepath.Join(root, "internal", "application", "characterasset")
	b, err := os.ReadFile(filepath.Join(base, "contracts.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, marker := range []string{"MID54", "MID62", "MID58", "MID51", "MID57", "MID783", "MID792", "MID785", "MID790", "MID304"} {
		if strings.Contains(s, marker) {
			t.Errorf("CA4-1 contract package contains future command marker %s", marker)
		}
	}
}
