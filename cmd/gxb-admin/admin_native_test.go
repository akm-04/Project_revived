//go:build postgres

package main

import (
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
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

type adminBootstrapBinder struct{}

func (adminBootstrapBinder) BindCharacterBootstrapOperation(_ context.Context, _ tx.Queryer, current operation.Context) (operation.Context, error) {
	return current, nil
}

func adminIdentifier(t *testing.T) ids.UUID {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value
}

func adminPool(t *testing.T, dsn string) *postgres.Pool {
	t.Helper()
	pool, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func adminExecute(t *testing.T, pool *postgres.Pool, statement string, arguments ...any) {
	t.Helper()
	if _, err := pool.Raw().Exec(context.Background(), statement, arguments...); err != nil {
		t.Fatal(err)
	}
}

func adminLivePlayer(t *testing.T, pool *postgres.Pool, at time.Time, secret []byte) (identity.PlayerID, string) {
	t.Helper()
	account, session := adminIdentifier(t), adminIdentifier(t)
	credentials := bootstrap.AccountCredentials{SID: "l3b-admin-sid-" + session.String(), LoginToken: "l3b-admin-login-" + session.String()}
	adminExecute(t, pool, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3)`, account.String(), "l3b-admin-"+account.String(), at.Add(-time.Hour))
	adminExecute(t, pool, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, session.String(), account.String(), at.Add(-time.Hour))
	for _, credential := range []struct{ kind, label, raw string }{{"SID", "sid", credentials.SID}, {"LOGIN_TOKEN", "login_token", credentials.LoginToken}} {
		digest, err := identity.DigestCredential(secret, credential.label, credential.raw)
		if err != nil {
			t.Fatal(err)
		}
		adminExecute(t, pool, `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,$5)`, adminIdentifier(t).String(), session.String(), credential.kind, digest[:], at.Add(-time.Hour))
	}
	service := i4store.BootstrapService{
		Runner: tx.Runner{DB: pool}, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool},
		DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "l3b-admin", BootstrapProfileVersion: "l3b-admin", OperationBinder: adminBootstrapBinder{},
	}
	operationContext := func(startedAt time.Time) operation.Context {
		id := adminIdentifier(t)
		return operation.Context{ID: id, StartedAt: startedAt, EntropySeed: sha256.Sum256([]byte(id.String()))}
	}
	if _, err := service.MID18(context.Background(), credentials, operationContext(at)); err != nil {
		t.Fatal(err)
	}
	result, err := service.MID1(context.Background(), bootstrap.RuntimeMID1Request{Credentials: credentials, Region: 1, Operation: operationContext(at)})
	if err != nil {
		t.Fatal(err)
	}
	return result.ContextPlan.Selected.PlayerID, result.Token
}

func adminRequest(token string, at time.Time) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation:  operation.Context{StartedAt: at},
		MID:        2784,
		ReceivedAt: at,
		Params:     map[string]any{"token": token, "region": int64(1)},
		Claims:     wire.CredentialClaims{Token: token, Region: 1},
	}}
}

func adminAuditRow(t *testing.T, pool *postgres.Pool, actor string) (int64, string, string, string, string, string) {
	t.Helper()
	var id int64
	var actorKind, targetKind, targetKey, outcome, policyVersion string
	if err := pool.QueryRow(context.Background(), `SELECT id,actor_kind,target_kind,target_key,outcome,policy_version FROM operator_audit_events WHERE actor_id=$1 ORDER BY id DESC LIMIT 1`, actor).Scan(&id, &actorKind, &targetKind, &targetKey, &outcome, &policyVersion); err != nil {
		t.Fatalf("audit row for %s: %v", actor, err)
	}
	return id, actorKind, targetKind, targetKey, outcome, policyVersion
}

// An operator revoke by player ends the live bearer and leaves one durable
// SUCCEEDED audit row; the audit table refuses later mutation.
func TestOperatorRevokeByPlayerEndsBearerAndAudits(t *testing.T) {
	dsn := os.Getenv("GXB_L3B_ADMIN_DSN")
	if dsn == "" {
		t.Fatal("GXB_L3B_ADMIN_DSN is required")
	}
	ctx := context.Background()
	pool := adminPool(t, dsn)
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	secret := []byte("l3b-admin-native-secret")
	player, token := adminLivePlayer(t, pool, at, secret)

	if err := run(ctx, []string{"-player", fmt.Sprint(int64(player)), "-operator", "operator-7", "-reason", "support"}, dsn); err != nil {
		t.Fatalf("revoke-session: %v", err)
	}
	id, actorKind, targetKind, targetKey, outcome, policyVersion := adminAuditRow(t, pool, "operator-7")
	if actorKind != "AdminOperator" || targetKind != "player" || targetKey != fmt.Sprint(int64(player)) || outcome != "SUCCEEDED" || policyVersion != revokeSessionPolicy {
		t.Fatalf("audit row agent=%s target=%s/%s outcome=%s policy=%s", actorKind, targetKind, targetKey, outcome, policyVersion)
	}

	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "l3b-admin"}
	if _, err := authority.ResolveGameplayBearer(ctx, token, at.Add(time.Minute)); !errors.Is(err, i4store.ErrGameplayBearerNotLive) {
		t.Fatalf("revoked bearer resolved: %v", err)
	}
	response := (stockruntime.LobbyDispatcher{Authority: authority}).Dispatch(ctx, adminRequest(token, at.Add(time.Minute)))
	if response.HTTPStatus != http.StatusUnauthorized || response.Body["error_code"] != int64(20003) || response.Body["error_msg"] == "" {
		t.Fatalf("revoked bearer reply: status=%d body=%v", response.HTTPStatus, response.Body)
	}

	if _, err := pool.Raw().Exec(ctx, `UPDATE operator_audit_events SET outcome='CHANGED' WHERE id=$1`, id); err == nil {
		t.Fatal("operator_audit_events accepted an UPDATE")
	}
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM operator_audit_events WHERE id=$1`, id); err == nil {
		t.Fatal("operator_audit_events accepted a DELETE")
	}
}

