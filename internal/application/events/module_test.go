package events

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func moduleCommand(t *testing.T, module operator.Module, name string) operator.CommandSpec {
	t.Helper()
	for _, command := range module.Commands {
		if command.Name == name {
			return command
		}
	}
	t.Fatalf("module %s does not declare %s", module.ID, name)
	return operator.CommandSpec{}
}

func TestEventsModuleRefusesEachDeclaredRequiredFieldWhenMissing(t *testing.T) {
	commands := Commands{}
	module := commands.Module()
	fixtures := map[string]map[string]any{
		"events.definition.deploy": {
			"activity_id": 1008, "revision": 1, "archetype": "RULE_MODIFIER",
			"hooks":               []any{map[string]any{"hook": "campaign.drop_multiplier", "scope": "normal", "item_kinds": []any{1}, "multiplier": 2}},
			"client_requirements": map[string]any{"lazy_assets": []any{}},
			"default_days":        1,
		},
		"events.definition.list": {"activity_id": 1008, "limit": 10},
		"events.schedule":        {"activity_id": 1008, "logical_server_ids": []any{1}, "start": "2026-11-23T00:00:00Z", "duration": "1d"},
		"events.cancel":          {"occurrence_id": 1},
		"events.end_now":         {"occurrence_id": 1},
		"events.extend":          {"occurrence_id": 1, "duration": "1d"},
		"events.set_permanent":   {"occurrence_id": 1},
		"events.occurrence.show": {"occurrence_id": 1, "limit": 10},
	}
	for name, fixture := range fixtures {
		spec := moduleCommand(t, module, name)
		for _, field := range spec.Fields {
			if !field.Required {
				continue
			}
			payload := make(map[string]any, len(fixture))
			for key, value := range fixture {
				payload[key] = value
			}
			delete(payload, field.Name)
			encoded, err := json.Marshal(payload)
			if err != nil {
				t.Fatal(err)
			}
			_, err = spec.Handler(context.Background(), tx.Scope{}, operator.Command{ModuleCommand: name, Payload: encoded})
			var refusal *operator.Refusal
			if !errors.As(err, &refusal) {
				t.Fatalf("%s without %s: err = %v", name, field.Name, err)
			}
		}
	}
}

func TestEventsListReadRequiresOnlyTheServer(t *testing.T) {
	module := Commands{}.Module()
	if len(module.Reads) != 1 || module.Reads[0].Name != "events.list" {
		t.Fatalf("reads = %+v", module.Reads)
	}
	required := map[string]bool{}
	for _, field := range module.Reads[0].Fields {
		if field.Required {
			required[field.Name] = true
		}
	}
	if len(required) != 1 || !required["server"] {
		t.Fatalf("required read fields = %v", required)
	}
}

func TestEventsModuleDeclaresEveryCommand(t *testing.T) {
	commands := Commands{}
	module := commands.Module()
	if len(module.Commands) != len(commands.Handlers()) {
		t.Fatalf("commands = %+v", module.Commands)
	}
	for name := range commands.Handlers() {
		spec := moduleCommand(t, module, name)
		if spec.Handler == nil {
			t.Fatalf("%s has a bus handler but no module handler", name)
		}
	}
}
