package presencestore

import (
	"os"
	"strings"
	"testing"
)

func TestI7A3MigrationDeclaresDerivedPresenceOwnership(t *testing.T) {
	raw, err := os.ReadFile("../../../../migrations/00031_i7a3_social_presence.sql")
	if err != nil {
		t.Fatal(err)
	}
	s := string(raw)
	for _, needle := range []string{
		"CREATE TABLE player_social_presence",
		"CREATE TABLE realtime_presence_leases",
		"PRIMARY KEY(gameplay_context_id,physical_role)",
		"ON DELETE CASCADE",
		"connection_generation bigint NOT NULL CHECK (connection_generation > 0)",
		"physical_role IN ('WORLD','GUILD','SERVICE')",
	} {
		if !strings.Contains(s, needle) {
			t.Fatalf("migration missing %q", needle)
		}
	}
}

func TestLeaseUpsertContainsGenerationAndPlayerFences(t *testing.T) {
	for _, needle := range []string{
		"realtime_presence_leases.player_id=EXCLUDED.player_id",
		"realtime_presence_leases.realtime_instance_id<>EXCLUDED.realtime_instance_id",
		"realtime_presence_leases.connection_generation<=EXCLUDED.connection_generation",
		"GREATEST(realtime_presence_leases.lease_expires_at,EXCLUDED.lease_expires_at)",
	} {
		if !strings.Contains(upsertLeaseSQL, needle) {
			t.Fatalf("upsert fence missing %q", needle)
		}
	}
}
