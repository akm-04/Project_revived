//go:build postgres

package identitylogout_test

import (
	"context"
	"encoding/json"
	"net/http"
	"os"
	"sync/atomic"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

const (
	testDSNVariable   = "GXB_I11A_L6_DSN"
	testDigestSecret  = "i11a-l6-native-digest-secret-01"
	testBearerSecret  = "i11a-l6-native-bearer-secret-01"
	testDerivationKey = "i11a-l6-native"
	testLobbyMID      = uint16(2784)
)

var playerSequence atomic.Int64

type seededSession struct {
	Player  identity.PlayerID
	Session identity.SessionID
	Context identity.ContextID
	Bearer  string
	Server  int32
}

func nativePool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv(testDSNVariable)
	if dsn == "" {
		t.Skip(testDSNVariable + " required (ops/testing/fresh_db.sh i11a_l6_logout)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func mustUUID(t *testing.T) ids.UUID {
	t.Helper()
	uuid, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return uuid
}

func nextPlayerID(server int32) identity.PlayerID {
	return identity.PlayerID(int64(server)*100000 + 1 + playerSequence.Add(1))
}

func execSQL(t *testing.T, pool *pg.Pool, statement string, arguments ...any) {
	t.Helper()
	if _, err := pool.Raw().Exec(context.Background(), statement, arguments...); err != nil {
		t.Fatalf("exec: %v\n%s", err, statement)
	}
}

// seedSession creates one live account session with a live gameplay context and
// one resolvable gameplay credential on the given logical server.
func seedSession(t *testing.T, pool *pg.Pool, player identity.PlayerID, server int32) seededSession {
	t.Helper()
	account, session, contextUUID, credential := mustUUID(t), mustUUID(t), mustUUID(t), mustUUID(t)
	issued := time.Now().UTC().Add(-time.Hour)
	execSQL(t, pool, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3)`, account.String(), "i11a-l6-"+account.String(), issued)
	execSQL(t, pool, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,$4,'i11a-l6-native')`, int64(player), account.String(), server, issued)
	execSQL(t, pool, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, session.String(), account.String(), issued)
	execSQL(t, pool, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,$4,$5,1,$6)`, contextUUID.String(), session.String(), account.String(), server, int64(player), issued)
	contextID, err := identity.ContextIDFrom(contextUUID)
	if err != nil {
		t.Fatal(err)
	}
	bearer, err := identity.DeriveGameplayBearer([]byte(testBearerSecret), identity.GameplayContext{ID: contextID, ContextGeneration: 1})
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer([]byte(testDigestSecret), bearer)
	if err != nil {
		t.Fatal(err)
	}
	execSQL(t, pool, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)VALUES($1,$2,$3,$4,1,$5,$6)`, credential.String(), contextUUID.String(), session.String(), digest[:], testDerivationKey, issued)
	sessionID, err := identity.SessionIDFrom(session)
	if err != nil {
		t.Fatal(err)
	}
	return seededSession{Player: player, Session: sessionID, Context: contextID, Bearer: bearer, Server: server}
}

