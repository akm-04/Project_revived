//go:build postgres

package playerdata_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/playerdatastore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/playerdata"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

const (
	testDigestSecret = "r86c-fixture-digest-key-00000001"
	testBearerSecret = "r86c-fixture-bearer-key-00000001"
	testKeyID        = "r86c-native"
)

type restoreFixture struct {
	pool   *pg.Pool
	plan   playerdata.Plan
	digest string
	root   string
}

func newRestoreFixture(t *testing.T) restoreFixture {
	t.Helper()
	root := t.TempDir()
	if err := os.MkdirAll(filepath.Join(root, "blobs"), 0o700); err != nil {
		t.Fatal(err)
	}
	plan, digest := exportPlan(t)
	return restoreFixture{pool: exportPool(t), plan: plan, digest: digest, root: root}
}

func (fixture restoreFixture) service() playerdata.RestoreService {
	return playerdata.RestoreService{Database: fixture.pool, Store: playerdatastore.Store{}, Roots: i4store.PlayerRootLocker{}, Blobs: mediaRootBlobs{root: fixture.root}}
}

// mediaRootBlobs mirrors cmd/gxb-player-data's ProfileAssetStore check.
type mediaRootBlobs struct{ root string }

func (blobs mediaRootBlobs) BlobExists(key string) (bool, error) {
	info, err := os.Stat(filepath.Join(blobs.root, "blobs", key))
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return info.Mode().IsRegular(), nil
}

func (fixture restoreFixture) writeBlob(t *testing.T, key string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(fixture.root, "blobs", key), []byte("blob"), 0o400); err != nil {
		t.Fatal(err)
	}
}

func (fixture restoreFixture) exportPlayer(t *testing.T, playerID int64) playerdata.Document {
	t.Helper()
	return exportService(t, fixture.pool, fixture.plan, fixture.digest, playerID, time.Date(2026, 11, 16, 2, 3, 4, 5, time.UTC))
}

func (fixture restoreFixture) restore(t *testing.T, document playerdata.Document, targetPlayerID int64) (playerdata.RestoreResult, error) {
	t.Helper()
	return fixture.service().Restore(context.Background(), fixture.plan, fixture.digest, targetPlayerID, document, time.Now().UTC())
}

func (fixture restoreFixture) mustRestore(t *testing.T, document playerdata.Document, targetPlayerID int64) playerdata.RestoreResult {
	t.Helper()
	result, err := fixture.restore(t, document, targetPlayerID)
	if err != nil {
		t.Fatal(err)
	}
	return result
}

func cloneDocument(document playerdata.Document) playerdata.Document {
	clone := document
	clone.BlobKeys = append([]string(nil), document.BlobKeys...)
	clone.Tables = make([]playerdata.TableRows, len(document.Tables))
	for index, table := range document.Tables {
		rows := make([]json.RawMessage, len(table.Rows))
		for rowIndex, row := range table.Rows {
			rows[rowIndex] = append(json.RawMessage(nil), row...)
		}
		clone.Tables[index] = playerdata.TableRows{Table: table.Table, Action: table.Action, Rows: rows}
	}
	return clone
}

func rewriteRow(t *testing.T, document *playerdata.Document, table string, change func(map[string]json.RawMessage)) {
	t.Helper()
	for index := range document.Tables {
		if document.Tables[index].Table != table {
			continue
		}
		for rowIndex, raw := range document.Tables[index].Rows {
			var row map[string]json.RawMessage
			if err := json.Unmarshal(raw, &row); err != nil {
				t.Fatal(err)
			}
			change(row)
			updated, err := json.Marshal(row)
			if err != nil {
				t.Fatal(err)
			}
			document.Tables[index].Rows[rowIndex] = updated
		}
		return
	}
	t.Fatalf("export has no %s table", table)
}

func withoutRows(document playerdata.Document, table string) playerdata.Document {
	clone := cloneDocument(document)
	for index := range clone.Tables {
		if clone.Tables[index].Table == table {
			clone.Tables[index].Rows = []json.RawMessage{}
		}
	}
	return clone
}

func snapshot(t *testing.T, fixture restoreFixture, playerID int64) map[string]string {
	t.Helper()
	out := make(map[string]string, len(fixture.plan.Tables))
	for _, table := range fixture.plan.Tables {
		rows, err := (playerdatastore.Store{}).SelectRows(context.Background(), fixture.pool, table.Select, playerID)
		if err != nil {
			t.Fatalf("%s snapshot: %v", table.Table, err)
		}
		parts := make([]string, len(rows))
		for index, row := range rows {
			parts[index] = string(row)
		}
		out[table.Table] = strings.Join(parts, "\n")
	}
	return out
}

