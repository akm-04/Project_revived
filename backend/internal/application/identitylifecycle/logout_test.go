package identitylifecycle

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeLogoutStore struct {
	live           []identity.SessionID
	revoked        map[identity.SessionID]bool
	playerSessions map[identity.PlayerID][]identity.SessionID
	sessionPlayers map[identity.SessionID]identity.PlayerID
	serverSessions map[identity.SessionID]identity.LogicalServerID
	serverFilters  []bool
	batchSizes     []int
	reasons        []string
	holds          []SessionHold
}

func newFakeLogoutStore() *fakeLogoutStore {
	return &fakeLogoutStore{revoked: map[identity.SessionID]bool{}, playerSessions: map[identity.PlayerID][]identity.SessionID{}, sessionPlayers: map[identity.SessionID]identity.PlayerID{}, serverSessions: map[identity.SessionID]identity.LogicalServerID{}}
}

func (store *fakeLogoutStore) PlayerIDsForSessionIDsTx(_ context.Context, _ tx.Queryer, sessions []identity.SessionID) ([]identity.PlayerID, error) {
	var out []identity.PlayerID
	for _, session := range sessions {
		if player, found := store.sessionPlayers[session]; found {
			out = append(out, player)
		}
	}
	return out, nil
}

func (store *fakeLogoutStore) InsertSessionHoldTx(_ context.Context, _ tx.Tx, hold SessionHold) error {
	store.holds = append(store.holds, hold)
	return nil
}

func logoutTestSession(t *testing.T) identity.SessionID {
	t.Helper()
	uuid, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	session, err := identity.SessionIDFrom(uuid)
	if err != nil {
		t.Fatal(err)
	}
	return session
}

func (store *fakeLogoutStore) FindLiveSessionIDsForPlayersTx(_ context.Context, _ tx.Queryer, players []identity.PlayerID) ([]identity.SessionID, error) {
	var out []identity.SessionID
	for _, player := range players {
		for _, session := range store.playerSessions[player] {
			if !store.revoked[session] {
				out = append(out, session)
			}
		}
	}
	return out, nil
}

func (store *fakeLogoutStore) ListLiveSessionIDsTx(_ context.Context, _ tx.Queryer, server *identity.LogicalServerID, after identity.SessionID, limit int) ([]identity.SessionID, error) {
	store.serverFilters = append(store.serverFilters, server != nil)
	var out []identity.SessionID
	for _, session := range store.live {
		if store.revoked[session] || !afterUUID(session, after) {
			continue
		}
		if server != nil && store.serverSessions[session] != *server {
			continue
		}
		out = append(out, session)
		if len(out) == limit {
			break
		}
	}
	return out, nil
}

func afterUUID(session, after identity.SessionID) bool {
	sessionUUID, afterUUIDValue := session.UUID(), after.UUID()
	return bytes.Compare(sessionUUID[:], afterUUIDValue[:]) > 0
}

func (store *fakeLogoutStore) RevokeSessionsTx(_ context.Context, _ tx.Tx, sessions []identity.SessionID, _ time.Time, reason string) (int64, error) {
	store.batchSizes = append(store.batchSizes, len(sessions))
	store.reasons = append(store.reasons, reason)
	var count int64
	for _, session := range sessions {
		if store.revoked[session] {
			continue
		}
		store.revoked[session] = true
		count++
	}
	return count, nil
}

func logoutOperation(t *testing.T) operation.Context {
	t.Helper()
	uuid, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: uuid, StartedAt: time.Date(2026, 11, 22, 0, 0, 0, 0, time.UTC)}
}

func runLogoutHandler(t *testing.T, store *fakeLogoutStore, name, payload string) (LogoutResult, error) {
	t.Helper()
	handlers := LogoutCommands{Store: store}.Handlers()
	handler, ok := handlers[name]
	if !ok {
		t.Fatalf("no handler for %s", name)
	}
	command := operator.Command{ModuleCommand: name, Envelope: operator.Envelope{SemanticKey: "key"}, Payload: json.RawMessage(payload)}
	value, err := handler(context.Background(), tx.Scope{Tx: &testTx{}, Operation: logoutOperation(t)}, command)
	if err != nil {
		return LogoutResult{}, err
	}
	result, ok := value.(LogoutResult)
	if !ok {
		t.Fatalf("%s returned %T", name, value)
	}
	return result, nil
}

