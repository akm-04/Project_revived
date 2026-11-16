//go:build postgres

package mentorstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	"gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
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
		pool.Raw().Exec(cleanup, `DELETE FROM mentor_exam_receipts WHERE student_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, accountUID)
	})
	return accountUID
}

func TestPayloadVersionRoundTripMentorStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-mentorstore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	store := mentorstore.Store{}
	pid := identity.PlayerID(113021)
	seedR82Player(t, p, pid, "mentor-native")
	relation, err := ids.ParseUUID("12345678-1234-4234-8234-123456789012")
	if err != nil {
		t.Fatal(err)
	}
	receipt := mentor.ExamReceipt{StudentID: pid, MissionID: 17, RelationID: relation, WonAt: time.Now().UTC().Truncate(time.Second), Items: []mentor.ExamItem{{ItemID: 1001, Quantity: 2}, {ItemID: 2002, Quantity: 5}}, Version: 1}

	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InsertExamReceiptTx(ctx, tr, receipt); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var items []mentor.ExamItem
	storedPayload(t, p, "mentor_exam_receipts", "items", "student_id=$1 AND mission_id=$2", &items, int64(pid), int64(17))
	samePayload(t, receipt.Items, items)
	read, ok, err := store.ReadExamReceiptTx(ctx, p, pid, 17)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, ok, err := store.LockExamReceiptTx(ctx, tr, pid, 17)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	samePayload(t, receipt.Items, read.Items)
	samePayload(t, receipt.Items, locked.Items)
}
