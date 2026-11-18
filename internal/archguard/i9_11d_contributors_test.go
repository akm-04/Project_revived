package archguard

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

var contributorTypePattern = regexp.MustCompile(`\b([a-z][a-zA-Z0-9]*\.[A-Z][a-zA-Z0-9]*)\{`)
var contributorAliasPattern = regexp.MustCompile(`(\w+)\s*:=\s*&?([a-z][a-zA-Z0-9]*\.[A-Z][a-zA-Z0-9]*)\{`)

func literalBlock(t *testing.T, source, marker string) string {
	t.Helper()
	start := strings.Index(source, marker)
	if start < 0 {
		t.Fatalf("marker %q not found", marker)
	}
	open := strings.Index(source[start:], "{")
	if open < 0 {
		t.Fatalf("no literal after %q", marker)
	}
	open += start
	depth := 0
	for index := open; index < len(source); index++ {
		switch source[index] {
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return source[open : index+1]
			}
		}
	}
	t.Fatalf("unbalanced literal after %q", marker)
	return ""
}

// TestI9D11Mid1ContributorListsAgree guards C4 against the defect it fixed: the
// golden login contributor list was a second hand list that missed the compat
// projection. It is an intentional subset of the composition, so every type it
// wires must exist in production and both must project MID 1 detail 17.
func TestI9D11Mid1ContributorListsAgree(t *testing.T) {
	productionSource, err := os.ReadFile(filepath.Join(repoRoot(t), "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	goldenSource, err := os.ReadFile(filepath.Join(repoRoot(t), "internal", "integration", "logincapacity", "mid1_two_step_native_test.go"))
	if err != nil {
		t.Fatal(err)
	}
	production := literalBlock(t, string(productionSource), "[]appboot.MID1DetailContributor")
	golden := literalBlock(t, string(goldenSource), "return []appboot.MID1DetailContributor")

	productionTypes := map[string]bool{}
	for _, match := range contributorTypePattern.FindAllStringSubmatch(production, -1) {
		productionTypes[match[1]] = true
	}
	for _, match := range contributorAliasPattern.FindAllStringSubmatch(string(productionSource), -1) {
		productionTypes[match[2]] = true
	}
	goldenTypes := map[string]bool{}
	for _, match := range contributorTypePattern.FindAllStringSubmatch(golden, -1) {
		goldenTypes[match[1]] = true
	}

	if !productionTypes["appcompat.BootstrapProjection"] || !goldenTypes["appcompat.BootstrapProjection"] {
		t.Fatalf("MID1 compat projection missing from the production=%v or golden=%v contributor list", productionTypes["appcompat.BootstrapProjection"], goldenTypes["appcompat.BootstrapProjection"])
	}
	for contributor := range goldenTypes {
		if !productionTypes[contributor] {
			t.Fatalf("golden login contributor %s is not registered by the production composition", contributor)
		}
	}
}
