//go:build postgres

package eventcentrestore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/eventcentrestore"
	"gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func storedPayload[T any](t *testing.T, p *pg.Pool, table, column, where string, out *T, args ...any) []byte {
	t.Helper()
	var raw []byte
	var version int16
	if err := p.QueryRow(context.Background(), `SELECT `+column+`::text,payload_version FROM `+table+` WHERE `+where, args...).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("%s.%s payload_version=%d want %d", table, column, version, payload.Current)
	}
	if err := payload.Decode(table, version, raw, out); err != nil {
		t.Fatalf("%s.%s strict decode: %v", table, column, err)
	}
	return raw
}

func samePayload(t *testing.T, written, decoded any) {
	t.Helper()
	writtenRaw, err := json.Marshal(written)
	if err != nil {
		t.Fatal(err)
	}
	decodedRaw, err := json.Marshal(decoded)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(decodedRaw, writtenRaw) {
		t.Fatalf("payload changed: decoded=%s written=%s", decodedRaw, writtenRaw)
	}
}

func seedR82Player(t *testing.T, pool *pg.Pool, pid identity.PlayerID, tag string) string {
	t.Helper()
	ctx := context.Background()
	accountUID := "r8-2b-" + tag + "-" + strconv.FormatInt(int64(pid), 10)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES(gen_random_uuid(),$1,'ACTIVE',clock_timestamp())`, accountUID); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) SELECT $1,account_id,1,clock_timestamp(),'r8-2b-native' FROM accounts WHERE account_uid=$2`, int64(pid), accountUID); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cleanup := context.Background()
		pool.Raw().Exec(cleanup, `DELETE FROM player_event_centre_roots WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, accountUID)
	})
	return accountUID
}

func TestPayloadVersionRoundTripEventCentreStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-eventcentrestore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	store := eventcentrestore.Store{}
	pid := identity.PlayerID(113023)
	seedR82Player(t, p, pid, "eventcentre-native")
	var revision string
	if err = p.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY revision_id LIMIT 1`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC().Truncate(time.Second)

	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.EnsureRootTx(ctx, tr, pid, revision, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var inserted eventcentre.State
	storedPayload(t, p, "player_event_centre_roots", "facts", "player_id=$1", &inserted, int64(pid))
	samePayload(t, eventcentre.Seed(), inserted)
	read, ok, err := store.ReadRootTx(ctx, p, pid)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, ok, err := store.LockRootTx(ctx, tr, pid)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}
	locked.Version = read.Version + 1
	locked.UpdatedAt = now.Add(time.Second)
	if err = store.SaveRootTx(ctx, tr, locked, read.Version); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var saved eventcentre.State
	storedPayload(t, p, "player_event_centre_roots", "facts", "player_id=$1", &saved, int64(pid))
	samePayload(t, locked.Facts, saved)
	read, ok, err = store.ReadRootTx(ctx, p, pid)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}
	samePayload(t, locked.Facts, read.Facts)
}
