//go:build postgres

package i4store_test

import (
	"context"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// allocateActivityPlayerID takes the next id from the logical server counter so
// the fixture never inserts an id an earlier package already used.
func allocateActivityPlayerID(t *testing.T, pool *postgres.Pool, logicalServerID int32) identity.PlayerID {
	t.Helper()
	var playerID int64
	if err := pool.Raw().QueryRow(context.Background(), `UPDATE logical_servers SET next_player_id=next_player_id+1,state_version=state_version+1 WHERE logical_server_id=$1 AND next_player_id+1<=max_player_id RETURNING next_player_id-1`, logicalServerID).Scan(&playerID); err != nil {
		t.Fatal(err)
	}
	return identity.PlayerID(playerID)
}

func TestCanonicalPlayerActivityWithoutRealtimeAndAcrossCharacters(t *testing.T) {
	databaseURL := os.Getenv("GXB_PLAYER_ACTIVITY_DSN")
	if databaseURL == "" {
		t.Skip("own migrated PostgreSQL database required")
	}
	ctx := context.Background()
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	var indexed bool
	if err := pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='gameplay_contexts' AND indexname='gameplay_contexts_player_id_idx')`).Scan(&indexed); err != nil || !indexed {
		t.Fatal("canonical player activity index missing", indexed, err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	firstContext, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	secondContext, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	firstOperation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	secondOperation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	_, err = transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, account.String(), account.String(), at.Add(-12*24*time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	firstPlayerID := allocateActivityPlayerID(t, pool, 1)
	thirdPlayerID := allocateActivityPlayerID(t, pool, 3)
	_, err = transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,$3,'activity-native'),($4,$2,3,$3,'activity-native')`, int64(firstPlayerID), account.String(), at.Add(-12*24*time.Hour), int64(thirdPlayerID))
	if err != nil {
		t.Fatal(err)
	}
	owner := i4store.PlayerLoginActivity{}
	if _, known, err := owner.ReadPlayerActivityTx(ctx, transaction, firstPlayerID, at); err != nil || known {
		t.Fatal("missing marker fabricated activity", known, err)
	}
	actor := identity.ActorContext{PlayerID: firstPlayerID, LogicalServerID: 1}
	initial := at.Add(-9 * 24 * time.Hour)
	if err := owner.ReconcileCharacterLogin(ctx, transaction, actor, operation.Context{ID: firstOperation, StartedAt: initial}, initial); err != nil {
		t.Fatal(err)
	}
	_, err = transaction.Exec(ctx, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1,$2,'activity-native',$3,$4)`, session.String(), account.String(), at.Add(-12*24*time.Hour), at)
	if err != nil {
		t.Fatal(err)
	}
	_, err = transaction.Exec(ctx, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,ended_at,end_reason) VALUES($1,$2,$3,1,$8,1,$4,$5,'SWITCHED'),($6,$2,$3,3,$9,2,$7,NULL,NULL)`, firstContext.String(), session.String(), account.String(), initial, at.Add(-8*24*time.Hour), secondContext.String(), at.Add(-time.Hour), int64(firstPlayerID), int64(thirdPlayerID))
	if err != nil {
		t.Fatal(err)
	}
	old, known, err := owner.ReadPlayerActivityTx(ctx, transaction, firstPlayerID, at)
	if err != nil || !known || !old.LatestActivityAt.Equal(at.Add(-8*24*time.Hour)) {
		t.Fatal("other character session activity leaked", old, known, err)
	}
	otherOperation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	otherActor := identity.ActorContext{PlayerID: thirdPlayerID, LogicalServerID: 3}
	if err := owner.ReconcileCharacterLogin(ctx, transaction, otherActor, operation.Context{ID: otherOperation, StartedAt: at.Add(-time.Hour)}, at.Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}
	live, known, err := owner.ReadPlayerActivityTx(ctx, transaction, thirdPlayerID, at)
	if err != nil || !known || !live.LatestActivityAt.Equal(at) || !live.LastLoginAt.Equal(at.Add(-time.Hour)) {
		t.Fatal("live character activity not scoped correctly", live, known, err)
	}

	expiredAt := at.Add(-time.Hour)
	_, err = transaction.Exec(ctx, `INSERT INTO player_social_presence(player_id,last_seen_at,created_at,updated_at) VALUES($1,$2,$2,$2),($3,$2,$2,$2)`, int64(firstPlayerID), initial, int64(thirdPlayerID))
	if err != nil {
		t.Fatal(err)
	}
	_, err = transaction.Exec(ctx, `INSERT INTO realtime_presence_leases(gameplay_context_id,physical_role,player_id,realtime_instance_id,connection_generation,connected_at,last_renewed_at,lease_expires_at,realtime_owner_fence) VALUES($1,'WORLD',$8,$3,1,$4,$4,$5,1),($1,'SERVICE',$8,$3,1,$4,$4,$6,1),($2,'WORLD',$9,$3,1,$4,$4,$7,1)`, firstContext.String(), secondContext.String(), firstOperation.String(), initial, expiredAt, at.Add(time.Hour), at.Add(-time.Minute), int64(firstPlayerID), int64(thirdPlayerID))
	if err != nil {
		t.Fatal(err)
	}
	expiry, err := (presencestore.Store{}).LatestExpiredLeaseAt(ctx, transaction, firstPlayerID, at)
	if err != nil || expiry == nil || !expiry.Equal(expiredAt) {
		t.Fatal("expired lease escaped target/time scope", expiry, err)
	}
	var leaseCount int
	if err := transaction.QueryRow(ctx, `SELECT count(*) FROM realtime_presence_leases WHERE player_id=$1`, int64(firstPlayerID)).Scan(&leaseCount); err != nil || leaseCount != 2 {
		t.Fatal("observation mutated leases", leaseCount, err)
	}
	empty, err := (presencestore.Store{}).LatestExpiredLeaseAt(ctx, transaction, firstPlayerID, initial)
	if err != nil || empty != nil {
		t.Fatal("invented expired lease", empty, err)
	}
	if err := owner.ReconcileCharacterLogin(ctx, transaction, actor, operation.Context{ID: secondOperation, StartedAt: at}, at); err != nil {
		t.Fatal(err)
	}
	recent, known, err := owner.ReadPlayerActivityTx(ctx, transaction, firstPlayerID, at)
	if err != nil || !known || !recent.LastLoginAt.Equal(at) || !recent.LatestActivityAt.Equal(at) || recent.StateVersion != 2 {
		t.Fatal("recent login without TCP not recorded", recent, known, err)
	}
	if err := owner.ReconcileCharacterLogin(ctx, transaction, actor, operation.Context{ID: firstOperation, StartedAt: initial}, initial); err != nil {
		t.Fatal("older observation failed login", err)
	}
	repeated, known, err := owner.ReadPlayerActivityTx(ctx, transaction, firstPlayerID, at)
	if err != nil || !known || repeated != recent {
		t.Fatal("older observation regressed state", repeated, recent, err)
	}
	if err := owner.ReconcileCharacterLogin(ctx, transaction, actor, operation.Context{ID: secondOperation, StartedAt: at}, at); err != nil {
		t.Fatal(err)
	}
	repeated, known, err = owner.ReadPlayerActivityTx(ctx, transaction, firstPlayerID, at)
	if err != nil || !known || repeated != recent {
		t.Fatal("equal observation changed state", repeated, recent, err)
	}
	if _, err := transaction.Exec(ctx, `UPDATE player_login_observations SET state_version=9223372036854775807 WHERE player_id=$1`, int64(firstPlayerID)); err != nil {
		t.Fatal(err)
	}
	nextAt := at.Add(time.Minute)
	if err := owner.ReconcileCharacterLogin(ctx, transaction, actor, operation.Context{ID: secondOperation, StartedAt: nextAt}, nextAt); err == nil {
		t.Fatal("exhausted activity version accepted new observation")
	}
	exhausted, known, err := owner.ReadPlayerActivityTx(ctx, transaction, firstPlayerID, nextAt)
	if err != nil || !known || exhausted.StateVersion != 9223372036854775807 || !exhausted.LastLoginAt.Equal(at) {
		t.Fatal("version exhaustion mutated activity", exhausted, known, err)
	}
	if _, _, err := owner.ReadPlayerActivityTx(ctx, transaction, firstPlayerID, at.Add(-time.Second)); err == nil {
		t.Fatal("future activity accepted")
	}
	if err := transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if _, known, err := owner.ReadPlayerActivityTx(ctx, pool, firstPlayerID, at); err != nil || known {
		t.Fatal("rollback leaked observation", known, err)
	}
}