func assertSnapshotUnchanged(t *testing.T, before, after map[string]string) {
	t.Helper()
	for table, rows := range before {
		if after[table] != rows {
			t.Fatalf("refused restore changed %s", table)
		}
	}
}

// comparableRows drops the columns a restore is allowed to change.
func comparableRows(t *testing.T, document playerdata.Document) map[string][]map[string]json.RawMessage {
	t.Helper()
	out := make(map[string][]map[string]json.RawMessage, len(document.Tables))
	for _, table := range document.Tables {
		rows := make([]map[string]json.RawMessage, 0, len(table.Rows))
		for _, raw := range table.Rows {
			var row map[string]json.RawMessage
			if err := json.Unmarshal(raw, &row); err != nil {
				t.Fatal(err)
			}
			delete(row, "state_version")
			delete(row, "updated_at")
			rows = append(rows, row)
		}
		out[table.Table] = rows
	}
	return out
}

func playerStateVersion(t *testing.T, pool *pg.Pool, playerID int64) int64 {
	t.Helper()
	var version int64
	if err := pool.QueryRow(context.Background(), `SELECT state_version FROM players WHERE player_id=$1`, playerID).Scan(&version); err != nil {
		t.Fatal(err)
	}
	return version
}

func execSQL(t *testing.T, pool *pg.Pool, statement string, arguments ...any) {
	t.Helper()
	if _, err := pool.Raw().Exec(context.Background(), statement, arguments...); err != nil {
		t.Fatal(err)
	}
}

func countRows(t *testing.T, pool *pg.Pool, statement string, arguments ...any) int {
	t.Helper()
	var count int
	if err := pool.QueryRow(context.Background(), statement, arguments...).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func appendTableRows(t *testing.T, document *playerdata.Document, table string, rows ...json.RawMessage) {
	t.Helper()
	for index := range document.Tables {
		if document.Tables[index].Table != table {
			continue
		}
		document.Tables[index].Rows = append(document.Tables[index].Rows, rows...)
		return
	}
	t.Fatalf("export has no %s table", table)
}

func rawRowFor(t *testing.T, document playerdata.Document, table string) json.RawMessage {
	t.Helper()
	for _, exported := range document.Tables {
		if exported.Table != table {
			continue
		}
		if len(exported.Rows) != 1 {
			t.Fatalf("table %s has %d rows, want 1", table, len(exported.Rows))
		}
		return append(json.RawMessage(nil), exported.Rows[0]...)
	}
	t.Fatalf("table %s missing from export", table)
	return nil
}

func assertSessionUntouched(t *testing.T, pool *pg.Pool, sessionID, contextID ids.UUID) {
	t.Helper()
	if countRows(t, pool, `SELECT count(*) FROM account_sessions WHERE session_id=$1 AND revoked_at IS NULL`, sessionID.String()) != 1 {
		t.Fatal("refused restore revoked the player's session")
	}
	if countRows(t, pool, `SELECT count(*) FROM gameplay_contexts WHERE context_id=$1 AND ended_at IS NULL`, contextID.String()) != 1 {
		t.Fatal("refused restore ended the player's context")
	}
}

func seedForeignStack(t *testing.T, pool *pg.Pool, playerID, itemID, quantity int64) {
	t.Helper()
	now := time.Now().UTC().Add(-time.Hour)
	execSQL(t, pool, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,$3,2,$4,$4)`, playerID, itemID, quantity, now)
}

func newUUID(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}

func TestRestoreEmptyPlayerRoundTrip(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	document := fixture.exportPlayer(t, player.id)

	result := fixture.mustRestore(t, document, player.id)
	if result.PlayerID != player.id || result.Tables != countRestoreTables(fixture.plan) {
		t.Fatalf("result %+v", result)
	}
	if result.Inserted == 0 {
		t.Fatal("restore inserted no rows")
	}
	again := fixture.exportPlayer(t, player.id)
	if !reflect.DeepEqual(comparableRows(t, document), comparableRows(t, again)) {
		t.Fatal("re-export of the restored player differs beyond version columns")
	}
}

func countRestoreTables(plan playerdata.Plan) int {
	count := 0
	for _, table := range plan.Tables {
		if table.Action == playerdata.ActionRestore {
			count++
		}
	}
	return count
}

func seedPopulatedRows(t *testing.T, pool *pg.Pool, player exportedPlayer) {
	t.Helper()
	now := time.Now().UTC().Add(-time.Hour)
	var revision string
	if err := pool.QueryRow(context.Background(), `SELECT revision_id FROM gxb_content_revisions WHERE revision_id='43541b13504ccb7adee1619147fef90f8cdf6a7bd06a5bb382002a8d8d551356'`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	statements := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'native restore',110001001,0,0,3,$2,$2)`, []any{player.id, now}},
		{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,12,345,4,$2)`, []any{player.id, now}},
		{`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,2,$2)`, []any{player.id, now}},
		{`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',900,5,$2)`, []any{player.id, now}},
		{`INSERT INTO achievement_roots(player_id,content_revision,policy_id,progress,complete_times,state_version,created_at,updated_at,payload_version)VALUES($1,$2,'C4B_MARRIED_POPULATION_TIER_FACTS_V1',10,'[0,0,0]'::jsonb,2,$3,$3,1)`, []any{player.id, revision, now}},
	}
	for _, statement := range statements {
		execSQL(t, pool, statement.sql, statement.args...)
	}
}

