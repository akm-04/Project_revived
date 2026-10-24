package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/activitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
)

func TestI6DProductionRealtimeUsesSameCanonicalGuildMembershipAdapterAsAPI(t *testing.T) {
	root := repoRoot(t)
	for _, rel := range []string{
		filepath.Join("cmd", "gxb-api", "main_postgres.go"),
		filepath.Join("cmd", "gxb-realtime", "main_postgres.go"),
	} {
		b, err := os.ReadFile(filepath.Join(root, rel))
		if err != nil {
			t.Fatal(err)
		}
		s := string(b)
		if !strings.Contains(s, `"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"`) {
			t.Fatalf("%s does not import canonical GuildMembership adapter", rel)
		}
		if !strings.Contains(s, "Guilds:    guildprojection.RealtimeMembership{Queryer: pool}") {
			t.Fatalf("%s does not install canonical GuildMembership adapter", rel)
		}
	}
}

func TestI6DAggregateMID1ContributorClaimsRemainDisjoint(t *testing.T) {
	contributors := []appboot.MID1DetailContributor{
		i5store.BootstrapProjection{},
		activitystore.BootstrapProjection{},
		guildprojection.BootstrapProjection{},
	}
	if err := appboot.ValidateDetailContributors(contributors); err != nil {
		t.Fatalf("actual I5+I6B+I6C contributor claim set collides: %v", err)
	}
	if got := contributors[1].Claims(); len(got) != 1 || got[0] != "229" {
		t.Fatalf("I6B Activity claim set drifted: %v", got)
	}
	guildClaims := contributors[2].Claims()
	if len(guildClaims) != 2 || guildClaims[0] != "17.guild_id" || guildClaims[1] != "612" {
		t.Fatalf("I6C Guild claim set drifted: %v", guildClaims)
	}
}

func TestI6DProductionKeepsDeferredRealtimePublicationInactive(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-realtime", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	if strings.Contains(s, "Dispatcher:") && !selectedChannelChat(t) {
		t.Fatal("I6D must not activate established-socket feature publication; I7A owns that surface")
	}
	if strings.Contains(s, "gxb-worker") || strings.Contains(s, "river.NewClient") {
		t.Fatal("I6D realtime composition must not activate deferred worker/River runtime providers")
	}
}

func TestI6DGuildRoomNamespaceStaysDisjointFromWorldAndService(t *testing.T) {
	for _, server := range []identity.LogicalServerID{1, 2, 99_999} {
		for _, serial := range []int64{1, 999_999} {
			gid, err := guild.WireID(server, serial)
			if err != nil {
				t.Fatalf("server=%d serial=%d: %v", server, serial, err)
			}
			if int64(gid) == int64(server) {
				t.Fatalf("Guild room %d collides with WORLD room %d", gid, server)
			}
			if int64(gid) == domainrt.ServiceRoomID {
				t.Fatalf("Guild room %d collides with SERVICE room", gid)
			}
			if int64(gid)/1_000_000 != int64(server) {
				t.Fatalf("Guild room %d escaped logical-server namespace %d", gid, server)
			}
		}
	}
}
