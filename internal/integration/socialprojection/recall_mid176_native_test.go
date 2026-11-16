//go:build postgres && socialintegration

package socialprojection_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/frienddmstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialfriendbase"
	"gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrecall "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

func TestSocialRecallMID176ProductionPresentationReloadNative(t *testing.T) {
	fixture := fresh(t)
	caller := identity.PlayerID(100001)
	activeTarget := identity.PlayerID(100002)
	completedTarget := identity.PlayerID(100003)
	fixture.sql(`DELETE FROM social_recall_tasks WHERE caller_player_id=ANY($1::bigint[]) OR target_player_id=ANY($1::bigint[])`, []int64{int64(caller), int64(activeTarget), int64(completedTarget)})
	fixture.sql(`DELETE FROM social_recall_awards WHERE player_id=ANY($1::bigint[])`, []int64{int64(caller), int64(activeTarget), int64(completedTarget)})
	fixture.sql(`DELETE FROM gxb_operation_receipts WHERE owner_key=ANY($1::text[])`, []string{fmt.Sprint(caller), fmt.Sprint(activeTarget), fmt.Sprint(completedTarget)})
	fixture.player(caller)
	fixture.player(activeTarget)
	fixture.player(completedTarget)
	fixture.friend(caller, activeTarget)
	fixture.friend(caller, completedTarget)

	content := contentstore.Store{Queryer: fixture.p}
	revision, err := content.ActiveRevision(ctx, fixture.p)
	if err != nil {
		t.Fatal(err)
	}
	for _, target := range []identity.PlayerID{activeTarget, completedTarget} {
		fixture.sql(`INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at) VALUES($1,1,100,1,'QUALIFIED_ABSENT',$2,'C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1','MANUAL_PRESERVATION','social176-native','social176-native',1,$3,$4)`, int64(target), revision, fixture.at.Add(-2*time.Hour), fixture.at.Add(-time.Hour))
	}

	actor, bearer := recallGameplayActor(t, fixture, caller)
	seedDurableRecallLogin(t, fixture, activeTarget)
	seedDurableRecallLogin(t, fixture, completedTarget)

	runner := tx.Runner{DB: fixture.p}
	progression := i5store.Store{Queryer: fixture.p}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: content}
	relations := socialrelationstore.Store{}
	recallTargets := socialrecallstore.TargetReader{
		Activity:    i4store.PlayerLoginActivity{},
		Progression: progression,
		Roster:      characterstore.RosterMetricReader{Store: characterstore.Store{Queryer: fixture.p}, Content: content},
		Privilege:   privileges,
		Relations:   relations,
	}
	recallOwner := socialrecallstore.Store{}
	recallService := socialrecall.StartService{
		Timed:         generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: fixture.p}}, Runner: runner},
		Fence:         progression,
		Content:       content,
		Starter:       socialrecall.Starter{Players: i4store.PlayerRootLocker{}, Owner: recallOwner, Targets: recallTargets},
		Projection:    socialrecallstore.DoingProjection{Directory: i4store.TransactionDiscoveryReader{}},
		Receipts:      kernelstore.Store{},
		ReceiptReader: kernelstore.Reader{Queryer: fixture.p},
	}
	if _, err := recallService.Start(ctx, actor, activeTarget, fixture.op()); err != nil {
		t.Fatalf("start active recall: %v", err)
	}
	if _, err := recallService.Start(ctx, actor, completedTarget, fixture.op()); err != nil {
		t.Fatalf("start completed recall: %v", err)
	}
	completeNativeRecall(t, fixture, recallOwner, completedTarget)

	for _, statement := range []string{
		`INSERT INTO player_economy_owners(player_id,state_version,created_at) VALUES($1,1,clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`,
		`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at) VALUES($1,1,0,1,clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`,
		`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES($1,'crystal',1000,1,clock_timestamp()) ON CONFLICT(player_id,resource_key) DO NOTHING`,
	} {
		fixture.sql(statement, int64(caller))
	}
	i5Service := appi5.Service{
		Runner:      runner,
		Store:       progression,
		Content:     content,
		Privileges:  privileges,
		Functions:   appi5.PetStarterFunctionAnnouncements{},
		Directory:   i4store.DirectoryLevelProjection{},
		Backpack:    progression,
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: fixture.p},
	}
	claimer := socialrecall.ClaimService{
		Timed:         generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: fixture.p}}, Runner: runner},
		Fence:         progression,
		Players:       i4store.PlayerRootLocker{},
		Content:       content,
		Awarder:       socialrecall.Awarder{Players: i4store.PlayerRootLocker{}, Owner: recallOwner, Content: content, Current: recallTargets, Grants: i5Service},
		Receipts:      kernelstore.Store{},
		ReceiptReader: kernelstore.Reader{Queryer: fixture.p},
	}
	if _, err := claimer.Claim(ctx, actor, 100001, fixture.op()); err != nil {
		t.Fatalf("claim completed recall: %v", err)
	}

	presentation := socialpresentation.TransactionReader{Display: publicpresentation.Display()}
	socialReads := socialprojection.Service{
		Runner:         runner,
		PlayerRoots:    i4store.PlayerRootLocker{},
		Relations:      relations,
		Inbox:          socialinboxstore.Store{},
		Directory:      publicpresentation.DiscoveryReader{},
		Presentation:   presentation,
		PresentationAt: presentation,
		Observer:       presentation,
		Recall:         socialrecallstore.RecallProjectionReader{Current: recallTargets},
		Content:        content,
	}
	socialTimed := generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: fixture.p}}, Runner: runner}
	friendMessages := frienddm.Service{
		Timed:       socialTimed,
		Queryer:     fixture.p,
		Store:       frienddmstore.Store{},
		Players:     i4store.PlayerRootLocker{},
		Privacy:     socialrelation.FriendDMPrivacyProvider{Store: relations},
		Observer:    presentation,
		Content:     content,
		Entitlement: appi5.EmoticonEntitlementReader{Store: progression, Content: content},
		Owner:       presencestore.Store{Queryer: fixture.p},
	}
	friendBase := socialfriendbase.Service{FriendDM: friendMessages, Projection: socialReads}
	secret := []byte("social176-native-http-secret-0123456789")
	authority := i4store.RealtimeAuthority{Queryer: fixture.p, DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "social176-v1"}
	buildHandler := func() http.Handler {
		router := httpedge.NewRouter()
		if err := stockruntime.RegisterSocialRoutes(router, stockruntime.SocialDispatcher{Authority: authority, Projection: friendBase}); err != nil {
			t.Fatal(err)
		}
		admission, err := httpedge.NewAdmission(8)
		if err != nil {
			t.Fatal(err)
		}
		return httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router}
	}
	postBase := func(handler http.Handler) map[string]any {
		parameters := map[string]any{"mid": int64(176), "token": bearer, "region": int64(1), "app_v": "1.0", "platform": "3", "v_": "123"}
		payload, err := json.Marshal(parameters)
		if err != nil {
			t.Fatal(err)
		}
		request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(string(payload))))
		request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusOK {
			t.Fatalf("MID176 status=%d body=%s", response.Code, response.Body.String())
		}
		var body map[string]any
		decoder := json.NewDecoder(bytes.NewReader(response.Body.Bytes()))
		decoder.UseNumber()
		if err := decoder.Decode(&body); err != nil {
			t.Fatalf("decode MID176 body %q: %v", response.Body.String(), err)
		}
		return body
	}
	first := postBase(buildHandler())
	assertRecallBaseWire(t, first, activeTarget, completedTarget)
	second := postBase(buildHandler())
	assertRecallBaseWire(t, second, activeTarget, completedTarget)
	for _, key := range []string{"doing_recall", "done_recall", "got_recall", "recall_awarded"} {
		firstJSON, _ := json.Marshal(first[key])
		secondJSON, _ := json.Marshal(second[key])
		if string(firstJSON) != string(secondJSON) {
			t.Fatalf("MID176 reload changed %s: %s vs %s", key, firstJSON, secondJSON)
		}
	}
}