func TestLogoutHandlersCoverEveryCommand(t *testing.T) {
	handlers := LogoutCommands{}.Handlers()
	if len(handlers) != 2 || handlers["session.logout"] == nil || handlers["session.logout_all"] == nil {
		t.Fatalf("handlers = %v", handlers)
	}
}

func TestLogoutRevokesPlayersAndNamedSessions(t *testing.T) {
	store := newFakeLogoutStore()
	player := identity.PlayerID(100001)
	byPlayer := logoutTestSession(t)
	byName := logoutTestSession(t)
	store.playerSessions[player] = []identity.SessionID{byPlayer}
	store.live = []identity.SessionID{byPlayer, byName}
	store.serverSessions[byPlayer] = 1
	store.serverSessions[byName] = 1

	result, err := runLogoutHandler(t, store, "session.logout",
		`{"player_ids":[100001],"session_ids":["`+byName.UUID().String()+`"]}`)
	if err != nil {
		t.Fatal(err)
	}
	if result.Revoked != 2 {
		t.Fatalf("revoked = %d, want 2", result.Revoked)
	}
	if !store.revoked[byPlayer] || !store.revoked[byName] {
		t.Fatalf("not every target was revoked: %v", store.revoked)
	}
	if len(store.reasons) != 1 || store.reasons[0] != identity.RevocationReasonOperatorLogout {
		t.Fatalf("revocation reasons = %v", store.reasons)
	}
}

func TestLogoutAllOnOneServerRevokesOnlyThatServer(t *testing.T) {
	store := newFakeLogoutStore()
	first, second := logoutTestSession(t), logoutTestSession(t)
	store.live = []identity.SessionID{first, second}
	store.serverSessions[first] = 1
	store.serverSessions[second] = 2

	result, err := runLogoutHandler(t, store, "session.logout_all", `{"server_id":1}`)
	if err != nil {
		t.Fatal(err)
	}
	if result.Revoked != 1 {
		t.Fatalf("revoked = %d, want 1", result.Revoked)
	}
	if !store.revoked[first] || store.revoked[second] {
		t.Fatalf("server scope leaked: %v", store.revoked)
	}
	if len(store.serverFilters) != 1 || !store.serverFilters[0] {
		t.Fatalf("server filter = %v", store.serverFilters)
	}
}

func TestLogoutAllWithoutServerRevokesEverythingAndRerunIsHarmless(t *testing.T) {
	store := newFakeLogoutStore()
	first, second := logoutTestSession(t), logoutTestSession(t)
	store.live = []identity.SessionID{first, second}
	store.serverSessions[first] = 1
	store.serverSessions[second] = 2

	result, err := runLogoutHandler(t, store, "session.logout_all", `{}`)
	if err != nil {
		t.Fatal(err)
	}
	if result.Revoked != 2 {
		t.Fatalf("revoked = %d, want 2", result.Revoked)
	}
	if len(store.serverFilters) != 1 || store.serverFilters[0] {
		t.Fatalf("no-server filter = %v", store.serverFilters)
	}
	rerun, err := runLogoutHandler(t, store, "session.logout_all", `{}`)
	if err != nil {
		t.Fatalf("rerun: %v", err)
	}
	if rerun.Revoked != 0 {
		t.Fatalf("rerun revoked = %d, want 0", rerun.Revoked)
	}
}

func TestLogoutAllBatchesMoreThanOneThousandSessions(t *testing.T) {
	store := newFakeLogoutStore()
	for range 1001 {
		store.live = append(store.live, logoutTestSession(t))
	}
	store.live = sortedSessions(sessionSet(store.live))

	result, err := runLogoutHandler(t, store, "session.logout_all", `{}`)
	if err != nil {
		t.Fatal(err)
	}
	if result.Revoked != 1001 {
		t.Fatalf("revoked = %d, want 1001", result.Revoked)
	}
	if len(store.batchSizes) != 2 || store.batchSizes[0] != LogoutBatchSize || store.batchSizes[1] != 1 {
		t.Fatalf("batches = %v", store.batchSizes)
	}
}

