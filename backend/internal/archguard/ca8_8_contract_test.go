package archguard

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"testing"
)

func TestCA88ModeGuildCharacterProviderBoundary(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "internal", "application", "characterasset", "mode_guild.go")
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)

	for _, need := range []string{
		"type ModeGuildCharacterReader struct", "Owned    *OwnedCompositeBuilder", "Borrowed *BorrowedCompositeBuilder",
		"func (r ModeGuildCharacterReader) SavedPresetReferencesTx", "func (r ModeGuildCharacterReader) BorrowedHeroTx", "func (r ModeGuildCharacterReader) BorrowedPetTx",
		"r.Owned.SavedPresetReferencesTx(ctx, scope, pid)", "r.Borrowed.BorrowedHeroTx(ctx, scope, ref)", "r.Borrowed.BorrowedPetTx(ctx, scope, ref)",
		"state.Clone()", "borrowed.clone()", "borrowed.Origin != ActorOriginBorrowed", "borrowed.QualifiedReference != ref",
	} {
		if !strings.Contains(s, need) {
			t.Fatalf("CA8-8 provider seam missing %q", need)
		}
	}

	f, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
	if err != nil {
		t.Fatal(err)
	}
	for _, im := range f.Imports {
		imp, err := strconv.Unquote(im.Path.Value)
		if err != nil {
			t.Fatal(err)
		}
		for _, bad := range []string{
			"database/sql", "/foundation/tx", "/foundation/clock", "/foundation/receipt",
			"/content/", "/application/guild", "/application/mode", "/application/rental",
			"/application/combat", "/application/battle", "/adapters/", "/protocol/",
		} {
			if strings.Contains(imp, bad) {
				t.Fatalf("CA8-8 product seam imports forbidden owner/mechanism %q via %q", bad, imp)
			}
		}
	}

	var methods []string
	ast.Inspect(f, func(n ast.Node) bool {
		fd, ok := n.(*ast.FuncDecl)
		if !ok || fd.Recv == nil || len(fd.Recv.List) != 1 {
			return true
		}
		id, ok := fd.Recv.List[0].Type.(*ast.Ident)
		if ok && id.Name == "ModeGuildCharacterReader" {
			methods = append(methods, fd.Name.Name)
		}
		return true
	})
	sort.Strings(methods)
	wantMethods := []string{"BorrowedHeroTx", "BorrowedPetTx", "SavedPresetReferencesTx"}
	if strings.Join(methods, ",") != strings.Join(wantMethods, ",") {
		t.Fatalf("CA8-8 reader method surface drifted: got=%v want=%v", methods, wantMethods)
	}

	forbiddenIdentifiers := map[string]bool{
		"CombatSnapshot":              true,
		"BattleCharacterScopeWitness": true,
		"ActiveRevision":              true,
		"SelectedFormation":           true,
		"CurrentFormation":            true,
		"RentalPrice":                 true,
		"RentalCost":                  true,
		"Receipt":                     true,
	}
	ast.Inspect(f, func(n ast.Node) bool {
		if id, ok := n.(*ast.Ident); ok && forbiddenIdentifiers[id.Name] {
			t.Errorf("CA8-8 product seam gained forbidden identifier %q", id.Name)
		}
		return true
	})

	for _, forbidden := range []string{
		"time.Now(", "NewCoherentReadScope(", "ActiveRevision(", "FOR UPDATE", ".Begin(", ".Commit(", ".Rollback(",
		"rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id", "rent_hero_player", "rent_hero_id", "tutor_rent_hero",
		"selected_formation", "current_formation", "snapshot_hash", "CombatSnapshot{", "ProviderRequiredButUnavailable",
		"GET_RENT_HEROS", "GUILD_START_FIGHT", "FIGHT_RESULT",
	} {
		if strings.Contains(s, forbidden) {
			t.Fatalf("CA8-8 product seam gained forbidden ownership/wire marker %q", forbidden)
		}
	}
}

func TestCA88IntroducesNoPersistenceWireOrForeignOwnerArtifact(t *testing.T) {
	root := repoRoot(t)
	for _, dir := range []string{
		"migrations",
		filepath.Join("internal", "adapters", "stockruntime"),
		filepath.Join("internal", "protocol"),
	} {
		path := filepath.Join(root, dir)
		if _, err := os.Stat(path); os.IsNotExist(err) {
			continue
		}
		err := filepath.WalkDir(path, func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			name := strings.ToLower(filepath.Base(path))
			if strings.Contains(name, "ca8_8") || strings.Contains(name, "mode_guild") {
				t.Fatalf("CA8-8 unexpectedly introduced persistence/wire artifact %s", path)
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}
