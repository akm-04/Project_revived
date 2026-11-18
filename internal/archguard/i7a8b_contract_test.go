package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestI7A8BType10ProducerFollowsGiftReadiness pins the fail-closed activation
// order: the guild-owned type10 producer is enabled by the same Gift readiness
// group that validates the catalog, so a readiness error leaves it inert.
func TestI7A8BType10ProducerFollowsGiftReadiness(t *testing.T) {
	root := repoRoot(t)
	read := func(path string) string {
		t.Helper()
		raw, e := os.ReadFile(filepath.Join(root, path))
		if e != nil {
			t.Fatal(e)
		}
		return string(raw)
	}
	if strings.Contains(read("cmd/gxb-api/guild_invite_river.go"), "InviteProjection") {
		t.Fatal("Invite producer is installed by the bundle preparation instead of the readiness group")
	}
	if !strings.Contains(read("cmd/gxb-api/main_postgres.go"), "BindType10Producer(") {
		t.Fatal("Gift readiness group does not bind the Invite producer")
	}
}