func TestRestorePopulatedPlayerRoundTrip(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, true)
	seedPopulatedRows(t, fixture.pool, player)
	fixture.writeBlob(t, player.blobKey)
	document := fixture.exportPlayer(t, player.id)
	if len(document.BlobKeys) != 1 {
		t.Fatalf("blob keys %v", document.BlobKeys)
	}

	fixture.mustRestore(t, document, player.id)
	again := fixture.exportPlayer(t, player.id)
	if !reflect.DeepEqual(comparableRows(t, document), comparableRows(t, again)) {
		t.Fatal("re-export of the restored player differs beyond version columns")
	}
}

func TestRestoreReplayRaisesVersions(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	document := fixture.exportPlayer(t, player.id)
	first := playerStateVersion(t, fixture.pool, player.id)
	fixture.mustRestore(t, document, player.id)
	second := playerStateVersion(t, fixture.pool, player.id)
	if second <= first {
		t.Fatalf("restore did not raise players.state_version: %d -> %d", first, second)
	}
	fixture.mustRestore(t, document, player.id)
	third := playerStateVersion(t, fixture.pool, player.id)
	if third <= second {
		t.Fatalf("replayed restore did not raise players.state_version: %d -> %d", second, third)
	}
}

func TestRestoreRefusals(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	document := fixture.exportPlayer(t, player.id)
	var databaseVersion int64
	if err := fixture.pool.QueryRow(context.Background(), `SELECT COALESCE(max(version_id),0) FROM goose_db_version WHERE is_applied`).Scan(&databaseVersion); err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		name      string
		target    int64
		document  func() playerdata.Document
		wantError string
	}{
		{"newer schema", player.id, func() playerdata.Document {
			clone := cloneDocument(document)
			clone.SchemaVersion = databaseVersion + 1
			return clone
		}, "schema version"},
		{"older schema", player.id, func() playerdata.Document {
			clone := cloneDocument(document)
			clone.SchemaVersion = databaseVersion - 1
			return clone
		}, "schema version"},
		{"other player", player.id + 1, func() playerdata.Document { return document }, "player"},
		{"other server", player.id, func() playerdata.Document {
			clone := cloneDocument(document)
			clone.LogicalServerID++
			rewriteRow(t, &clone, playerdata.PlayersTable, func(row map[string]json.RawMessage) {
				row["logical_server_id"] = json.RawMessage(fmt.Sprintf("%d", clone.LogicalServerID))
			})
			return clone
		}, "server"},
		{"changed plan", player.id, func() playerdata.Document {
			clone := cloneDocument(document)
			clone.PlanSHA256 = strings.Repeat("0", 64)
			return clone
		}, "plan"},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			before := snapshot(t, fixture, player.id)
			_, err := fixture.restore(t, testCase.document(), testCase.target)
			if !errors.Is(err, playerdata.ErrRestoreRefused) || !strings.Contains(err.Error(), testCase.wantError) {
				t.Fatalf("want refusal containing %q, got %v", testCase.wantError, err)
			}
			assertSnapshotUnchanged(t, before, snapshot(t, fixture, player.id))
		})
	}
}

func TestRestoreRefusesMissingMediaBlob(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, true)
	document := fixture.exportPlayer(t, player.id)
	before := snapshot(t, fixture, player.id)
	_, err := fixture.restore(t, document, player.id)
	if !errors.Is(err, playerdata.ErrRestoreRefused) || !strings.Contains(err.Error(), "media blob") {
		t.Fatalf("want missing media blob refusal, got %v", err)
	}
	assertSnapshotUnchanged(t, before, snapshot(t, fixture, player.id))
}

