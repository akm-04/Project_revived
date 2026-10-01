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

func TestCA86PublicShowcaseCharacterOwnershipFence(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "internal", "application", "characterasset", "public_showcase.go")
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)

	for _, need := range []string{
		"type PublicHeroCharacterFacet struct", "type PublicPetCharacterFacet struct",
		"type PublicShowcaseCharacterReader struct", "OwnerComposite *OwnedCompositeBuilder",
		"func (r PublicShowcaseCharacterReader) HeroTx", "func (r PublicShowcaseCharacterReader) PetTx",
		"character.HeroRef", "character.PetRef", "r.OwnerComposite.OwnedHeroTx", "r.OwnerComposite.OwnedPetTx",
		"ActorOriginOwned", "ProviderUnavailableUnqualified", "HeroSkillsDisposition",
	} {
		if !strings.Contains(s, need) {
			t.Fatalf("CA8-6 public showcase seam missing %q", need)
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
			"/content/", "/application/public", "/application/profile", "/application/guild",
			"/application/mode", "/application/rental", "/adapters/", "/protocol/",
		} {
			if strings.Contains(imp, bad) {
				t.Fatalf("CA8-6 product seam imports forbidden owner/mechanism %q via %q", bad, imp)
			}
		}
	}

	for label, pattern := range map[string]string{
		"transaction runner":         `\btx\.Runner\b`,
		"fresh clock":                `\btime\.Now\s*\(`,
		"content rediscovery":        `\bActiveRevision\s*\(`,
		"transaction ownership":      `\.(?:Begin|Commit|Rollback)\s*\(`,
		"SQL locking":                `(?i)FOR\s+UPDATE`,
		"receipt ownership":          `\breceipt\.(?:Record|Receipt|Store)\b`,
		"MID/wire activation":        `\b(?:MID\d*|xyd\.mid|protocol\.)\b`,
		"borrowed origin":            `\bActorOriginBorrowed\b`,
		"trial origin":               `\bActorOriginTrial\b`,
		"NPC origin":                 `\bActorOriginNPCTemplate\b`,
		"final combat snapshot":      `\bCombatSnapshot\b`,
		"combat RNG":                 `\b(?:RNG|RandomSeed|Resolver)\b`,
		"bookmark owner fabrication": `\b(?:Bookmark|is_like|HERO_COLLOCATION)\b`,
	} {
		if regexp.MustCompile(pattern).FindStringIndex(s) != nil {
			t.Fatalf("CA8-6 product seam gained forbidden marker %q", label)
		}
	}

	// Identity is an already-qualified persistent ref. Keep raw profile slot and
	// table identity out of the public CA8-6 API surface.
	for _, forbidden := range []string{
		"ShowcaseIndex", "SlotIndex", "ProfilePlayerID", "SubType", "RawIDs", "TableID int64",
	} {
		if strings.Contains(s, forbidden) {
			t.Fatalf("CA8-6 product seam gained raw public identity field %q", forbidden)
		}
	}
}

func TestCA86IntroducesNoPersistenceWireOrForeignOwnerArtifact(t *testing.T) {
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
			if strings.Contains(name, "ca8_6") || strings.Contains(name, "public_showcase") {
				t.Fatalf("CA8-6 unexpectedly introduced persistence/wire artifact %s", path)
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}
