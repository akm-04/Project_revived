//go:build postgres

package retention_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/clientlogstore"
	"gxb.local/backend/v2/internal/adapters/postgres/illusionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func openPool(t *testing.T) (*pg.Pool, context.Context) {
	t.Helper()
	dsn := os.Getenv("GXB_R8_4C_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_4C_DSN with a migrated and content-deployed disposable database is required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	t.Cleanup(cancel)
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-4-purge"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool, ctx
}

func token(t *testing.T) string {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id.String()
}

func rowPresent(t *testing.T, ctx context.Context, pool *pg.Pool, statement string, argument any) bool {
	t.Helper()
	var count int
	if err := pool.Raw().QueryRow(ctx, statement, argument).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count == 1
}

func seedLogicalServer(t *testing.T, ctx context.Context, pool *pg.Pool, server int64) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES($1,'R8-4 purge native',clock_timestamp(),true,true,true,$2,$3,1,clock_timestamp())`, server, server*100000+25001, (server+1)*100000-1); err != nil {
		t.Fatal(err)
	}
}

func TestClientLogsPurgeCapsClassWindows(t *testing.T) {
	pool, ctx := openPool(t)
	now := time.Now().UTC()
	older := now.Add(-5 * 24 * time.Hour)
	younger := now.Add(-24 * time.Hour)
	expires := func(received time.Time, class string) time.Time {
		window := 30 * 24 * time.Hour
		if class == "ROUTINE" {
			window = 7 * 24 * time.Hour
		}
		return received.Add(window)
	}
	insertUpload := func(class string, received time.Time) ids.UUID {
		id, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		if _, err = pool.Raw().Exec(ctx, `INSERT INTO client_log_uploads(upload_id,received_at,kind,account_uid,player_id,session_ref,attribution,status,retention_class,body_bytes,row_count,expires_at)
VALUES($1,$2,0,NULL,NULL,NULL,'UNATTRIBUTED_MISSING','PARSED',$3,1,1,$4)`, id.String(), received, class, expires(received, class)); err != nil {
			t.Fatal(err)
		}
		return id
	}
	insertRow := func(class string, received time.Time) ids.UUID {
		upload, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		if _, err = pool.Raw().Exec(ctx, `INSERT INTO client_log_rows(upload_id,ordinal,received_at,account_uid,retention_class,is_crash,expires_at)
