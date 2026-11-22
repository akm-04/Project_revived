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
	if list.Modules[2].Commands[0].Route != operator.RouteAgent {
		t.Fatalf("server commands = %+v", list.Modules[2].Commands)
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
