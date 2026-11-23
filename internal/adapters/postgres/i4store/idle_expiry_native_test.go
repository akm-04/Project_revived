//go:build postgres

package i4store_test

import (
	"context"
	"errors"
	"net/http"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

const idleExpiryServer = 9025

func idleIdentifier(t *testing.T) ids.UUID {
	t.Helper()
	value, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return value
}

func idleExpiryRequest(token string, at time.Time) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation:  operation.Context{StartedAt: at},
		MID:        2784,
		ReceivedAt: at,
		Params:     map[string]any{"token": token, "region": int64(idleExpiryServer)},
		Claims:     wire.CredentialClaims{Token: token, Region: idleExpiryServer},
	}}
}

// A session idle beyond its own timeout is refused by the gameplay bearer
// resolution (stock HTTP auth), by the realtime liveness fence and therefore
// answers the 20003 relog signal.
func TestIdleExpiredSessionIsRefusedByEveryBearerCheckNative(t *testing.T) {
	dsn := os.Getenv("GXB_IDLE_EXPIRY_DSN")
	if dsn == "" {
		t.Skip("GXB_IDLE_EXPIRY_DSN required (ops/testing/fresh_db.sh idle-expiry)")
	}
	ctx := context.Background()
	pool, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	now := time.Now().UTC().Truncate(time.Microsecond)
	account, session, contextID := idleIdentifier(t), idleIdentifier(t), idleIdentifier(t)
	player := int64(idleExpiryServer*100000 + 1)
	secret := []byte("idle-expiry-native-secret")
	gameplayContext := identity.GameplayContext{ID: identity.ContextID{}, ContextGeneration: 1}
	parsedContext, err := identity.ContextIDFrom(contextID)
	if err != nil {
		t.Fatal(err)
	}
	gameplayContext.ID = parsedContext
	raw, err := identity.DeriveGameplayBearer(secret, gameplayContext)
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer(secret, raw)
	if err != nil {
		t.Fatal(err)
	}
	execute := func(statement string, arguments ...any) {
		t.Helper()
		if _, err := pool.Raw().Exec(ctx, statement, arguments...); err != nil {
			t.Fatal(err)
		}
	}
	for _, statement := range []string{
		`DELETE FROM gameplay_contexts WHERE logical_server_id=$1`,
		`DELETE FROM account_sessions WHERE account_id IN (SELECT account_id FROM players WHERE logical_server_id=$1)`,
		`DELETE FROM players WHERE logical_server_id=$1`,
		`DELETE FROM logical_servers WHERE logical_server_id=$1`,
	} {
		execute(statement, idleExpiryServer)
	}
	execute(`INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'IdleBearer',true,true,true,$2,$3,$4)`, idleExpiryServer, idleExpiryServer*100000+25001, (idleExpiryServer+1)*100000-1, now)
	execute(`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3)`, account.String(), "idle-bearer-"+account.String(), now.Add(-3*time.Hour))
	execute(`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,$4,'idle')`, player, account.String(), idleExpiryServer, now.Add(-3*time.Hour))
	execute(`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,idle_timeout_seconds,last_activity_at,liveness_version)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,3600,$4,1)`, session.String(), account.String(), now.Add(-2*time.Hour), now.Add(-2*time.Hour))
	execute(`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version)VALUES($1,$2,$3,$4,$5,1,$6,1)`, contextID.String(), session.String(), account.String(), idleExpiryServer, player, now.Add(-2*time.Hour))
	execute(`INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)VALUES($1,$2,$3,$4,1,$5,$6)`, idleIdentifier(t).String(), contextID.String(), session.String(), digest[:], "idle-expiry-native", now.Add(-2*time.Hour))

	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "idle-expiry-native"}
	actor, err := authority.ResolveGameplayBearer(ctx, raw, now.Add(-90*time.Minute))
	if err != nil {
		t.Fatalf("bearer was not live 30 minutes into the one-hour idle window: %v", err)
	}
	if err := authority.ValidateActor(ctx, actor, now); !errors.Is(err, i4store.ErrGameplayBearerNotLive) {
		t.Fatalf("liveness fence accepted a session idle past its timeout: %v", err)
	}
	if _, err := authority.ResolveGameplayBearer(ctx, raw, now); !errors.Is(err, i4store.ErrGameplayBearerNotLive) {
		t.Fatalf("stock HTTP auth accepted a session idle past its timeout: %v", err)
	}
	response := (stockruntime.LobbyDispatcher{Authority: authority}).Dispatch(ctx, idleExpiryRequest(raw, now))
	if response.HTTPStatus != http.StatusUnauthorized || response.Body["error_code"] != int64(20003) || response.Body["error_msg"] == "" {
		t.Fatalf("idle-expired session reply: status=%d body=%v", response.HTTPStatus, response.Body)
	}
}
