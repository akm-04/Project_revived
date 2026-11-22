//go:build postgres

package i5store_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
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
		pool.Raw().Exec(cleanup, `DELETE FROM player_awakening_roots WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, accountUID)
	})
	return accountUID
}

func TestPayloadVersionRoundTripI5Store(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-i5store-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	store := i5store.Store{}
	pid := identity.PlayerID(113022)
	seedR82Player(t, p, pid, "i5-native")

	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = store.LockAwakeningTx(ctx, tr, pid); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var inserted objective.AwakeRoot
	storedPayload(t, p, "player_awakening_roots", "payload", "player_id=$1", &inserted, int64(pid))
	samePayload(t, objective.NewAwakeRoot(), inserted)
	read, err := store.ReadAwakeningTx(ctx, p, pid)
	if err != nil {
		t.Fatal(err)
	}

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, err := store.LockAwakeningTx(ctx, tr, pid)
	if err != nil {
		t.Fatal(err)
	}
	locked.Version++
	locked.NextGeneration++
	if err = store.SaveAwakeningTx(ctx, tr, pid, locked, read.Version); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var saved objective.AwakeRoot
	storedPayload(t, p, "player_awakening_roots", "payload", "player_id=$1", &saved, int64(pid))
	samePayload(t, locked, saved)
	read, err = store.ReadAwakeningTx(ctx, p, pid)
	if err != nil {
		t.Fatal(err)
	}
	samePayload(t, locked, read)
}
