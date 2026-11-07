//go:build postgres

package socialrecallstore_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

func waitRecallBlocked(t *testing.T, pool *postgres.Pool, blockedPID, holderPID int32, timeout time.Duration) string {
	t.Helper()
	deadline := time.Now().Add(timeout)
	var lastEventType, lastEvent string
	var lastBlockers []int32
	for time.Now().Before(deadline) {
		lastEventType, lastEvent, lastBlockers = "", "", nil
		err := pool.Raw().QueryRow(context.Background(), `SELECT COALESCE(wait_event_type,''),COALESCE(wait_event,''),pg_blocking_pids(pid) FROM pg_stat_activity WHERE pid=$1`, blockedPID).Scan(&lastEventType, &lastEvent, &lastBlockers)
		if err != nil {
			t.Fatalf("read wait graph: %v", err)
		}
		for _, blocker := range lastBlockers {
			if blocker == holderPID {
				if lastEventType != "Lock" {
					t.Fatalf("blocked waiter reported non-lock event %s/%s", lastEventType, lastEvent)
				}
				t.Logf("observed PostgreSQL row-lock contention: holder=%d blocked=%d wait_event_type=%s wait_event=%s", holderPID, blockedPID, lastEventType, lastEvent)
				return lastEvent
			}
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("bounded wait graph did not show holder=%d blocking waiter=%d: type=%q event=%q blockers=%v", holderPID, blockedPID, lastEventType, lastEvent, lastBlockers)
	return ""
}

func TestRecallStartVersusLoginRootContentionNative(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 133001, 133002, [2]string{"Caller133001", "Target133002"})
	at := dbClock(t, pool)
	pins, err := policy.NewSet(policy.Ref{Name: "content", Version: world.revision}, policy.Ref{Name: "roster-metrics", Version: characterasset.RosterMetricPolicy})
	if err != nil {
		t.Fatal(err)
	}
	operationContext := operation.Context{ID: mustUUID(t), StartedAt: at, EntropySeed: [32]byte{9, 8, 7}, Policies: pins}
	request := socialrecall.StartRequest{Caller: world.caller, Target: world.target, LogicalServerID: 1, ContentRevision: world.revision, PolicyVersion: socialrecall.RecallPolicyVersion, Limits: world.rules.Limits, Duration: world.rules.TaskDuration}
	startTransaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer startTransaction.Rollback(ctx)
	var holderPID int32
	if err := startTransaction.QueryRow(ctx, `SELECT pg_backend_pid()`).Scan(&holderPID); err != nil {
		t.Fatal(err)
	}
	scope := tx.Scope{Tx: startTransaction, Operation: operationContext, Attempt: 1, Options: tx.Options{Isolation: tx.Serializable}}
	record, err := world.service.Starter.StartTx(ctx, scope, request, at)
	if err != nil {
		t.Fatalf("start transaction did not reach task insertion: %v", err)
	}
	if record.Task.Target != world.target || record.Task.Status != "ACTIVE" {
		t.Fatalf("start transaction did not insert the expected task: %+v", record)
	}

	loginAt := at.Add(time.Minute)
	loginOperationID := mustUUID(t)
	ready := make(chan int32, 1)
	loginDone := make(chan error, 1)
	go func() {
		// The barrier starts the login before the start commit, so the login side
		// uses ReadCommitted to re-snapshot the task after it unblocks on the root.
		loginTransaction, err := pool.Begin(context.Background(), tx.Options{Isolation: tx.ReadCommitted})
		if err != nil {
			loginDone <- err
			return
		}
		defer loginTransaction.Rollback(context.Background())
		var loginPID int32
		if err := loginTransaction.QueryRow(context.Background(), `SELECT pg_backend_pid()`).Scan(&loginPID); err != nil {
			loginDone <- err
			return
		}
		ready <- loginPID
		actor := identity.ActorContext{PlayerID: world.target, LogicalServerID: 1}
		current := operation.Context{ID: loginOperationID, StartedAt: loginAt}
		if err := (socialrecall.LoginReconciler{Owner: world.store, Players: i4store.PlayerRootLocker{}}).ReconcileCharacterLogin(context.Background(), loginTransaction, actor, current, loginAt); err != nil {
			loginDone <- err
			return
		}
		loginDone <- loginTransaction.Commit(context.Background())
	}()
	loginPID := <-ready
	waitRecallBlocked(t, pool, loginPID, holderPID, 10*time.Second)

	if err := startTransaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-loginDone; err != nil {
		t.Fatalf("login after the start commit failed: %v", err)
	}
	var status string
	var completedAt *time.Time
	var stateVersion int64
	if err := pool.Raw().QueryRow(ctx, `SELECT status,completed_at,state_version FROM social_recall_tasks WHERE operation_id=$1::uuid`, record.Task.OperationID.String()).Scan(&status, &completedAt, &stateVersion); err != nil {
		t.Fatal(err)
	}
	if status != "COMPLETED" || completedAt == nil || !completedAt.Equal(loginAt) || stateVersion != 2 {
		t.Fatalf("login did not complete the start-inserted task: %s %v %d", status, completedAt, stateVersion)
	}
	t.Logf("direct-barrier login attempts observed=1 (no retry loop); task state=COMPLETED version=%d", stateVersion)
}

type recallHTTPBody struct {
	DoingRecall []struct {
		PlayerID      int64  `json:"player_id"`
		PlayerName    string `json:"player_name"`
		RecallingTime int64  `json:"recalling_time"`
	} `json:"doing_recall"`
	ErrorCode *int64 `json:"error_code"`
}

func recallHTTPPost(t *testing.T, handler http.Handler, mid uint16, target identity.PlayerID, bearer string) (*httptest.ResponseRecorder, recallHTTPBody) {
	t.Helper()
	payload, err := json.Marshal(map[string]any{"mid": mid, "friend_id": int64(target), "token": bearer, "region": int64(1)})
	if err != nil {
		t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(string(payload))))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	var body recallHTTPBody
	if response.Body.Len() > 0 {
		if err := json.Unmarshal(response.Body.Bytes(), &body); err != nil {
			t.Fatalf("decode HTTP body %q: %v", response.Body.String(), err)
		}
	}
	return response, body
}

