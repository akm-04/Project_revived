package operatorgrant

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
)

func TestGrantModuleCoversEveryRegisteredHandler(t *testing.T) {
	commands := Commands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Grants: &fakeGrants{}, LineCap: 10}
	module := commands.Module()
	for name := range commands.Handlers() {
		if module.Commands[0].Name != name || module.Commands[0].Handler == nil {
			t.Fatalf("%s is not the module command", name)
		}
	}
}

func TestGrantModuleRefusesEachDeclaredRequiredFieldWhenMissing(t *testing.T) {
	commands := Commands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Grants: &fakeGrants{}, LineCap: 10}
	module := commands.Module()
	if len(module.Commands) != 1 {
		t.Fatalf("commands = %+v", module.Commands)
	}
	spec := module.Commands[0]
	fixture := map[string]any{
		"target": map[string]any{"player_ids": []any{int64(1)}},
		"lines":  []any{map[string]any{"id": "50001010", "amount": int64(1)}},
	}
	required := map[string]bool{}
	for _, field := range spec.Fields {
		if field.Required {
			required[field.Name] = true
			continue
		}
		t.Fatalf("%s is declared optional", field.Name)
	}
	for _, name := range []string{"target", "lines"} {
		if !required[name] {
			t.Fatalf("%s is not declared required", name)
		}
		payload := make(map[string]any, len(fixture))
		for key, value := range fixture {
			payload[key] = value
		}
		delete(payload, name)
		encoded, err := json.Marshal(payload)
		if err != nil {
			t.Fatal(err)
		}
		_, err = spec.Handler(context.Background(), testScope(), operator.Command{ModuleCommand: CommandGrantItems, Payload: encoded})
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) {
			t.Fatalf("grant.items without %s: err = %v", name, err)
		}
	}
}