func TestRestoreRefusesInboundRowTheExportLacks(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	friend := seedPlayer(t, fixture.pool, false)
	now := time.Now().UTC().Add(-time.Hour)
	execSQL(t, fixture.pool, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, player.id, now)
	execSQL(t, fixture.pool, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, friend.id, now)
	document := fixture.exportPlayer(t, player.id)
	low, high := player.id, friend.id
	if low > high {
		low, high = high, low
	}
	execSQL(t, fixture.pool, `INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,$3,1,$3)`, low, high, now)

	before := snapshot(t, fixture, player.id)
	_, err := fixture.restore(t, withoutRows(document, "player_social_roots"), player.id)
	if !errors.Is(err, playerdata.ErrRestoreRefused) || !strings.Contains(err.Error(), "player_social_roots") {
		t.Fatalf("want inbound refusal naming the table, got %v", err)
	}
	assertSnapshotUnchanged(t, before, snapshot(t, fixture, player.id))
}

// A-071/Amendment 1A: a full valid export of A carrying one B-owned
// player_item_stacks row is refused; A and B are unchanged and A's session
// survives, because the refusal rolls the whole transaction back.
func TestRestoreRefusesAnotherPlayersStackRow(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	foreign := seedPlayer(t, fixture.pool, false)
	const itemID = int64(40001053)
	seedForeignStack(t, fixture.pool, foreign.id, itemID, 5)
	foreignDocument := fixture.exportPlayer(t, foreign.id)
	foreignRow := rawRowFor(t, foreignDocument, "player_item_stacks")
	execSQL(t, fixture.pool, `DELETE FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, foreign.id, itemID)

	document := fixture.exportPlayer(t, player.id)
	appendTableRows(t, &document, "player_item_stacks", foreignRow)
	sessionID, contextID, _ := seedPlayerSession(t, fixture.pool, player)
	before := snapshot(t, fixture, player.id)
	foreignBefore := snapshot(t, fixture, foreign.id)

	_, err := fixture.restore(t, document, player.id)
	if !errors.Is(err, playerdata.ErrRestoreRefused) || !strings.Contains(err.Error(), "player_item_stacks") {
		t.Fatalf("want cross-player refusal naming the table, got %v", err)
	}
	assertSnapshotUnchanged(t, before, snapshot(t, fixture, player.id))
	assertSnapshotUnchanged(t, foreignBefore, snapshot(t, fixture, foreign.id))
	if countRows(t, fixture.pool, `SELECT count(*) FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, foreign.id, itemID) != 0 {
		t.Fatal("refused restore inserted the foreign player's stack")
	}
	assertSessionUntouched(t, fixture.pool, sessionID, contextID)
}

// Parent-owned child from the generated plan: mail_attachments selects through
// its mail_records parent, so a B-owned attachment is refused even though its
// table has no player column at all.
func TestRestoreRefusesAnotherPlayersParentOwnedChildRow(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	foreign := seedPlayer(t, fixture.pool, false)
	mailID := newUUID(t).String()
	now := time.Now().UTC().Add(-time.Hour)
	execSQL(t, fixture.pool, `INSERT INTO mail_records(mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,created_at,compatibility_policy_version)VALUES($1::uuid,$2,'NORMAL',900001,'R86C_NATIVE',$1::text,$3,'R8_RESTORE_V1')`, mailID, foreign.id, now)
	execSQL(t, fixture.pool, `INSERT INTO mail_attachments(mail_uuid,ordinal,grant_line_kind,item_id,amount)VALUES($1,0,'STACK_ITEM',40001053,5)`, mailID)
	foreignDocument := fixture.exportPlayer(t, foreign.id)
	attachmentRow := rawRowFor(t, foreignDocument, "mail_attachments")
	execSQL(t, fixture.pool, `DELETE FROM mail_attachments WHERE mail_uuid=$1`, mailID)

	document := fixture.exportPlayer(t, player.id)
	appendTableRows(t, &document, "mail_attachments", attachmentRow)
	sessionID, contextID, _ := seedPlayerSession(t, fixture.pool, player)
	before := snapshot(t, fixture, player.id)
	foreignBefore := snapshot(t, fixture, foreign.id)

	_, err := fixture.restore(t, document, player.id)
	if !errors.Is(err, playerdata.ErrRestoreRefused) || !strings.Contains(err.Error(), "mail_attachments") {
		t.Fatalf("want parent-owned child refusal naming the table, got %v", err)
	}
	assertSnapshotUnchanged(t, before, snapshot(t, fixture, player.id))
	assertSnapshotUnchanged(t, foreignBefore, snapshot(t, fixture, foreign.id))
	if countRows(t, fixture.pool, `SELECT count(*) FROM mail_attachments WHERE mail_uuid=$1`, mailID) != 0 {
		t.Fatal("refused restore inserted the foreign player's attachment")
	}
	assertSessionUntouched(t, fixture.pool, sessionID, contextID)
}

