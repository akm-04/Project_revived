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
			{Name: "server.restart", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Stop the backend process and start it again; a failure after the stop leaves it stopped.", Fields: []operator.Field{
				operator.NewField("closed", operator.FieldBool, false, "start without binding the game listener"),
			}},
			{Name: "server.stop", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Stop the backend process."},
			{Name: "server.status", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Report whether the backend process is running."},
			{Name: "server.url.set", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Set the client-facing server URL in the backend env file; the APK must be rebuilt with it.", Fields: []operator.Field{
				operator.NewField("url", operator.FieldString, true, "absolute http or https address the clients reach"),
			}},
			{Name: "server.public_urls.set", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Set the role-keyed public URLs (public_urls.sdk, .api, .assets); the game API URL is also written to the backend env file. Unknown roles are refused.", Fields: []operator.Field{
				operator.NewField("sdk", operator.FieldString, false, "SDK URL; absolute http or https"),
				operator.NewField("api", operator.FieldString, false, "game API URL; absolute http or https"),
				operator.NewField("assets", operator.FieldString, false, "assets URL; absolute http or https"),
			}},
		},
	}
}

// AgentSettingsModule is the agent's own settings module (G22): the paths in
// agent.json and the backend URL in its env file. The OTA paths stay in the ota
// module and are changed through ota.settings.set.
func AgentSettingsModule() operator.Module {
	return operator.Module{
		ID:         "agent",
		Title:      "Agent settings",
		Role:       operator.RoleRoot,
		LogChannel: "agent",
		Screen:     operator.Screen{Tab: "Settings"},
		Commands: []operator.CommandSpec{
			{Name: "agent.settings.set", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Set the agent.json paths; every value is validated and a refused value keeps the old one.", Fields: []operator.Field{
				operator.NewField("backend_path", operator.FieldString, false, "absolute path of the gxb-api binary"),
				operator.NewField("backup_path", operator.FieldString, false, "absolute snapshot folder; empty restores <agent root>/backups"),
				operator.NewField("app_repack_path", operator.FieldString, false, "absolute app_repack folder for the APK build"),
				operator.NewField("toolchain_path", operator.FieldString, false, "portable tools folder; empty uses the system PATH"),
			}},
		},
		Reads: []operator.Read{
			{Name: "agent.settings", Help: "Current agent paths, the backend URL and the OTA settings."},
			{Name: "agent.fs.list", Help: "List the folders, and with show_files the files, of one folder for the path picker; names only.", Fields: []operator.Field{
				operator.NewField("path", operator.FieldString, false, "absolute folder to list; empty uses the agent root"),
				operator.NewField("show_files", operator.FieldBool, false, "include files beside the folders"),
			}},
			{Name: "agent.cli.usage", Help: "The operator CLI help text and one row per command, the same text the CLI prints."},
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
				operator.NewField("version", operator.FieldString, false, "release number; omitted builds the lane's next last-component increment; a lower number is a rollback"),
				operator.NewField("rollback", operator.FieldBool, false, "acknowledge a number below the lane's active release; clients must clear app data or reinstall to take it"),
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

// BackupModule is the agent's backup module (B1-B7): snapshots, listing,
// pruning, restore and the update-backend maintenance flow all run in the
// agent, so they work while the backend or database is down.
func BackupModule() operator.Module {
	return operator.Module{
		ID:         "backup",
		Title:      "Backups",
		Role:       operator.RoleRoot,
		LogChannel: "backup",
		Screen:     operator.Screen{Tab: "Backups", Columns: []string{"id", "name", "pinned", "kind", "created_at", "size", "migration", "damaged"}},
		Commands: []operator.CommandSpec{
			{Name: "backup.snapshot", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Take a database snapshot.", Fields: []operator.Field{
				operator.NewField("kind", operator.FieldString, false, "manual, safety, pre-update or pre-delete").WithEnum("manual", "safety", "pre-update", "pre-delete").WithDefault("manual"),
				operator.NewField("name", operator.FieldString, false, "snapshot name, 1-80 printable characters"),
				operator.NewField("pin", operator.FieldBool, false, "keep this snapshot: pinned snapshots are never pruned"),
			}},
			{Name: "backup.list", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "List snapshots newest first, with the newest age and damage state."},
			{Name: "backup.prune", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Delete all but the newest backup_keep snapshots; pinned snapshots stay."},
			{Name: "backup.pin", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Name a snapshot and keep it out of every prune.", Fields: []operator.Field{
				operator.NewField("id", operator.FieldString, true, "snapshot id from backup.list"),
				operator.NewField("name", operator.FieldString, true, "name, 1-80 printable characters"),
			}},
			{Name: "backup.unpin", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Return a pinned snapshot to normal pruning.", Fields: []operator.Field{
				operator.NewField("id", operator.FieldString, true, "snapshot id from backup.list"),
			}},
			{Name: "backup.restore", Class: operator.ClassMaintenance, Route: operator.RouteAgent, Help: "Restore a snapshot with a safety snapshot and a rename swap.", Fields: []operator.Field{
				operator.NewField("id", operator.FieldString, true, "snapshot id from backup.list"),
			}},
			{Name: "backup.update_backend", Class: operator.ClassMaintenance, Route: operator.RouteAgent, Help: "Snapshot, stop the backend, then swap the binary and start."},
		},
	}
}

