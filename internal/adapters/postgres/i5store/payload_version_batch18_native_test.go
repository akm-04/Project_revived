//go:build postgres

package i5store

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripI5StoreBatch18(t *testing.T) {
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
	at := time.Date(2026, 11, 16, 5, 40, 0, 123123000, time.UTC)
	player := identity.PlayerID(3000001)
	for _, statement := range []string{
		`INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES(30,'payload-version-i5-batch18',NULL,false,false,false,3099999,3099999,1,now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES('77777777-7777-4777-8777-777777777730','payload-version-i5-batch18','ACTIVE',now()) ON CONFLICT DO NOTHING`,
		`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES(3000001,'77777777-7777-4777-8777-777777777730',30,now(),'payload-version-i5-batch18') ON CONFLICT DO NOTHING`,
		`INSERT INTO player_profiles(player_id,avatar_id,created_at,updated_at) VALUES(3000001,1,now(),now()) ON CONFLICT DO NOTHING`,
	} {
		if _, err := pool.Raw().Exec(ctx, statement); err != nil {
			t.Fatal(err)
		}
	}
	store := Store{}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()

	displayOperationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	actor, err := batch18Actor(player)
	if err != nil {
		t.Fatal(err)
	}
	admission := app.Admission{
		Operation:  operation.Context{ID: displayOperationID, StartedAt: at},
		Actor:      actor,
		Command:    app.Command{Kind: "rename", Name: "renamed"},
		Revision:   "content-rev-1",
		DecisionAt: at,
		State:      "PENDING",
	}
	if err := store.InsertDisplayAdmissionTx(ctx, transaction, admission); err != nil {
		t.Fatal(err)
	}

	bundleID, campaignID, codeID, err := newBatch18UUIDs()
	if err != nil {
		t.Fatal(err)
	}
	minimum, maximum := int64(1), int64(80)
	audience := audienceJSON{MinLevel: &minimum, MaxLevel: &maximum, LogicalServers: []int32{30}}
	audienceRaw, err := json.Marshal(audience)
	if err != nil {
		t.Fatal(err)
	}
	plan := grant.Plan{
		Source: grant.SourceIdentity{Domain: "redeem", Operation: "grant", BusinessKey: "bundle-1", PolicyVersion: "content-rev-1"},
		Lines:  []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "coin", Amount: 5}},
	}
	planRaw, err := json.Marshal(plan)
	if err != nil {
		t.Fatal(err)
	}
	contentHash := sha256.Sum256([]byte("bundle-1"))
	if _, err := transaction.Exec(ctx, `INSERT INTO redeem_reward_bundle_revisions(reward_bundle_revision_id,grant_plan,content_hash,created_by,created_at) VALUES($1::uuid,$2::jsonb,$3,'payload-version',$4)`, bundleID.String(), string(planRaw), contentHash[:], at); err != nil {
		t.Fatal(err)
	}
	if _, err := transaction.Exec(ctx, `INSERT INTO redeem_campaigns(campaign_id,name,status,redemption_subject,audience_policy,reward_bundle_revision_id,per_subject_cap,policy_version,created_by,created_at) VALUES($1::uuid,'payload-version','ACTIVE','PLAYER',$2::jsonb,$3::uuid,1,'content-rev-1','payload-version',$4)`, campaignID.String(), string(audienceRaw), bundleID.String(), at); err != nil {
		t.Fatal(err)
	}
	digest := sha256.Sum256([]byte("payload-version-code"))
	if _, err := transaction.Exec(ctx, `INSERT INTO redeem_codes(code_id,campaign_id,lookup_digest,code_kind,status,created_at) VALUES($1::uuid,$2::uuid,$3,'PUBLIC_CAMPAIGN_CODE','ACTIVE',$4)`, codeID.String(), campaignID.String(), digest[:], at); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	var displayText string
	var displayVersion int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM player_display_admissions WHERE operation_id=$1::uuid`, displayOperationID.String()).Scan(&displayText, &displayVersion); err != nil {
		t.Fatal(err)
	}
	var audienceText, planText string
	var audienceVersion, planVersion int16
	if err := pool.Raw().QueryRow(ctx, `SELECT audience_policy::text,payload_version FROM redeem_campaigns WHERE campaign_id=$1::uuid`, campaignID.String()).Scan(&audienceText, &audienceVersion); err != nil {
		t.Fatal(err)
	}
	if err := pool.Raw().QueryRow(ctx, `SELECT grant_plan::text,payload_version FROM redeem_reward_bundle_revisions WHERE reward_bundle_revision_id=$1::uuid`, bundleID.String()).Scan(&planText, &planVersion); err != nil {
		t.Fatal(err)
	}
	if displayVersion != payload.Current {
		t.Fatalf("player_display_admissions payload_version=%d want=%d", displayVersion, payload.Current)
	}
	if audienceVersion != 0 || planVersion != 0 {
		t.Fatalf("content payload_version audience=%d plan=%d want=0 (operator SQL writer)", audienceVersion, planVersion)
	}
	var displayDecoded app.Admission
	if err := payload.Decode("player_display_admissions", displayVersion, []byte(displayText), &displayDecoded); err != nil {
		t.Fatalf("display strict decode: %v", err)
	}
	assertSameI5Batch18JSON(t, displayDecoded, admission)
	displayRead, found, err := store.ReadDisplayAdmissionTx(ctx, pool, displayOperationID.String(), false)
	if err != nil || !found {
		t.Fatalf("ReadDisplayAdmissionTx found=%v err=%v", found, err)
	}
	assertSameI5Batch18JSON(t, displayRead, admission)
	var audienceDecoded audienceJSON
	if err := payload.Decode("redeem_campaigns", audienceVersion, []byte(audienceText), &audienceDecoded); err != nil {
		t.Fatalf("audience decode: %v", err)
	}
	if audienceDecoded.MinLevel == nil || *audienceDecoded.MinLevel != 1 || audienceDecoded.MaxLevel == nil || *audienceDecoded.MaxLevel != 80 || len(audienceDecoded.LogicalServers) != 1 || audienceDecoded.LogicalServers[0] != 30 {
		t.Fatalf("audience decoded=%+v", audienceDecoded)
	}
	var planDecoded grant.Plan
	if err := payload.Decode("redeem_reward_bundle_revisions", planVersion, []byte(planText), &planDecoded); err != nil {
		t.Fatalf("grant plan decode: %v", err)
	}
	assertSameI5Batch18JSON(t, planDecoded, plan)
	readTransaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = readTransaction.Rollback(ctx) }()
	_, campaign, readPlan, err := store.LockRedeemByDigestTx(ctx, readTransaction, digest)
	if err != nil {
		t.Fatalf("LockRedeemByDigestTx: %v", err)
	}
	if campaign.Campaign.Audience.MinLevel == nil || *campaign.Campaign.Audience.MinLevel != 1 || len(campaign.Campaign.Audience.LogicalServers) != 1 {
		t.Fatalf("campaign audience=%+v", campaign.Campaign.Audience)
	}
	assertSameI5Batch18JSON(t, readPlan, plan)
}

func batch18Actor(player identity.PlayerID) (identity.ActorContext, error) {
	accountUUID, err := ids.NewUUID()
	if err != nil {
		return identity.ActorContext{}, err
	}
	sessionUUID, err := ids.NewUUID()
	if err != nil {
		return identity.ActorContext{}, err
	}
	contextUUID, err := ids.NewUUID()
	if err != nil {
		return identity.ActorContext{}, err
	}
	account, err := identity.AccountIDFrom(accountUUID)
	if err != nil {
		return identity.ActorContext{}, err
	}
	session, err := identity.SessionIDFrom(sessionUUID)
	if err != nil {
		return identity.ActorContext{}, err
	}
	contextID, err := identity.ContextIDFrom(contextUUID)
	if err != nil {
		return identity.ActorContext{}, err
	}
	return identity.ActorContext{
		AccountID:              account,
		AccountUID:             identity.AccountUID("payload-version-account"),
		SessionID:              session,
		ContextID:              contextID,
		LogicalServerID:        30,
		PlayerID:               player,
		ContextGeneration:      1,
		SessionLivenessVersion: 1,
		ContextLivenessVersion: 1,
	}, nil
}

func newBatch18UUIDs() (ids.UUID, ids.UUID, ids.UUID, error) {
	bundle, err := ids.NewUUID()
	if err != nil {
		return ids.UUID{}, ids.UUID{}, ids.UUID{}, err
	}
	campaign, err := ids.NewUUID()
	if err != nil {
		return ids.UUID{}, ids.UUID{}, ids.UUID{}, err
	}
	code, err := ids.NewUUID()
	if err != nil {
		return ids.UUID{}, ids.UUID{}, ids.UUID{}, err
	}
	return bundle, campaign, code, nil
}

func assertSameI5Batch18JSON(t *testing.T, got, want any) {
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
