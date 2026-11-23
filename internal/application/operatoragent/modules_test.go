package operatoragent

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
)

type fakeBackendModules struct {
	modules []operator.Module
	err     error
}

func (source fakeBackendModules) Modules(context.Context) ([]operator.Module, error) {
	return source.modules, source.err
}

func TestModuleCatalogMergesTheAgentCommandsIntoTheBackendList(t *testing.T) {
	backend := []operator.Module{
		{ID: "ota", Title: "OTA", Commands: []operator.CommandSpec{
			{Name: "ota.register_build", Class: operator.ClassMaintenance},
			{Name: "ota.publish", Class: operator.ClassMaintenance},
			{Name: "ota.settings.set", Class: operator.ClassLive},
		}},
		{ID: "mail", Title: "Mail", Planned: "O3"},
	}
	catalog := ModuleCatalog{Backend: fakeBackendModules{modules: backend}, Local: []operator.Module{ServerModule(), AgentOTAModule()}}
	list := catalog.List(context.Background())
	if list.BackendError != "" {
		t.Fatalf("backend error = %q", list.BackendError)
	}
	if len(list.Modules) != 3 || list.Modules[0].ID != "ota" || list.Modules[2].ID != "server" {
		t.Fatalf("modules = %+v", list.Modules)
	}
	publish, build, registerBuild, settings := false, false, false, false
	for _, command := range list.Modules[0].Commands {
		switch command.Name {
		case "ota.publish":
			publish = command.Route == operator.RouteAgent
		case "ota.build":
			build = command.Route == operator.RouteAgent
		case "ota.register_build":
			registerBuild = true
		case "ota.settings.set":
			settings = true
		}
	}
	if !publish || !build || !registerBuild || !settings {
		t.Fatalf("merged ota commands = %+v", list.Modules[0].Commands)
	}
	serverRoutes := map[string]string{}
	for _, command := range list.Modules[2].Commands {
		serverRoutes[command.Name] = command.Route
	}
	for _, name := range []string{"server.start", "server.restart", "server.stop", "server.status", "server.url.set"} {
		if serverRoutes[name] != operator.RouteAgent {
			t.Fatalf("server command %q route = %q", name, serverRoutes[name])
		}
	}
}

func TestModuleCatalogStillAnswersTheAgentModulesWithoutTheBackend(t *testing.T) {
	catalog := ModuleCatalog{Backend: fakeBackendModules{err: errors.New("down")}, Local: []operator.Module{ServerModule()}}
	list := catalog.List(context.Background())
	if list.BackendError == "" {
		t.Fatal("the backend failure was not reported")
	}
	if len(list.Modules) != 1 || list.Modules[0].ID != "server" {
		t.Fatalf("modules = %+v", list.Modules)
	}
}

func TestBackupModuleIsRegisteredAsAnAgentModule(t *testing.T) {
	module := BackupModule()
	if module.ID != "backup" || module.Planned != "" || len(module.Commands) != 5 {
		t.Fatalf("module = %+v", module)
	}
	for _, command := range module.Commands {
		if command.Route != operator.RouteAgent {
			t.Fatalf("command %q route = %q", command.Name, command.Route)
		}
	}
	for _, planned := range operator.PlannedModules() {
		if planned.ID == "backup" {
			t.Fatal("the backend still declares backup as a later leaf")
		}
	}
	catalog := ModuleCatalog{Backend: fakeBackendModules{}, Local: []operator.Module{BackupModule()}}
	list := catalog.List(context.Background())
	if len(list.Modules) != 1 || list.Modules[0].ID != "backup" || list.Modules[0].Planned != "" {
		t.Fatalf("merged list = %+v", list.Modules)
	}
	for _, command := range list.Modules[0].Commands {
		if command.Name == "backup.restore" {
			if len(command.Fields) != 1 || command.Fields[0].Name != "id" || !command.Fields[0].Required {
				t.Fatalf("backup.restore fields = %+v", command.Fields)
			}
			return
		}
	}
	t.Fatal("backup.restore is not declared")
}

func TestLogsModuleMergesTheAgentAndBackendHalves(t *testing.T) {
	catalog := ModuleCatalog{
		Backend: fakeBackendModules{modules: []operator.Module{operator.LogsModule()}},
		Local:   []operator.Module{AgentLogsModule()},
	}
	list := catalog.List(context.Background())
	if len(list.Modules) != 1 || list.Modules[0].ID != "logs" {
		t.Fatalf("modules = %+v", list.Modules)
	}
	reads := map[string]bool{}
	for _, read := range list.Modules[0].Reads {
		reads[read.Name] = true
	}
	for _, name := range []string{"logs.tail", "logs.search", "logs.timeline"} {
		if !reads[name] {
			t.Fatalf("missing read %s in %+v", name, list.Modules[0].Reads)
		}
	}
	if len(list.Modules[0].Commands) != 1 || list.Modules[0].Commands[0].Name != "logs.clear" || list.Modules[0].Commands[0].Route != operator.RouteAgent {
		t.Fatalf("logs commands = %+v", list.Modules[0].Commands)
	}
}
