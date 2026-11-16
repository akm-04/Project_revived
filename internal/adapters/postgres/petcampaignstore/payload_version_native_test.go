//go:build postgres

package petcampaignstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/petcampaignstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripPetcampaignStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH18_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH18_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	for _, statement := range []string{
		`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(27,'payload-version-petcampaign',NULL,false,false,false,2799999,2799999,1,now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777718','payload-version-petcampaign','ACTIVE',now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(2700001,'77777777-7777-4777-8777-777777777718',27,now(),'payload-version-petcampaign') ON CONFLICT DO NOTHING`,
	} {
		if _, err := pool.Raw().Exec(ctx, statement); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		for _, statement := range []string{
			`DELETE FROM petcampaign_players WHERE player_id=2700001`,
			`DELETE FROM players WHERE player_id=2700001`,
			`DELETE FROM accounts WHERE account_id='77777777-7777-4777-8777-777777777718'`,
			`DELETE FROM logical_servers WHERE logical_server_id=27`,
		} {
			if _, err := pool.Raw().Exec(context.Background(), statement); err != nil {
				t.Errorf("cleanup %q: %v", statement, err)
			}
		}
	})
	at := time.Date(2026, 11, 16, 5, 0, 0, 123456000, time.UTC)
	player := identity.PlayerID(2700001)
	server := identity.LogicalServerID(27)
	store := petcampaignstore.Store{}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	state, err := store.LockTx(ctx, transaction, player, at)
	if err != nil {
		t.Fatal(err)
	}
	state.Server = int64(server)
	state.Player = int64(player)
	state.Initialized = true
	state.Day = 5
	state.Current = 7
	state.Max = 42
	state.EliteMax = 3
	state.Attained = at.UnixMilli()
	state.LastSweep = map[string]any{"floor": 7}
	state.LastResult = map[string]any{"kind": "win"}
	if err := store.SaveTx(ctx, transaction, player, state, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM petcampaign_players WHERE player_id=$1`, int64(player)).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded d.State
	if err := payload.Decode(petcampaignTable, version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSamePetcampaignJSON(t, decoded, state)
	read, found, err := store.ReadTx(ctx, pool, player)
	if err != nil || !found {
		t.Fatalf("ReadTx found=%v err=%v", found, err)
	}
	assertSamePetcampaignJSON(t, read, state)
	ranks, place, err := store.RanksTx(ctx, pool, server, read)
	if err != nil || len(ranks) != 1 || ranks[0].Player != player || ranks[0].Floor != 42 || place != 1 {
		t.Fatalf("RanksTx ranks=%+v place=%d err=%v", ranks, place, err)
	}
	elite, elitePlace, err := store.EliteRanksTx(ctx, pool, server, read)
	if err != nil || len(elite) != 1 || elite[0].Player != player || elite[0].Floor != 3 || elitePlace != 1 {
		t.Fatalf("EliteRanksTx ranks=%+v place=%d err=%v", elite, elitePlace, err)
	}
	expected, err := json.Marshal(state)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(expected)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored payload=%s want json.Marshal=%s", storedText, expectedText)
	}
}

func assertSamePetcampaignJSON(t *testing.T, got, want any) {
	t.Helper()
	gotRaw, err := json.Marshal(got)
	if err != nil {
		t.Fatal(err)
	}
	wantRaw, err := json.Marshal(want)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(gotRaw, wantRaw) {
		t.Fatalf("decoded=%s want=%s", gotRaw, wantRaw)
	}
}
