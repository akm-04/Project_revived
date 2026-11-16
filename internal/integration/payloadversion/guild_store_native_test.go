//go:build postgres

package payloadversion

import (
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripGuildStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH14_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH14_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err := transaction.Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(999999,'payload-version-guild',NULL,false,false,false,99999925002,99999999999,1,now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777777','payload-version-guild','ACTIVE',now())`); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(99999925001,'77777777-7777-4777-8777-777777777777',999999,now(),'payload-version-guild')`); err != nil {
		t.Fatal(err)
	}
	const guildID = guild.ID(999999000001)
	if _, err := transaction.Exec(ctx, `INSERT INTO guilds(guild_id,logical_server_id,name,icon,apply_type,min_allow_level,vitality,policy_revision,created_at,updated_at) VALUES($1,999999,'payload-version',1,0,1,0,'rev',now(),now())`, int64(guildID)); err != nil {
		t.Fatal(err)
	}
	var zero ids.UUID
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	writer := guildstore.Store{}
	if err := writer.AppendAuditTx(ctx, transaction, guildID, "ROLE", identity.PlayerID(99999925001), identity.PlayerID(99999925001), at, "rev", zero, `{"role":2}`); err != nil {
		t.Fatal(err)
	}
	if err := writer.AppendAuditTx(ctx, transaction, guildID, "ROLE", identity.PlayerID(99999925001), identity.PlayerID(99999925001), at.Add(time.Minute), "rev", zero, `{"role":0}`); err != nil {
		t.Fatal(err)
	}
	if err := writer.AppendAuditTx(ctx, transaction, guildID, "KICK", identity.PlayerID(99999925001), identity.PlayerID(99999925001), at.Add(2*time.Minute), "rev", zero, "{}"); err != nil {
		t.Fatal(err)
	}

	var storedText string
	var version int16
	if err := transaction.QueryRow(ctx, `SELECT details::text,payload_version FROM guild_audit_log WHERE guild_id=$1 AND sequence=2`, int64(guildID)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	role := int64(0)
	marshalled, err := json.Marshal(guildstore.AuditDetails{Role: &role})
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := transaction.QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored details=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded guildstore.AuditDetails
	if err := payload.Decode("guild_audit_log", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if decoded.Role == nil || *decoded.Role != 0 {
		t.Fatalf("decoded role=%v want 0", decoded.Role)
	}

	rows, err := writer.ListMemberLogTx(ctx, transaction, int64(guildID), at.Add(-time.Hour), 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 3 {
		t.Fatalf("member log rows=%d want 3", len(rows))
	}
	wantRoles := []int64{-1, 0, 2}
	for index, row := range rows {
		if row.Role != wantRoles[index] {
			t.Fatalf("row %d kind=%s role=%d want=%d", index, row.Kind, row.Role, wantRoles[index])
		}
	}
}
