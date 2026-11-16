//go:build postgres

package profilefeedbackstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripProfileFeedbackStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH18_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH18_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	for _, statement := range []string{
		`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(31,'payload-version-comments',NULL,false,false,false,3199999,3199999,1,now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777731','payload-version-comments','ACTIVE',now()),('77777777-7777-4777-8777-777777777732','payload-version-comments-target','ACTIVE',now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(3100001,'77777777-7777-4777-8777-777777777731',31,now(),'payload-version-comments'),(3100002,'77777777-7777-4777-8777-777777777732',31,now(),'payload-version-comments-target') ON CONFLICT DO NOTHING`,
	} {
		if _, err := pool.Raw().Exec(ctx, statement); err != nil {
			t.Fatal(err)
		}
	}
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 11, 16, 5, 20, 0, 111222000, time.UTC)
	policies, err := policy.NewSet(
		policy.Ref{Name: "content", Version: "content-rev-1"},
		policy.Ref{Name: "profile-comment", Version: d.CommentPolicyVersion},
	)
	if err != nil {
		t.Fatal(err)
	}
	command := app.CommentCommand{Kind: "post", Target: identity.PlayerID(3100002), Content: "hello"}
	fingerprint, err := receipt.FingerprintRequest(command)
	if err != nil {
		t.Fatal(err)
	}
	admission := app.CommentAdmission{
		Operation:   operation.Context{ID: operationID, StartedAt: at, Policies: policies},
		Actor:       identity.PlayerID(3100001),
		Target:      command.Target,
		Account:     "payload-version-account",
		Context:     "payload-version-context",
		Server:      identity.LogicalServerID(31),
		Command:     command,
		Fingerprint: fingerprint,
		DecisionAt:  at.Add(time.Second),
		Revision:    "content-rev-1",
		State:       "PENDING",
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	store := profilefeedbackstore.Store{}
	if err := store.InsertAdmissionTx(ctx, transaction, admission); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT admission_payload::text,payload_version FROM player_profile_comment_operations WHERE operation_id=$1::uuid`, operationID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	directory := filepath.Join("testdata", "payloads", commentOperationTable+"."+commentAdmissionColumn)
	if capture := os.Getenv("GXB_R8_2C_BATCH18_CAPTURE"); capture != "" {
		captureProfileFeedbackGolden(t, filepath.Join(capture, "internal/adapters/postgres/profilefeedbackstore", directory), storedText)
		return
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	var decoded app.CommentAdmission
	if err := payload.Decode(commentOperationTable, version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	assertSameProfileFeedbackJSON(t, decoded, admission)
	read, found, err := store.ReadAdmissionTx(ctx, pool, operationID.String(), false)
	if err != nil || !found {
		t.Fatalf("ReadAdmissionTx found=%v err=%v", found, err)
	}
	assertSameProfileFeedbackJSON(t, read, admission)
	pendingTransaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = pendingTransaction.Rollback(ctx) }()
	pending, found, err := store.PendingAdmissionTx(ctx, pendingTransaction, identity.PlayerID(3100001))
	if err != nil || !found {
		t.Fatalf("PendingAdmissionTx found=%v err=%v", found, err)
	}
	assertSameProfileFeedbackJSON(t, pending, admission)
	expected, err := json.Marshal(admission)
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(expected)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored payload=%s want json.Marshal=%s", storedText, expectedText)
	}
}

func assertSameProfileFeedbackJSON(t *testing.T, got, want any) {
	t.Helper()
	gotRaw, err := json.Marshal(got)
	if err != nil {
		t.Fatal(err)
	}
	wantRaw, err := json.Marshal(want)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(gotRaw, wantRaw) {
		t.Fatalf("decoded=%s want=%s", gotRaw, wantRaw)
	}
}

func captureProfileFeedbackGolden(t *testing.T, directory, stored string) {
	t.Helper()
	var decoded app.CommentAdmission
	if err := payload.Decode(commentOperationTable, 0, []byte(stored), &decoded); err != nil {
		t.Fatal(err)
	}
	expected, err := json.MarshalIndent(decoded, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "v0.json"), []byte(stored), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "v0.expected.json"), expected, 0o644); err != nil {
		t.Fatal(err)
	}
}
