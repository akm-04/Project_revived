//go:build postgres

package undeliveredstore_test

import (
	"context"
	"errors"
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

// takeMark claims first, then stores a mark under that claim.
func takeMark(t *testing.T, store undeliveredstore.Store, player int64, mark undelivered.Mark) undelivered.Mark {
	t.Helper()
	take, err := store.TakeMark(ctx, player)
	if err != nil {
		t.Fatal(err)
	}
	if take.HasMark {
		t.Fatalf("unexpected mark before a store: %+v", take)
	}
	mark.PlayerID, mark.Claim = player, take.Claim
	return mark
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
	mark := takeMark(t, store, player, undelivered.Mark{SessionID: session.String(), MID: 5, Fingerprint: [32]byte{9, 8, 7}, Reply: []byte(`{"ok":1}` + "\n"), MarkedAt: at})
	if err := store.Mark(ctx, mark); err != nil {
		t.Fatal(err)
	}
	taken, err := store.TakeMark(ctx, player)
	if err != nil || !taken.HasMark {
		t.Fatalf("found=%v err=%v", taken.HasMark, err)
	}
	if taken.Claim <= mark.Claim {
		t.Fatalf("claim did not advance: %d then %d", mark.Claim, taken.Claim)
	}
	if taken.Mark.PlayerID != player || taken.Mark.SessionID != session.String() || taken.Mark.MID != 5 || taken.Mark.Fingerprint != mark.Fingerprint || string(taken.Mark.Reply) != string(mark.Reply) || !taken.Mark.MarkedAt.Equal(at) {
		t.Fatalf("taken=%+v", taken)
	}
	empty, err := store.TakeMark(ctx, player)
	if err != nil || empty.HasMark || empty.Claim <= taken.Claim {
		t.Fatalf("second take=%+v err=%v", empty, err)
	}
}

func TestUndeliveredStoreUpsertKeepsOneRow(t *testing.T) {
	pool := nativePool(t)
	store := undeliveredstore.Store{Pool: pool.Raw()}
	player := nativePlayer(t, pool)
	first := takeMark(t, store, player, undelivered.Mark{SessionID: nativeSession(t), MID: 5, Fingerprint: [32]byte{1}, Reply: []byte("first"), MarkedAt: time.Now().UTC()})
	second := first
	second.MID, second.Fingerprint, second.Reply = 6, [32]byte{2}, []byte("second")
	if err := store.Mark(ctx, first); err != nil {
		t.Fatal(err)
	}
	if err := store.Mark(ctx, second); err != nil {
		t.Fatal(err)
	}
	taken, err := store.TakeMark(ctx, player)
	if err != nil || !taken.HasMark || taken.Mark.MID != 6 || string(taken.Mark.Reply) != "second" {
		t.Fatalf("taken=%+v err=%v", taken, err)
	}
}

func TestUndeliveredStoreConcurrentTakeReturnsTheMarkOnce(t *testing.T) {
	pool := nativePool(t)
	store := undeliveredstore.Store{Pool: pool.Raw()}
	player := nativePlayer(t, pool)
	mark := takeMark(t, store, player, undelivered.Mark{SessionID: nativeSession(t), MID: 5, Fingerprint: [32]byte{1}, Reply: []byte("reply"), MarkedAt: time.Now().UTC()})
	if err := store.Mark(ctx, mark); err != nil {
		t.Fatal(err)
	}
	var wait sync.WaitGroup
	var mu sync.Mutex
	taken := 0
	for range 2 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			take, err := store.TakeMark(ctx, player)
			if err != nil {
				t.Errorf("take: %v", err)
				return
			}
			if take.HasMark {
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

func TestUndeliveredStoreLateMarkIsSuperseded(t *testing.T) {
	pool := nativePool(t)
	store := undeliveredstore.Store{Pool: pool.Raw()}
	player := nativePlayer(t, pool)
	first, err := store.TakeMark(ctx, player)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.TakeMark(ctx, player); err != nil {
		t.Fatal(err)
	}
	late := undelivered.Mark{PlayerID: player, Claim: first.Claim, SessionID: nativeSession(t), MID: 5, Fingerprint: [32]byte{1}, Reply: []byte("late"), MarkedAt: time.Now().UTC()}
	if err := store.Mark(ctx, late); !errors.Is(err, undelivered.ErrSuperseded) {
		t.Fatalf("late mark err=%v want superseded", err)
	}
	taken, err := store.TakeMark(ctx, player)
	if err != nil || taken.HasMark {
		t.Fatalf("superseded mark was restored: %+v err=%v", taken, err)
	}
}
