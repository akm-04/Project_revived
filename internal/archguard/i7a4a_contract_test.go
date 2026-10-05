package archguard

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
)

func TestI7A4AApplicationOwnershipAndLockRanks(t *testing.T) {
	if playerroot.LockRank != 315 || socialrelation.LockRankSocialRoot != 360 || socialrelation.LockRankFriendship != 361 || socialrelation.LockRankRequest != 362 || socialrelation.LockRankBlock != 363 || socialrelation.LockRankRequestEpoch != 364 || socialinbox.LockRankNotice != 370 {
		t.Fatalf("I7A-4A lock ranks drifted: player=%d social=%d/%d/%d/%d/%d notice=%d", playerroot.LockRank, socialrelation.LockRankSocialRoot, socialrelation.LockRankFriendship, socialrelation.LockRankRequest, socialrelation.LockRankBlock, socialrelation.LockRankRequestEpoch, socialinbox.LockRankNotice)
	}
	root := repoRoot(t)
	for _, rel := range []string{"internal/application/socialrelation", "internal/application/socialinbox"} {
		err := filepath.WalkDir(filepath.Join(root, filepath.FromSlash(rel)), func(path string, d os.DirEntry, err error) error {
			if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
				return err
			}
			b, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			s := string(b)
			for _, bad := range []string{"internal/adapters", "internal/protocol", "database/sql", "github.com/jackc/pgx", "SELECT ", "INSERT INTO ", "UPDATE ", "DELETE FROM ", "time.Now("} {
				if strings.Contains(s, bad) {
					t.Errorf("%s contains forbidden application ownership/edge marker %q", path, bad)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}

func TestI7A4AMigrationIsForwardOnlyEmptyFoundation(t *testing.T) {
	root := repoRoot(t)
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	var got []string
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), "00033") {
			got = append(got, e.Name())
		}
	}
	if len(got) != 1 || got[0] != "00033_i7a4a_social_foundation.sql" {
		t.Fatalf("00033 inventory=%v", got)
	}
	b, err := os.ReadFile(filepath.Join(root, "migrations", got[0]))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	if !strings.HasPrefix(s, "-- +goose Up\n") || strings.Contains(s, "-- +goose Down") {
		t.Fatal("00033 violates canonical forward-only Goose envelope")
	}
	for _, need := range []string{
		`CREATE INDEX player_directory_profiles_name_player_idx`, `name COLLATE "C",player_id`,
		"CREATE TABLE player_social_roots", "CREATE TABLE social_friendships", "CREATE TABLE social_friend_requests", "CREATE TABLE social_blocks", "CREATE TABLE social_request_epochs", "CREATE SEQUENCE social_notice_id_seq AS bigint", "CREATE TABLE social_notices",
		"UNIQUE(recipient_player_id,source_kind,source_key)", "status IN ('PENDING','ACCEPTED','DENIED','IGNORED')",
	} {
		if !strings.Contains(s, need) {
			t.Errorf("00033 missing %q", need)
		}
	}
	for _, bad := range []string{"CREATE UNIQUE INDEX player_directory_profiles_name", "UNIQUE(name", "INSERT INTO player_social_roots", "INSERT INTO social_friendships", "INSERT INTO social_friend_requests", "INSERT INTO social_blocks", "INSERT INTO social_request_epochs", "INSERT INTO social_notices", "UPDATE player_directory_profiles", "DELETE FROM"} {
		if strings.Contains(s, bad) {
			t.Errorf("00033 invents/backfills or over-constrains facts with %q", bad)
		}
	}
}

func TestI7A4AOwnershipMetadataAndAdapterBoundaries(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "docs", "architecture", "CANONICAL_TABLE_OWNERSHIP.json"))
	if err != nil {
		t.Fatal(err)
	}
	var doc struct {
		Tables map[string]struct {
			Owner     string   `json:"owner"`
			Migration string   `json:"migration"`
			Read      []string `json:"allowed_read_paths"`
			Write     []string `json:"allowed_write_paths"`
		} `json:"tables"`
	}
	if err := json.Unmarshal(b, &doc); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"player_social_roots", "social_friendships", "social_friend_requests", "social_blocks", "social_request_epochs"} {
		e, ok := doc.Tables[name]
		if !ok {
			t.Fatalf("missing ownership entry %s", name)
		}
		if e.Owner != "social-relation" || e.Migration != "migrations/00033_i7a4a_social_foundation.sql" || len(e.Read) != 1 || e.Read[0] != "internal/adapters/postgres/socialrelationstore/" || len(e.Write) != 1 || e.Write[0] != "internal/adapters/postgres/socialrelationstore/" {
			t.Fatalf("bad %s ownership %+v", name, e)
		}
	}
	e, ok := doc.Tables["social_notices"]
	if !ok {
		t.Fatal("missing social_notices ownership")
	}
	if e.Owner != "social-inbox" || len(e.Read) != 1 || e.Read[0] != "internal/adapters/postgres/socialinboxstore/" || len(e.Write) != 1 || e.Write[0] != "internal/adapters/postgres/socialinboxstore/" {
		t.Fatalf("bad social_notices ownership %+v", e)
	}

	relationRaw, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "socialrelationstore", "store.go"))
	if err != nil {
		t.Fatal(err)
	}
	relation := strings.ToLower(string(relationRaw))
	for _, need := range []string{"player_social_roots", "social_friendships", "social_friend_requests", "social_blocks", "social_request_epochs"} {
		if !strings.Contains(relation, need) {
			t.Errorf("relation store missing owner table %s", need)
		}
	}
	for _, bad := range []string{"player_directory_profiles", "player_social_presence", "realtime_presence_leases", "social_notices", "guild_", "insert into players", "update players", "delete from players"} {
		if strings.Contains(relation, bad) {
			t.Errorf("relation store contains foreign-owner marker %q", bad)
		}
	}
	inboxRaw, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "socialinboxstore", "store.go"))
	if err != nil {
		t.Fatal(err)
	}
	inbox := strings.ToLower(string(inboxRaw))
	for _, need := range []string{"social_notices", "social_notice_id_seq"} {
		if !strings.Contains(inbox, need) {
			t.Errorf("inbox store missing %s", need)
		}
	}
	for _, bad := range []string{"player_directory_profiles", "social_friendships", "social_friend_requests", "social_blocks", "social_request_epochs", "player_social_presence", "realtime_presence_leases"} {
		if strings.Contains(inbox, bad) {
			t.Errorf("inbox store contains foreign-owner marker %q", bad)
		}
	}
}

