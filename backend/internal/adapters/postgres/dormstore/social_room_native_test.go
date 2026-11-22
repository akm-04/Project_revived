//go:build postgres

package dormstore_test

import (
	"context"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	domain "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestDormSocialRoomMetadataCASAndRollback(t *testing.T) {
	databaseURL := os.Getenv("GXB_DORM_SOCIAL_DSN")
	if databaseURL == "" {
		t.Skip("explicit own migrated PostgreSQL database required")
	}
	ctx := context.Background()
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	// Owned structural fixtures; no content activation or gameplay creation is claimed.
	_, err = transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES(gen_random_uuid(),'dorm-social-room-native','ACTIVE',$1)`, at)
	if err != nil {
		t.Fatal(err)
	}
	_, err = transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) SELECT 125701,account_id,1,$1,'dorm-native' FROM accounts WHERE account_uid='dorm-social-room-native'`, at)
	if err != nil {
		t.Fatal(err)
	}
	_, err = transaction.Exec(ctx, `INSERT INTO player_dorm_roots VALUES(125701,2,1,$1,$1)`, at)
	if err != nil {
		t.Fatal(err)
	}
	_, err = transaction.Exec(ctx, `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,created_at,updated_at) VALUES(125701,1,1000001,1,repeat('a',64),1,1,0,0,1,'{}',$1,$1)`, at)
	if err != nil {
		t.Fatal(err)
	}
	owner := dormstore.Store{}
	if _, err = owner.LockRootTx(ctx, transaction, 125701); err != nil {
		t.Fatal(err)
	}
	target := domain.RoomTarget{Server: 1, Owner: 125701, HouseID: 1}
	if _, found, err := owner.ReadSocialRoomTx(ctx, transaction, target); err != nil || found {
		t.Fatal("absence must remain explicit", found, err)
	}
	state := domain.SocialRoomState{Target: target, Name: "abcdefghijkl", Hidden: true, StateVersion: 1, UpdatedAt: at}
	if err = owner.SaveSocialRoomTx(ctx, transaction, state, 0); err != nil {
		t.Fatal(err)
	}
	read, found, err := owner.ReadSocialRoomTx(ctx, transaction, target)
	if err != nil || !found || read != state {
		t.Fatal(read, found, err)
	}
	if err = owner.SaveSocialRoomTx(ctx, transaction, state, 0); err == nil {
		t.Fatal("stale insert accepted")
	}
	state.Name = "一二三四五六"
	state.Hidden = false
	state.StateVersion = 2
	state.UpdatedAt = at.Add(time.Second)
	if err = owner.SaveSocialRoomTx(ctx, transaction, state, 1); err != nil {
		t.Fatal(err)
	}
	if err = owner.SaveSocialRoomTx(ctx, transaction, state, 1); err == nil {
		t.Fatal("stale CAS accepted")
	}
	backdated := state
	backdated.StateVersion = 3
	backdated.UpdatedAt = at
	if err = owner.SaveSocialRoomTx(ctx, transaction, backdated, 2); err == nil {
		t.Fatal("backdated metadata write accepted")
	}
	for _, name := range []string{"abcdefghijklm", "一二三四五六七"} {
		invalid := state
		invalid.Name = name
		invalid.StateVersion = 3
		invalid.UpdatedAt = state.UpdatedAt.Add(time.Second)
		if err := owner.SaveSocialRoomTx(ctx, transaction, invalid, 2); err == nil {
			t.Fatal("invalid display-width name stored", name)
		}
	}
	read, found, err = owner.ReadSocialRoomTx(ctx, transaction, target)
	if err != nil || !found || read != state {
		t.Fatal(read, found, err)
	}
	if err = transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if _, found, err = owner.ReadSocialRoomTx(ctx, pool, target); err != nil || found {
		t.Fatal("rollback leaked metadata", found, err)
	}
}
