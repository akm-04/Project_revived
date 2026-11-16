//go:build postgres

package campaignstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type campaignFixture struct {
	transaction tx.Tx
}

func newCampaignFixture(t *testing.T) *campaignFixture {
	t.Helper()
	dsn := os.Getenv("GXB_R8_MANIFEST_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_MANIFEST_DSN required")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = transaction.Rollback(ctx) })
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',now())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,now(),'payload-version-probe')`, int64(identity.PlayerID(190001)), account.String()); err != nil {
		t.Fatal(err)
	}
	return &campaignFixture{transaction: transaction}
}

func requireVersionOne(t *testing.T, version int16) {
	t.Helper()
	if version != payload.Current {
		t.Fatalf("payload_version = %d, want %d", version, payload.Current)
	}
}

func requireSameJSON(t *testing.T, raw string, value any) {
	t.Helper()
	expected, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	var storedValue, expectedValue any
	if err := json.Unmarshal([]byte(raw), &storedValue); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(expected, &expectedValue); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(storedValue, expectedValue) {
		t.Fatalf("stored payload differs from written value\n got: %s\nwant: %s", raw, expected)
	}
}

func requireDecodes[T any](t *testing.T, table string, version int16, raw []byte, want T) T {
	t.Helper()
	var value T
	if err := payload.Decode(table, version, raw, &value); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(value, want) {
		t.Fatalf("%s decoded value differs: got %+v want %+v", table, value, want)
	}
	return value
}

func TestPayloadVersionRoundTripCampaignStore(t *testing.T) {
	ctx := context.Background()
	fixture := newCampaignFixture(t)
	at := time.Now().UTC().Truncate(time.Second)
	store := campaignstore.Store{}
	record, err := store.LockTx(ctx, fixture.transaction, 190001, at)
	if err != nil {
		t.Fatal(err)
	}
	record.PendingGeneration = "generation-open"
	record.PendingItems = []d.Item{{ItemID: 1001, Num: 2}, {ItemID: 1002, Num: 1}}
	record.LastGeneration = "generation-settled"
	record.LastResult = json.RawMessage(`{"error_code":0}`)
	record.Progress.ChapterClaims = map[int64]int64{100001: 2}
	record.Progress.StoryClaims = map[int64]json.RawMessage{100001: json.RawMessage(`{"node_id":100001}`)}
	record.Progress.TrialWins = map[int64]modes.Counter{100001: {Period: 3, Used: 2}}
	if err := store.SaveTx(ctx, fixture.transaction, 190001, record, nil, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	var pending, chapters, stories, trials string
	var version int16
	if err := fixture.transaction.QueryRow(ctx, `SELECT pending_items::text,chapter_claims::text,story_claims::text,trial_wins::text,payload_version FROM campaign_players WHERE player_id=$1`, 190001).Scan(&pending, &chapters, &stories, &trials, &version); err != nil {
		t.Fatal(err)
	}
	requireVersionOne(t, version)
	requireSameJSON(t, pending, record.PendingItems)
	requireSameJSON(t, chapters, record.Progress.ChapterClaims)
	requireSameJSON(t, stories, record.Progress.StoryClaims)
	requireSameJSON(t, trials, record.Progress.TrialWins)
	requireDecodes(t, "campaign_players", version, []byte(pending), record.PendingItems)
	requireDecodes(t, "campaign_players", version, []byte(chapters), record.Progress.ChapterClaims)
	requireDecodes(t, "campaign_players", version, []byte(trials), record.Progress.TrialWins)
	var decodedStories map[int64]json.RawMessage
	if err := payload.Decode("campaign_players", version, []byte(stories), &decodedStories); err != nil {
		t.Fatal(err)
	}
	requireSameJSON(t, string(decodedStories[100001]), record.Progress.StoryClaims[100001])
	stored, err := store.ReadTx(ctx, fixture.transaction, 190001)
	if err != nil {
		t.Fatal("ReadTx", err)
	}
	if !reflect.DeepEqual(stored.PendingItems, record.PendingItems) || !reflect.DeepEqual(stored.Progress.ChapterClaims, record.Progress.ChapterClaims) ||
		!reflect.DeepEqual(stored.Progress.TrialWins, record.Progress.TrialWins) {
		t.Fatal("ReadTx payloads differ")
	}
	if len(stored.Progress.StoryClaims) != 1 {
		t.Fatalf("ReadTx story claims = %+v", stored.Progress.StoryClaims)
	}
	requireSameJSON(t, string(stored.Progress.StoryClaims[100001]), record.Progress.StoryClaims[100001])

	record.StateVersion = 2
	record.PendingGeneration = ""
	if err := store.SaveTx(ctx, fixture.transaction, 190001, record, nil, at.Add(2*time.Minute)); err != nil {
		t.Fatal(err)
	}
	var pendingIsNull bool
	if err := fixture.transaction.QueryRow(ctx, `SELECT pending_items IS NULL,payload_version FROM campaign_players WHERE player_id=$1`, 190001).Scan(&pendingIsNull, &version); err != nil {
		t.Fatal(err)
	}
	if !pendingIsNull {
		t.Fatal("pending_items should be NULL without an open generation")
	}
	requireVersionOne(t, version)
	withoutPending, err := store.ReadTx(ctx, fixture.transaction, 190001)
	if err != nil {
		t.Fatal("ReadTx", err)
	}
	if len(withoutPending.PendingItems) != 0 {
		t.Fatalf("ReadTx pending items = %+v, want empty", withoutPending.PendingItems)
	}
	if !reflect.DeepEqual(withoutPending.Progress.TrialWins, record.Progress.TrialWins) {
		t.Fatal("ReadTx trial wins differ after update")
	}
}