func TestI7A4ADiscoveryIsI4OwnedAndDomainNeutral(t *testing.T) {
	root := repoRoot(t)
	app, err := os.ReadFile(filepath.Join(root, "internal", "application", "playerdirectory", "reader.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(app)
	for _, need := range []string{"type DiscoveryReader interface", "ProfilesByExactName", "PlayerIDBounds", "ProfilesAfter"} {
		if !strings.Contains(s, need) {
			t.Errorf("DiscoveryReader missing %q", need)
		}
	}
	for _, bad := range []string{"Friend", "Block", "Recommendation", "SOCIAL_REQUEST", "MID188", "MID190"} {
		if strings.Contains(s, bad) {
			t.Errorf("I4 discovery port contains Social policy %q", bad)
		}
	}
	adapter, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "i4store", "directory_discovery.go"))
	if err != nil {
		t.Fatal(err)
	}
	a := strings.ToLower(string(adapter))
	if !strings.Contains(a, "player_directory_profiles") || !strings.Contains(a, `collate "c"`) {
		t.Fatal("I4 discovery adapter missing exact C-collated owner read")
	}
	for _, bad := range []string{"social_friend", "social_block", "social_notice", "player_social_roots", "order by random("} {
		if strings.Contains(a, bad) {
			t.Errorf("I4 discovery adapter contains foreign/Social policy %q", bad)
		}
	}
}

func TestI7A4ARoutesRemainExternallyEquivalentToPass629(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	if !strings.Contains(s, "[]uint16{56, 1056, 176, 1302, 1344, 2754, 2784, 8193}") {
		t.Fatal("existing MID176 lobby facade routing drifted")
	}
	for _, mid := range []string{"177", "178", "179", "180", "181", "182", "184", "185", "186", "187", "188", "189", "190"} {
		re := regexp.MustCompile(`\b` + mid + `\b`)
		if re.FindStringIndex(s) != nil {
			t.Fatalf("I7A-4A prematurely activates Social MID %s", mid)
		}
	}
}
