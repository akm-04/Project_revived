//go:build postgres

package undeliveredstore_test

import (
	"context"
	"os"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/undeliveredstore"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/undelivered"
)

var ctx = context.Background()

func nativePool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_R6_UNDELIVERED_DSN")
	if dsn == "" {
		t.Fatal("GXB_R6_UNDELIVERED_DSN required")
	}
	pool, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func nativePlayer(t *testing.T, pool *postgres.Pool) int64 {
	t.Helper()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	var player int64
	if err := pool.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&player); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,clock_timestamp(),'r6-native')`, player, account.String()); err != nil {
		t.Fatal(err)
	}
	return player
}

func nativeSession(t *testing.T) string {
	t.Helper()
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return session.String()
}

func TestUndeliveredStoreMarkThenTake(t *testing.T) {
	pool := nativePool(t)
	store := undeliveredstore.Store{Pool: pool.Raw()}
	player := nativePlayer(t, pool)
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Now().UTC().Truncate(time.Microsecond)
	mark := undelivered.Mark{PlayerID: player, SessionID: session.String(), MID: 5, Fingerprint: [32]byte{9, 8, 7}, Reply: []byte(`{"ok":1}` + "\n"), MarkedAt: at}
	if err := store.Mark(ctx, mark); err != nil {
		t.Fatal(err)
	}
	taken, found, err := store.TakeMark(ctx, player)
	if err != nil || !found {
		t.Fatalf("found=%v err=%v", found, err)
	}
	if taken.PlayerID != player || taken.SessionID != session.String() || taken.MID != 5 || taken.Fingerprint != mark.Fingerprint || string(taken.Reply) != string(mark.Reply) || !taken.MarkedAt.Equal(at) {
		t.Fatalf("taken=%+v", taken)
	}
	if _, found, err = store.TakeMark(ctx, player); err != nil || found {
		t.Fatalf("second take found=%v err=%v", found, err)
	}
}

func TestUndeliveredStoreUpsertKeepsOneRow(t *testing.T) {
	pool := nativePool(t)
	store := undeliveredstore.Store{Pool: pool.Raw()}
	player := nativePlayer(t, pool)
	first := undelivered.Mark{PlayerID: player, SessionID: nativeSession(t), MID: 5, Fingerprint: [32]byte{1}, Reply: []byte("first"), MarkedAt: time.Now().UTC()}
	second := undelivered.Mark{PlayerID: player, SessionID: nativeSession(t), MID: 6, Fingerprint: [32]byte{2}, Reply: []byte("second"), MarkedAt: time.Now().UTC()}
	if err := store.Mark(ctx, first); err != nil {
		t.Fatal(err)
	}
	if err := store.Mark(ctx, second); err != nil {
		t.Fatal(err)
	}
	taken, found, err := store.TakeMark(ctx, player)
	if err != nil || !found || taken.MID != 6 || string(taken.Reply) != "second" {
		t.Fatalf("taken=%+v found=%v err=%v", taken, found, err)
	}
}

func TestUndeliveredStoreConcurrentTakeReturnsTheMarkOnce(t *testing.T) {
	pool := nativePool(t)
	store := undeliveredstore.Store{Pool: pool.Raw()}
	player := nativePlayer(t, pool)
	if err := store.Mark(ctx, undelivered.Mark{PlayerID: player, SessionID: nativeSession(t), MID: 5, Fingerprint: [32]byte{1}, Reply: []byte("reply"), MarkedAt: time.Now().UTC()}); err != nil {
		t.Fatal(err)
	}
	var wait sync.WaitGroup
	var mu sync.Mutex
	taken := 0
	for range 2 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			_, found, err := store.TakeMark(ctx, player)
			if err != nil {
				t.Errorf("take: %v", err)
				return
			}
			if found {
				mu.Lock()
				taken++
				mu.Unlock()
			}
		}()
	}
	wait.Wait()
	if taken != 1 {
		t.Fatalf("taken=%d", taken)
	}
}
