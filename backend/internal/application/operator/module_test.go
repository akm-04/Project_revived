package operator

import (
	"context"
	"encoding/json"
	"errors"
	"net/url"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func handlerStub() Handler {
	return func(context.Context, tx.Scope, Command) (any, error) { return nil, nil }
}

func readStub(context.Context, url.Values) (any, error) { return nil, nil }

func testModule(id string, commandNames ...string) Module {
	commands := make([]CommandSpec, 0, len(commandNames))
	for _, name := range commandNames {
		commands = append(commands, CommandSpec{Name: name, Class: ClassLive, Handler: handlerStub()})
	}
	return Module{ID: id, Title: id, Commands: commands}
}

func TestRegistryDerivesHandlersReadsAndPlannedRows(t *testing.T) {
	registry, err := NewRegistry(
		testModule("alpha", "alpha.one", "alpha.two"),
		Module{ID: "beta", Title: "beta", Reads: []Read{{Name: "beta.read", Handler: readStub}}},
		Module{ID: "planned", Title: "planned", Planned: "later", Commands: []CommandSpec{{Name: "planned.run", Class: ClassLive}}},
	)
	if err != nil {
		t.Fatal(err)
	}
	handlers := registry.Handlers()
	if len(handlers) != 2 || handlers["alpha.one"] == nil || handlers["alpha.two"] == nil {
		t.Fatalf("handlers = %v", handlers)
	}
	reads := registry.Reads()
	if len(reads) != 1 || reads["beta.read"] == nil {
		t.Fatalf("reads = %v", reads)
	}
	modules := registry.Modules()
	if len(modules) != 3 || modules[2].Planned != "later" {
		t.Fatalf("modules = %+v", modules)
	}
}

func TestRegistryFailsClosedOnADeclarationWithoutHandler(t *testing.T) {
	cases := map[string]Module{
		"command": {ID: "alpha", Title: "alpha", Commands: []CommandSpec{{Name: "alpha.one", Class: ClassLive}}},
		"read":    {ID: "alpha", Title: "alpha", Reads: []Read{{Name: "alpha.read"}}},
		"title":   {ID: "alpha"},
		"prefix":  {ID: "alpha", Title: "alpha", Commands: []CommandSpec{{Name: "beta.one", Class: ClassLive, Handler: handlerStub()}}},
		"class":   {ID: "alpha", Title: "alpha", Commands: []CommandSpec{{Name: "alpha.one", Handler: handlerStub()}}},
	}
	for name, module := range cases {
		if _, err := NewRegistry(module); err == nil {
			t.Fatalf("%s: an invalid module was accepted", name)
		}
	}
	if _, err := NewRegistry(testModule("alpha", "alpha.one"), testModule("alpha", "alpha.two")); err == nil {
		t.Fatal("a duplicate module id was accepted")
	}
}

func TestBindRefusesHandlersForUndeclaredNames(t *testing.T) {
	module := testModule("alpha", "alpha.one")
	if _, err := module.BindCommands(map[string]Handler{"alpha.ghost": handlerStub()}); err == nil {
		t.Fatal("a command handler outside the module was accepted")
	}
	if _, err := module.BindReads(map[string]ReadHandler{"alpha.read": readStub}); err == nil {
		t.Fatal("a read handler outside the module was accepted")
	}
}

// A command that no module registered cannot reach an owner: the bus refuses
// it before it looks at any handler.
func TestCommandOutsideEveryModuleIsRefused(t *testing.T) {
	registry, err := NewRegistry(testModule("alpha", "alpha.one"))
	if err != nil {
		t.Fatal(err)
	}
	bus := Bus{Runner: tx.Runner{DB: stubBeginner{}}, Clock: clock.System{}, Store: stubCommandStore{}, Handlers: registry.Handlers()}
	command, err := NewCommand("mail.send", Envelope{Principal: "root", Role: RoleRoot, Scope: "global", Reason: "test", SemanticKey: "k1"}, json.RawMessage(`{}`))
	if err != nil {
		t.Fatal(err)
	}
	_, err = bus.Execute(context.Background(), command)
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeUnknownCommand {
		t.Fatalf("err = %v", err)
	}
}

func TestMergeModulesKeepsBackendEntriesAndOverridesByName(t *testing.T) {
	backend := []Module{
		{ID: "ota", Title: "OTA", Commands: []CommandSpec{
			{Name: "ota.register_build", Class: ClassMaintenance},
			{Name: "ota.publish", Class: ClassMaintenance, Help: "backend"},
			{Name: "ota.settings.set", Class: ClassLive},
		}},
		{ID: "mail", Title: "Mail", Planned: "O3", Commands: []CommandSpec{{Name: "mail.send", Class: ClassLive}}},
	}
	local := []Module{
		{ID: "ota", Title: "OTA", Commands: []CommandSpec{
			{Name: "ota.publish", Class: ClassMaintenance, Route: RouteAgent, Help: "agent"},
			{Name: "ota.build", Class: ClassLive, Route: RouteAgent},
		}},
		{ID: "server", Title: "Server", Commands: []CommandSpec{{Name: "server.status", Class: ClassLive, Route: RouteAgent}}},
	}
	merged := MergeModules(backend, local)
	if len(merged) != 3 || merged[2].ID != "server" {
		t.Fatalf("merged modules = %+v", merged)
	}
	ota := merged[0]
	if len(ota.Commands) != 4 {
		t.Fatalf("ota commands = %+v", ota.Commands)
	}
	for _, command := range ota.Commands {
		if command.Name == "ota.publish" && (command.Route != RouteAgent || command.Help != "agent") {
			t.Fatalf("the agent ota.publish did not override: %+v", command)
		}
	}
	if merged[1].Planned != "O3" {
		t.Fatalf("the planned row was lost: %+v", merged[1])
	}
}

// player.find declares uid and name_prefix as its any-of target, and the
// service refuses an empty filter (the adapter only parses the query).
func TestPlayerFindReadRefusesAnEmptyFilter(t *testing.T) {
	find := PlayerModule().Reads[0]
	if find.Name != "player.find" || len(find.AnyOf) != 2 {
		t.Fatalf("read = %+v", find)
	}
	service := PlayerReadService{Runner: tx.Runner{DB: stubBeginner{}}, Directory: stubDirectory{}}
	_, err := service.Find(context.Background(), playerdirectory.OperatorFind{})
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeReadInvalid {
		t.Fatalf("err = %v", err)
	}
}

type stubDirectory struct{}

func (stubDirectory) FindPlayersTx(context.Context, tx.Queryer, playerdirectory.OperatorFind) ([]playerdirectory.OperatorPlayer, error) {
	return nil, errors.New("unused fake directory")
}

func (stubDirectory) OperatorPlayerTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.OperatorPlayer, bool, error) {
	return playerdirectory.OperatorPlayer{}, false, errors.New("unused fake directory")
}

type stubBeginner struct{}

func (stubBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return nil, errors.New("unused fake runner")
}

type stubCommandStore struct{}

func (stubCommandStore) ClaimTx(context.Context, tx.Tx, Command, time.Time) (*Record, error) {
	return nil, errors.New("unused fake store")
}
func (stubCommandStore) RetryFailedTx(context.Context, tx.Tx, string) error {
	return errors.New("unused fake store")
}
func (stubCommandStore) FinishTx(context.Context, tx.Tx, string, string, json.RawMessage, time.Time) error {
	return errors.New("unused fake store")
}
func (stubCommandStore) ReadTx(context.Context, tx.Queryer, string) (*Record, error) {
	return nil, errors.New("unused fake store")
}
