package archguard

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestCA87BattleContributionCharacterOwnershipFence(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "internal", "application", "characterasset", "battle_contribution.go")
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)

	for _, need := range []string{
		`const BattleCharacterContributionSchemaVersion = "ca8-7/v1"`,
		"type BattleCharacterScopeWitness struct", "OperationID     ids.UUID", "ContentRevision string", "ObservedAt      time.Time",
		"type OwnedHeroBattleContribution struct", "type OwnedPetBattleContribution struct",
		"type BorrowedHeroBattleContribution struct", "type BorrowedPetBattleContribution struct",
		"type SyntheticHeroBattleContribution struct", "type SyntheticPetBattleContribution struct",
		"type BattleCharacterContributionReader struct", "Owned    *OwnedCompositeBuilder", "Borrowed *BorrowedCompositeBuilder",
		"r.Owned.OwnedHeroTx", "r.Owned.OwnedPetTx", "r.Borrowed.BorrowedHeroTx", "r.Borrowed.BorrowedPetTx",
		"MaterializeSyntheticHero", "MaterializeSyntheticPet", "ProviderUnavailableUnqualified",
	} {
		if !strings.Contains(s, need) {
			t.Fatalf("CA8-7 battle contribution seam missing %q", need)
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
			"/content/", "/application/combat", "/application/battle", "/application/guild",
			"/application/mode", "/application/rental", "/adapters/", "/protocol/",
		} {
			if strings.Contains(imp, bad) {
				t.Fatalf("CA8-7 product seam imports forbidden owner/mechanism %q via %q", bad, imp)
			}
		}
	}

	forbiddenIdentifiers := map[string]bool{
		"ProviderRequiredButUnavailable": true,
		"CombatSnapshot":                 true,
		"ActiveRevision":                 true,
		"RandomSeed":                     true,
		"Resolver":                       true,
		"Force":                          true,
		"FinalStats":                     true,
	}
	ast.Inspect(f, func(n ast.Node) bool {
		if id, ok := n.(*ast.Ident); ok && forbiddenIdentifiers[id.Name] {
			t.Errorf("CA8-7 product seam gained forbidden identifier %q", id.Name)
		}
		return true
	})

	for _, forbidden := range []string{
		"time.Now(", "ActiveRevision(", "FOR UPDATE", ".Begin(", ".Commit(", ".Rollback(",
		"GET_PLAYER_CARD_INFO", "FIGHT_RESULT", "MID", "snapshot_hash", "entropy_policy_version",
		"rules_corpus_version", "trust_profile_version", "content_policy_version",
	} {
		if strings.Contains(s, forbidden) {
			t.Fatalf("CA8-7 product seam gained forbidden mechanism marker %q", forbidden)
		}
	}
}

func TestCA87IntroducesNoPersistenceWireOrBattleOwnerArtifact(t *testing.T) {
	root := repoRoot(t)
	for _, dir := range []string{
		"migrations",
		filepath.Join("internal", "adapters", "stockruntime"),
		filepath.Join("internal", "protocol"),
	} {
		err := filepath.WalkDir(filepath.Join(root, dir), func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			name := strings.ToLower(filepath.Base(path))
			if strings.Contains(name, "ca8_7") || strings.Contains(name, "battle_contribution") {
				t.Fatalf("CA8-7 unexpectedly introduced persistence/wire artifact %s", path)
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}
