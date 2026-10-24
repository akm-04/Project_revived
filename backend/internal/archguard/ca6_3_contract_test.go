package archguard

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestCA63BaseAndCA64AutoProductionRoutingIsAtomic(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	if !strings.Contains(s, "practiceD := stockruntime.PracticeDispatcher{Authority: authority, Service: practiceSvc, Tracker: tracker}") {
		t.Fatal("CA6-3 Practice dispatcher is not production-composed")
	}
	practiceRE := regexp.MustCompile(`(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, practiceD\)`)
	m := practiceRE.FindStringSubmatch(s)
	if len(m) != 2 {
		t.Fatal("CA6-3 Practice route list not found")
	}
	got := strings.NewReplacer(" ", "", "\n", "", "\t", "").Replace(m[1])
	if got != "124,125,126,127,128,129,130,131,132,133" {
		t.Fatalf("cumulative Practice route list=%q", got)
	}
	if strings.Contains(got, "134") {
		t.Fatalf("Practice captured foreign PetEXP route: %q", got)
	}
	lobbyRE := regexp.MustCompile(`(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, lobbyD\)`)
	lm := lobbyRE.FindStringSubmatch(s)
	if len(lm) != 2 || regexp.MustCompile(`(^|[, ]+)124([, ]+|$)`).MatchString(lm[1]) {
		t.Fatal("MID124 was not atomically removed from Lobby routing")
	}
	petRE := regexp.MustCompile(`(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, petD\)`)
	pm := petRE.FindStringSubmatch(s)
	if len(pm) != 2 || !regexp.MustCompile(`(^|[, ]+)134([, ]+|$)`).MatchString(pm[1]) {
		t.Fatal("MID134 no longer remains on PetDispatcher")
	}
}

func TestCA63ReusesOwnersReceiptsAndDoesNotLeakForeignSQL(t *testing.T) {
	root := repoRoot(t)
	appDir := filepath.Join(root, "internal", "application", "characterpractice")
	entries, err := os.ReadDir(appDir)
	if err != nil {
		t.Fatal(err)
	}
	var joined strings.Builder
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".go") || strings.HasSuffix(e.Name(), "_test.go") {
			continue
		}
		b, err := os.ReadFile(filepath.Join(appDir, e.Name()))
		if err != nil {
			t.Fatal(err)
		}
		joined.Write(b)
	}
	s := joined.String()
	for _, need := range []string{
		"HeroPracticeOwner", "PetPracticeOwner", "SaveAccountingTx", "TxLevelAndScalarDebiter", "TxLevelAndStackDebiter",
		"receipt.Resolver", "SemanticKey: op.ID.String()", "tx.Options{Isolation: tx.ReadCommitted}",
		"PRACTICE_ROLL_POLICY_V1", "PASS574_CA6_3_POLICY_REGISTER_AMENDMENT#base_ledger_compatibility",
	} {
		if !strings.Contains(s, need) {
			t.Errorf("CA6-3 application missing contract marker %q", need)
		}
	}
	for _, bad := range []string{
		"player_scalar", "player_scalars", "player_item", "player_items", "player_progression", "player_heroes", "player_pets",
		"SELECT ", "INSERT INTO ", "UPDATE ", "DELETE FROM ",
	} {
		if strings.Contains(s, bad) {
			t.Errorf("CA6-3 application leaked SQL/foreign-owner marker %q", bad)
		}
	}
}

func TestCA63DispatcherPreservesTelemetryAndExcludesFutureMIDs(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "stockruntime", "practice_dispatcher.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{"case 124:", "case 125:", "case 126:", "case 128:", "case 129:", "case 130:", "case 131:", "case 133:", "lobby.BootLegitTimer", "ResolveGameplayBearer", "region_mismatch"} {
		if !strings.Contains(s, need) {
			t.Errorf("CA6-3 dispatcher missing %q", need)
		}
	}
	if strings.Contains(s, "case 127:") || strings.Contains(s, "case 132:") || strings.Contains(s, "case 134:") {
		t.Fatal("CA6-3 dispatcher activated AUTO or captured MID134")
	}
}
