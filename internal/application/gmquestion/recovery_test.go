package gmquestion

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	domain "gxb.local/backend/v2/internal/domain/gmquestion"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestRecoveryRejectsCorruptTerminalProof(t *testing.T) {
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(identifier)
	if err != nil {
		t.Fatal(err)
	}
	current := operation.Context{ID: identifier, StartedAt: time.Unix(100, 123456789).UTC(), EntropySeed: [32]byte{1}}
	references, err := policy.NewSet(policy.Ref{Name: "gmquestion", Version: PolicyVersion})
	if err != nil {
		t.Fatal(err)
	}
	actor := identity.ActorContext{PlayerID: 125001, LogicalServerID: 1, AccountUID: "question-owner", ContextID: contextID}
	proof := recovery{identity: receipt.Identity{OwnerKind: "player", OwnerKey: "125001", Domain: "gmquestion", Operation: "ask", SemanticKey: identifier.String()}, fingerprint: [32]byte{2}, actor: actor, current: current, message: "help"}
	payload := terminal{Question: domain.Question{Operation: identifier, Player: 125001, Server: 1, Message: "help", AskedAt: time.Unix(101, 0).UTC()}, StartedAt: current.StartedAt, EntropySeed: current.EntropySeed, Reply: &Acknowledgement{}}
	encoded, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	bound := current
	bound.Policies = references
	stored, err := receipt.New(bound, proof.identity, operationClass, resultSchema, encoded, proof.fingerprint)
	if err != nil {
		t.Fatal(err)
	}
	stored.ActorAccountUID = string(actor.AccountUID)
	stored.ContextID = identifier
	stored.PolicyVersion = PolicyVersion
	stored.OperationStartedAt = stored.OperationStartedAt.Truncate(time.Microsecond)
	if _, err := proof.decode(stored); err != nil {
		t.Fatal("valid PostgreSQL timestamp precision refused", err)
	}
	for _, name := range []string{"fingerprint", "actor", "context", "policy", "schema", "start", "message", "entropy", "null-reply", "extra-field", "trailing-value", "extra-policy"} {
		t.Run(name, func(t *testing.T) {
			changed := stored
			terminalValue := payload
			switch name {
			case "extra-policy":
				changed.OperationPolicyRefs, err = policy.NewSet(policy.Ref{Name: "gmquestion", Version: PolicyVersion}, policy.Ref{Name: "unexpected", Version: "V1"})
				if err != nil {
					t.Fatal(err)
				}
			case "fingerprint":
				changed.RequestFingerprint = [32]byte{3}
			case "actor":
				changed.ActorAccountUID = "other"
			case "context":
				changed.ContextID = ids.UUID{}
			case "policy":
				changed.PolicyVersion = "unqualified"
			case "schema":
				changed.ResultSchema = "unqualified"
			case "start":
				changed.OperationStartedAt = changed.OperationStartedAt.Add(time.Second)
			case "message":
				terminalValue.Question.Message = "other"
			case "entropy":
				terminalValue.EntropySeed = [32]byte{3}
			case "null-reply":
				terminalValue.Reply = nil
			case "extra-field":
				changed.ResultPayload = json.RawMessage(`{"unexpected":true}`)
			case "trailing-value":
				changed.ResultPayload = append(append([]byte{}, encoded...), []byte(" {}")...)
			}
			if name == "message" || name == "entropy" || name == "null-reply" {
				changed.ResultPayload, err = json.Marshal(terminalValue)
				if err != nil {
					t.Fatal(err)
				}
			}
			if _, err := proof.decode(changed); err == nil {
				t.Fatal("corrupt proof accepted")
			} else if name == "fingerprint" {
				var conflict *receipt.ConflictError
				if !errors.As(err, &conflict) {
					t.Fatal(err)
				}
			}
		})
	}
}
