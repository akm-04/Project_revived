package archguard

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

func TestCA76ContributionReadSeamAndPreservationFences(t *testing.T) {
	paths := []string{
		"../application/characterasset/appearance_contribution.go",
		"../application/characterhero/appearance_contribution.go",
		"../application/characterpet/appearance_contribution.go",
	}
	var combined strings.Builder
	for _, path := range paths {
		b, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		combined.Write(b)
		combined.WriteByte('\n')
	}
	s := combined.String()
	for _, need := range []string{"HeroAppearanceContribution", "PetAppearanceContribution", "tx.Queryer", "ContentRevision", "OriginTableID"} {
		if !strings.Contains(s, need) {
			t.Fatalf("CA7-6 contribution seam missing %q", need)
		}
	}
	for label, pattern := range map[string]string{
		"tx.Runner":             `\btx\.Runner\b`,
		"ActiveRevision call":   `\bActiveRevision\s*\(`,
		"time.Now call":         `\btime\.Now\s*\(`,
		"foundation/receipt":    `"[^"\n]*/foundation/receipt(?:/[^"\n]*)?"`,
		"application/i5":        `"[^"\n]*/application/i5(?:/[^"\n]*)?"`,
		"TimedRunner":           `\bTimedRunner\b`,
		"transaction ownership": `\.(?:Begin|Commit|Rollback)\s*\(`,
		"FOR UPDATE":            `(?i)FOR\s+UPDATE`,
		"battle-derived id":     `\b(?:BattleModelID|EffectiveModelID|SkillModelID|SkinSkillID)\b`,
		"Library board state":   `\b(?:board_partner|board_card|board_model_id)\b`,
	} {
		re := regexp.MustCompile(pattern)
		if re.FindStringIndex(s) != nil {
			t.Fatalf("CA7-6 read seam gained forbidden ownership/policy marker %q", label)
		}
	}
	heroBytes, err := os.ReadFile("../application/characterhero/appearance_contribution.go")
	if err != nil {
		t.Fatal(err)
	}
	hero := string(heroBytes)
	if !strings.Contains(hero, "HeroKindTx(ctx, q, h.CreationContentRevision, h.TableID)") {
		t.Fatal("CA7-6 Hero kind provenance no longer uses CreationContentRevision")
	}
	if !strings.Contains(hero, "h.PlayerID != pid || h.PartnerID != partnerID") {
		t.Fatal("CA7-6 Hero contribution no longer fails closed on owner mismatch")
	}
	if !strings.Contains(hero, "BuildEffectiveHeroAppearanceTx(ctx, q, revision") {
		t.Fatal("CA7-6 Hero appearance no longer qualifies on caller-pinned revision")
	}
	petBytes, err := os.ReadFile("../application/characterpet/appearance_contribution.go")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(petBytes), "p.PlayerID != pid || p.PetID != petID") {
		t.Fatal("CA7-6 Pet contribution no longer fails closed on owner mismatch")
	}

	queryBytes, err := os.ReadFile("../adapters/postgres/characterqueries/querytext_gen.go")
	if err != nil {
		t.Fatal(err)
	}
	queries := string(queryBytes)
	constant := func(name string) string {
		re := regexp.MustCompile(`(?s)const ` + regexp.QuoteMeta(name) + ` = ` + "`" + `([^` + "`" + `]*)` + "`")
		m := re.FindStringSubmatch(queries)
		if len(m) != 2 {
			t.Fatalf("query constant %s not found", name)
		}
		return m[1]
	}
	for _, name := range []string{"SaveHeroState", "SaveHeroPractice"} {
		q := constant(name)
		if strings.Contains(q, "current_skin_id") || strings.Contains(q, "illusion_skin_id") {
			t.Fatalf("%s rewrites CA7 Hero selectors", name)
		}
	}
	for _, name := range []string{"SavePetState", "SavePetPractice"} {
		if strings.Contains(constant(name), "active_style") {
			t.Fatalf("%s rewrites CA7 Pet selector", name)
		}
	}
	heroApp := constant("SaveHeroAppearanceSelectors")
	for _, bad := range []string{"star=", "level=", "exp=", "color=", "equip_", "fumo_", "practice_"} {
		if strings.Contains(heroApp, bad) {
			t.Fatalf("Hero appearance CAS rewrites earlier-owned field marker %q", bad)
		}
	}
	petApp := constant("SavePetActiveStyle")
	for _, bad := range []string{"star=", "level=", "exp=", "color=", "skill_", "equip_", "fumo_", "practice_", "is_show="} {
		if strings.Contains(petApp, bad) {
			t.Fatalf("Pet appearance CAS rewrites earlier-owned field marker %q", bad)
		}
	}
	if _, err := os.Stat("../../migrations/00030_ca7_2_appearance_foundation.sql"); err != nil {
		t.Fatal(err)
	}
	matches, err := os.ReadDir("../../migrations")
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range matches {
		if strings.Contains(strings.ToLower(e.Name()), "ca7_6") {
			t.Fatalf("CA7-6 unexpectedly introduced migration %s", e.Name())
		}
	}
}
