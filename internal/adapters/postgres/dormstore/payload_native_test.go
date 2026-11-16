//go:build postgres

package dormstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func storedPayload[T any](t *testing.T, p *pg.Pool, table, column, where string, arg any, out *T) []byte {
	t.Helper()
	var raw []byte
	var version int16
	if err := p.QueryRow(context.Background(), `SELECT `+column+`::text,payload_version FROM `+table+` WHERE `+where, arg).Scan(&raw, &version); err != nil {
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

func seedR82Players(t *testing.T, pool *pg.Pool, pid identity.PlayerID) string {
	t.Helper()
	ctx := context.Background()
	accountUID := "r8-2b-dorm-native-" + strconv.FormatInt(int64(pid), 10)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES(gen_random_uuid(),$1,'ACTIVE',clock_timestamp()) ON CONFLICT (account_uid) DO NOTHING`, accountUID); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) SELECT $1,account_id,1,clock_timestamp(),'r8-2b-native' FROM accounts WHERE account_uid=$2 ON CONFLICT (player_id) DO NOTHING`, int64(pid), accountUID); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cleanup := context.Background()
		for _, query := range []string{`DELETE FROM player_dorm_admissions WHERE player_id=$1`, `DELETE FROM player_dorm_heroes WHERE player_id=$1`, `DELETE FROM player_dorm_rooms WHERE player_id=$1`, `DELETE FROM player_dorm_roots WHERE player_id=$1`} {
			pool.Raw().Exec(cleanup, query, int64(pid))
		}
		pool.Raw().Exec(cleanup, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, accountUID)
	})
	return accountUID
}

func TestPayloadVersionRoundTripDormStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-dormstore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	store := dormstore.Store{Queryer: p}
	pid := identity.PlayerID(112011)
	accountUID := seedR82Players(t, p, pid)
	now := time.Now().UTC().Truncate(time.Second)
	var revision string
	if err = p.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY revision_id LIMIT 1`).Scan(&revision); err != nil {
		t.Fatal(err)
	}

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
	var loungeLayout map[string]string
	storedPayload(t, p, "player_dorm_rooms", "furniture_record", "player_id=$1 AND house_id=1", int64(pid), &loungeLayout)
	samePayload(t, map[string]string{}, loungeLayout)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	room, err := store.ReadRoomTx(ctx, tr, pid, 1)
	if err != nil {
		t.Fatal(err)
	}
	room.Layout = map[string]string{"10#1#1#1": "1"}
	room.ExpansionLevel = 1
	room.Pending = &dorm.Expansion{Occurrence: "pending", ContentRevision: revision, NextLevel: 2, DurationSeconds: 3600, StartedAt: now}
	room.StateVersion = 2
	room.UpdatedAt = now
	if err = store.SaveRoomTx(ctx, tr, room, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedLayout map[string]string
	storedPayload(t, p, "player_dorm_rooms", "furniture_record", "player_id=$1 AND house_id=1", int64(pid), &savedLayout)
	samePayload(t, room.Layout, savedLayout)
	var savedPending dorm.Expansion
	storedPayload(t, p, "player_dorm_rooms", "pending_expansion", "player_id=$1 AND house_id=1", int64(pid), &savedPending)
	samePayload(t, *room.Pending, savedPending)

	inserted := dorm.Room{Player: pid, ID: 2, TableID: 1000002, MainType: 2, CreationRevision: revision, Floor: 1, Position: 1, Comfort: 0, ExpansionLevel: 1, StateVersion: 1, Layout: map[string]string{"20#1#1#1": "1"}, Pending: &dorm.Expansion{Occurrence: "fresh", ContentRevision: revision, NextLevel: 2, DurationSeconds: 600, StartedAt: now}, CreatedAt: now, UpdatedAt: now}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InsertRoomTx(ctx, tr, inserted); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var insertedLayout map[string]string
	storedPayload(t, p, "player_dorm_rooms", "furniture_record", "player_id=$1 AND house_id=2", int64(pid), &insertedLayout)
	samePayload(t, inserted.Layout, insertedLayout)
	var insertedPending dorm.Expansion
	storedPayload(t, p, "player_dorm_rooms", "pending_expansion", "player_id=$1 AND house_id=2", int64(pid), &insertedPending)
	samePayload(t, *inserted.Pending, insertedPending)

	ref := character.HeroRef{PlayerID: pid, PartnerID: 1}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InitFreshHeroTx(ctx, tr, ref, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var freshEquipment []int64
	storedPayload(t, p, "player_dorm_heroes", "equipment", "player_id=$1 AND partner_id=1", int64(pid), &freshEquipment)
	samePayload(t, [5]int64{}, freshEquipment)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	facts, err := store.ReadHeroTx(ctx, tr, ref)
	if err != nil {
		t.Fatal(err)
	}
	facts.Equipment[1] = 2
	facts.StateVersion = 2
	facts.UpdatedAt = now
	if err = store.SaveHeroTx(ctx, tr, facts, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedEquipment []int64
	storedPayload(t, p, "player_dorm_heroes", "equipment", "player_id=$1 AND partner_id=1", int64(pid), &savedEquipment)
	samePayload(t, facts.Equipment, savedEquipment)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.EnsureHeroTx(ctx, tr, character.HeroRef{PlayerID: pid, PartnerID: 2}, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var ensuredEquipment []int64
	storedPayload(t, p, "player_dorm_heroes", "equipment", "player_id=$1 AND partner_id=2", int64(pid), &ensuredEquipment)
	samePayload(t, [5]int64{}, ensuredEquipment)

	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision}, policy.Ref{Name: "dorm", Version: app.LifecyclePolicy})
	if err != nil {
		t.Fatal(err)
	}
	operationID, _ := ids.NewUUID()
	admission := app.Admission{
		Operation:       operation.Context{ID: operationID, StartedAt: now, Policies: policies},
		DecisionAt:      now,
		Actor:           app.DurableActor{Account: operationID, Session: operationID, Context: operationID, AccountUID: accountUID, Server: 1, Player: int64(pid), Generation: 1, SessionVersion: 1, ContextVersion: 1},
		Command:         app.Command{Family: app.Save, HouseID: 1, Furniture: map[string]string{"10#1#1#1": "1"}},
		ContentRevision: revision,
		State:           "PENDING",
	}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SaveAdmissionTx(ctx, tr, admission); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var decoded app.Admission
	storedPayload(t, p, "player_dorm_admissions", "operation_context", "player_id=$1", int64(pid), &decoded)
	samePayload(t, admission, decoded)
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, exists, err := store.LockAdmissionTx(ctx, tr, pid, app.Save)
	if err != nil || !exists || locked.Operation.ID != operationID {
		t.Fatalf("LockAdmissionTx exists=%v id=%s err=%v", exists, locked.Operation.ID, err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
}