VALUES($1,0,$2,NULL,$3,false,$4)`, upload.String(), received, class, expires(received, class)); err != nil {
			t.Fatal(err)
		}
		return upload
	}
	oldRoutineUpload := insertUpload("ROUTINE", older)
	youngRoutineUpload := insertUpload("ROUTINE", younger)
	oldErrorRow := insertRow("ERROR", older)
	youngErrorRow := insertRow("ERROR", younger)
	capability := strings.ReplaceAll(token(t), "-", "") + strings.ReplaceAll(token(t), "-", "")
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO client_log_capabilities(capability_digest,account_uid,player_id,logical_server_id,session_ref,issued_at,expires_at)
VALUES(decode($1,'hex'),'r8-4-capability',1,1,repeat('a',32),$2,$3)`, capability, now.Add(-2*time.Hour), now.Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}

	if _, err := (clientlogstore.Store{Pool: pool.Raw()}).PurgeExpired(ctx, now, 3, 5000); err != nil {
		t.Fatal(err)
	}
	for name, id := range map[string]ids.UUID{"old routine upload": oldRoutineUpload, "old error row": oldErrorRow} {
		var count int
		table := "client_log_uploads"
		if name == "old error row" {
			table = "client_log_rows"
		}
		query := `SELECT count(*) FROM ` + table + ` WHERE upload_id=$1`
		if err := pool.Raw().QueryRow(ctx, query, id.String()).Scan(&count); err != nil {
			t.Fatal(err)
		}
		if count != 0 {
			t.Fatalf("%s survived the capped purge", name)
		}
	}
	for name, id := range map[string]ids.UUID{"young routine upload": youngRoutineUpload, "young error row": youngErrorRow} {
		table := "client_log_uploads"
		if name == "young error row" {
			table = "client_log_rows"
		}
		var count int
		query := `SELECT count(*) FROM ` + table + ` WHERE upload_id=$1`
		if err := pool.Raw().QueryRow(ctx, query, id.String()).Scan(&count); err != nil {
			t.Fatal(err)
		}
		if count != 1 {
			t.Fatalf("%s was purged inside the capped window", name)
		}
	}
	var capabilityCount int
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM client_log_capabilities WHERE account_uid='r8-4-capability'`).Scan(&capabilityCount); err != nil {
		t.Fatal(err)
	}
	if capabilityCount != 0 {
		t.Fatal("expired capability survived")
	}
}

func TestRequestJournalPurgeCapsRoutineWindow(t *testing.T) {
	pool, ctx := openPool(t)
	now := time.Now().UTC()
	older := now.Add(-5 * 24 * time.Hour)
	younger := now.Add(-24 * time.Hour)
	insertJournal := func(uid, class string, received time.Time) time.Time {
		t.Helper()
		expired := received.Add(7 * 24 * time.Hour)
		if class != "ROUTINE" {
			expired = received.Add(30 * 24 * time.Hour)
		}
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO request_journal(received_at,account_uid,mid,outcome,error_code,http_status,latency_microseconds,request_bytes,response_bytes,retention_class,expires_at)
VALUES($1,$2,1,'OK',0,200,1,1,1,$3,$4)`, received, uid, class, expired); err != nil {
			t.Fatal(err)
		}
		return received
	}
	oldRoutine := "r8-4-journal-old-" + token(t)
	youngRoutine := "r8-4-journal-young-" + token(t)
	oldError := "r8-4-journal-error-" + token(t)
	youngError := "r8-4-journal-error-young-" + token(t)
	insertJournal(oldRoutine, "ROUTINE", older)
	insertJournal(youngRoutine, "ROUTINE", younger)
	insertJournal(oldError, "ERROR", older)
	insertJournal(youngError, "ERROR", younger)

	if _, err := (clientlogstore.Store{Pool: pool.Raw()}).PurgeExpired(ctx, now, 3, 5000); err != nil {
		t.Fatal(err)
	}
	for name, uid := range map[string]string{"old routine": oldRoutine, "old error": oldError} {
		if rowPresent(t, ctx, pool, `SELECT count(*) FROM request_journal WHERE account_uid=$1`, uid) {
			t.Fatalf("%s journal row survived the capped purge", name)
		}
	}
	for name, uid := range map[string]string{"young routine": youngRoutine, "young error": youngError} {
		if !rowPresent(t, ctx, pool, `SELECT count(*) FROM request_journal WHERE account_uid=$1`, uid) {
			t.Fatalf("%s journal row was purged inside the capped window", name)
		}
	}
}

