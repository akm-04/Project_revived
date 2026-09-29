package archguard

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestCA84BorrowedProjectionKeepsQualificationAndOwnershipFences(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "internal", "application", "characterasset", "borrowed_composite.go")
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{
		"BorrowedCapabilityProvenance",
		"QualifiedBorrowedHeroReference",
		"QualifiedBorrowedPetReference",
		"BorrowedHeroComposite",
		"BorrowedPetComposite",
		"ActorOriginBorrowed",
		"OwnerComposite.OwnedHeroTx(ctx, scope, ref.ActorRef)",
		"OwnerComposite.OwnedPetTx(ctx, scope, ref.ActorRef)",
	} {
		if !strings.Contains(s, need) {
			t.Fatalf("CA8-4 borrowed projection missing contract marker %q", need)
		}
	}

	for label, pattern := range map[string]string{
		"transaction runner":      `\btx\.Runner\b|\bTimedRunner\b`,
		"transaction ownership":   `\.(?:Begin|Commit|Rollback)\s*\(`,
		"receipt ownership":       `"[^"\n]*/foundation/receipt(?:/[^"\n]*)?"`,
		"lock ownership":          `"[^"\n]*/foundation/lockkey(?:/[^"\n]*)?"`,
		"database/sql":            `"database/sql"`,
		"postgres driver":         `"github\.com/jackc/pgx`,
		"foreign owner import":    `"[^"\n]*/application/(?:guild|guildcore|modes)(?:/[^"\n]*)?"|"[^"\n]*/domain/(?:guild|modes)(?:/[^"\n]*)?"`,
		"borrower identity":       `\bBorrowerPlayerID\b`,
		"raw rental wire":         `\b(?:rent_need_mana|can_rent|have_rent|rent_count|rent_type|rent_player_id|rent_formation|rent_hero_player|rent_hero_id|rent_pet_player|rent_pet_player_id|rent_pet_id)\b`,
		"mode health state":       `\b(?:total_hp|current_hp|current_mp)\b`,
		"wire/MID activation":     `\bxyd\.mid\b|\bMID\d+\b`,
		"SQL ownership":           `(?i)\b(?:SELECT|INSERT|UPDATE|DELETE)\b.+\b(?:player_heroes|player_pets|guild)\b`,
		"wall clock discovery":    `\btime\.Now\s*\(`,
		"requiredness assignment": `ProviderRequiredButUnavailable\s*[:=]`,
	} {
		if regexp.MustCompile(pattern).FindStringIndex(s) != nil {
			t.Fatalf("CA8-4 borrowed projection gained forbidden %s", label)
		}
	}

	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		if strings.Contains(strings.ToLower(e.Name()), "ca8_4") {
			t.Fatalf("CA8-4 unexpectedly introduced migration %s", e.Name())
		}
	}
}
