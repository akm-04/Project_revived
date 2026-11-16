//go:build postgres

package i4store_test

import (
	"context"
	"crypto/sha256"
	"errors"
	"net/http"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type supersededBootstrapBinder struct{}

func (supersededBootstrapBinder) BindCharacterBootstrapOperation(_ context.Context, _ tx.Queryer, current operation.Context) (operation.Context, error) {
	return current, nil
}

func supersededIdentifier(t *testing.T) ids.UUID {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value
}

func supersededRequest(token string, at time.Time) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation:  operation.Context{StartedAt: at},
		MID:        2784,
		ReceivedAt: at,
		Params:     map[string]any{"token": token, "region": int64(1)},
		Claims:     wire.CredentialClaims{Token: token, Region: 1},
	}}
}

// A late request from a context that a server switch superseded answers 409 with
// an empty error_msg, so the newly switched scene is not restarted. A revoked or
// expired session still answers 401 with the message.lua 20003 relog text.
func TestContextSupersededBearerAnswersQuietRefusal(t *testing.T) {
	dsn := os.Getenv("GXB_CONTEXT_SUPERSEDED_DSN")
	if dsn == "" {
		t.Fatal("GXB_CONTEXT_SUPERSEDED_DSN is required")
	}
	ctx := context.Background()
	pool, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	account, session := supersededIdentifier(t), supersededIdentifier(t)
	secret := []byte("context-superseded-native-secret")
	credentials := bootstrap.AccountCredentials{SID: "test-sid-" + session.String(), LoginToken: "test-login-" + session.String()}
	execute := func(statement string, arguments ...any) {
		t.Helper()
		if _, err := pool.Raw().Exec(ctx, statement, arguments...); err != nil {
			t.Fatal(err)
		}
	}
	execute(`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3)`, account.String(), "context-superseded-"+account.String(), at.Add(-time.Hour))
	execute(`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, session.String(), account.String(), at.Add(-time.Hour))
	for _, credential := range []struct{ kind, label, raw string }{{"SID", "sid", credentials.SID}, {"LOGIN_TOKEN", "login_token", credentials.LoginToken}} {
		digest, err := identity.DigestCredential(secret, credential.label, credential.raw)
		if err != nil {
			t.Fatal(err)
		}
		execute(`INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,$5)`, supersededIdentifier(t).String(), session.String(), credential.kind, digest[:], at.Add(-time.Hour))
	}
	service := i4store.BootstrapService{
		Runner: tx.Runner{DB: pool}, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool},
		DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "context-superseded-native",
		BootstrapProfileVersion: "context-superseded-native", OperationBinder: supersededBootstrapBinder{},
	}
	currentOperation := func(startedAt time.Time) operation.Context {
		id := supersededIdentifier(t)
		return operation.Context{ID: id, StartedAt: startedAt, EntropySeed: sha256.Sum256([]byte(id.String()))}
	}
	if _, err := service.MID18(ctx, credentials, currentOperation(at)); err != nil {
		t.Fatal(err)
	}
	first, err := service.MID1(ctx, bootstrap.RuntimeMID1Request{Credentials: credentials, Region: 1, Operation: currentOperation(at)})
	if err != nil {
		t.Fatal(err)
	}
	switchedAt := at.Add(time.Minute)
	second, err := service.MID1(ctx, bootstrap.RuntimeMID1Request{Credentials: credentials, Region: 2, Operation: currentOperation(switchedAt)})
	if err != nil {
		t.Fatal(err)
	}
	var endReason string
	if err := pool.QueryRow(ctx, `SELECT end_reason FROM gameplay_contexts WHERE context_id=$1`, first.ContextPlan.Selected.ID.UUID().String()).Scan(&endReason); err != nil || endReason != "superseded" {
		t.Fatalf("old context end_reason=%q err=%v", endReason, err)
	}

	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "context-superseded-native"}
	replayAt := switchedAt.Add(time.Minute)
	if _, err := authority.ResolveGameplayBearer(ctx, first.Token, replayAt); !errors.Is(err, i4store.ErrContextSuperseded) {
		t.Fatalf("old bearer classification: %v, want ErrContextSuperseded", err)
	}
	dispatcher := stockruntime.LobbyDispatcher{Authority: authority}
	response := dispatcher.Dispatch(ctx, supersededRequest(first.Token, replayAt))
	if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35028) || response.Body["error_msg"] != "" {
		t.Fatalf("superseded bearer reply: status=%d body=%v", response.HTTPStatus, response.Body)
	}

	actor, err := authority.ResolveGameplayBearer(ctx, second.Token, replayAt)
	if err != nil || actor.ContextID != second.ContextPlan.Selected.ID {
		t.Fatalf("new bearer actor=%v err=%v", actor, err)
	}
	execute(`UPDATE account_sessions SET revoked_at=clock_timestamp(),revocation_reason='context-superseded-native' WHERE session_id=$1`, session.String())
	response = dispatcher.Dispatch(ctx, supersededRequest(second.Token, replayAt))
	if response.HTTPStatus != http.StatusUnauthorized || response.Body["error_code"] != int64(20003) || response.Body["error_msg"] == "" {
		t.Fatalf("revoked session reply: status=%d body=%v", response.HTTPStatus, response.Body)
	}

	execute(`UPDATE account_sessions SET revoked_at=NULL,revocation_reason=NULL,absolute_expires_at=$2 WHERE session_id=$1`, session.String(), replayAt.Add(-time.Second))
	if _, err := authority.ResolveGameplayBearer(ctx, first.Token, replayAt); !errors.Is(err, i4store.ErrGameplayBearerNotLive) {
		t.Fatalf("expired superseded bearer classification: %v, want ErrGameplayBearerNotLive", err)
	}
	response = dispatcher.Dispatch(ctx, supersededRequest(first.Token, replayAt))
	if response.HTTPStatus != http.StatusUnauthorized || response.Body["error_code"] != int64(20003) || response.Body["error_msg"] == "" {
		t.Fatalf("expired superseded bearer reply: status=%d body=%v", response.HTTPStatus, response.Body)
	}
}