// Owner column that is not player_id: mail_records keys its owner by
// recipient_player_id, so a B-owned mail record in A's export is refused.
func TestRestoreRefusesRowUnderAnotherOwnerColumn(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	foreign := seedPlayer(t, fixture.pool, false)
	mailID := newUUID(t).String()
	now := time.Now().UTC().Add(-time.Hour)
	execSQL(t, fixture.pool, `INSERT INTO mail_records(mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,created_at,compatibility_policy_version)VALUES($1::uuid,$2,'NORMAL',900002,'R86C_NATIVE',$1::text,$3,'R8_RESTORE_V1')`, mailID, foreign.id, now)
	foreignDocument := fixture.exportPlayer(t, foreign.id)
	mailRow := rawRowFor(t, foreignDocument, "mail_records")
	execSQL(t, fixture.pool, `DELETE FROM mail_records WHERE mail_uuid=$1`, mailID)

	document := fixture.exportPlayer(t, player.id)
	appendTableRows(t, &document, "mail_records", mailRow)
	sessionID, contextID, _ := seedPlayerSession(t, fixture.pool, player)
	before := snapshot(t, fixture, player.id)
	foreignBefore := snapshot(t, fixture, foreign.id)

	_, err := fixture.restore(t, document, player.id)
	if !errors.Is(err, playerdata.ErrRestoreRefused) || !strings.Contains(err.Error(), "mail_records") {
		t.Fatalf("want owner-column refusal naming the table, got %v", err)
	}
	assertSnapshotUnchanged(t, before, snapshot(t, fixture, player.id))
	assertSnapshotUnchanged(t, foreignBefore, snapshot(t, fixture, foreign.id))
	if countRows(t, fixture.pool, `SELECT count(*) FROM mail_records WHERE mail_uuid=$1`, mailID) != 0 {
		t.Fatal("refused restore inserted the foreign player's mail record")
	}
	assertSessionUntouched(t, fixture.pool, sessionID, contextID)
}

// insertRedeemedCode writes one issued code and its redemption, the U7 redeem
// ledger row a restore must keep.
func insertRedeemedCode(t *testing.T, pool *pg.Pool, player exportedPlayer, redemption ids.UUID, at time.Time) {
	t.Helper()
	rewardBundle := newUUID(t)
	campaign := newUUID(t)
	code := newUUID(t)
	receipt := newUUID(t)
	execSQL(t, pool, `INSERT INTO redeem_reward_bundle_revisions(reward_bundle_revision_id,grant_plan,content_hash,created_by,created_at)VALUES($1,'{}'::jsonb,decode(repeat('00',32),'hex'),'r86c-native',$2)`, rewardBundle.String(), at)
	execSQL(t, pool, `INSERT INTO redeem_campaigns(campaign_id,name,status,redemption_subject,reward_bundle_revision_id,policy_version,created_by,created_at)VALUES($1,'r86c-native','ACTIVE','PLAYER',$2,'R8_REDEEM_V1','r86c-native',$3)`, campaign.String(), rewardBundle.String(), at)
	execSQL(t, pool, `INSERT INTO redeem_codes(code_id,campaign_id,lookup_digest,code_kind,status,created_at)VALUES($1,$2,sha256(convert_to(($1::uuid)::text,'UTF8')),'PUBLIC_CAMPAIGN_CODE','ACTIVE',$3)`, code.String(), campaign.String(), at)
	execSQL(t, pool, `INSERT INTO gxb_operation_receipts(receipt_id,owner_kind,owner_key,domain,operation,operation_class,semantic_key,request_fingerprint,result_schema,result_payload,operation_started_at,policy_version,actor_account_uid,recorded_at)VALUES($1,'player',$2,'redeem','redeem','REDEEM',($1::uuid)::text,sha256(convert_to(($1::uuid)::text,'UTF8')),'r86c.redeem.v1','{}'::jsonb,$3,'R8_REDEEM_V1','r86c-native',$3)`, receipt.String(), fmt.Sprint(player.id), at)
	execSQL(t, pool, `INSERT INTO redeem_redemptions(redemption_id,code_id,subject_type,subject_id,player_id,account_id,logical_server_id,reward_bundle_revision_id,grant_receipt_id,redeemed_at,policy_version)VALUES($1,$2,'PLAYER',$3,$4,(SELECT account_id FROM players WHERE player_id=$4),$5,$6,$7,$8,'R8_REDEEM_V1')`, redemption.String(), code.String(), fmt.Sprint(player.id), player.id, player.server, rewardBundle.String(), receipt.String(), at)
}

