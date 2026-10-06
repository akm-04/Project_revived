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

const expected4DContractSHA = "09c4b4ada91d83d759ac54dfe93dd2602ee805671e90f5256a4b5080edb2dc4b"

func selectedSocialActivation(t *testing.T) bool {
	t.Helper()
	root := repoRoot(t)
	b, e := os.ReadFile(filepath.Join(root, "BUILD_INFO.json"))
	if e != nil {
		t.Fatal(e)
	}
	var m map[string]any
	if json.Unmarshal(b, &m) != nil {
		t.Fatal("build metadata")
	}
	if m["i7a4d_stage"] == nil {
		return false
	}
	p, e := os.ReadFile(filepath.Join(root, "docs/i7a4d/PASS637_I7A4D_IMPLEMENTATION_CONTRACT.json"))
	if e != nil {
		t.Fatal(e)
	}
	// This is the exact independently sealed637contract; arbitrary phase metadata
	// cannot turn the historical dormancy checks off.
	if fmt.Sprintf("%x", sha256.Sum256(p)) != expected4DContractSHA || m["i7a4d_contract_sha256"] != expected4DContractSHA {
		t.Fatal("4Dcontract selection identity mismatch")
	}
	return true
}
func validateSocialActivationRoutes(t *testing.T) {
	t.Helper()
	root := repoRoot(t)
	read := func(path string) string {
		b, e := os.ReadFile(filepath.Join(root, path))
		if e != nil {
			t.Fatal(e)
		}
		return string(b)
	}
	main := read("cmd/gxb-api/main_postgres.go")
	if strings.Contains(main, "[]uint16{56, 1056, 176,") || !strings.Contains(main, "stockruntime.RegisterSocialRoutes(router, socialDispatcher)") {
		t.Fatal("4D176replacement/assembly")
	}
	d := read("internal/adapters/stockruntime/social_dispatcher.go")
	if !strings.Contains(d, "[]uint16{176, 177, 178, 179, 180, 181, 182, 184, 185, 186, 187, 188, 189, 190}") {
		t.Fatal("4Dfinite14routes/183exclusion")
	}
	if !strings.Contains(d, "lobby.BootExplicitHTTP") {
		t.Fatal("176bootcontract")
	}
	reload := read("internal/adapters/stockruntime/social_reload.go")
	if !strings.Contains(reload, "MID: mids.MIDForceReload") || !strings.Contains(reload, "Roles: []rt.Role{rt.World}") || !strings.Contains(reload, "Validate: ValidateSocialReload") {
		t.Fatal("4DstrictWORLDschema")
	}
	rtmain := read("cmd/gxb-realtime/main_postgres.go")
	if !strings.Contains(rtmain, "Route: postgres.SocialReloadRoute, Handler: socialHandler") || !strings.Contains(rtmain, "<-listenerDone") {
		t.Fatal("4Ddedicatedlistener supervision")
	}
}
func TestI7A4DSelectedFiniteActivationContracts(t *testing.T) {
	if selectedSocialActivation(t) {
		validateSocialActivationRoutes(t)
	}
}
