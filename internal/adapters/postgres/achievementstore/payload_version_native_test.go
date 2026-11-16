//go:build postgres

package achievementstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type achievementFixture struct {
	transaction tx.Tx
	revision    string
}

func newAchievementFixture(t *testing.T) *achievementFixture {
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
	fixture := &achievementFixture{transaction: transaction}
	if err := transaction.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY installed_at DESC LIMIT 1`).Scan(&fixture.revision); err != nil {
		t.Fatal("content revision required:", err)
	}
	for _, pid := range []identity.PlayerID{190001, 190002} {
		account, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',now())`, account.String(), account.String()); err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,now(),'payload-version-probe')`, int64(pid), account.String()); err != nil {
			t.Fatal(err)
		}
	}
	return fixture
}

func (f *achievementFixture) storedPayload(t *testing.T, sql string, args ...any) (string, int16) {
	t.Helper()
	var raw string
	var version int16
	if err := f.transaction.QueryRow(context.Background(), sql, args...).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	return raw, version
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

func TestPayloadVersionRoundTripAchievementStore(t *testing.T) {
	ctx := context.Background()
	fixture := newAchievementFixture(t)
	at := time.Now().UTC().Truncate(time.Second)
	store := achievementstore.Store{}

	if err := store.InitFreshTx(ctx, fixture.transaction, 190001, fixture.revision, at); err != nil {
		t.Fatal(err)
	}
	initialRaw, initialVersion := fixture.storedPayload(t, `SELECT complete_times::text,payload_version FROM achievement_roots WHERE player_id=$1`, 190001)
	if initialVersion != 0 {
		t.Fatalf("SQL-built initial payload version = %d, want 0", initialVersion)
	}
	requireDecodes(t, "achievement_roots", initialVersion, []byte(initialRaw), []*time.Time{nil, nil, nil})

	root, found, err := store.ReadRootTx(ctx, fixture.transaction, 190001, true)
	if err != nil || !found {
		t.Fatal("ReadRootTx", found, err)
	}
	stamp := at.Add(time.Minute)
	root.CompleteTimes[0] = &stamp
	root.Progress, root.StateVersion, root.UpdatedAt = 1, 2, at.Add(time.Hour)
	if err := store.SaveRootTx(ctx, fixture.transaction, root, 1); err != nil {
		t.Fatal(err)
	}
	raw, version := fixture.storedPayload(t, `SELECT complete_times::text,payload_version FROM achievement_roots WHERE player_id=$1`, 190001)
	requireVersionOne(t, version)
	requireSameJSON(t, raw, root.CompleteTimes)
	requireDecodes(t, "achievement_roots", version, []byte(raw), []*time.Time{&stamp, nil, nil})
	storedRoot, found, err := store.ReadRootTx(ctx, fixture.transaction, 190001, false)
	if err != nil || !found || !reflect.DeepEqual(storedRoot.CompleteTimes, root.CompleteTimes) {
		t.Fatal("ReadRootTx payloads differ", found, err)
	}

	if err := store.InitFreshTx(ctx, fixture.transaction, 190002, fixture.revision, at); err != nil {
		t.Fatal(err)
	}
	streak, err := d.NewStreak(190002, d.WinStreakID, fixture.revision, at)
	if err != nil {
		t.Fatal(err)
	}
	firstStamp := at.Add(time.Minute)
	streak.Current = 5
	streak.CompleteTimes[0] = &firstStamp
	streak.UpdatedAt = at.Add(time.Hour)
	if err := store.SaveStreakTx(ctx, fixture.transaction, streak, 0); err != nil {
		t.Fatal(err)
	}
	raw, version = fixture.storedPayload(t, `SELECT complete_times::text,payload_version FROM achievement_streaks WHERE player_id=$1`, 190002)
	requireVersionOne(t, version)
	requireSameJSON(t, raw, streak.CompleteTimes)
	requireDecodes(t, "achievement_streaks", version, []byte(raw), []*time.Time{&firstStamp, nil, nil})

	secondStamp := at.Add(2 * time.Minute)
	streak.CompleteTimes[1] = &secondStamp
	streak.Current, streak.StateVersion, streak.UpdatedAt = 15, 2, at.Add(2*time.Hour)
	if err := store.SaveStreakTx(ctx, fixture.transaction, streak, 1); err != nil {
		t.Fatal(err)
	}
	raw, version = fixture.storedPayload(t, `SELECT complete_times::text,payload_version FROM achievement_streaks WHERE player_id=$1`, 190002)
	requireVersionOne(t, version)
	requireSameJSON(t, raw, streak.CompleteTimes)
	requireDecodes(t, "achievement_streaks", version, []byte(raw), []*time.Time{&firstStamp, &secondStamp, nil})
	storedStreak, found, err := store.ReadStreakTx(ctx, fixture.transaction, 190002, d.WinStreakID, false)
	if err != nil || !found || !reflect.DeepEqual(storedStreak.CompleteTimes, streak.CompleteTimes) {
		t.Fatal("ReadStreakTx payloads differ", found, err)
	}
}
