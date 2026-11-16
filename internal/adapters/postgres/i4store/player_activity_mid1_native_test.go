//go:build postgres

package i4store_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/application/bootstrap"
	recall "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type activityLoginTime struct{ at time.Time }

func (clock *activityLoginTime) Now(context.Context) (time.Time, error) { return clock.at, nil }

type activityBootstrapBinder struct{}

func (activityBootstrapBinder) BindCharacterBootstrapOperation(_ context.Context, _ tx.Queryer, current operation.Context) (operation.Context, error) {
	return current, nil
}

var rejectedActivityLogin = errors.New("controlled post-recall login refusal")

type rejectActivityLogin struct{}

func (rejectActivityLogin) Name() string { return "test.post-recall-refusal" }
func (rejectActivityLogin) ReconcileCharacterLogin(context.Context, tx.Tx, identity.ActorContext, operation.Context, time.Time) error {
	return rejectedActivityLogin
}

func TestCanonicalActivityAndRecallThroughFreshRetainedMID1(t *testing.T) {
	databaseURL := os.Getenv("GXB_PLAYER_ACTIVITY_MID1_DSN")
	if databaseURL == "" {
		t.Skip("dedicated fresh migrated psoc database required")
	}
	ctx := context.Background()
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	at := time.Date(2026, 11, 6, 0, 0, 0, 0, time.UTC)
	identifier := func() ids.UUID {
		value, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		return value
	}
	account, session, callerAccount := identifier(), identifier(), identifier()
	accountName := "activity-mid1-" + account.String()
	secret := []byte("controlled-native-activity-secret")
	credentials := bootstrap.AccountCredentials{SID: "test-sid-" + session.String(), LoginToken: "test-login-" + session.String()}
	execute := func(statement string, arguments ...any) {
		t.Helper()
		transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		defer transaction.Rollback(ctx)
		if _, err := transaction.Exec(ctx, statement, arguments...); err != nil {
			t.Fatal(err)
		}
		if err := transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	execute(`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3),($4,$5,'ACTIVE',$3)`, account.String(), accountName, at.Add(-time.Hour), callerAccount.String(), "activity-caller-"+callerAccount.String())
	execute(`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, session.String(), account.String(), at.Add(-time.Hour))
	for _, credential := range []struct{ kind, label, raw string }{{"SID", "sid", credentials.SID}, {"LOGIN_TOKEN", "login_token", credentials.LoginToken}} {
		digest, err := identity.DigestCredential(secret, credential.label, credential.raw)
		if err != nil {
			t.Fatal(err)
		}
		execute(`INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,$5)`, identifier().String(), session.String(), credential.kind, digest[:], at.Add(-time.Hour))
	}
	clock := &activityLoginTime{at: at}
	owner := i4store.PlayerLoginActivity{}
	reconciler := recall.LoginReconciler{Owner: socialrecallstore.Store{}, Players: i4store.PlayerRootLocker{}}
	service := i4store.BootstrapService{Runner: tx.Runner{DB: pool}, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}, DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "activity-native-v1", BootstrapProfileVersion: "activity-native", OperationBinder: activityBootstrapBinder{}, LoginTime: clock, LoginReconcilers: []bootstrap.CharacterLoginReconciler{owner, reconciler}}
	currentOperation := func() operation.Context {
		return operation.Context{ID: identifier(), StartedAt: clock.at, EntropySeed: [32]byte{1, 2, 3}}
	}
	if _, err := service.MID18(ctx, credentials, currentOperation()); err != nil {
		t.Fatal(err)
	}
	first, err := service.MID1(ctx, bootstrap.RuntimeMID1Request{Credentials: credentials, Region: 1, Operation: currentOperation()})
	if err != nil || !first.PlayerCreated {
		t.Fatal("fresh MID1 failed", err)
	}
	observed, known, err := owner.ReadPlayerActivityTx(ctx, pool, first.Player.PlayerID, clock.at)
	if err != nil || !known || !observed.LastLoginAt.Equal(clock.at) || observed.StateVersion != 1 {
		t.Fatal("fresh MID1 missed canonical activity", observed, known, err)
	}
	caller := allocateActivityPlayerID(t, pool, 1)
	execute(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,$3,'activity-native')`, int64(caller), callerAccount.String(), at)
	task, err := domain.NewTask(caller, first.Player.PlayerID, 1, identifier(), at.Add(time.Minute), 72*time.Hour, domain.Baseline{AcademyLevel: 51, OwnedHeroCount: 3})
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	record := recall.TaskRecord{Task: task, StateVersion: 1, UpdatedAt: task.StartedAt, ContentRevision: strings.Repeat("a", 64), PolicyVersion: recall.RecallPolicyVersion}
	if err := (socialrecallstore.Store{}).InsertTaskTx(ctx, transaction, record); err != nil {
		_ = transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	clock.at = at.Add(2 * time.Minute)
	service.LoginReconcilers = append(service.LoginReconcilers, rejectActivityLogin{})
	retainedRequest := bootstrap.RuntimeMID1Request{Credentials: credentials, Region: 1, Operation: currentOperation()}
	if _, err := service.MID1(ctx, retainedRequest); !errors.Is(err, rejectedActivityLogin) {
		t.Fatal("controlled login refusal not returned", err)
	}
	observed, known, err = owner.ReadPlayerActivityTx(ctx, pool, first.Player.PlayerID, clock.at)
	if err != nil || !known || observed.StateVersion != 1 || !observed.LastLoginAt.Equal(at) {
		t.Fatal("failed login committed activity", observed, known, err)
	}
	var status string
	if err := pool.QueryRow(ctx, `SELECT status FROM social_recall_tasks WHERE operation_id=$1`, task.OperationID.String()).Scan(&status); err != nil || status != "ACTIVE" {
		t.Fatal("failed login committed recall", status, err)
	}
	service.LoginReconcilers = service.LoginReconcilers[:2]
	retained, err := service.MID1(ctx, retainedRequest)
	if err != nil {
		t.Fatal("retained MID1 failed", err)
	}
	if retained.PlayerCreated || retained.Player.PlayerID != first.Player.PlayerID || retained.ContextPlan.Selected.ID != first.ContextPlan.Selected.ID || retained.Token != first.Token {
		t.Fatal("retained selection identity changed")
	}
	observed, known, err = owner.ReadPlayerActivityTx(ctx, pool, first.Player.PlayerID, clock.at)
	if err != nil || !known || observed.StateVersion != 2 || !observed.LastLoginAt.Equal(clock.at) {
		t.Fatal("retained MID1 reused stale login observation", observed, known, err)
	}
	var completedAt time.Time
	if err := pool.QueryRow(ctx, `SELECT status,completed_at FROM social_recall_tasks WHERE operation_id=$1`, task.OperationID.String()).Scan(&status, &completedAt); err != nil || status != "COMPLETED" || !completedAt.Equal(clock.at) {
		t.Fatal("retained MID1 did not complete recall", status, completedAt, err)
	}
}
