package operator_test

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
)

func TestEnvelopeValidation(t *testing.T) {
	valid := operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "server:1", Reason: "r", SemanticKey: "k"}
	if err := valid.Validate(); err != nil {
		t.Fatal(err)
	}
	negative := int64(-1)
	for name, envelope := range map[string]operator.Envelope{
		"role":     {Principal: "root", Role: "admin", Scope: "global", Reason: "r", SemanticKey: "k"},
		"scope":    {Principal: "root", Role: operator.RoleRoot, Scope: "server:0", Reason: "r", SemanticKey: "k"},
		"reason":   {Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "  ", SemanticKey: "k"},
		"key":      {Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "r", SemanticKey: " k"},
		"revision": {Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "r", SemanticKey: "k", ExpectedRevision: &negative},
	} {
		var refusal *operator.Refusal
		if err := envelope.Validate(); !errors.As(err, &refusal) || refusal.Code != operator.CodeEnvelopeInvalid {
			t.Fatalf("%s: err = %v", name, err)
		}
	}
}
