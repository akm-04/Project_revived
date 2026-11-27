package otarelease

import (
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

func runHandledCommand(t *testing.T, commands Commands, at time.Time, name string, envelope operator.Envelope, payload any) (any, error) {
	t.Helper()
	command, err := operator.NewCommand(name, envelope, mustJSON(t, payload))
	if err != nil {
		t.Fatal(err)
	}
	return commands.Handlers()[name](context.Background(), commandScope(at), command)
}

func receiptEnvelope(key string) operator.Envelope {
	return operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "A-213 regression", SemanticKey: key}
}

func TestFileReceiptBindsModuleAndPayload(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	code := buildPayload(t, "1.631.5", "code", 2000)
	root := rootWithVolumes(t, code)
	store := NewStateFile(root)
	commands := Commands{Store: store, Root: root}
	if _, err := runHandledCommand(t, commands, at, "ota.register_build", receiptEnvelope("register-key"), code); err != nil {
		t.Fatal(err)
	}
	revision := int64(0)
	publishEnvelope := receiptEnvelope("publish-key")
	publishEnvelope.ExpectedRevision = &revision
	if _, err := runHandledCommand(t, commands, at, "ota.publish", publishEnvelope, map[string]string{"version": "1.631.5"}); err != nil {
		t.Fatal(err)
	}
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	receipt := document.Applied["publish-key"]
	if receipt.ModuleCommand != commandPublish || receipt.PayloadSHA256 == "" {
		t.Fatalf("receipt = %+v", receipt)
	}
	// A recovered key with another payload of the same module is refused.
	if _, err := runHandledCommand(t, commands, at, "ota.publish", publishEnvelope, map[string]string{"version": "1.631.6"}); refusalCode(t, err) != operator.CodeKeyReused {
		t.Fatalf("different payload err=%v", err)
	}
	// A recovered key with another module is refused before payload validation.
	if _, err := runHandledCommand(t, commands, at, "ota.withdraw", publishEnvelope, map[string]string{"version": "1.631.5"}); refusalCode(t, err) != operator.CodeKeyReused {
		t.Fatalf("another module err=%v", err)
	}
	// The same command still replays its original reply without a second effect.
	replayed, err := runHandledCommand(t, commands, at, "ota.publish", publishEnvelope, map[string]string{"version": "1.631.5"})
	if err != nil {
		t.Fatal(err)
	}
	var activation Activation
	encoded, ok := replayed.(json.RawMessage)
	if !ok || json.Unmarshal(encoded, &activation) != nil || activation.Version != "1.631.5" || activation.ActivationID != 1 {
		t.Fatalf("replayed reply = %#v", replayed)
	}
	document, err = store.Load()
	if err != nil {
		t.Fatal(err)
	}
	unchanged := document.Applied["publish-key"]
	if len(document.Activations) != 1 || unchanged.ModuleCommand != receipt.ModuleCommand || unchanged.PayloadSHA256 != receipt.PayloadSHA256 || string(unchanged.Result) != string(receipt.Result) {
		t.Fatalf("refused commands changed the file: activations=%+v receipts=%+v", document.Activations, document.Applied)
	}
	if revision, err := store.ActiveRevisionTx(context.Background(), nil); err != nil || revision != 1 {
		t.Fatalf("revision = %d err=%v", revision, err)
	}
}

func TestLegacyReceiptReplaysOnlyForTheSameModule(t *testing.T) {
	store := NewStateFile(t.TempDir())
	legacy, err := json.Marshal(map[string]any{
		"version": 1,
		"applied": map[string]any{
			"legacy-key": map[string]any{
				"activation_id": 7,
				"version":       "1.631.5",
				"action":        "PUBLISH",
				"state":         string(domain.StateActive),
				"at":            time.Unix(1000, 0).UTC(),
			},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(store.Path(), legacy, 0o644); err != nil {
		t.Fatal(err)
	}
	document, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	if receipt := document.Applied["legacy-key"]; receipt.ModuleCommand != "" || receipt.PayloadSHA256 != "" || receipt.Result == nil {
		t.Fatalf("legacy receipt = %+v", receipt)
	}
	result, found, err := store.AppliedResult("legacy-key", commandPublish, "a-different-digest")
	if err != nil || !found {
		t.Fatalf("legacy replay found=%v err=%v", found, err)
	}
	var activation Activation
	if json.Unmarshal(result, &activation) != nil || activation.ActivationID != 7 {
		t.Fatalf("legacy replay result = %s", result)
	}
	if _, _, err := store.AppliedResult("legacy-key", commandWithdraw, "a-different-digest"); refusalCode(t, err) != operator.CodeKeyReused {
		t.Fatalf("legacy replay for another module err=%v", err)
	}
}
