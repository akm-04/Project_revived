//go:build postgres

package playerdisplay_test

import (
	"net/url"
	"os"
	"strings"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
)

// D488 migration 00117 applies on an empty database and upgrades a 00116
// database without a Down section.
func TestI9_10TopFloorOfferSnapshotMigrationNative(t *testing.T) {
	base := os.Getenv("GXB_I7B6A_DSN")
	if base == "" {
		t.Fatal("native DSN required")
	}
	migrations := migrationsRoot(t)
	for _, testCase := range []struct {
		name string
		upTo string
	}{{"empty", ""}, {"from116", "00116"}} {
		dsn, cleanup := disposableTopFloorDatabase(t, base, testCase.name)
		if testCase.upTo != "" {
			runTool(t, "goose", "-dir", migrations, "postgres", dsn, "up-to", testCase.upTo)
			connection := openNativePool(t, dsn)
			if tableExists(t, connection) {
				t.Fatal("00117 table exists before the migration")
			}
			connection.Close()
		}
		runTool(t, "goose", "-dir", migrations, "postgres", dsn, "up")
		connection := openNativePool(t, dsn)
		if !tableExists(t, connection) {
			t.Fatal("00117 table missing after the migration")
		}
		for _, column := range []string{"player_id", "logical_server_id", "scope", "generation", "challenger_rank", "offers", "updated_at"} {
			if !columnExists(t, connection, column) {
				t.Fatalf("00117 column %s missing", column)
			}
		}
		connection.Close()
		cleanup()
	}
}

func disposableTopFloorDatabase(t *testing.T, baseDSN, suffix string) (string, func()) {
	t.Helper()
	base, err := url.Parse(baseDSN)
	if err != nil {
		t.Fatal(err)
	}
	name := "ptf7_offer_migration_" + suffix + "_" + strings.ReplaceAll(uuid().String(), "-", "")
	runTool(t, "createdb", "--maintenance-db", baseDSN, name)
	target := *base
	target.Path = "/" + name
	return target.String(), func() {
		runTool(t, "dropdb", "--force", "--maintenance-db", baseDSN, name)
	}
}

func tableExists(t *testing.T, connection *pg.Pool) bool {
	t.Helper()
	var found bool
	if err := connection.QueryRow(ctx, `SELECT to_regclass('top_floor_offer_snapshots') IS NOT NULL`).Scan(&found); err != nil {
		t.Fatal(err)
	}
	return found
}

func columnExists(t *testing.T, connection *pg.Pool, column string) bool {
	t.Helper()
	var found bool
	if err := connection.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='top_floor_offer_snapshots' AND column_name=$1)`, column).Scan(&found); err != nil {
		t.Fatal(err)
	}
	return found
}
