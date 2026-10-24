package i4store

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
	"time"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func testSessionID(t *testing.T) identity.SessionID {
	t.Helper()
	u, err := ids.ParseUUID("11111111-1111-4111-8111-111111111111")
	if err != nil {
		t.Fatal(err)
	}
	x, err := identity.SessionIDFrom(u)
	if err != nil {
		t.Fatal(err)
	}
	return x
}

func TestResolvedI4DefaultsAreExecutable(t *testing.T) {
	p := resolvedProfile(DefaultI4Profile())
	if err := p.Validate(); err != nil {
		t.Fatal(err)
	}
	r := resolvedRetry(tx.RetryPolicy{})
	if r.MaxAttempts != 3 || !r.RetryDefiniteAbort || !r.AllowReplayAfterAuthoritativeNegative {
		t.Fatalf("unexpected retry defaults: %+v", r)
	}
}

func TestMID1ReceiptIdentitySeparatesSelectionGenerations(t *testing.T) {
	sid := testSessionID(t)
	a := mid1ReceiptIdentity(sid, identity.LogicalServerID(1), 1)
	same := mid1ReceiptIdentity(sid, identity.LogicalServerID(1), 1)
	later := mid1ReceiptIdentity(sid, identity.LogicalServerID(1), 3)
	if a != same {
		t.Fatal("same selection generation must be replay-stable")
	}
	if a == later {
		t.Fatal("Server 1 -> Server 2 -> Server 1 must not collide with original Server 1 receipt")
	}
	if err := a.Validate(); err != nil {
		t.Fatal(err)
	}
	if err := later.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestI4DerivedIDsAreRetryStableAndDomainSeparated(t *testing.T) {
	op := operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(100, 0).UTC(), EntropySeed: [32]byte{1, 2, 3}}
	c1, err := contextIDFromOperation(op)
	if err != nil {
		t.Fatal(err)
	}
	c2, err := contextIDFromOperation(op)
	if err != nil {
		t.Fatal(err)
	}
	g1, err := credentialIDFromOperation(op)
	if err != nil {
		t.Fatal(err)
	}
	if c1 != c2 {
		t.Fatal("context id changed across retry-stable operation")
	}
	if c1.UUID() == g1.UUID() {
		t.Fatal("context and credential derivations must be domain-separated")
	}
}

func testContextID(t *testing.T, raw string) identity.ContextID {
	t.Helper()
	u, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	x, err := identity.ContextIDFrom(u)
	if err != nil {
		t.Fatal(err)
	}
	return x
}

func testAccountID(t *testing.T, raw string) identity.AccountID {
	t.Helper()
	u, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	x, err := identity.AccountIDFrom(u)
	if err != nil {
		t.Fatal(err)
	}
	return x
}

func mid1SelectionResultForTest(t *testing.T) appboot.MID1Result {
	t.Helper()
	cid := testContextID(t, "22222222-2222-4222-8222-222222222222")
	sid := testSessionID(t)
	aid := testAccountID(t, "33333333-3333-4333-8333-333333333333")
	ctx := identity.GameplayContext{ID: cid, SessionID: sid, AccountID: aid, LogicalServerID: 1, PlayerID: 125001, ContextGeneration: 2, CreatedAt: time.Unix(100, 0).UTC(), LivenessVersion: 1}
	player := logicalserver.PlayerRoot{PlayerID: 125001, AccountID: aid, LogicalServerID: 1, CreatedAt: time.Unix(10, 0).UTC(), BootstrapProfileVersion: "wave-s-v1", FirstEntryPending: true, StateVersion: 1}
	server := logicalserver.Server{ID: 1, Name: "Server 1", DirectoryVisible: true, ExistingLoginAllowed: true, NewCharacterAllowed: true, NextPlayerID: 125002, MaxPlayerID: 199999, StateVersion: 1, CreatedAt: time.Unix(1, 0).UTC()}
	return appboot.MID1Result{Region: 1, UID: identity.AccountUID("20000007"), Detail: map[string]any{"stale": true}, IsNew: 1, Player: player, Server: server, ContextPlan: identity.SelectionPlan{Kind: identity.SelectionCoalesced, Selected: ctx}}
}

func TestMID1V2ReceiptContainsSelectionOnlyAndSurvivesMutableHydrationChange(t *testing.T) {
	current := mid1SelectionResultForTest(t)
	payload, err := buildMID1SelectionPayload(current, "bearer-key-v1")
	if err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(raw, []byte(`"token"`)) || bytes.Contains(raw, []byte(`"detail"`)) || bytes.Contains(raw, []byte(`"is_new"`)) {
		t.Fatalf("mutable/secret MID1 data leaked into v2 receipt: %s", raw)
	}
	stored := receipt.Receipt{ResultSchema: mid1ReceiptSchemaV2, ResultPayload: raw, ActorAccountUID: string(current.UID), ContextID: current.ContextPlan.Selected.ID.UUID()}
	// Same immutable selection, but current canonical hydration changed after the
	// receipt was written. The receipt must remain valid and must not freeze it.
	current.Detail = map[string]any{"fresh": true}
	current.IsNew = 0
	current.Player.FirstEntryPending = false
	if err := validateStoredMID1Selection(stored, current, "bearer-key-v1"); err != nil {
		t.Fatal(err)
	}
}

func TestLegacyMID1V1ReceiptIsSelectionEvidenceNotHydrationTruth(t *testing.T) {
	current := mid1SelectionResultForTest(t)
	legacy := []byte(`{"token":"historical-secret","region":1,"uid":"20000007","detail":{"stale":true},"is_new":1}`)
	stored := receipt.Receipt{ResultSchema: mid1ReceiptSchemaV1, ResultPayload: legacy, ActorAccountUID: string(current.UID), ContextID: current.ContextPlan.Selected.ID.UUID()}
	current.Detail = map[string]any{"current": true}
	current.IsNew = 0
	current.Player.FirstEntryPending = false
	if err := validateStoredMID1Selection(stored, current, "bearer-key-v1"); err != nil {
		t.Fatal(err)
	}
}

func TestMID1ServerAdmissionFenceSeparatesExistingAndCreationPaths(t *testing.T) {
	if got := serverAdmissionFenceQuery(true); got != lockLogicalServerShared || !strings.Contains(got, "FOR SHARE") || strings.Contains(got, "FOR UPDATE") {
		t.Fatalf("existing-player fence=%q", got)
	}
	if got := serverAdmissionFenceQuery(false); got != lockLogicalServer || !strings.Contains(got, "FOR UPDATE") {
		t.Fatalf("creation fence=%q", got)
	}
}