func expectRecallHTTPRefusal(t *testing.T, handler http.Handler, world *recallWorld, bearer, name string) {
	t.Helper()
	response, body := recallHTTPPost(t, handler, 193, world.target, bearer)
	if response.Code == http.StatusOK || body.DoingRecall != nil || body.ErrorCode == nil {
		t.Fatalf("%s: refusal was not a non-200 error without doing_recall: status=%d body=%s", name, response.Code, response.Body.String())
	}
	t.Logf("%s: refusal status=%d error_code=%d", name, response.Code, *body.ErrorCode)
}

func TestRecallMID193HTTPThroughProductionDispatcher(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 134001, 134002, [2]string{"Caller134001", "Target134002"})
	secret := []byte("social40-native-http-secret-0123456789")
	gameplayContext := identity.GameplayContext{ID: world.actor.ContextID, SessionID: world.actor.SessionID, AccountID: world.actor.AccountID, LogicalServerID: 1, PlayerID: world.caller, ContextGeneration: 1}
	bearer, err := identity.DeriveGameplayBearer(secret, gameplayContext)
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer(secret, bearer)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at) VALUES($1,$2,$3,$4,1,'social40-v1',now())`, mustUUID(t).String(), world.actor.ContextID.UUID().String(), world.actor.SessionID.UUID().String(), digest[:]); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM gameplay_context_credentials WHERE context_id=$1::uuid`, world.actor.ContextID.UUID().String())
	})
	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "social40-v1"}
	router := httpedge.NewRouter()
	if err := router.Register(193, stockruntime.SocialRecallStartDispatcher{Authority: authority, Service: world.service}); err != nil {
		t.Fatal(err)
	}
	admission, err := httpedge.NewAdmission(8)
	if err != nil {
		t.Fatal(err)
	}
	handler := httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router}

	targetAccount := func() string {
		var account string
		if err := pool.Raw().QueryRow(ctx, `SELECT account_id::text FROM players WHERE player_id=$1`, int64(world.target)).Scan(&account); err != nil {
			t.Fatal(err)
		}
		return account
	}()

	if _, err := pool.Raw().Exec(ctx, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at) VALUES($1,$2,1,true,now()-interval '1 hour',1,now()-interval '1 hour')`, int64(world.caller), int64(world.target)); err != nil {
		t.Fatal(err)
	}
	expectRecallHTTPRefusal(t, handler, world, bearer, "blocked")
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM social_blocks WHERE blocker_player_id=$1 AND blocked_player_id=$2`, int64(world.caller), int64(world.target)); err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Raw().Exec(ctx, `UPDATE social_friendships SET active=false,ended_at=now(),updated_at=now() WHERE player_low_id=$1 AND player_high_id=$2`, int64(min(world.caller, world.target)), int64(max(world.caller, world.target))); err != nil {
		t.Fatal(err)
	}
	expectRecallHTTPRefusal(t, handler, world, bearer, "nonfriend")
	if _, err := pool.Raw().Exec(ctx, `UPDATE social_friendships SET active=true,ended_at=NULL,updated_at=now() WHERE player_low_id=$1 AND player_high_id=$2`, int64(min(world.caller, world.target)), int64(max(world.caller, world.target))); err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Raw().Exec(ctx, `UPDATE player_login_observations SET last_login_at=now()-interval '1 hour' WHERE player_id=$1`, int64(world.target)); err != nil {
		t.Fatal(err)
	}
	expectRecallHTTPRefusal(t, handler, world, bearer, "recent-login")
	if _, err := pool.Raw().Exec(ctx, `UPDATE player_login_observations SET last_login_at=now()-interval '9 days' WHERE player_id=$1`, int64(world.target)); err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Raw().Exec(ctx, `DELETE FROM player_login_observations WHERE player_id=$1`, int64(world.target)); err != nil {
		t.Fatal(err)
	}
	expectRecallHTTPRefusal(t, handler, world, bearer, "canonical-unknown")
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_login_observations(player_id,logical_server_id,last_login_at,source_operation_id,state_version) VALUES($1,1,now()-interval '9 days',$2,1)`, int64(world.target), mustUUID(t).String()); err != nil {
		t.Fatal(err)
	}

	targetSession, targetContext := mustUUID(t), mustUUID(t)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',now()-interval '9 days',now()-interval '9 days')`, targetSession.String(), targetAccount); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,ended_at,end_reason) VALUES($1,$2,$3,1,$4,1,now()-interval '9 days',now()-interval '9 days','SWITCHED')`, targetContext.String(), targetSession.String(), targetAccount, int64(world.target)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO realtime_presence_leases(gameplay_context_id,physical_role,player_id,realtime_instance_id,connection_generation,connected_at,last_renewed_at,lease_expires_at,realtime_owner_fence) VALUES($1,'WORLD',$2,$3,1,now()-interval '8 days',now()-interval '8 days',now()+interval '1 hour',1)`, targetContext.String(), int64(world.target), mustUUID(t).String()); err != nil {
		t.Fatal(err)
	}
	expectRecallHTTPRefusal(t, handler, world, bearer, "online")
	for _, cleanup := range []string{
		`DELETE FROM realtime_presence_leases WHERE gameplay_context_id=$1::uuid`,
		`DELETE FROM gameplay_contexts WHERE context_id=$1::uuid`,
		`DELETE FROM account_sessions WHERE session_id=$1::uuid`,
	} {
		argument := targetContext.String()
		if strings.Contains(cleanup, "account_sessions") {
			argument = targetSession.String()
		}
		if _, err := pool.Raw().Exec(ctx, cleanup, argument); err != nil {
			t.Fatal(err)
		}
	}

	response, body := recallHTTPPost(t, handler, 193, world.target, bearer)
	if response.Code != http.StatusOK || body.ErrorCode != nil || len(body.DoingRecall) != 1 || body.DoingRecall[0].PlayerID != int64(world.target) || body.DoingRecall[0].PlayerName != world.targetName {
		t.Fatalf("MID193 success body: status=%d body=%s", response.Code, response.Body.String())
	}
	var startedAt time.Time
	if err := pool.Raw().QueryRow(ctx, `SELECT started_at FROM social_recall_tasks WHERE caller_player_id=$1 AND target_player_id=$2 AND status='ACTIVE'`, int64(world.caller), int64(world.target)).Scan(&startedAt); err != nil {
		t.Fatal(err)
	}
	if body.DoingRecall[0].RecallingTime != startedAt.Unix() {
		t.Fatalf("MID193 recalling_time %d != committed start %d", body.DoingRecall[0].RecallingTime, startedAt.Unix())
	}
	t.Logf("MID193 real HTTP success: target=%d name=%q recalling_time=%d", body.DoingRecall[0].PlayerID, body.DoingRecall[0].PlayerName, body.DoingRecall[0].RecallingTime)
}
