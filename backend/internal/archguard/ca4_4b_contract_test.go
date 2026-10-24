package archguard

import (
	"os"
	"path/filepath"
	"regexp"
	"testing"
)

func TestCA44BPetPromotionWiresAreProductionRegistered(t *testing.T) {
	root := repoRoot(t)
	mainBytes, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	re := regexp.MustCompile(`(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, petD\)`)
	match := re.FindStringSubmatch(string(mainBytes))
	if len(match) != 2 {
		t.Fatal("production Pet registration set not found")
	}
	for _, mid := range []string{"785", "790"} {
		midRE := regexp.MustCompile(`(^|\D)` + mid + `(\D|$)`)
		if !midRE.MatchString(match[1]) {
			t.Fatalf("CA4-4B MID%s is not production registered", mid)
		}
	}
}