// A refusal leaves one REFUSED audit row and a non-zero exit; an already
// revoked session and an unknown session both take that path.
func TestOperatorRevokeRefusalsAreAudited(t *testing.T) {
	dsn := os.Getenv("GXB_L3B_ADMIN_DSN")
	if dsn == "" {
		t.Fatal("GXB_L3B_ADMIN_DSN is required")
	}
	ctx := context.Background()
	pool := adminPool(t, dsn)
	at := time.Date(2026, 11, 16, 0, 0, 0, 0, time.UTC)
	account, session := adminIdentifier(t), adminIdentifier(t)
	adminExecute(t, pool, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3)`, account.String(), "l3b-admin-revoked-"+account.String(), at.Add(-time.Hour))
	adminExecute(t, pool, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at,revoked_at,revocation_reason)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3,$3,'support')`, session.String(), account.String(), at.Add(-time.Hour))

	if err := run(ctx, []string{"-session", session.String(), "-operator", "operator-8", "-reason", "support"}, dsn); err == nil {
		t.Fatal("already-revoked session was accepted")
	}
	_, _, targetKind, targetKey, outcome, _ := adminAuditRow(t, pool, "operator-8")
	if targetKind != "session" || targetKey != session.String() || outcome != "REFUSED" {
		t.Fatalf("refusal audit target=%s/%s outcome=%s", targetKind, targetKey, outcome)
	}

	unknown := adminIdentifier(t)
	if err := run(ctx, []string{"-session", unknown.String(), "-operator", "operator-9", "-reason", "support"}, dsn); err == nil {
		t.Fatal("unknown session was accepted")
	}
	_, _, targetKind, targetKey, outcome, _ = adminAuditRow(t, pool, "operator-9")
	if targetKind != "session" || targetKey != unknown.String() || outcome != "REFUSED" {
		t.Fatalf("unknown-session audit target=%s/%s outcome=%s", targetKind, targetKey, outcome)
	}
}

// A production build without a database refuses the operator command instead
// of performing an unaudited revocation.
func TestOperatorCommandWithoutDatabaseRefuses(t *testing.T) {
	if err := run(context.Background(), []string{"-player", "100001", "-operator", "operator-7", "-reason", "support"}, ""); err == nil {
		t.Fatal("audited operator command ran without a database")
	}
}
