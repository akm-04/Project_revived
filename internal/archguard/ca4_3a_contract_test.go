package archguard

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

func TestCA43AMID58WiringAndStageBoundary(t *testing.T) {
	dispatcher, err := os.ReadFile("../adapters/stockruntime/hero_dispatcher.go")
	if err != nil {
		t.Fatal(err)
	}
	d := string(dispatcher)
	for _, need := range []string{"case 58:", "FeedFumo(ctx, actor", `"fumo": got.Fumo`, `"fumo_lev": levels`, `"economy_": map[string]any{"mana": mana}`} {
		if !strings.Contains(d, need) {
			t.Fatalf("MID58 dispatcher missing %q", need)
		}
	}
	main, err := os.ReadFile("../../cmd/gxb-api/main_postgres.go")
	if err != nil {
		t.Fatal(err)
	}
	m := string(main)
	re := regexp.MustCompile(`(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, heroD\)`)
	match := re.FindStringSubmatch(m)
	if len(match) != 2 || !strings.Contains(match[1], "58") {
		t.Fatal("MID58 not production registered in Hero route set")
	}
	for _, bad := range []string{"mustRegister(54", "mustRegister(62", "[]uint16{49, 52, 54", "[]uint16{49, 52, 55, 58, 62"} {
		if strings.Contains(m, bad) {
			t.Fatalf("pre-CA4-5 Hero equipment route leak %q", bad)
		}
	}
}