func TestLogoutRefusesAnEmptyOrMalformedTarget(t *testing.T) {
	for _, payload := range []string{`{}`, `{"player_ids":[0]}`, `{"session_ids":["not-a-uuid"]}`, `{"unknown":1}`} {
		_, err := runLogoutHandler(t, newFakeLogoutStore(), "session.logout", payload)
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != operator.CodePayloadInvalid {
			t.Fatalf("payload %s: %v", payload, err)
		}
	}
	for _, payload := range []string{`{"server_id":0}`, `{"server_id":-1}`, `{"other":1}`} {
		_, err := runLogoutHandler(t, newFakeLogoutStore(), "session.logout_all", payload)
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != operator.CodePayloadInvalid {
			t.Fatalf("payload %s: %v", payload, err)
		}
	}
}

func TestLogoutHoldsThePlayerScopeForTheDefaultFiveSeconds(t *testing.T) {
	store := newFakeLogoutStore()
	player := identity.PlayerID(100001)
	store.playerSessions[player] = []identity.SessionID{logoutTestSession(t)}
	result, err := runLogoutHandler(t, store, "session.logout", `{"player_ids":[100001],"hold_seconds":5}`)
	if err != nil {
		t.Fatal(err)
	}
	if result.Revoked != 1 {
		t.Fatalf("revoked = %d", result.Revoked)
	}
	if len(store.holds) != 1 {
		t.Fatalf("holds = %+v", store.holds)
	}
	hold := store.holds[0]
	if hold.ScopeKind != HoldScopePlayer || hold.ScopeKey != int64(player) || hold.Reason != identity.RevocationReasonOperatorLogout {
		t.Fatalf("hold = %+v", hold)
	}
	want := logoutOperation(t).StartedAt.Add(5 * time.Second)
	if !hold.HeldUntil.Equal(want) || hold.CommandKey != "key" {
		t.Fatalf("hold = %+v want until %s", hold, want)
	}
}

func TestLogoutAllHoldsTheServerOrGlobalScope(t *testing.T) {
	store := newFakeLogoutStore()
	if _, err := runLogoutHandler(t, store, "session.logout_all", `{"server_id":2,"hold_seconds":7}`); err != nil {
		t.Fatal(err)
	}
	if len(store.holds) != 1 || store.holds[0].ScopeKind != HoldScopeServer || store.holds[0].ScopeKey != 2 {
		t.Fatalf("server hold = %+v", store.holds)
	}
	globalStore := newFakeLogoutStore()
	if _, err := runLogoutHandler(t, globalStore, "session.logout_all", `{"hold_seconds":7}`); err != nil {
		t.Fatal(err)
	}
	if len(globalStore.holds) != 1 || globalStore.holds[0].ScopeKind != HoldScopeGlobal || globalStore.holds[0].ScopeKey != 0 {
		t.Fatalf("global hold = %+v", globalStore.holds)
	}
}

func TestLogoutHoldSecondsZeroDisablesTheHold(t *testing.T) {
	store := newFakeLogoutStore()
	store.playerSessions[identity.PlayerID(100001)] = []identity.SessionID{logoutTestSession(t)}
	if _, err := runLogoutHandler(t, store, "session.logout", `{"player_ids":[100001],"hold_seconds":0}`); err != nil {
		t.Fatal(err)
	}
	if len(store.holds) != 0 {
		t.Fatalf("holds = %+v", store.holds)
	}
}

func TestLogoutRefusesAHoldOutsideItsBounds(t *testing.T) {
	for _, payload := range []string{`{"player_ids":[100001],"hold_seconds":-1}`, `{"player_ids":[100001],"hold_seconds":3601}`} {
		_, err := runLogoutHandler(t, newFakeLogoutStore(), "session.logout", payload)
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != operator.CodePayloadInvalid {
			t.Fatalf("payload %s: %v", payload, err)
		}
	}
}

func sessionSet(sessions []identity.SessionID) map[identity.SessionID]struct{} {
	out := make(map[identity.SessionID]struct{}, len(sessions))
	for _, session := range sessions {
		out[session] = struct{}{}
	}
	return out
}
