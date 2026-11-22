//go:build postgres

package socialrecallstore_test

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func openRecallStartPool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_SOCIAL_RECALL_START_DSN")
	if dsn == "" {
		t.Skip("explicit own migrated PostgreSQL database required; skip is not native proof")
	}
	pool, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

type recallWorld struct {
	pool       *postgres.Pool
	revision   string
	caller     identity.PlayerID
	target     identity.PlayerID
	callerName string
	targetName string
	actor      identity.ActorContext
	rules      domain.StartRules
	service    socialrecall.StartService
	content    contentstore.Store
	store      socialrecallstore.Store
}

type recallIdentity struct{ raw string }

func newRecallIdentity(t *testing.T, source byte) (ids.UUID, recallIdentity) {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	id[15] = source
	return id, recallIdentity{raw: id.String()}
}

func stringifyPlayer(player identity.PlayerID) string { return strconv.FormatInt(int64(player), 10) }

func mustUUID(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}

func dbClock(t *testing.T, pool *postgres.Pool) time.Time {
	t.Helper()
	var at time.Time
	if err := pool.Raw().QueryRow(context.Background(), "SELECT clock_timestamp()").Scan(&at); err != nil {
		t.Fatal(err)
	}
	return at.UTC()
}

// seedRecallWorld writes exact valid owner facts for the native composition.
// These rows are structural test fixtures over the production schemas; every
// read under test still goes through the owning production adapter.
func clearRecallWorld(t *testing.T, pool *postgres.Pool, caller, target identity.PlayerID) {
	t.Helper()
	ctx := context.Background()
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM gxb_operation_receipts WHERE owner_key IN ($1,$2)`, stringifyPlayer(caller), stringifyPlayer(target)); err != nil {
		t.Fatalf("clear fixture receipts: %v", err)
	}
	rows, err := pool.Raw().Query(ctx, `SELECT account_id::text FROM players WHERE player_id IN ($1,$2)`, int64(caller), int64(target))
	if err != nil {
		t.Fatalf("clear fixture accounts read: %v", err)
	}
	var accounts []string
	for rows.Next() {
		var account string
		if err := rows.Scan(&account); err != nil {
			t.Fatal(err)
		}
		accounts = append(accounts, account)
	}
	rows.Close()
	for _, statement := range []string{
		`DELETE FROM social_recall_awards WHERE player_id IN ($1,$2)`,
		`DELETE FROM social_recall_tasks WHERE caller_player_id IN ($1,$2) OR target_player_id IN ($1,$2)`,
		`DELETE FROM realtime_presence_leases WHERE player_id IN ($1,$2)`,
		`DELETE FROM player_login_observations WHERE player_id IN ($1,$2)`,
		`DELETE FROM commerce_privilege_roots WHERE player_id IN ($1,$2)`,
		`DELETE FROM player_social_presence WHERE player_id IN ($1,$2)`,
		`DELETE FROM social_friendships WHERE player_low_id IN ($1,$2) OR player_high_id IN ($1,$2)`,
		`DELETE FROM player_social_roots WHERE player_id IN ($1,$2)`,
		`DELETE FROM player_hero_roots WHERE player_id IN ($1,$2)`,
		`DELETE FROM player_progression WHERE player_id IN ($1,$2)`,
		`DELETE FROM player_directory_profiles WHERE player_id IN ($1,$2)`,
		`DELETE FROM gameplay_context_credentials WHERE context_id IN (SELECT context_id FROM gameplay_contexts WHERE player_id IN ($1,$2))`,
		`DELETE FROM gameplay_contexts WHERE player_id IN ($1,$2)`,
		`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE player_id IN ($1,$2))`,
		`DELETE FROM players WHERE player_id IN ($1,$2)`,
	} {
		if _, err := pool.Raw().Exec(ctx, statement, int64(caller), int64(target)); err != nil {
			t.Fatalf("clear fixture: %v: %v", err, statement)
		}
	}
	if len(accounts) > 0 {
		if _, err := pool.Raw().Exec(ctx, `DELETE FROM accounts WHERE account_id::text=ANY($1)`, accounts); err != nil {
			t.Fatalf("clear fixture accounts: %v", err)
		}
	}
}

func seedRecallWorld(t *testing.T, pool *postgres.Pool, caller, target identity.PlayerID, names [2]string) *recallWorld {
	t.Helper()
	ctx := context.Background()
	clearRecallWorld(t, pool, caller, target)
	t.Cleanup(func() { clearRecallWorld(t, pool, caller, target) })
	now := dbClock(t, pool)
	content := contentstore.Store{Queryer: pool}
	revision, err := content.ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	callerAccount, targetAccount := mustUUID(t), mustUUID(t)
	callerSession, callerContext := mustUUID(t), mustUUID(t)
	activityOperation := mustUUID(t)

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	statements := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',$3),($4,$5,'ACTIVE',$3)`,
			[]any{callerAccount.String(), "social40-caller-" + callerAccount.String(), now.Add(-12 * 24 * time.Hour), targetAccount.String(), "social40-target-" + targetAccount.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`,
			[]any{callerSession.String(), callerAccount.String(), now.Add(-24 * time.Hour)}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,$3,'social40-native'),($4,$5,1,$3,'social40-native')`,
			[]any{int64(caller), callerAccount.String(), now.Add(-12 * 24 * time.Hour), int64(target), targetAccount.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at) VALUES($1,$2,$3,1,$4,1,$5)`,
			[]any{callerContext.String(), callerSession.String(), callerAccount.String(), int64(caller), now.Add(-24 * time.Hour)}},
		{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at) VALUES($1,51,10,1,$2)`,
			[]any{int64(target), now.Add(-time.Hour)}},
		{`INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at) VALUES($1,1,0,7,$2,$2)`,
			[]any{int64(target), now.Add(-time.Hour)}},
		{`INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at) VALUES($1,1,100,1,'QUALIFIED_ABSENT',$2,$3,$4,'social40-native','social40-native',1,$5,$6)`,
			[]any{int64(target), revision, "C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1", "MANUAL_PRESERVATION", now.Add(-2 * time.Hour), now.Add(-time.Hour)}},
		{`INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at) VALUES($1,1,$3,$3),($2,1,$3,$3)`,
			[]any{int64(caller), int64(target), now.Add(-12 * 24 * time.Hour)}},
		{`INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,state_version,updated_at) VALUES($1,$2,1,true,$3,1,$3)`,
			[]any{int64(min(caller, target)), int64(max(caller, target)), now.Add(-10 * 24 * time.Hour)}},
		{`INSERT INTO player_social_presence(player_id,last_seen_at,created_at,updated_at) VALUES($1,$2,$2,$2)`,
			[]any{int64(target), now.Add(-8 * 24 * time.Hour)}},
		{`INSERT INTO player_login_observations(player_id,logical_server_id,last_login_at,source_operation_id,state_version) VALUES($1,1,$2,$3,1)`,
			[]any{int64(target), now.Add(-9 * 24 * time.Hour), activityOperation.String()}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,$2,51,$4,$4),($3,$5,51,$4,$4)`,
			[]any{int64(caller), names[0], int64(target), now.Add(-time.Hour), names[1]}},
	}
	for _, statement := range statements {
		if _, err := transaction.Exec(ctx, statement.sql, statement.args...); err != nil {
			t.Fatalf("%v: %v", err, statement.sql)
		}
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	rules, err := content.SocialRecallRulesTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	progression := i5store.Store{Queryer: pool}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: content}
	store := socialrecallstore.Store{}
	service := socialrecall.StartService{
		Timed:   generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: tx.Runner{DB: pool}},
		Fence:   progression,
		Content: content,
		Starter: socialrecall.Starter{
			Players: i4store.PlayerRootLocker{},
			Owner:   store,
			Targets: socialrecallstore.TargetReader{
				Activity:    i4store.PlayerLoginActivity{},
				Progression: progression,
				Roster:      characterstore.RosterMetricReader{Store: characterstore.Store{Queryer: pool}, Content: content},
				Privilege:   privileges,
				Relations:   socialrelationstore.Store{},
			},
		},
		Projection:    socialrecallstore.DoingProjection{Directory: i4store.TransactionDiscoveryReader{}},
		Receipts:      kernelstore.Store{},
		ReceiptReader: kernelstore.Reader{Queryer: pool},
	}
	accountID, _ := identity.AccountIDFrom(callerAccount)
	sessionID, _ := identity.SessionIDFrom(callerSession)
	contextID, _ := identity.ContextIDFrom(callerContext)
	return &recallWorld{
		pool: pool, revision: revision, caller: caller, target: target,
		callerName: names[0], targetName: names[1],
		actor:   identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID("social40-caller-" + callerAccount.String()), SessionID: sessionID, ContextID: contextID, LogicalServerID: 1, PlayerID: caller, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1},
		rules:   rules,
		service: service,
		content: content,
		store:   store,
	}
}

func operationFor(t *testing.T) operation.Context {
	t.Helper()
	seed := [32]byte{}
	for index := range seed {
		seed[index] = byte(index + 1)
	}
	return operation.Context{ID: mustUUID(t), StartedAt: time.Now().UTC(), EntropySeed: seed, Policies: policy.Set{}}
}

func TestRecallStartServiceNativeComposition(t *testing.T) {
	pool := openRecallStartPool(t)
	world := seedRecallWorld(t, pool, 130001, 130002, [2]string{"Caller130001", "Target130002"})
	ctx := context.Background()
	current := operationFor(t)
	body, err := world.service.Start(ctx, world.actor, world.target, current)
	if err != nil {
		t.Fatalf("full StartService failed: %v", err)
	}
	rows, ok := body["doing_recall"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("success doing_recall shape: %#v", body)
	}
	entry, ok := rows[0].(map[string]any)
	if !ok {
		t.Fatalf("doing entry shape: %#v", rows[0])
	}
	if entry["player_id"] != int64(world.target) || entry["player_name"] != world.targetName {
		t.Fatalf("doing identity mismatch: %#v", entry)
	}

	var (
		caller, target, server, stateVersion                   int64
		revision, policyVersion, status                        string
		startedAt, expiresAt, updatedAt                        time.Time
		academyLevel, ownedHeros, chargeTotal                  int64
		storedPolicy, storedSchema, storedActor, storedContext string
		storedStarted                                          time.Time
		payload                                                string
	)
	err = pool.Raw().QueryRow(ctx, `SELECT caller_player_id,target_player_id,logical_server_id,content_revision,policy_version,started_at,expires_at,status,baseline_academy_level,baseline_owned_hero_count,baseline_charge_total,state_version,updated_at FROM social_recall_tasks WHERE operation_id=$1::uuid`, current.ID.String()).Scan(&caller, &target, &server, &revision, &policyVersion, &startedAt, &expiresAt, &status, &academyLevel, &ownedHeros, &chargeTotal, &stateVersion, &updatedAt)
	if err != nil {
		t.Fatalf("committed task missing: %v", err)
	}
	if caller != int64(world.caller) || target != int64(world.target) || server != 1 || revision != world.revision || policyVersion != socialrecall.RecallPolicyVersion || status != "ACTIVE" || academyLevel != 51 || ownedHeros != 0 || chargeTotal != 100 || stateVersion != 1 || !expiresAt.Equal(startedAt.Add(72*time.Hour)) || !updatedAt.Equal(startedAt) {
		t.Fatalf("committed task values: %d %d %d %s %s %s %d %d %d %d %v %v %v", caller, target, server, revision, policyVersion, status, academyLevel, ownedHeros, chargeTotal, stateVersion, startedAt, expiresAt, updatedAt)
	}
	if entry["recalling_time"] != startedAt.Unix() {
		t.Fatalf("client epoch mismatch: %v vs %d", entry["recalling_time"], startedAt.Unix())
	}
	err = pool.Raw().QueryRow(ctx, `SELECT result_payload::text,result_schema,policy_version,actor_account_uid,context_id::text,operation_started_at FROM gxb_operation_receipts WHERE semantic_key=$1`, current.ID.String()).Scan(&payload, &storedSchema, &storedPolicy, &storedActor, &storedContext, &storedStarted)
	if err != nil {
		t.Fatalf("terminal receipt missing from same commit: %v", err)
	}
	if storedSchema != "gxb.social.recall.start.v1" || storedPolicy != socialrecall.RecallPolicyVersion || storedActor != string(world.actor.AccountUID) || storedContext != world.actor.ContextID.UUID().String() || storedStarted.UnixMicro() != current.StartedAt.UnixMicro() {
		t.Fatalf("receipt identity: %s %s %s %s %v", storedSchema, storedPolicy, storedActor, storedContext, storedStarted)
	}
	var terminal struct {
		OperationID string
		Record      struct {
			ContentRevision string
			Task            struct {
				OperationID string
				Status      string
			}
		}
		Doing []socialrecall.DoingRecall
	}
	decoder := json.NewDecoder(strings.NewReader(payload))
	if err := decoder.Decode(&terminal); err != nil {
		t.Fatal(err)
	}
	if terminal.OperationID != current.ID.String() || terminal.Record.Task.OperationID != current.ID.String() || terminal.Record.Task.Status != "ACTIVE" || terminal.Record.ContentRevision != world.revision || len(terminal.Doing) != 1 || terminal.Doing[0].PlayerID != world.target || terminal.Doing[0].PlayerName != world.targetName || terminal.Doing[0].RecallingTime != startedAt.Unix() {
		t.Fatalf("receipt terminal mismatch: %+v", terminal)
	}
	var policyRefs string
	if err := pool.Raw().QueryRow(ctx, `SELECT operation_policy_refs::text FROM gxb_operation_receipts WHERE semantic_key=$1`, current.ID.String()).Scan(&policyRefs); err != nil {
		t.Fatal(err)
	}
	for _, wanted := range []string{world.revision, characterasset.RosterMetricPolicy, socialrecall.RecallPolicyVersion} {
		if !strings.Contains(policyRefs, wanted) {
			t.Fatalf("receipt policy refs missing %s: %s", wanted, policyRefs)
		}
	}
	if _, err := hex.DecodeString(world.revision); err != nil {
		t.Fatal(err)
	}
}

func TestRecallStartServiceNativeUnnamedTarget(t *testing.T) {
	pool := openRecallStartPool(t)
	world := seedRecallWorld(t, pool, 135001, 135002, [2]string{"Caller135001", ""})
	body, err := world.service.Start(context.Background(), world.actor, world.target, operationFor(t))
	if err != nil {
		t.Fatalf("unnamed recall target refused: %v", err)
	}
	rows, ok := body["doing_recall"].([]any)
	if !ok || len(rows) != 1 || rows[0].(map[string]any)["player_name"] != "" {
		t.Fatalf("doing_recall = %+v", body)
	}
}
