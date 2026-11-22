package operatoragent

import (
	"context"

	"gxb.local/backend/v2/internal/application/operator"
)

// ServerModule is the agent's server module (I11A_ARCHITECTURE_V1 S1-S4): the
// process control commands the agent runs itself, so they still work when the
// backend or the database is down.
func ServerModule() operator.Module {
	return operator.Module{
		ID:         "server",
		Title:      "Server",
		Role:       operator.RoleRoot,
		LogChannel: "server",
		Screen:     operator.Screen{Tab: "Server", Columns: []string{"running", "pid", "state"}},
		Commands: []operator.CommandSpec{
			{Name: "server.start", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Start the backend process.", Fields: []operator.Field{
				operator.NewField("closed", operator.FieldBool, false, "start without binding the game listener"),
			}},
			{Name: "server.stop", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Stop the backend process."},
			{Name: "server.status", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Report whether the backend process is running."},
		},
	}
}

// AgentOTAModule is the agent's ota module: the commands the agent runs as a
// long operation or a maintenance window (I11A_1_PLAN L4c). Its entries merge
// by name into the backend ota module, so ota.settings.set and
// ota.register_build stay listed.
func AgentOTAModule() operator.Module {
	return operator.Module{
		ID:         "ota",
		Title:      "OTA releases",
		Role:       operator.RoleRoot,
		LogChannel: "ota",
		Commands: []operator.CommandSpec{
			{Name: "ota.build", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Build a release offline; poll the returned operation id.", Fields: []operator.Field{
				operator.NewField("lane", operator.FieldString, true, "artifact lane").WithEnum("code", "assets", "catalog"),
				operator.NewField("version", operator.FieldString, false, "release number; omitted builds the lane's next last-component increment, a rollback names the lower number"),
				operator.NewField("rollback", operator.FieldBool, false, "allow a number below the lane's active release"),
				operator.NewField("lazy_refresh", operator.FieldBool, false, "rewrite lazyFile.json from the active assets release"),
			}},
			{Name: "ota.publish", Class: operator.ClassMaintenance, Route: operator.RouteAgent, Help: "Publish inside a maintenance window.", Fields: []operator.Field{
				operator.NewField("version", operator.FieldString, true, "release number"),
			}},
			{Name: "ota.withdraw", Class: operator.ClassMaintenance, Route: operator.RouteAgent, Help: "Withdraw an active release; installed clients keep it.", Fields: []operator.Field{
				operator.NewField("version", operator.FieldString, true, "release number"),
			}},
		},
	}
}

// ModuleSource is the agent's outbound module-list port.
type ModuleSource interface {
	Modules(context.Context) ([]operator.Module, error)
}

// ModuleLister answers the agent's merged module list.
type ModuleLister interface {
	List(context.Context) AgentModules
}

// AgentModules is GET /agent/v1/modules: the merged list and, when the backend
// is down, why only the agent's own modules are present.
type AgentModules struct {
	Modules      []operator.Module `json:"modules"`
	BackendError string            `json:"backend_error,omitempty"`
}

// ModuleCatalog merges the backend's module list with the agent's own modules.
// A backend failure still answers the agent's modules: the operator tool keeps
// working while the backend is down (S2).
type ModuleCatalog struct {
	Backend ModuleSource
	Local   []operator.Module
}

// List answers the merged module list.
func (catalog ModuleCatalog) List(ctx context.Context) AgentModules {
	if catalog.Backend == nil {
		return AgentModules{Modules: operator.MergeModules(nil, catalog.Local)}
	}
	backend, err := catalog.Backend.Modules(ctx)
	if err != nil {
		return AgentModules{Modules: operator.MergeModules(nil, catalog.Local), BackendError: "the backend module list is unavailable"}
	}
	return AgentModules{Modules: operator.MergeModules(backend, catalog.Local)}
}