func TestRestoreKeepsPurchasesRedemptionsAndClaims(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	seedPopulatedRows(t, fixture.pool, player)
	now := time.Now().UTC().Add(-time.Minute)
	execSQL(t, fixture.pool, `INSERT INTO commerce_charge_purchases(player_id,charge_id,charge_count,first_buy_time,last_buy_time)VALUES($1,101,1,$2,$2)`, player.id, now.Unix())
	document := fixture.exportPlayer(t, player.id)

	execSQL(t, fixture.pool, `INSERT INTO commerce_charge_purchases(player_id,charge_id,charge_count,first_buy_time,last_buy_time)VALUES($1,102,2,$2,$2)`, player.id, now.Unix()+1)
	redemption := newUUID(t)
	insertRedeemedCode(t, fixture.pool, player, redemption, now)
	operation := newUUID(t)
	var revision string
	if err := fixture.pool.QueryRow(context.Background(), `SELECT revision_id FROM gxb_content_revisions LIMIT 1`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	execSQL(t, fixture.pool, `INSERT INTO achievement_award_claims(player_id,level_id,content_revision,operation_id,total_points,claimed_at)VALUES($1,3,$2,$3,7,$4)`, player.id, revision, operation.String(), now)

	fixture.mustRestore(t, document, player.id)

	var charges int
	if err := fixture.pool.QueryRow(context.Background(), `SELECT count(*) FROM commerce_charge_purchases WHERE player_id=$1`, player.id).Scan(&charges); err != nil {
		t.Fatal(err)
	}
	if charges != 2 {
		t.Fatalf("restore changed the purchase ledger: %d rows", charges)
	}
	var redemptions int
	if err := fixture.pool.QueryRow(context.Background(), `SELECT count(*) FROM redeem_redemptions WHERE redemption_id=$1`, redemption.String()).Scan(&redemptions); err != nil {
		t.Fatal(err)
	}
	if redemptions != 1 {
		t.Fatalf("restore changed the redeem ledger: %d rows", redemptions)
	}
	var claims int
	if err := fixture.pool.QueryRow(context.Background(), `SELECT count(*) FROM achievement_award_claims WHERE player_id=$1`, player.id).Scan(&claims); err != nil {
		t.Fatal(err)
	}
	if claims != 1 {
		t.Fatalf("restore changed the claim ledger: %d rows", claims)
	}
	if _, err := fixture.pool.Raw().Exec(context.Background(), `INSERT INTO achievement_award_claims(player_id,level_id,content_revision,operation_id,total_points,claimed_at)VALUES($1,3,$2,$3,7,$4)`, player.id, revision, operation.String(), now); err == nil {
		t.Fatal("the claim could be taken twice after the restore")
	}
}

func TestRestoreLeavesFriendRelations(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	friend := seedPlayer(t, fixture.pool, false)
	now := time.Now().UTC().Add(-time.Hour)
	execSQL(t, fixture.pool, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, player.id, now)
	execSQL(t, fixture.pool, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, friend.id, now)
	document := fixture.exportPlayer(t, player.id)

	low, high := player.id, friend.id
	if low > high {
		low, high = high, low
	}
	execSQL(t, fixture.pool, `INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,$3,2,$3)`, low, high, now)
	execSQL(t, fixture.pool, `INSERT INTO social_friend_requests(requester_player_id,target_player_id,generation,status,requested_at,state_version,updated_at)VALUES($1,$2,1,'PENDING',$3,1,$3)`, player.id, friend.id, now)

	fixture.mustRestore(t, document, player.id)

	var friends int
	if err := fixture.pool.QueryRow(context.Background(), `SELECT count(*) FROM social_friendships WHERE player_low_id=$1 AND player_high_id=$2`, low, high).Scan(&friends); err != nil {
		t.Fatal(err)
	}
	if friends != 1 {
		t.Fatalf("restore dropped the friendship: %d rows", friends)
	}
	var requests int
	if err := fixture.pool.QueryRow(context.Background(), `SELECT count(*) FROM social_friend_requests WHERE requester_player_id=$1 AND target_player_id=$2 AND status='PENDING'`, player.id, friend.id).Scan(&requests); err != nil {
		t.Fatal(err)
	}
	if requests != 1 {
		t.Fatalf("restore dropped the pending friend request: %d rows", requests)
	}
}

// stubDisplayService proves the edge never reaches a command handler for a
// session the restore ended.
type stubDisplayService struct{}

func (stubDisplayService) Execute(context.Context, identity.ActorContext, playerdisplay.Command, operation.Context) (playerdisplay.Result, error) {
	return playerdisplay.Result{}, errors.New("display command reached for an ended session")
}

func (stubDisplayService) Read(context.Context, identity.ActorContext, string, operation.Context) (map[string]any, error) {
	return nil, errors.New("display read reached for an ended session")
}

func seedPlayerSession(t *testing.T, pool *pg.Pool, player exportedPlayer) (ids.UUID, ids.UUID, string) {
	t.Helper()
	sessionID := newUUID(t)
	contextID := newUUID(t)
	credentialID := newUUID(t)
	now := time.Now().UTC().Add(-time.Hour)
	execSQL(t, pool, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,(SELECT account_id FROM players WHERE player_id=$2),'r86c-native',$3,$3)`, sessionID.String(), player.id, now)
	execSQL(t, pool, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,(SELECT account_id FROM players WHERE player_id=$3),$4,$3,1,$5)`, contextID.String(), sessionID.String(), player.id, player.server, now)
	contextDomain, err := identity.ContextIDFrom(contextID)
	if err != nil {
		t.Fatal(err)
	}
	bearer, err := identity.DeriveGameplayBearer([]byte(testBearerSecret), identity.GameplayContext{ID: contextDomain, ContextGeneration: 1})
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer([]byte(testDigestSecret), bearer)
	if err != nil {
		t.Fatal(err)
	}
	execSQL(t, pool, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)VALUES($1,$2,$3,$4,1,$5,$6)`, credentialID.String(), contextID.String(), sessionID.String(), digest[:], testKeyID, now)
	return sessionID, contextID, bearer
}

// U6: a session open at the restore is refused afterwards with message.lua
// 20003, the same answer the existing session-revocation path produces.
func TestRestoreEndsPlayerSessions(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	sessionID, contextID, bearer := seedPlayerSession(t, fixture.pool, player)
	authority := i4store.RealtimeAuthority{Queryer: fixture.pool, DigestSecret: []byte(testDigestSecret), BearerSecret: []byte(testBearerSecret), DerivationKeyID: testKeyID}
	if _, err := authority.ResolveGameplayBearer(context.Background(), bearer, time.Now().UTC()); err != nil {
		t.Fatalf("fixture session does not resolve before the restore: %v", err)
	}
	document := fixture.exportPlayer(t, player.id)
	fixture.mustRestore(t, document, player.id)

	var revoked bool
	if err := fixture.pool.QueryRow(context.Background(), `SELECT revoked_at IS NOT NULL FROM account_sessions WHERE session_id=$1`, sessionID.String()).Scan(&revoked); err != nil {
		t.Fatal(err)
	}
	if !revoked {
		t.Fatal("restore did not revoke the open session")
	}
	var ended bool
	if err := fixture.pool.QueryRow(context.Background(), `SELECT ended_at IS NOT NULL FROM gameplay_contexts WHERE context_id=$1`, contextID.String()).Scan(&ended); err != nil {
		t.Fatal(err)
	}
	if !ended {
		t.Fatal("restore did not end the live context")
	}
	var liveCredentials int
	if err := fixture.pool.QueryRow(context.Background(), `SELECT count(*) FROM gameplay_context_credentials WHERE session_id=$1 AND revoked_at IS NULL`, sessionID.String()).Scan(&liveCredentials); err != nil {
		t.Fatal(err)
	}
	if liveCredentials != 0 {
		t.Fatalf("restore left %d live gameplay credentials", liveCredentials)
	}
	if _, err := authority.ResolveGameplayBearer(context.Background(), bearer, time.Now().UTC()); !errors.Is(err, i4store.ErrGameplayBearerNotLive) {
		t.Fatalf("bearer still resolves after the restore: %v", err)
	}

	dispatcher := stockruntime.PlayerDisplayDispatcher{Authority: authority, Service: stubDisplayService{}}
	response := dispatcher.Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 23, ReceivedAt: time.Now().UTC(), Claims: wire.CredentialClaims{Token: bearer, Region: int64(player.server)}}})
	if response.HTTPStatus != http.StatusUnauthorized {
		t.Fatalf("status %d, want 401", response.HTTPStatus)
	}
	if response.Body["error_code"] != int64(20003) {
		t.Fatalf("error_code %v, want 20003", response.Body["error_code"])
	}
}

func actorForSession(t *testing.T, pool *pg.Pool, player exportedPlayer, sessionID, contextID ids.UUID) identity.ActorContext {
	t.Helper()
	var rawAccount string
	if err := pool.QueryRow(context.Background(), `SELECT account_id::text FROM players WHERE player_id=$1`, player.id).Scan(&rawAccount); err != nil {
		t.Fatal(err)
	}
	accountUUID, err := ids.ParseUUID(rawAccount)
	if err != nil {
		t.Fatal(err)
	}
	accountID, err := identity.AccountIDFrom(accountUUID)
	if err != nil {
		t.Fatal(err)
	}
	session, err := identity.SessionIDFrom(sessionID)
	if err != nil {
		t.Fatal(err)
	}
	contextDomain, err := identity.ContextIDFrom(contextID)
	if err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{AccountID: accountID, SessionID: session, ContextID: contextDomain, LogicalServerID: identity.LogicalServerID(player.server), PlayerID: identity.PlayerID(player.id), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

// restoreSignalStore reports the moment Restore starts ending sessions so the
// test can play the gameplay transaction's next lock without polling.
type restoreSignalStore struct {
	playerdata.RestoreStore
	revocationStarted chan struct{}
}

func (store restoreSignalStore) EndPlayerSessions(ctx context.Context, transaction tx.Tx, playerID int64, at time.Time) (int, error) {
	close(store.revocationStarted)
	return store.RestoreStore.EndPlayerSessions(ctx, transaction, playerID, at)
}

// A-072/Amendment 1B: gameplay takes the identity fence FOR SHARE and then the
// player root. Restore must end sessions before it takes the root, or the two
// transactions form a lock cycle. The fence transaction here is real; every
// wait carries the test context deadline, so a deadlock fails instead of
// hanging.
func TestRestoreFenceOrderEndsSessionsBeforeRoot(t *testing.T) {
	fixture := newRestoreFixture(t)
	player := seedPlayer(t, fixture.pool, false)
	sessionID, contextID, bearer := seedPlayerSession(t, fixture.pool, player)
	document := fixture.exportPlayer(t, player.id)
	actor := actorForSession(t, fixture.pool, player, sessionID, contextID)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	fence, err := fixture.pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer fence.Rollback(ctx)
	if err := (i5store.Store{}).FenceActorTx(ctx, fence, actor, time.Now().UTC()); err != nil {
		t.Fatalf("fixture gameplay fence: %v", err)
	}

	reached := make(chan struct{})
	service := fixture.service()
	service.Store = restoreSignalStore{RestoreStore: service.Store, revocationStarted: reached}
	outcome := make(chan error, 1)
	go func() {
		_, err := service.Restore(ctx, fixture.plan, fixture.digest, player.id, document, time.Now().UTC())
		outcome <- err
	}()

	select {
	case <-reached:
	case <-ctx.Done():
		t.Fatalf("restore did not start ending sessions: %v", ctx.Err())
	}

	_, fenceRootErr := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, fence, identity.LogicalServerID(player.server), []identity.PlayerID{identity.PlayerID(player.id)})
	fenceCommitErr := fence.Commit(ctx)
	var restoreErr error
	select {
	case restoreErr = <-outcome:
	case <-ctx.Done():
		t.Fatalf("restore did not finish under the held fence: %v", ctx.Err())
	}

	if fenceRootErr != nil {
		t.Fatalf("gameplay root lock behind the restore: %v", fenceRootErr)
	}
	if fenceCommitErr != nil {
		t.Fatalf("gameplay commit: %v", fenceCommitErr)
	}
	if restoreErr != nil {
		t.Fatalf("restore beside a held gameplay fence: %v", restoreErr)
	}

	authority := i4store.RealtimeAuthority{Queryer: fixture.pool, DigestSecret: []byte(testDigestSecret), BearerSecret: []byte(testBearerSecret), DerivationKeyID: testKeyID}
	if _, err := authority.ResolveGameplayBearer(ctx, bearer, time.Now().UTC()); !errors.Is(err, i4store.ErrGameplayBearerNotLive) {
		t.Fatalf("the held command's bearer still resolves after the restore: %v", err)
	}
}
