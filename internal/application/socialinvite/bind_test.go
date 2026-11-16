package socialinvite

import (
	"encoding/json"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestBindRecoveryAcceptsUnnamedInviter(t *testing.T) {
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	contextIdentifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(contextIdentifier)
	if err != nil {
		t.Fatal(err)
	}
	current := operation.Context{ID: identifier, StartedAt: time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)}
	actor := identity.ActorContext{PlayerID: 100002, LogicalServerID: 1, AccountUID: "invite-account", ContextID: contextID}
	identityValue := receipt.Identity{OwnerKind: "player", OwnerKey: "100002", Domain: "socialinvite", Operation: "bind", SemanticKey: identifier.String()}
	fingerprint := [32]byte{1}
	terminal := bindTerminal{OperationID: identifier.String(), StartedAt: current.StartedAt, InviterID: 100001, InviterName: "", Policy: PolicyVersion}
	encoded, err := json.Marshal(terminal)
	if err != nil {
		t.Fatal(err)
	}
	bound, err := bindPolicies(current)
	if err != nil {
		t.Fatal(err)
	}
	value, err := receipt.New(bound, identityValue, bindOperationClass, bindResultSchema, encoded, fingerprint)
	if err != nil {
		t.Fatal(err)
	}
	value.PolicyVersion = PolicyVersion
	value.ActorAccountUID = string(actor.AccountUID)
	value.ContextID = actor.ContextID.UUID()
	recovery := bindRecovery{identity: identityValue, fingerprint: fingerprint, actor: actor, current: current}
	output, err := recovery.decode(value)
	if err != nil {
		t.Fatalf("unnamed inviter refused: %v", err)
	}
	if output["invitor_id"] != int64(100001) || output["invitor_name"] != "" {
		t.Fatalf("binding reply = %+v", output)
	}
}
