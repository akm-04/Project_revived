//go:build postgres

package guildinvitestore_test

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripGuildInviteStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH16_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH16_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	exec := func(statement string, arguments ...any) {
		t.Helper()
		if _, err := pool.Raw().Exec(ctx, statement, arguments...); err != nil {
			t.Fatalf("seed %q: %v", statement, err)
		}
	}
	exec(`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(1,'payload-version-guildinvite',NULL,false,false,false,125002,199999,1,now()) ON CONFLICT DO NOTHING`)
	for index, playerID := range []int64{100001, 100002} {
		accountID := "77777777-7777-4777-8777-77777777200" + string(rune('1'+index))
		exec(`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',now()) ON CONFLICT DO NOTHING`, accountID, "payload-version-guildinvite-"+accountID)
		exec(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,now(),'payload-version-guildinvite') ON CONFLICT DO NOTHING`, playerID, accountID)
	}
	newReceipt := func(ownerKind, ownerKey, operationName, semanticKey string, started time.Time) ids.UUID {
		t.Helper()
		receiptID, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		exec(`INSERT INTO gxb_operation_receipts(receipt_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,recorded_at)
VALUES($1,$2,$3,'guild',$4,'I6C_GUILD',$5,decode(repeat('ab',32),'hex'),'gxb.i6c.guild.probe.v1','{}'::jsonb,$6,$6)`,
			receiptID.String(), ownerKind, ownerKey, operationName, semanticKey, started)
		return receiptID
	}

	revision, coreRevision := strings.Repeat("a", 64), strings.Repeat("b", 64)
	references, err := policy.NewSet(
		policy.Ref{Name: "content", Version: revision},
		policy.Ref{Name: "guild-core", Version: coreRevision},
		policy.Ref{Name: "guild-invite", Version: gi.PolicyID},
	)
	if err != nil {
		t.Fatal(err)
	}
	startedAt := time.Unix(2000, 123456000).UTC()
	decisionAt := time.Unix(2001, 0).UTC()
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	sourceReceiptID := newReceipt("guild", "1000001", "invite", "actorver:1:target:100002:gen:8", startedAt)
	contextID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	issue := gi.Issue{
		Operation: operation.Context{ID: operationID, StartedAt: startedAt, Policies: references},
		Tuple:     gi.Tuple{GuildID: 1000001, Recipient: 100002, Generation: 8},
		Serial:    7, Server: 1, Inviter: 100001, ActorAccountUID: "payload-version-uid",
		DecisionAt: decisionAt, ExpiresAt: decisionAt.Add(time.Hour), GuildName: "公会",
		LastJoinEventID: 5, LastJoinedAt: decisionAt.Add(-time.Hour), SendEventID: 6,
		ContentRevision: revision, GuildCoreRevision: coreRevision, PolicyID: gi.PolicyID,
		Core: gi.CoreReceipt{ID: sourceReceiptID, OwnerKind: "guild", OwnerKey: "1000001", Domain: "guild",
			Operation: "invite", SemanticKey: "actorver:1:target:100002:gen:8", Schema: "gxb.i6c.guild.invite.v1",
			OperationClass: "I6C_GUILD", PolicyVersion: coreRevision, ActorAccountUID: "payload-version-uid",
			ContextID: contextID, OperationStartedAt: startedAt, OperationPolicyRefs: references},
	}
	if err := issue.Validate(); err != nil {
		t.Fatalf("issue fixture invalid: %v", err)
	}
	markerOperationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	markerReceiptID := newReceipt("guild", "1000001", "accept_application", "payload-version-marker", startedAt)
	markerContextID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	marker := gi.Marker{
		Operation: operation.Context{ID: markerOperationID, StartedAt: startedAt, Policies: references},
		Kind:      gi.Join, GuildID: 1000001, Server: 1, Actor: 100001, Subject: 100002,
		ActorAccountUID: "payload-version-uid", EventID: 100, DecisionAt: decisionAt.Add(time.Second),
		MaxIssueSerial: issue.Serial, ContentRevision: revision, GuildCoreRevision: coreRevision, PolicyID: gi.PolicyID,
		Core: gi.CoreReceipt{ID: markerReceiptID, OwnerKind: "guild", OwnerKey: "1000001", Domain: "guild",
			Operation: "accept_application", SemanticKey: "payload-version-marker", Schema: "gxb.i6c.guild.accept_application.v1",
			OperationClass: "I6C_GUILD", PolicyVersion: coreRevision, ActorAccountUID: "payload-version-uid",
			ContextID: markerContextID, OperationStartedAt: startedAt, OperationPolicyRefs: references},
	}
	if err := marker.Validate(); err != nil {
		t.Fatalf("marker fixture invalid: %v", err)
	}
	markerFingerprint, err := marker.Fingerprint()
	if err != nil {
		t.Fatal(err)
	}
	cursorReceiptID := newReceipt("player", "100002", "invite-progress", "payload-version-cursor", decisionAt)
	cursorProof := gi.CursorProof{
		Request: gi.CursorRequest{
			MarkerID: markerOperationID, MarkerFingerprint: markerFingerprint, From: 0, To: 1,
			Covered:  gi.SetWitness{Count: 0, Digest: sha256.Sum256(nil)},
			Evidence: gi.CoveredEvidence{SourcePayloads: gi.SetWitness{Count: 0, Digest: sha256.Sum256(nil)}, TargetPayloads: gi.SetWitness{Count: 0, Digest: sha256.Sum256(nil)}, Receipts: gi.SetWitness{Count: 1, Digest: sha256.Sum256([]byte("payload-version-cursor"))}},
		},
		ReceiptID: cursorReceiptID, DecisionAt: decisionAt.Add(time.Minute),
	}
	if err := cursorProof.Validate(marker); err != nil {
		t.Fatalf("cursor proof fixture invalid: %v", err)
	}
	progress := gi.MarkerProgress{MarkerID: markerOperationID, MaxIssueSerial: marker.MaxIssueSerial, CursorSerial: 0, LastEnqueueAt: marker.DecisionAt, NextWakeupAt: marker.DecisionAt.Add(time.Minute)}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	delivery := gi.Delivery{SourceID: operationID, Recipient: 100002, State: gi.Pending, LastEnqueueAt: issue.DecisionAt, NextWakeupAt: issue.DecisionAt.Add(time.Minute)}
	if err := (guildinvitestore.Store{}).InsertIssueTx(ctx, transaction, issue, delivery); err != nil {
		t.Fatal(err)
	}
	if err := (guildinvitestore.Store{}).InsertMarkerTx(ctx, transaction, marker, progress); err != nil {
		t.Fatal(err)
	}
	if err := (guildinvitestore.Store{}).AdvanceProvenMarkerTx(ctx, transaction, progress, cursorProof); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	var issueText, markerText, cursorText string
	var issueVersion, markerVersion int16
	if err := pool.Raw().QueryRow(ctx, `SELECT source_payload::text,payload_version FROM guild_invite_projection_sources WHERE source_id=$1::uuid`, operationID.String()).Scan(&issueText, &issueVersion); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT source_payload::text,cursor_proof::text,payload_version FROM guild_invite_projection_markers WHERE marker_id=$1::uuid`, markerOperationID.String()).Scan(&markerText, &cursorText, &markerVersion); err != nil {
		t.Fatal(err)
	}
	if issueVersion != payload.Current || markerVersion != payload.Current {
		t.Fatalf("payload_version issue=%d marker=%d want=%d", issueVersion, markerVersion, payload.Current)
	}
	for name, row := range map[string]struct {
		table   string
		stored  string
		version int16
		written any
	}{
		"issue":  {"guild_invite_projection_sources", issueText, issueVersion, issue},
		"marker": {"guild_invite_projection_markers", markerText, markerVersion, marker},
		"cursor": {"guild_invite_projection_markers", cursorText, markerVersion, cursorProof},
	} {
		marshalled, err := json.Marshal(row.written)
		if err != nil {
			t.Fatal(err)
		}
		var expectedText string
		if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
			t.Fatal(err)
		}
		if row.stored != expectedText {
			t.Fatalf("%s stored=%s want json.Marshal=%s", name, row.stored, expectedText)
		}
	}
	var decodedIssue gi.Issue
	if err := payload.Decode("guild_invite_projection_sources", issueVersion, []byte(issueText), &decodedIssue); err != nil {
		t.Fatalf("strict issue decode: %v", err)
	}
	var decodedMarker gi.Marker
	if err := payload.Decode("guild_invite_projection_markers", markerVersion, []byte(markerText), &decodedMarker); err != nil {
		t.Fatalf("strict marker decode: %v", err)
	}
	var decodedCursor gi.CursorProof
	if err := payload.Decode("guild_invite_projection_markers", markerVersion, []byte(cursorText), &decodedCursor); err != nil {
		t.Fatalf("strict cursor decode: %v", err)
	}
	readIssue, found, err := (guildinvitestore.Store{}).ReadIssueTx(ctx, pool, operationID)
	if err != nil || !found || !reflect.DeepEqual(readIssue, issue) {
		t.Fatalf("ReadIssueTx found=%v err=%v read=%#v want=%#v", found, err, readIssue, issue)
	}
	readMarker, readProgress, found, err := (guildinvitestore.Store{}).ReadMarkerTx(ctx, pool, markerOperationID)
	if err != nil || !found || !reflect.DeepEqual(readMarker, marker) {
		t.Fatalf("ReadMarkerTx found=%v err=%v read=%#v want=%#v", found, err, readMarker, marker)
	}
	if readProgress.CursorProof == nil || !reflect.DeepEqual(*readProgress.CursorProof, cursorProof) {
		t.Fatalf("ReadMarkerTx cursor proof=%#v want=%#v", readProgress.CursorProof, cursorProof)
	}
}
