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

func TestI6CGuildApplicationKeepsMechanismsAndForeignSQLOut(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "guildcore")
	forbiddenImports := []string{module + "internal/adapters", "github.com/jackc/pgx", "github.com/riverqueue/river", "database/sql", "net/http"}
	forbiddenText := []string{"player_currency_balances", "player_progression", "player_social_presence", "account_sessions.last_activity_at", "time.Now("}
	err := filepath.WalkDir(base, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") {
			return err
		}
		f, e := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if e != nil {
			return e
		}
		for _, im := range f.Imports {
			imp, _ := strconv.Unquote(im.Path.Value)
			for _, bad := range forbiddenImports {
				if imp == bad || strings.HasPrefix(imp, bad+"/") {
					t.Errorf("%s imports forbidden I6C mechanism %s", path, imp)
				}
			}
		}
		b, e := os.ReadFile(path)
		if e != nil {
			return e
		}
		for _, bad := range forbiddenText {
			if strings.Contains(string(b), bad) {
				t.Errorf("%s contains forbidden I6C ownership/presence marker %q", path, bad)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestI6CGuildStoreDoesNotReachIntoI5OwnedTables(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "guildstore", "store.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, bad := range []string{"player_currency_balances", "player_progression", "player_temporal_resources", "player_item_stacks", "player_economy_owners", "logical_servers", "players", "gameplay_contexts", "account_sessions"} {
		if strings.Contains(s, bad) {
			t.Fatalf("Guild store contains foreign I5-owned table %q", bad)
		}
	}
}

func TestI6CProductionMIDOwnershipAndDeferredSurfaces(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	want := "[]uint16{576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 589, 598, 599, 612, 2563, 2564, 2565}"
	if !strings.Contains(s, want) {
		t.Fatal("I6C Guild MID composition missing or drifted")
	}
	for _, bad := range []string{"mustRegister(588", "mustRegister(609", "[]uint16{588", "[]uint16{609"} {
		if strings.Contains(s, bad) {
			t.Fatalf("deferred Guild surface unexpectedly activated: %s", bad)
		}
	}
	if strings.Contains(s, "[]uint16{56, 612,") {
		t.Fatal("MID612 must no longer be owned by frozen Lobby facade")
	}
	if !strings.Contains(s, "guildprojection.BootstrapProjection{}") {
		t.Fatal("I6C MID1 Guild projection missing")
	}
	if !strings.Contains(s, "Guilds:    guildprojection.RealtimeMembership") {
		t.Fatal("canonical GuildMembership realtime authority adapter missing")
	}
}

func TestI6CMigrations00012And00013StayBoundedAndPresenceRemainsGated(t *testing.T) {
	root := repoRoot(t)
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	var twelve, thirteen []string
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), "00012") {
			twelve = append(twelve, e.Name())
		}
		if strings.HasPrefix(e.Name(), "00013") {
			thirteen = append(thirteen, e.Name())
		}
	}
	if len(twelve) != 1 || twelve[0] != "00012_i6c_guild_core.sql" {
		t.Fatalf("I6C migration 00012 inventory=%v", twelve)
	}
	if len(thirteen) != 1 || thirteen[0] != "00013_i6c_guild_replay_repair.sql" {
		t.Fatalf("F2/I6C repair migration 00013 inventory=%v", thirteen)
	}
	b, err := os.ReadFile(filepath.Join(root, "migrations", twelve[0]))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	for _, need := range []string{"guild_server_allocators", "guilds", "guild_memberships", "guild_applications", "guild_invites", "guild_membership_events", "guild_invite_send_events", "guild_audit_log", "guild_memberships_one_leader_per_guild_uq", "guilds_server_active_name_uq"} {
		if !strings.Contains(s, need) {
			t.Errorf("migration 00012 missing %s", need)
		}
	}
	if !strings.Contains(s, `ON guilds(logical_server_id, name COLLATE "C") WHERE retired_at IS NULL`) {
		t.Error("migration 00012 active Guild-name uniqueness policy drifted")
	}
	for _, bad := range []string{"player_social_presence", "last_activity_at"} {
		if strings.Contains(s, bad) {
			t.Errorf("migration 00012 improperly owns presence marker %s", bad)
		}
	}

	repairBytes, err := os.ReadFile(filepath.Join(root, "migrations", thirteen[0]))
	if err != nil {
		t.Fatal(err)
	}
	repair := string(repairBytes)
	for _, need := range []string{"-- +goose Up", "DELETE FROM guild_applications", "USING guild_memberships", "gm.player_id = ga.player_id"} {
		if !strings.Contains(repair, need) {
			t.Errorf("migration 00013 missing bounded cleanup marker %q", need)
		}
	}
	for _, bad := range []string{"-- +goose Down", "CREATE TABLE", "ALTER TABLE", "DROP TABLE", "TRUNCATE", "guild_membership_events"} {
		if strings.Contains(strings.ToUpper(repair), strings.ToUpper(bad)) {
			t.Errorf("migration 00013 exceeded data-cleanup-only contract with %q", bad)
		}
	}
}

func TestF1F2GuildReplayRepairGuardsIdentityCriticalFactsAndV2Receipts(t *testing.T) {
	root := repoRoot(t)
	storeBytes, err := os.ReadFile(filepath.Join(root, "internal", "adapters", "postgres", "guildstore", "store.go"))
	if err != nil {
		t.Fatal(err)
	}
	store := string(storeBytes)
	for _, need := range []string{"LatestMembershipEventTx", "ORDER BY event_id DESC LIMIT 1", "guild_membership_events"} {
		if !strings.Contains(store, need) {
			t.Errorf("F1 membership-incarnation store seam missing %q", need)
		}
	}

	for _, rel := range []string{"internal/adapters/postgres/guildstore", "migrations"} {
		err := filepath.WalkDir(filepath.Join(root, filepath.FromSlash(rel)), func(path string, d os.DirEntry, err error) error {
			if err != nil || d.IsDir() {
				return err
			}
			if !strings.HasSuffix(path, ".go") && !strings.HasSuffix(path, ".sql") {
				return nil
			}
			b, readErr := os.ReadFile(path)
			if readErr != nil {
				return readErr
			}
			upper := strings.ToUpper(string(b))
			for _, bad := range []string{"DELETE FROM GUILD_MEMBERSHIP_EVENTS", "TRUNCATE GUILD_MEMBERSHIP_EVENTS"} {
				if strings.Contains(upper, bad) {
					t.Errorf("identity-critical membership event ledger is no longer append-only: %s contains %q", path, bad)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}

	mutBytes, err := os.ReadFile(filepath.Join(root, "internal", "application", "guildcore", "mutations.go"))
	if err != nil {
		t.Fatal(err)
	}
	mut := string(mutBytes)
	for _, need := range []string{"currentMembershipIncarnationTx", "gxb.i6c.guild.leave.v2", "gxb.i6c.guild.kick.v2", "gxb.i6c.guild.set_role.v2", "targetinc:", "actorinc:"} {
		if !strings.Contains(mut, need) {
			t.Errorf("F1 v2 membership replay contract missing %q", need)
		}
	}
	serviceBytes, err := os.ReadFile(filepath.Join(root, "internal", "application", "guildcore", "service.go"))
	if err != nil {
		t.Fatal(err)
	}
	service := string(serviceBytes)
	for _, need := range []string{"gxb.i6c.guild.apply_application.v2", "gxb.i6c.guild.join_immediate.v2", "DeleteApplicationsForPlayerTx", "LockApplicationTx"} {
		if !strings.Contains(service, need) {
			t.Errorf("F2 current-state convergence contract missing %q", need)
		}
	}
}