func TestIllusionReportsPurgeCapsWindow(t *testing.T) {
	pool, ctx := openPool(t)
	server := int64(884020 + time.Now().UnixNano()%1000)
	seedLogicalServer(t, ctx, pool, server)
	now := time.Now().UTC()
	insertReport := func(name string, createdAt time.Time) string {
		t.Helper()
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO illusion_reports(report_id,logical_server_id,open_day,campaign_id,content,created_at,expires_at)
VALUES($1,$2,0,100001,'{}'::jsonb,$3::timestamptz,($3::timestamptz + interval '7 days'))`, name, server, createdAt); err != nil {
			t.Fatal(err)
		}
		return name
	}
	old := insertReport("r8-4-illusion-old-"+token(t), now.Add(-5*24*time.Hour))
	young := insertReport("r8-4-illusion-young-"+token(t), now.Add(-24*time.Hour))

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	if _, err = (illusionstore.Store{}).PurgeExpiredReportsTx(ctx, transaction, now, 7, 100); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if !rowPresent(t, ctx, pool, `SELECT count(*) FROM illusion_reports WHERE report_id=$1`, old) {
		t.Fatal("owner window alone purged a five-day-old illusion report")
	}

	transaction, err = pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	if _, err = (illusionstore.Store{}).PurgeExpiredReportsTx(ctx, transaction, now, 3, 100); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if rowPresent(t, ctx, pool, `SELECT count(*) FROM illusion_reports WHERE report_id=$1`, old) {
		t.Fatal("five-day-old illusion report survived the three-day cap")
	}
	if !rowPresent(t, ctx, pool, `SELECT count(*) FROM illusion_reports WHERE report_id=$1`, young) {
		t.Fatal("one-day-old illusion report was purged inside the cap")
	}
}

func TestAdventureReportsPurgeCapsWindow(t *testing.T) {
	pool, ctx := openPool(t)
	server := int64(886020 + time.Now().UnixNano()%1000)
	seedLogicalServer(t, ctx, pool, server)
	now := time.Now().UTC()
	insertReport := func(createdAt time.Time) string {
		t.Helper()
		name := "r8-4-adventure-" + token(t)
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO adventure_reports(report_id,logical_server_id,room_id,member_ids,content,created_at,expires_at)
VALUES($1,$2,1,'{1}'::bigint[],'{}',$3::timestamptz,($3::timestamptz + interval '7 days'))`, name, server, createdAt); err != nil {
			t.Fatal(err)
		}
		return name
	}
	young := insertReport(now.Add(-2 * 24 * time.Hour))
	old := insertReport(now.Add(-8 * 24 * time.Hour))

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	if _, err = (adventurestore.Store{}).PurgeExpiredReportsTx(ctx, transaction, now, 15, 100); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if !rowPresent(t, ctx, pool, `SELECT count(*) FROM adventure_reports WHERE report_id=$1`, young) {
		t.Fatal("two-day-old adventure report was purged inside the fifteen-day cap")
	}
	if rowPresent(t, ctx, pool, `SELECT count(*) FROM adventure_reports WHERE report_id=$1`, old) {
		t.Fatal("eight-day-old adventure report survived past the owner window")
	}

	transaction, err = pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	if _, err = (adventurestore.Store{}).PurgeExpiredReportsTx(ctx, transaction, now, 1, 100); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if rowPresent(t, ctx, pool, `SELECT count(*) FROM adventure_reports WHERE report_id=$1`, young) {
		t.Fatal("two-day-old adventure report survived the one-day cap")
	}
}

func TestOccultReportsPurgeCapsWindow(t *testing.T) {
	pool, ctx := openPool(t)
	server := int64(885020 + time.Now().UnixNano()%1000)
	seedLogicalServer(t, ctx, pool, server)
	room := time.Now().UnixNano()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO occult_runs(room_id,logical_server_id,chapter_id,campaign_type,started_at)
VALUES($1,$2,1,1,clock_timestamp())`, room, server); err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC()
	insertReport := func(createdAt time.Time) string {
		t.Helper()
		name := "r8-4-occult-" + token(t)
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO occult_reports(report_id,logical_server_id,room_id,member_ids,content,created_at,expires_at)
VALUES($1,$2,$3,'{1}'::bigint[],'{}'::jsonb,$4::timestamptz,($4::timestamptz + interval '7 days'))`, name, server, room, createdAt); err != nil {
			t.Fatal(err)
		}
		return name
	}
	old := insertReport(now.Add(-5 * 24 * time.Hour))
	young := insertReport(now.Add(-24 * time.Hour))

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	if _, err = (occultstore.Store{}).PurgeExpiredReportsTx(ctx, transaction, now, 7, 100); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if !rowPresent(t, ctx, pool, `SELECT count(*) FROM occult_reports WHERE report_id=$1`, old) {
		t.Fatal("owner window alone purged a five-day-old occult report")
	}

	transaction, err = pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	if _, err = (occultstore.Store{}).PurgeExpiredReportsTx(ctx, transaction, now, 3, 100); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if rowPresent(t, ctx, pool, `SELECT count(*) FROM occult_reports WHERE report_id=$1`, old) {
		t.Fatal("five-day-old occult report survived the three-day cap")
	}
	if !rowPresent(t, ctx, pool, `SELECT count(*) FROM occult_reports WHERE report_id=$1`, young) {
		t.Fatal("one-day-old occult report was purged inside the cap")
	}
}