// seedSessionsOfOnePlayer creates count live sessions that share one player,
// enough to cross the 1000-session batch.
func seedSessionsOfOnePlayer(t *testing.T, pool *pg.Pool, count int, server int32) identity.PlayerID {
	t.Helper()
	player := nextPlayerID(server)
	account := mustUUID(t)
	issued := time.Now().UTC().Add(-time.Hour)
	execSQL(t, pool, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',$3)`, account.String(), "i11a-l6-bulk-"+account.String(), issued)
	execSQL(t, pool, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,$4,'i11a-l6-native')`, int64(player), account.String(), server, issued)
	for range count {
		session, context := mustUUID(t), mustUUID(t)
		execSQL(t, pool, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'SID_LOGIN_TOKEN_PAIR',$3,$3)`, session.String(), account.String(), issued)
		execSQL(t, pool, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,$4,$5,1,$6)`, context.String(), session.String(), account.String(), server, int64(player), issued)
	}
	return player
}

func nativeBus(pool *pg.Pool) operator.Bus {
	return operator.Bus{Runner: tx.Runner{DB: pool}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: appidentity.LogoutCommands{Store: identitystore.Store{}}.Handlers()}
}

func nativeCommand(t *testing.T, name string, payload any, semanticKey string) operator.Command {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "i11a l6 native", SemanticKey: semanticKey}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func executeLogout(t *testing.T, bus operator.Bus, command operator.Command) (operator.Outcome, appidentity.LogoutResult) {
	t.Helper()
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatalf("%s: %v", command.ModuleCommand, err)
	}
	var result appidentity.LogoutResult
	if err := json.Unmarshal(outcome.Result, &result); err != nil {
		t.Fatalf("%s result: %v", command.ModuleCommand, err)
	}
	return outcome, result
}

func revocationState(t *testing.T, pool *pg.Pool, session identity.SessionID) (bool, string, bool, int) {
	t.Helper()
	var revoked bool
	var reason *string
	if err := pool.QueryRow(context.Background(), `SELECT revoked_at IS NOT NULL,revocation_reason FROM account_sessions WHERE session_id=$1`, session.UUID().String()).Scan(&revoked, &reason); err != nil {
		t.Fatal(err)
	}
	var contextEnded bool
	if err := pool.QueryRow(context.Background(), `SELECT ended_at IS NOT NULL FROM gameplay_contexts WHERE session_id=$1`, session.UUID().String()).Scan(&contextEnded); err != nil {
		t.Fatal(err)
	}
	var liveCredentials int
	if err := pool.QueryRow(context.Background(), `SELECT count(*) FROM gameplay_context_credentials WHERE session_id=$1 AND revoked_at IS NULL`, session.UUID().String()).Scan(&liveCredentials); err != nil {
		t.Fatal(err)
	}
	value := ""
	if reason != nil {
		value = *reason
	}
	return revoked, value, contextEnded, liveCredentials
}

func authority(pool *pg.Pool) i4store.RealtimeAuthority {
	return i4store.RealtimeAuthority{Queryer: pool, DigestSecret: []byte(testDigestSecret), BearerSecret: []byte(testBearerSecret), DerivationKeyID: testDerivationKey}
}

func lobbyResponse(t *testing.T, pool *pg.Pool, bearer string, server int32) httpedge.Response {
	t.Helper()
	at := time.Now().UTC()
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation: operation.Context{StartedAt: at}, MID: testLobbyMID, ReceivedAt: at,
		Params: map[string]any{"token": bearer, "region": int64(server)},
		Claims: wire.CredentialClaims{Token: bearer, Region: int64(server)},
	}}
	return (stockruntime.LobbyDispatcher{Authority: authority(pool)}).Dispatch(context.Background(), request)
}

// A session.logout by player ends the bearer; the next gameplay request gets
// message.lua 20003, and the command leaves an APPLIED audit row. Replaying the
// same key changes nothing.
func TestSessionLogoutEndsBearerAndAuditsThroughTheBus(t *testing.T) {
	pool := nativePool(t)
	seeded := seedSession(t, pool, nextPlayerID(1), 1)
	bus := nativeBus(pool)
	key := mustUUID(t).String()
	command := nativeCommand(t, "session.logout", map[string]any{"player_ids": []int64{int64(seeded.Player)}}, key)

	outcome, result := executeLogout(t, bus, command)
	if outcome.State != operator.StateApplied || result.Revoked != 1 {
		t.Fatalf("outcome=%s result=%+v", outcome.State, result)
	}
	revoked, reason, contextEnded, liveCredentials := revocationState(t, pool, seeded.Session)
	if !revoked || reason != identity.RevocationReasonOperatorLogout || !contextEnded || liveCredentials != 0 {
		t.Fatalf("revoked=%v reason=%q contextEnded=%v liveCredentials=%d", revoked, reason, contextEnded, liveCredentials)
	}
	response := lobbyResponse(t, pool, seeded.Bearer, seeded.Server)
	if response.HTTPStatus != http.StatusUnauthorized || response.Body["error_code"] != int64(20003) || response.Body["error_msg"] == "" {
		t.Fatalf("revoked bearer reply: status=%d body=%v", response.HTTPStatus, response.Body)
	}
	var auditState string
	if err := pool.QueryRow(context.Background(), `SELECT state FROM operator_commands WHERE semantic_key=$1 AND module_command='session.logout'`, key).Scan(&auditState); err != nil {
		t.Fatal(err)
	}
	if auditState != operator.StateApplied {
		t.Fatalf("audit state = %s", auditState)
	}

	replay, replayResult := executeLogout(t, bus, command)
	if !replay.Replayed || replayResult.Revoked != 1 {
		t.Fatalf("replay outcome=%+v result=%+v", replay, replayResult)
	}
}

// logout_all with a server id revokes only that server's live sessions.
func TestSessionLogoutAllOnOneServerLeavesTheOtherServerLive(t *testing.T) {
	pool := nativePool(t)
	first := seedSession(t, pool, nextPlayerID(1), 1)
	second := seedSession(t, pool, nextPlayerID(2), 2)
	bus := nativeBus(pool)
	_, result := executeLogout(t, bus, nativeCommand(t, "session.logout_all", map[string]any{"server_id": 1}, mustUUID(t).String()))
	if result.Revoked < 1 {
		t.Fatalf("revoked = %d, want at least 1", result.Revoked)
	}
	revoked, reason, _, _ := revocationState(t, pool, first.Session)
	if !revoked || reason != identity.RevocationReasonOperatorLogoutAll {
		t.Fatalf("server 1 session revoked=%v reason=%q", revoked, reason)
	}
	otherRevoked, _, _, _ := revocationState(t, pool, second.Session)
	if otherRevoked {
		t.Fatal("logout_all with server_id revoked another server's session")
	}
	if response := lobbyResponse(t, pool, second.Bearer, second.Server); response.HTTPStatus != http.StatusOK {
		t.Fatalf("server 2 bearer refused: status=%d body=%v", response.HTTPStatus, response.Body)
	}
}

// logout_all without a server revokes every live session, and a rerun returns
// zero without an error.
func TestSessionLogoutAllWithoutServerRevokesEveryServerAndRerunIsHarmless(t *testing.T) {
	pool := nativePool(t)
	first := seedSession(t, pool, nextPlayerID(1), 1)
	second := seedSession(t, pool, nextPlayerID(2), 2)
	bus := nativeBus(pool)
	_, result := executeLogout(t, bus, nativeCommand(t, "session.logout_all", map[string]any{}, mustUUID(t).String()))
	if result.Revoked < 2 {
		t.Fatalf("revoked = %d, want at least 2", result.Revoked)
	}
	for _, seeded := range []seededSession{first, second} {
		revoked, reason, contextEnded, liveCredentials := revocationState(t, pool, seeded.Session)
		if !revoked || reason != identity.RevocationReasonOperatorLogoutAll || !contextEnded || liveCredentials != 0 {
			t.Fatalf("revoked=%v reason=%q contextEnded=%v liveCredentials=%d", revoked, reason, contextEnded, liveCredentials)
		}
	}
	_, rerun := executeLogout(t, bus, nativeCommand(t, "session.logout_all", map[string]any{}, mustUUID(t).String()))
	if rerun.Revoked != 0 {
		t.Fatalf("rerun revoked = %d, want 0", rerun.Revoked)
	}
}

// More than 1000 live sessions are all revoked; the handler pages them.
func TestSessionLogoutAllHandlesMoreThanOneThousandSessions(t *testing.T) {
	pool := nativePool(t)
	player := seedSessionsOfOnePlayer(t, pool, 1001, 1)
	var seeded []identity.SessionID
	rows, err := pool.Raw().Query(context.Background(), `SELECT session_id::text FROM gameplay_contexts WHERE player_id=$1 AND ended_at IS NULL`, int64(player))
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var value string
		if err := rows.Scan(&value); err != nil {
			t.Fatal(err)
		}
		uuid, err := ids.ParseUUID(value)
		if err != nil {
			t.Fatal(err)
		}
		session, err := identity.SessionIDFrom(uuid)
		if err != nil {
			t.Fatal(err)
		}
		seeded = append(seeded, session)
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
	if len(seeded) != 1001 {
		t.Fatalf("seeded %d sessions", len(seeded))
	}

	bus := nativeBus(pool)
	_, result := executeLogout(t, bus, nativeCommand(t, "session.logout_all", map[string]any{"server_id": 1}, mustUUID(t).String()))
	if result.Revoked < 1001 {
		t.Fatalf("revoked = %d, want at least 1001", result.Revoked)
	}
	var live int
	if err := pool.QueryRow(context.Background(), `SELECT count(*) FROM account_sessions s JOIN gameplay_contexts c ON c.session_id=s.session_id WHERE c.player_id=$1 AND s.revoked_at IS NULL`, int64(player)).Scan(&live); err != nil {
		t.Fatal(err)
	}
	if live != 0 {
		t.Fatalf("%d sessions still live", live)
	}
}
