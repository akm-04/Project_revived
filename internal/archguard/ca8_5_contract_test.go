package archguard

import (
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
)

func TestCA85SyntheticProjectionOwnershipFence(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "internal", "application", "characterasset", "synthetic_projection.go")
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)

	for _, need := range []string{
		"SyntheticActorIdentity", "SyntheticProfileProvenance", "SyntheticHeroBase", "SyntheticPetBase",
		"SyntheticFeaturePayload", "QualifiedSyntheticHeroSpec", "QualifiedSyntheticPetSpec",
		"MaterializeSyntheticHero", "MaterializeSyntheticPet", "ActorOriginTrial", "ActorOriginNPCTemplate",
	} {
		if !strings.Contains(s, need) {
			t.Fatalf("CA8-5 synthetic projection seam missing %q", need)
		}
	}

	f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
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
			"/content/", "/application/i5", "/application/guild", "/application/modes",
			"/adapters/", "/protocol/",
		} {
			if strings.Contains(imp, bad) {
				t.Fatalf("CA8-5 product seam imports forbidden owner/mechanism %q via %q", bad, imp)
			}
		}
	}

	for label, pattern := range map[string]string{
		"queryer use":               `\.Queryer\s*\(`,
		"transaction runner":        `\btx\.Runner\b`,
		"fresh clock":               `\btime\.Now\s*\(`,
		"content rediscovery":       `\bActiveRevision\s*\(`,
		"transaction ownership":     `\.(?:Begin|Commit|Rollback)\s*\(`,
		"SQL locking":               `(?i)FOR\s+UPDATE`,
		"receipt ownership":         `\breceipt\.(?:Record|Receipt|Store)\b`,
		"MID/wire activation":       `\b(?:MID|xyd\.mid)\b`,
		"fake equipment owner":      `\bRawEquipmentState\b`,
		"fake practice owner":       `\bPracticeContribution\b`,
		"fake Hero appearance":      `\bHeroAppearanceContribution\b`,
		"fake Pet appearance":       `\bPetAppearanceContribution\b`,
		"final combat snapshot":     `\bCombatSnapshot\b`,
		"final combat content hash": `\bcontent_hash\b`,
	} {
		if regexp.MustCompile(pattern).FindStringIndex(s) != nil {
			t.Fatalf("CA8-5 product seam gained forbidden marker %q", label)
		}
	}
}

func TestCA85IntroducesNoPersistenceOrWireArtifact(t *testing.T) {
	root := repoRoot(t)
	for _, dir := range []string{"migrations", filepath.Join("internal", "adapters", "stockruntime"), filepath.Join("internal", "protocol")} {
		err := filepath.WalkDir(filepath.Join(root, dir), func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			name := strings.ToLower(filepath.Base(path))
			if strings.Contains(name, "ca8_5") || strings.Contains(name, "synthetic_projection") {
				t.Fatalf("CA8-5 unexpectedly introduced persistence/wire artifact %s", path)
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}
