package archguard

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func selectedGiftStockActivation(t *testing.T) bool {
	root := repoRoot(t)
	raw, e := os.ReadFile(filepath.Join(root, "BUILD_INFO.json"))
	if e != nil {
		t.Fatal(e)
	}
	var build map[string]any
	if json.Unmarshal(raw, &build) != nil {
		t.Fatal("build")
	}
	if build["i7a7b_stage"] == nil {
		return false
	}
	raw, e = os.ReadFile(filepath.Join(root, "docs/i7a7b/IMPLEMENTATION_SELECTION.json"))
	if e != nil || fmt.Sprintf("%x", sha256.Sum256(raw)) != build["i7a7b_contract_sha256"] {
		t.Fatal("Gift stock selection identity")
	}
	var s struct{ Contracts map[string]string }
	if json.Unmarshal(raw, &s) != nil || len(s.Contracts) != 5 {
		t.Fatal("five Gift stock consumer contracts")
	}
	for n, h := range s.Contracts {
		b, e := os.ReadFile(filepath.Join(root, "docs/i7a7b", n+".json"))
		if e != nil || fmt.Sprintf("%x", sha256.Sum256(b)) != h {
			t.Fatal("Gift stock contract drift", n)
		}
	}
	return true
}
func validateGiftStockActivation(t *testing.T) {
	root := repoRoot(t)
	read := func(p string) string {
		b, e := os.ReadFile(filepath.Join(root, p))
		if e != nil {
			t.Fatal(e)
		}
		return string(b)
	}
	d := read("internal/adapters/stockruntime/social_dispatcher.go")
	for _, v := range []string{"[]uint16{176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190}", "mid == 183 && !d.giftStockReady", "d.Gifts.Claim(", "d.Scalar.CurrentScalar(", "friendship_coin", "9007199254740991"} {
		if !strings.Contains(d, v) {
			t.Fatal("Gift finite stock delta", v)
		}
	}
	api := read("cmd/gxb-api/main_postgres.go")
	if strings.Contains(api, "ActivateBuiltin(") {
		t.Fatal("API startup switches pointer")
	}
	for _, v := range []string{"stockruntime.PrepareGiftStock(", "giftGroup.Enable(", "legacyReads.Gifts = nil", "legacyReads.NoticePages = nil"} {
		if !strings.Contains(api, v) {
			t.Fatal("Gift whole group readiness", v)
		}
	}
	if !strings.Contains(read("cmd/gxb-content-gift-activate/main_postgres.go"), "s.ActivateBuiltin(") {
		t.Fatal("explicit owning activation missing")
	}
	if strings.Count(read("cmd/gxb-realtime/main_postgres.go"), "realtimewakeup.Registration{") != 3 {
		t.Fatal("fourth generic bus/worker introduced")
	}
}
func TestI7A7BFiniteConsumerActivation(t *testing.T) {
	if !selectedGiftStockActivation(t) {
		t.Fatal("selected Gift stock contracts missing")
	}
	validateGiftStockActivation(t)
}
