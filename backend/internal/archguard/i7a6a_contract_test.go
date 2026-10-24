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

const expected6ASelectionSHA = "854011799f9c3b2eb779f0b1ec3e3cd291566aef58a491d317236f1c0f70f7da"

func selectedFriendDMActivation(t *testing.T) bool {
	t.Helper()
	root := repoRoot(t)
	raw, e := os.ReadFile(filepath.Join(root, "BUILD_INFO.json"))
	if e != nil {
		t.Fatal(e)
	}
	var build map[string]any
	if json.Unmarshal(raw, &build) != nil {
		t.Fatal("build metadata")
	}
	if build["i7a6a_stage"] == nil {
		return false
	}
	selection, e := os.ReadFile(filepath.Join(root, "docs/i7a6a/IMPLEMENTATION_SELECTION.json"))
	if e != nil || fmt.Sprintf("%x", sha256.Sum256(selection)) != expected6ASelectionSHA || build["i7a6a_contract_sha256"] != expected6ASelectionSHA {
		t.Fatal("6A selection identity mismatch")
	}
	var value struct{ Contracts map[string]string }
	if json.Unmarshal(selection, &value) != nil || len(value.Contracts) != 6 {
		t.Fatal("6A six contract selection")
	}
	for n, want := range value.Contracts {
		raw, e := os.ReadFile(filepath.Join(root, "docs/i7a6a", n+".json"))
		if e != nil || fmt.Sprintf("%x", sha256.Sum256(raw)) != want {
			t.Fatal("6A immutable contract drift", n)
		}
	}
	return true
}
func validateFriendDMActivation(t *testing.T) {
	t.Helper()
	root := repoRoot(t)
	read := func(p string) string {
		b, e := os.ReadFile(filepath.Join(root, p))
		if e != nil {
			t.Fatal(e)
		}
		return string(b)
	}
	api := read("cmd/gxb-api/main_postgres.go")
	if !strings.Contains(api, "mustRegister(515, stockruntime.FriendDMDispatcher") || !strings.Contains(api, "Projection: friendBase") {
		t.Fatal("6A HTTP/sameTx assembly")
	}
	realtime := read("cmd/gxb-realtime/main_postgres.go")
	expectedRoutes := 2
	if selectedGeneralDMActivation(t) {
		expectedRoutes = 3
	}
	if genericWakeupRoutes(realtime) != expectedRoutes || !strings.Contains(realtime, "Route: frienddm.WakeupRoute, Handler: friendReconcile") || !strings.Contains(realtime, "<-reconcileDone") {
		t.Fatal("6A routes/reconcile join")
	}
	schema := read("internal/adapters/stockruntime/friend_dm_delivery.go")
	if strings.Count(schema, "MID:") != 2 || !strings.Contains(schema, "MID: mids.MIDChatFromFriend") || !strings.Contains(schema, "Validate: rt.ValidateFriendDM") || !strings.Contains(schema, "Roles: []rt.Role{rt.World}") {
		t.Fatal("6A finite target schema")
	}
}
func TestI7A6ASelectedFiniteActivation(t *testing.T) {
	if selectedFriendDMActivation(t) {
		validateFriendDMActivation(t)
	}
}
