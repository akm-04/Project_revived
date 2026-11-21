//go:build postgres

package socialinboxstore_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// K3: a notice written while the workspace clock was forward keeps its own
// notice_time when the user dismisses it after a backward step; the write
// clamps dismissed_at instead of violating the owner invariant.
func TestDismissKeepsTheStoredNoticeTimeWhenTheClockIsBehind(t *testing.T) {
	dsn := os.Getenv("GXB_I7B6A_DSN")
	if dsn == "" {
		t.Fatal("GXB_I7B6A_DSN required for a migrated test database")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)

	const server, player = 611, 61125001
	account := newUUID(t)
	for _, statement := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at)
VALUES($1,'socialinbox-dismiss-native',false,false,false,$2,$2,$3) ON CONFLICT(logical_server_id) DO NOTHING`, []any{server, player, time.Now().UTC()}},
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',$3) ON CONFLICT(account_id) DO NOTHING`, []any{account.String(), account.String(), time.Now().UTC()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,$3,$4,'socialinbox-dismiss-native') ON CONFLICT(player_id) DO NOTHING`, []any{player, account.String(), server, time.Now().UTC()}},
		{`INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at) VALUES($1,1,$2,$2) ON CONFLICT(player_id) DO NOTHING`, []any{player, time.Now().UTC()}},
	} {
		if _, err := transaction.Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatal(err)
		}
	}

	base := time.Date(2026, 11, 21, 10, 0, 0, 0, time.UTC)
	noticeTime := base.Add(8 * time.Hour)
	decisionTime := base.Add(time.Hour)
	source := socialinbox.SourceKey{Kind: socialinbox.RoomInviteSourceKind, Key: "6:1:0:0:0"}
	var noticeID int64
	if err := transaction.QueryRow(ctx, `INSERT INTO social_notices(recipient_player_id,notice_type,source_kind,source_key,active,notice_time,created_at,updated_at) VALUES($1,$2,$3,$4,true,$5,$6,$5) RETURNING notice_id`, player, socialinbox.RoomInviteIllusionNoticeType, source.Kind, source.Key, noticeTime, base).Scan(&noticeID); err != nil {
		t.Fatal(err)
	}
	store := socialinboxstore.Store{}
	notice, found, err := store.LockNoticeTx(ctx, transaction, identity.PlayerID(player), socialinbox.NoticeID(noticeID))
	if err != nil || !found {
		t.Fatalf("LockNoticeTx found=%v err=%v", found, err)
	}
	if err := store.DismissNoticeTx(ctx, transaction, notice, decisionTime); err != nil {
		t.Fatalf("dismiss after a backward clock step failed: %v", err)
	}
	dismissed, found, err := store.ReadNoticeSourceTx(ctx, transaction, identity.PlayerID(player), source)
	if err != nil || !found {
		t.Fatalf("ReadNoticeSourceTx found=%v err=%v", found, err)
	}
	if dismissed.Active || dismissed.DismissedAt == nil || dismissed.DismissedAt.Before(dismissed.NoticeTime) {
		t.Fatalf("dismissed notice = %+v", dismissed)
	}
}
