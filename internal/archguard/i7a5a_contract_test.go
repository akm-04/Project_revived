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

const selected5ASHA = "1ebca25be86d7fe6b49bf5ff40b59292847d67455821b3fe05d3cb2570db094c"

func selectedChannelChat(t *testing.T) bool {
	t.Helper()
	root := repoRoot(t)
	b, e := os.ReadFile(filepath.Join(root, "BUILD_INFO.json"))
	if e != nil {
		t.Fatal(e)
	}
	var m map[string]any
	if json.Unmarshal(b, &m) != nil {
		t.Fatal("buildmetadata")
	}
	if m["i7a5a_stage"] == nil {
		return false
	}
	contract, e := os.ReadFile(filepath.Join(root, "docs/i7a5a/PASS640_I7A5A_IMPLEMENTATION_CONTRACT.json"))
	if e != nil || fmt.Sprintf("%x", sha256.Sum256(contract)) != selected5ASHA || m["i7a5a_contract_sha256"] != selected5ASHA {
		t.Fatal("5Aactivation requires exactselected640contract")
	}
	return true
}
func TestI7A5ASelectedFiniteProductionComposition(t *testing.T) {
	if !selectedChannelChat(t) {
		return
	}
	root := repoRoot(t)
	read := func(p string) string {
		b, e := os.ReadFile(filepath.Join(root, p))
		if e != nil {
			t.Fatal(e)
		}
		return string(b)
	}
	main := read("cmd/gxb-realtime/main_postgres.go")
	for _, w := range []string{"SessionDispatcher: chatDispatcher", "channelchatread.Reader{}", "NewChannelChatEventRegistry()", "DefaultChannelChatPolicy(runtimePolicy.MaxConnections)", "Route: postgres.SocialReloadRoute, Handler: socialHandler"} {
		if !strings.Contains(main, w) {
			t.Fatal("missing production contract", w)
		}
	}
	reader := read("internal/adapters/channelchatread/reader.go")
	for _, w := range []string{"RealtimeAuthority{Queryer: t}", "RealtimeMembership{Queryer: t}", "PlayerDirectoryReader{Queryer: t}", "i5store.Store{Queryer: t}", "AuthoritativeTime{Queryer: t}"} {
		if !strings.Contains(reader, w) {
			t.Fatal("wrong callerTx port", w)
		}
	}
	if strings.Contains(reader, "SELECT ") || strings.Contains(reader, "Begin(") || strings.Contains(reader, "Commit(") {
		t.Fatal("foreignSQL/nestedtransaction")
	}
	app := read("internal/application/channelchat/service.go")
	for _, bad := range []string{"internal/protocol", "net.Conn", "32782", "32783", "NamedEpoch"} {
		if strings.Contains(app, bad) {
			t.Fatal("application boundary", bad)
		}
	}
	for _, w := range []string{"ReadOnly: true", "Isolation: tx.RepeatableRead", "MaxAttempts: 1", "result.Outcome != tx.DefiniteCommit"} {
		if !strings.Contains(app, w) {
			t.Fatal("transaction contract", w)
		}
	}
}