// AgentLogsModule is the agent half of the logs module (L1-L4): the file
// sources, the live tail cursor and the clear command. The backend contributes
// logs.timeline and the client source reads; MergeModules keeps both halves.
func AgentLogsModule() operator.Module {
	return operator.Module{
		ID:         "logs",
		Title:      "Logs",
		Role:       operator.RoleRoot,
		LogChannel: "logs",
		Screen:     operator.Screen{Tab: "Logs", Columns: []string{"at", "level", "text"}},
		Reads: []operator.Read{
			{Name: "logs.tail", Help: "Tail one log source with a cursor; poll every 2 s for the live view.", Fields: []operator.Field{
				operator.NewField("source", operator.FieldString, true, "tool, backend, database or client").WithEnum(LogSourceTool, LogSourceBackend, LogSourceDatabase, LogSourceClient),
				operator.NewField("after_cursor", operator.FieldString, false, "next_cursor of the previous poll"),
				operator.NewField("level", operator.FieldString, false, "info, warn or error").WithEnum("info", "warn", "error"),
				operator.NewField("limit", operator.FieldInt, false, "page size").Bounded(1, MaxLogTailLimit).WithDefault(DefaultLogTailLimit),
			}},
			{Name: "logs.search", Help: "Search one log source, newest first; the client source takes a player id or name.", Fields: []operator.Field{
				operator.NewField("source", operator.FieldString, true, "tool, backend, database or client").WithEnum(LogSourceTool, LogSourceBackend, LogSourceDatabase, LogSourceClient),
				operator.NewField("player", operator.FieldString, false, "player id or name (client source)"),
				operator.NewField("from", operator.FieldString, false, "RFC3339 lower bound"),
				operator.NewField("to", operator.FieldString, false, "RFC3339 upper bound"),
				operator.NewField("level", operator.FieldString, false, "info, warn or error").WithEnum("info", "warn", "error"),
				operator.NewField("limit", operator.FieldInt, false, "page size").Bounded(1, MaxLogTailLimit).WithDefault(DefaultLogTailLimit),
			}},
		},
		Commands: []operator.CommandSpec{
			{Name: "logs.clear", Class: operator.ClassLive, Route: operator.RouteAgent, Help: "Clear client logs through the backend or the backend process log; the tool log is never cleared.", Fields: []operator.Field{
				operator.NewField("source", operator.FieldString, true, "client or backend").WithEnum(LogSourceClient, LogSourceBackend),
				operator.NewField("scope", operator.FieldString, true, "all, player or older_than").WithEnum("all", "player", "older_than"),
				operator.NewField("player", operator.FieldString, false, "player id or name (client source)"),
				operator.NewField("older_than", operator.FieldString, false, "RFC3339 boundary for the older_than scope"),
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
