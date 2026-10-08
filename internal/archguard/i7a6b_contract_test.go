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

func selectedGeneralDMActivation(t *testing.T) bool {
	root := repoRoot(t)
	b, e := os.ReadFile(filepath.Join(root, "BUILD_INFO.json"))
	if e != nil {
		t.Fatal(e)
	}
	var build map[string]any
	if json.Unmarshal(b, &build) != nil {
		t.Fatal("build info")
	}
	if build["i7a6b_stage"] == nil {
		return false
	}
	raw, e := os.ReadFile(filepath.Join(root, "docs/i7a6b/IMPLEMENTATION_SELECTION.json"))
	if e != nil || fmt.Sprintf("%x", sha256.Sum256(raw)) != build["i7a6b_contract_sha256"] {
		t.Fatal("GeneralDM selection identity mismatch")
	}
	var value struct{ Contracts map[string]string }
	if json.Unmarshal(raw, &value) != nil || len(value.Contracts) != 6 {
		t.Fatal("six GeneralDM contracts required")
	}
	for n, h := range value.Contracts {
		b, e := os.ReadFile(filepath.Join(root, "docs/i7a6b", n+".json"))
		if e != nil || fmt.Sprintf("%x", sha256.Sum256(b)) != h {
			t.Fatal("GeneralDM contract drift", n)
		}
	}
	return true
}
func validateGeneralDMActivation(t *testing.T) {
	root := repoRoot(t)
	read := func(p string) string {
		b, e := os.ReadFile(filepath.Join(root, p))
		if e != nil {
			t.Fatal(e)
		}
		return string(b)
	}
	api := read("cmd/gxb-api/main_postgres.go")
	realtime := read("cmd/gxb-realtime/main_postgres.go")
	schema := read("internal/adapters/stockruntime/general_dm_events.go")
	for _, v := range []string{"mustRegister(513, stockruntime.GeneralDMDispatcher", "Slots: make(chan struct{}, 16)", "Bindings: generaldmbindings.Reader{}", "GeneralDMPrivacyProvider"} {
		if !strings.Contains(api, v) {
			t.Fatal("missing GeneralDM API qualification", v)
		}
	}
	for _, v := range []string{"Route: generaldm.WakeupRoute, Handler: generalReconcile", "generalReconcile.InitialReconcile(ctx)", "generalReconcile.Run(ctx)", "<-generalDone"} {
		if !strings.Contains(realtime, v) {
			t.Fatal("missing GeneralDM realtime qualification", v)
		}
	}
	if strings.Count(realtime, "realtimewakeup.Registration{") != 3 || strings.Count(schema, "MID:") != 3 || !strings.Contains(schema, "Validate: rt.ValidateGeneralDM") {
		t.Fatal("GeneralDM exact schema/route set")
	}
	foreign := read("internal/adapters/postgres/generaldmstore/store.go")
	for _, v := range []string{"FROM gameplay_contexts", "FROM realtime_presence_leases", "FROM social_blocks", "FROM players"} {
		if strings.Contains(foreign, v) {
			t.Fatal("PersonalDM owner foreign SQL", v)
		}
	}
}
func TestI7A6BSelectedFiniteActivation(t *testing.T) {
	if selectedGeneralDMActivation(t) {
		validateGeneralDMActivation(t)
	}
}