func recallGameplayActor(t *testing.T, fixture *fixture, player identity.PlayerID) (identity.ActorContext, string) {
	t.Helper()
	var accountText, accountUID string
	if err := fixture.p.QueryRow(ctx, `SELECT a.account_id::text,a.account_uid FROM accounts a JOIN players p USING(account_id) WHERE p.player_id=$1`, int64(player)).Scan(&accountText, &accountUID); err != nil {
		t.Fatal(err)
	}
	accountUUID, err := ids.ParseUUID(accountText)
	if err != nil {
		t.Fatal(err)
	}
	sessionUUID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	contextUUID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	accountID, err := identity.AccountIDFrom(accountUUID)
	if err != nil {
		t.Fatal(err)
	}
	sessionID, err := identity.SessionIDFrom(sessionUUID)
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(contextUUID)
	if err != nil {
		t.Fatal(err)
	}
	server := identity.LogicalServerID(1)
	at := fixture.now()
	fixture.sql(`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, sessionUUID.String(), accountUUID.String(), at)
	fixture.sql(`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at) VALUES($1,$2,$3,$4,$5,1,$6)`, contextUUID.String(), sessionUUID.String(), accountUUID.String(), int32(server), int64(player), at)
	gameplayContext := identity.GameplayContext{ID: contextID, SessionID: sessionID, AccountID: accountID, LogicalServerID: server, PlayerID: player, ContextGeneration: 1}
	secret := []byte("social176-native-http-secret-0123456789")
	bearer, err := identity.DeriveGameplayBearer(secret, gameplayContext)
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer(secret, bearer)
	if err != nil {
		t.Fatal(err)
	}
	credentialUUID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	fixture.sql(`INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at) VALUES($1,$2,$3,$4,1,'social176-v1',$5)`, credentialUUID.String(), contextUUID.String(), sessionUUID.String(), digest[:], at)
	actor := identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID(accountUID), SessionID: sessionID, ContextID: contextID, LogicalServerID: server, PlayerID: player, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	return actor, bearer
}

func seedDurableRecallLogin(t *testing.T, fixture *fixture, player identity.PlayerID) {
	t.Helper()
	sourceOperation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := fixture.at.Add(-9 * 24 * time.Hour)
	transaction, err := fixture.p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	actor := identity.ActorContext{PlayerID: player, LogicalServerID: identity.LogicalServerID(1)}
	operationContext := operation.Context{ID: sourceOperation, StartedAt: at}
	if err := (i4store.PlayerLoginActivity{}).ReconcileCharacterLogin(ctx, transaction, actor, operationContext, at); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func completeNativeRecall(t *testing.T, fixture *fixture, owner socialrecallstore.Store, target identity.PlayerID) {
	t.Helper()
	transaction, err := fixture.p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	previous, exists, err := owner.ReadActiveRecallForTargetTx(ctx, transaction, target)
	if err != nil || !exists {
		t.Fatalf("active recall missing for %d: %v", target, err)
	}
	completedAt := fixture.now()
	next := previous
	next.Task, _, err = previous.Task.Complete(completedAt)
	if err != nil || next.Task.Status != domainrecall.StatusCompleted {
		t.Fatalf("complete recall: status=%s error=%v", next.Task.Status, err)
	}
	next.StateVersion++
	next.UpdatedAt = completedAt.UTC()
	if err := owner.SaveRecallLoginTransitionTx(ctx, transaction, previous, next); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func assertRecallBaseWire(t *testing.T, body map[string]any, activeTarget, completedTarget identity.PlayerID) {
	t.Helper()
	for _, key := range []string{"server_time", "blacklist", "friend_list", "notice_list", "request_list", "offline_msg_list", "send_gift_count", "receive_gift_count", "doing_recall", "done_recall", "got_recall", "recall_awarded"} {
		if _, exists := body[key]; !exists {
			t.Fatalf("MID176 omitted required field %q: %#v", key, body)
		}
	}
	friends, ok := body["friend_list"].([]any)
	if !ok || len(friends) != 2 {
		t.Fatalf("MID176 friend list: %#v", body["friend_list"])
	}
	activeFriend, ok := friends[0].(map[string]any)
	if !ok || recallWireNumber(t, activeFriend["player_id"]) != int64(activeTarget) || recallWireNumber(t, activeFriend["recalling_friend"]) != 1 {
		t.Fatalf("MID176 active friend row: %#v", friends[0])
	}
	completedFriend, ok := friends[1].(map[string]any)
	if !ok || recallWireNumber(t, completedFriend["player_id"]) != int64(completedTarget) || recallWireNumber(t, completedFriend["recalling_friend"]) != 0 {
		t.Fatalf("MID176 completed friend row: %#v", friends[1])
	}
	doing, ok := body["doing_recall"].([]any)
	if !ok || len(doing) != 1 {
		t.Fatalf("MID176 doing recall: %#v", body["doing_recall"])
	}
	doingRow, ok := doing[0].(map[string]any)
	if !ok || recallWireNumber(t, doingRow["player_id"]) != int64(activeTarget) || doingRow["player_name"] != fmt.Sprint(activeTarget) || recallWireNumber(t, doingRow["recalling_time"]) <= 0 {
		t.Fatalf("MID176 doing recall row: %#v", doing[0])
	}
	done, ok := body["done_recall"].([]any)
	if !ok || len(done) != 1 {
		t.Fatalf("MID176 done recall: %#v", body["done_recall"])
	}
	doneRow, ok := done[0].(map[string]any)
	if !ok || recallWireNumber(t, doneRow["player_id"]) != int64(completedTarget) || doneRow["player_name"] != fmt.Sprint(completedTarget) {
		t.Fatalf("MID176 done recall row: %#v", done[0])
	}
	for _, key := range []string{"lev", "cur_lev", "partner_num", "cur_partner_num", "charge", "cur_charge"} {
		if _, exists := doneRow[key]; !exists {
			t.Fatalf("MID176 done recall omitted %q: %#v", key, doneRow)
		}
	}
	got, ok := body["got_recall"].([]any)
	if !ok || len(got) != 2 || recallWireNumber(t, got[0]) != int64(activeTarget) || recallWireNumber(t, got[1]) != int64(completedTarget) {
		t.Fatalf("MID176 got recall: %#v", body["got_recall"])
	}
	awarded, ok := body["recall_awarded"].([]any)
	if !ok || len(awarded) != 1 || recallWireNumber(t, awarded[0]) != 100001 {
		t.Fatalf("MID176 awarded recall: %#v", body["recall_awarded"])
	}
}

func recallWireNumber(t *testing.T, value any) int64 {
	t.Helper()
	number, ok := value.(json.Number)
	if !ok {
		t.Fatalf("MID176 value is not a JSON number: %#v", value)
	}
	integer, err := number.Int64()
	if err != nil {
		t.Fatal(err)
	}
	return integer
}
