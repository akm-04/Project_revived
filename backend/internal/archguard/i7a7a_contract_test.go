package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestI7A7AOwnerAndActivationBoundaries(t *testing.T) {
	root := repoRoot(t)
	read := func(p string) string {
		b, e := os.ReadFile(filepath.Join(root, p))
		if e != nil {
			t.Fatal(e)
		}
		return string(b)
	}
	service := read("internal/application/socialgift/service.go")
	store := read("internal/adapters/postgres/socialgiftstore/store.go")
	for _, foreign := range []string{"player_currency_balances", "gxb_operation_receipts", "social_notices", "players WHERE", "player_social_roots"} {
		if strings.Contains(store, foreign) {
			t.Fatal("Gift persistence reaches foreign owner", foreign)
		}
	}
	if strings.Count(service, ".SettleGrantTx(") != 1 || strings.Contains(service, "AllowReplayAfterAuthoritativeNegative: true") || strings.Contains(service, "http.") || strings.Contains(service, "go func") {
		t.Fatal("Grant/replay/transaction orchestration boundary")
	}
	inbox := read("internal/adapters/postgres/socialinboxstore/dismissal.go")
	if !strings.Contains(inbox, "ValidateRelationLifecycle") {
		t.Fatal("legacy relation dismissal weakened")
	}
	for _, p := range []string{"internal/adapters/stockruntime/social.go", "internal/protocol/mids/raw_guard.go"} {
		if _, e := os.Stat(filepath.Join(root, p)); e == nil {
			_ = read(p)
		}
	}
	migration := read("migrations/00036_social_gift.sql")
	for _, want := range []string{"ON DELETE RESTRICT", "DEFERRABLE INITIALLY DEFERRED", "nonempty SocialGift/content rollback prohibited", "claimed_at IS NOT NULL"} {
		if !strings.Contains(migration, want) {
			t.Fatal("durable schema boundary", want)
		}
	}
	if strings.Contains(migration, "-- +goose Down") {
		t.Fatal("forward-only foundation violated")
	}
	if strings.Contains(migration, "REFERENCES players(player_id) ON DELETE CASCADE") {
		t.Fatal("gift value receiver cascade")
	}
}
