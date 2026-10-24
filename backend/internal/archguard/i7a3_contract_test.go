package archguard

import (
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestI7A3SocialPresenceApplicationHasNoEdgeOrPersistenceDependency(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "socialpresence")
	forbiddenImports := []string{
		module + "internal/adapters",
		module + "internal/protocol",
		"github.com/jackc/pgx",
		"github.com/riverqueue/river",
		"database/sql",
		"net/http",
	}
	forbiddenText := []string{
		"player_social_presence",
		"realtime_presence_leases",
		"guild_memberships",
		"guild_membership_events",
		"gameplay_contexts",
		"account_sessions",
		"time.Now(",
	}
	err := filepath.WalkDir(base, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return err
		}
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if err != nil {
			return err
		}
		for _, im := range f.Imports {
			imp, _ := strconv.Unquote(im.Path.Value)
			for _, bad := range forbiddenImports {
				if imp == bad || strings.HasPrefix(imp, bad+"/") {
					t.Errorf("%s imports forbidden I7A-3 dependency %q", path, imp)
				}
			}
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for _, bad := range forbiddenText {
			if strings.Contains(string(b), bad) {
				t.Errorf("%s contains forbidden I7A-3 ownership/time marker %q", path, bad)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestI7A3PresenceStoreOwnsOnlyPresenceMutationSQL(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "presencestore", "store.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := strings.ToLower(string(b))
	for _, need := range []string{"realtime_presence_owner_state", "player_social_presence", "realtime_presence_leases"} {
		if !strings.Contains(s, need) {
			t.Fatalf("Presence store missing owned table %q", need)
		}
	}
	for _, bad := range []string{
		"insert into guild_", "update guild_", "delete from guild_",
		"insert into gameplay_contexts", "update gameplay_contexts", "delete from gameplay_contexts",
		"insert into players", "update players", "delete from players",
		"account_sessions",
	} {
		if strings.Contains(s, bad) {
			t.Fatalf("Presence store contains foreign-owner mutation/reference marker %q", bad)
		}
	}
}

func TestI7A3GuildStoresDoNotOwnPresenceSQL(t *testing.T) {
	root := repoRoot(t)
	for _, rel := range []string{
		"internal/adapters/postgres/guildstore/store.go",
		"internal/adapters/postgres/guildstore/realtime_binding.go",
		"internal/adapters/postgres/guildprojection/realtime_membership.go",
	} {
		b, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(rel)))
		if err != nil {
			t.Fatal(err)
		}
		s := strings.ToLower(string(b))
		for _, bad := range []string{"player_social_presence", "realtime_presence_leases"} {
			if strings.Contains(s, bad) {
				t.Fatalf("%s contains foreign Presence table %q", rel, bad)
			}
		}
	}
}

func TestI7A3MigrationInventoryAndOwnershipBoundaries(t *testing.T) {
	root := repoRoot(t)
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	var thirtyOne, thirtyTwo []string
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), "00031") {
			thirtyOne = append(thirtyOne, e.Name())
		}
		if strings.HasPrefix(e.Name(), "00032") {
			thirtyTwo = append(thirtyTwo, e.Name())
		}
	}
	if len(thirtyOne) != 1 || thirtyOne[0] != "00031_i7a3_social_presence.sql" {
		t.Fatalf("I7A-3 migration 00031 inventory=%v", thirtyOne)
	}
	if len(thirtyTwo) != 1 || thirtyTwo[0] != "00032_i7a3_presence_owner_fence_repair.sql" {
		t.Fatalf("I7A-3 repair migration 00032 inventory=%v", thirtyTwo)
	}
	baseRaw, err := os.ReadFile(filepath.Join(root, "migrations", thirtyOne[0]))
	if err != nil {
		t.Fatal(err)
	}
	base := string(baseRaw)
	for _, need := range []string{
		"CREATE TABLE player_social_presence",
		"CREATE TABLE realtime_presence_leases",
		"PRIMARY KEY(gameplay_context_id,physical_role)",
		"REFERENCES players(player_id) ON DELETE CASCADE",
		"REFERENCES gameplay_contexts(context_id) ON DELETE CASCADE",
		"REFERENCES player_social_presence(player_id) ON DELETE CASCADE",
		"physical_role IN ('WORLD','GUILD','SERVICE')",
		"connection_generation bigint NOT NULL CHECK (connection_generation > 0)",
		"last_renewed_at >= connected_at",
		"lease_expires_at > connected_at",
	} {
		if !strings.Contains(base, need) {
			t.Errorf("migration 00031 missing %q", need)
		}
	}
	if strings.Contains(base, "realtime_owner_fence") {
		t.Fatal("sealed migration 00031 was rewritten instead of repaired forward")
	}
	repairRaw, err := os.ReadFile(filepath.Join(root, "migrations", thirtyTwo[0]))
	if err != nil {
		t.Fatal(err)
	}
	repair := string(repairRaw)
	for _, need := range []string{
		"CREATE SEQUENCE realtime_presence_owner_fence_seq AS bigint",
		"CREATE TABLE realtime_presence_owner_state",
		"DELETE FROM realtime_presence_leases",
		"ADD COLUMN realtime_owner_fence bigint NOT NULL CHECK (realtime_owner_fence > 0)",
	} {
		if !strings.Contains(repair, need) {
			t.Errorf("migration 00032 missing %q", need)
		}
	}
	for _, bad := range []string{"DELETE FROM player_social_presence", "account_sessions", "last_activity_at", "guild_memberships", "guild_membership_events", "CREATE TABLE guild_"} {
		if strings.Contains(base, bad) || strings.Contains(repair, bad) {
			t.Errorf("I7A-3 migrations exceed ownership/backfill contract with %q", bad)
		}
	}
}

