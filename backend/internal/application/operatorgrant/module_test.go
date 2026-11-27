package operatorgrant

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	appi5 "gxb.local/backend/v2/internal/application/i5"
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

func TestMailModuleCoversEveryRegisteredHandler(t *testing.T) {
	commands := MailCommands{}
	module := commands.Module()
	handlers := commands.Handlers()
	if len(module.Reads) != 0 {
		t.Fatalf("mail declares reads = %+v", module.Reads)
	}
	if len(module.Commands) != len(handlers) {
		t.Fatalf("commands = %+v, handlers = %v", module.Commands, handlers)
	}
	for name := range handlers {
		spec := moduleCommandByName(t, module, name)
		if spec.Handler == nil {
			t.Fatalf("%s has a bus handler but no module handler", name)
		}
	}
}

func TestMailModuleRefusesEachDeclaredRequiredFieldWhenMissing(t *testing.T) {
	commands := MailCommands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Mail: &fakeMail{}, LineCap: 10}
	spec := moduleCommandByName(t, commands.Module(), CommandMailSend)
	fixture := map[string]any{
		"target": map[string]any{"player_ids": []any{int64(1)}},
		"title":  "Server gift",
		"body":   "Thank you for playing",
		"expire": map[string]any{"on_read": true},
	}
	refusals := map[string]string{"target": CodeGrantTarget, "title": CodeMailTitle, "body": CodeMailBody, "expire": CodeMailExpire}
	assertDeclaredRequiredFields(t, spec, fixture, refusals)
	assertFieldBounds(t, spec, "title", 1, MaxMailTitleRunes)
	assertFieldBounds(t, spec, "body", 1, MaxMailBodyRunes)
}

func TestRedeemModuleCoversEveryRegisteredHandlerAndRead(t *testing.T) {
	commands := RedeemCommands{}
	module := commands.Module()
	handlers := commands.Handlers()
	if len(module.Commands) != len(handlers) {
		t.Fatalf("commands = %+v, handlers = %v", module.Commands, handlers)
	}
	for name := range handlers {
		if spec := moduleCommandByName(t, module, name); spec.Handler == nil {
			t.Fatalf("%s has a bus handler but no module handler", name)
		}
	}
	if len(module.Reads) != 1 || module.Reads[0].Name != "redeem.list" {
		t.Fatalf("reads = %+v", module.Reads)
	}
	limit := fieldNamed(t, module.Reads[0].Fields, "limit")
	if limit.Minimum == nil || *limit.Minimum != 1 || limit.Maximum == nil || *limit.Maximum != appi5.MaxRedeemListLimit {
		t.Fatalf("redeem.list limit = %+v", limit)
	}
}

func TestRedeemModuleRefusesEachDeclaredRequiredFieldWhenMissing(t *testing.T) {
	commands := RedeemCommands{Catalogue: testCatalogue(t), Redeem: &redeemingOwner{}, LineCap: 10}
	module := commands.Module()
	create := moduleCommandByName(t, module, CommandRedeemCreate)
	assertDeclaredRequiredFields(t, create, map[string]any{
		"code":  "GIFT2026",
		"lines": []any{map[string]any{"id": "stack_item:50001010", "amount": int64(1)}},
	}, map[string]string{"lines": CodeGrantLines})
	disable := moduleCommandByName(t, module, CommandRedeemDisable)
	assertDeclaredRequiredFields(t, disable, map[string]any{"code": "GIFT2026"}, map[string]string{"code": CodeRedeemCode})
}

func assertDeclaredRequiredFields(t *testing.T, spec operator.CommandSpec, fixture map[string]any, refusals map[string]string) {
	t.Helper()
	required := map[string]bool{}
	for _, field := range spec.Fields {
		if field.Required {
			required[field.Name] = true
		}
	}
	if len(required) != len(refusals) {
		t.Fatalf("%s required fields = %v, refusals = %v", spec.Name, required, refusals)
	}
	for name, code := range refusals {
		if !required[name] {
			t.Fatalf("%s does not declare %s required", spec.Name, name)
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
		_, err = spec.Handler(context.Background(), testScope(), operator.Command{ModuleCommand: spec.Name, Payload: encoded})
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != code {
			t.Fatalf("%s without %s: err = %v, want %s", spec.Name, name, err, code)
		}
	}
}

func moduleCommandByName(t *testing.T, module operator.Module, name string) operator.CommandSpec {
	t.Helper()
	for _, command := range module.Commands {
		if command.Name == name {
			return command
		}
	}
	t.Fatalf("module %s does not declare %s", module.ID, name)
	return operator.CommandSpec{}
}

func fieldNamed(t *testing.T, fields []operator.Field, name string) operator.Field {
	t.Helper()
	for _, field := range fields {
		if field.Name == name {
			return field
		}
	}
	t.Fatalf("no field %s", name)
	return operator.Field{}
}

func assertFieldBounds(t *testing.T, spec operator.CommandSpec, name string, minimum, maximum int64) {
	t.Helper()
	field := fieldNamed(t, spec.Fields, name)
	if field.Minimum == nil || *field.Minimum != minimum || field.Maximum == nil || *field.Maximum != maximum {
		t.Fatalf("%s bounds = %v..%v, want %d..%d", name, field.Minimum, field.Maximum, minimum, maximum)
	}
}
