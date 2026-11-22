package identitylifecycle

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func moduleCommand(t *testing.T, name string) operator.CommandSpec {
	t.Helper()
	for _, command := range (LogoutCommands{}).Module().Commands {
		if command.Name == name {
			return command
		}
	}
	t.Fatalf("session module does not declare %s", name)
	return operator.CommandSpec{}
}

func TestSessionModuleDeclaresItsAnyOfAndNoRequiredField(t *testing.T) {
	spec := moduleCommand(t, "session.logout")
	for _, field := range spec.Fields {
		if field.Required {
			t.Fatalf("%s is declared required, but either target kind may be omitted", field.Name)
		}
	}
	if len(spec.AnyOf) != 2 {
		t.Fatalf("any_of = %v", spec.AnyOf)
	}
}

func TestSessionLogoutRefusesACommandWithNoTarget(t *testing.T) {
	spec := moduleCommand(t, "session.logout")
	_, err := spec.Handler(context.Background(), tx.Scope{}, operator.Command{ModuleCommand: "session.logout", Payload: json.RawMessage(`{}`)})
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) {
		t.Fatalf("err = %v", err)
	}
}

func TestSessionModuleCoversBothCommands(t *testing.T) {
	commands := LogoutCommands{}
	module := commands.Module()
	if len(module.Commands) != 2 {
		t.Fatalf("commands = %+v", module.Commands)
	}
	for name := range commands.Handlers() {
		if spec := moduleCommand(t, name); spec.Handler == nil {
			t.Fatalf("%s has a bus handler but no module handler", name)
		}
	}
}
