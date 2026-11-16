//go:build postgres

package commerceprivilegestore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadVersionRoundTripCommercePrivilegeStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH17_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH17_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	at := time.Date(2026, 11, 16, 4, 0, 0, 123456000, time.UTC)
	crystal, vipXP := int64(120), int64(30)
	final := d.ChargeTuning{Version: 1, Mode: d.TuningGrant, Products: map[string]d.ChargeOverride{"80001007": {Crystal: &crystal, VIPXP: &vipXP, Off: true}}}
	payloadText, err := json.Marshal(final)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO commerce_recharge_tuning(singleton,payload,updated_at)VALUES(true,$1::jsonb,$2) ON CONFLICT(singleton)DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at`, string(payloadText), at); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM commerce_recharge_tuning`).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != 0 {
		t.Fatalf("payload_version=%d want=0 (operator SQL writer)", version)
	}
	var decoded d.ChargeTuning
	if err := payload.Decode("commerce_recharge_tuning", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("decode: %v", err)
	}
	assertSameJSON(t, decoded, final)
	tuning, found, err := (commerceprivilegestore.Store{}).ChargeTuningTx(ctx, pool)
	if err != nil || !found {
		t.Fatalf("ChargeTuningTx found=%v err=%v", found, err)
	}
	assertSameJSON(t, tuning, final)
}

func assertSameJSON(t *testing.T, got, want any) {
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