func TestI7A3PresenceOwnerFenceExtendsR6WithoutReplacingIt(t *testing.T) {
	root := repoRoot(t)
	mainRaw, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-realtime", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	main := string(mainRaw)
	acquire := strings.Index(main, "AcquireRealtimeOwner")
	activate := strings.Index(main, "ActivateRealtimeOwnerFence")
	serve := strings.Index(main, "RealtimeServer{")
	if acquire < 0 || activate <= acquire || serve <= activate {
		t.Fatalf("owner-fence startup order must be R6 advisory owner -> Presence fence -> serving: acquire=%d activate=%d serve=%d", acquire, activate, serve)
	}
	storeRaw, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "presencestore", "store.go"))
	if err != nil {
		t.Fatal(err)
	}
	store := string(storeRaw)
	for _, need := range []string{
		"realtime_presence_owner_state",
		"FOR SHARE",
		"realtime_presence_leases.realtime_owner_fence < EXCLUDED.realtime_owner_fence",
		"realtime_presence_leases.realtime_owner_fence = EXCLUDED.realtime_owner_fence",
	} {
		if !strings.Contains(store, need) {
			t.Fatalf("Presence owner fence missing %q", need)
		}
	}
	if strings.Contains(store, "realtime_presence_leases.realtime_instance_id<>EXCLUDED.realtime_instance_id") {
		t.Fatal("unordered realtime instance UUID must not authorize Presence owner takeover")
	}
}

func TestI7A3KeepsDeferredWorkerAndOfflineLeaderPoliciesInactive(t *testing.T) {
	root := repoRoot(t)
	worker, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-worker", "main.go"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(worker), "socialpresence") || strings.Contains(string(worker), "ReconcileProviderName") {
		t.Fatal("I7A-3 unexpectedly activated Presence reconciliation in gxb-worker/I7A-8 surface")
	}

	var offenders []string
	for _, rel := range []string{"internal/application/guildcore", "internal/adapters/postgres/guildstore"} {
		err := filepath.WalkDir(filepath.Join(root, filepath.FromSlash(rel)), func(path string, d os.DirEntry, err error) error {
			if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
				return err
			}
			b, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			s := strings.ToLower(string(b))
			for _, marker := range []string{"259200", "offline leader", "offline_leader", "guild_offline_chief"} {
				if strings.Contains(s, marker) {
					relPath, _ := filepath.Rel(root, path)
					offenders = append(offenders, filepath.ToSlash(relPath)+":"+marker)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
	if len(offenders) != 0 {
		t.Fatalf("I7A-3 unexpectedly activated deferred offline-leader policy: %v", offenders)
	}
}
