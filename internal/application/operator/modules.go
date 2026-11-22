package operator

// PlayerModule is the player module (I11A_OPERATOR_COMMANDS_V1 N3): the two
// bounded, read-only player reads. It has no command, so an operator cannot edit
// a player through it.
func PlayerModule() Module {
	return Module{
		ID:         "player",
		Title:      "Players",
		Role:       RoleRoot,
		LogChannel: "player",
		Screen:     Screen{Tab: "Players", Columns: []string{"player_id", "name", "level", "logical_server_id", "last_login"}},
		Reads: []Read{
			{Name: "player.find", Help: "Find players by uid or name prefix.", Fields: []Field{
				NewField("uid", FieldString, false, "exact account uid"),
				NewField("name_prefix", FieldString, false, "player name prefix"),
				NewField("server_id", FieldInt, false, "logical server id filter"),
				NewField("limit", FieldInt, false, "page size").Bounded(1, maxPlayerFindLimit),
			}, AnyOf: []string{"uid", "name_prefix"}},
			{Name: "player.summary", Help: "Identity and wallet facts of one player.", Fields: []Field{
				NewField("player_id", FieldInt, true, "player id"),
			}},
		},
	}
}

// ServerModule is the backend's server read module (OPERATOR_GUI_V2 design
// item 1). Its commands are the agent's, merged into this module by id.
func ServerModule() Module {
	return Module{
		ID:         ModServer,
		Title:      "Server",
		Role:       RoleRoot,
		LogChannel: "server",
		Screen:     Screen{Tab: "Server", Columns: []string{"server_id", "name", "open", "online_count"}},
		Reads: []Read{
			{Name: "server.list", Help: "Registered logical servers with their live session count."},
		},
	}
}

// OperatorModule is the operator module (audit and bulk progress). Its two
// reads are the only operator-tool state that comes from the bus itself.
func OperatorModule() Module {
	return Module{
		ID:         "operator",
		Title:      "Operator",
		Role:       RoleRoot,
		LogChannel: "operator",
		Screen:     Screen{Tab: "Audit", Columns: []string{"created_at", "module_command", "principal", "state", "semantic_key"}},
		Reads: []Read{
			{Name: "operator.audit.list", Help: "Newest first audit rows of the command bus.", Fields: []Field{
				NewField("from", FieldString, false, "RFC3339 lower bound"),
				NewField("to", FieldString, false, "RFC3339 upper bound"),
				NewField("module", FieldString, false, "module or module.command filter"),
				NewField("principal", FieldString, false, "operator principal filter"),
				NewField("semantic_key", FieldString, false, "idempotency key filter"),
				NewField("limit", FieldInt, false, "page size").Bounded(1, maxAuditLimit),
				NewField("cursor", FieldString, false, "next_cursor of the previous page"),
			}},
			{Name: "operator.bulk.show", Help: "Progress of one frozen bulk target.", Fields: []Field{
				NewField("semantic_key", FieldString, true, "command key of the bulk command"),
			}},
		},
	}
}

// PlannedModules are registered modules whose owner slot is not built yet
// (I11A_OPERATOR_COMMANDS_V1 ruling 4: an unbuilt owner is not registered).
// Their commands are declarations only and cannot be called.
func PlannedModules() []Module {
	later := "later leaf"
	return []Module{
		{ID: "gm", Title: "GM questions", LogChannel: "gm", Planned: later, Commands: []CommandSpec{
			{Name: "gm.list", Class: ClassLive, Help: "Player questions inbox."},
			{Name: "gm.answer", Class: ClassLive, Help: "Answer one stored question."},
			{Name: "gm.catcher_mode", Class: ClassLive, Help: "Off, allow-list or everyone."},
		}},
		{ID: "tuning", Title: "Tuning overlays", LogChannel: "tuning", Planned: later, Commands: []CommandSpec{
			{Name: "tuning.get", Class: ClassLive, Help: "Read one overlay (one command per overlay)."},
			{Name: "tuning.set", Class: ClassLive, Help: "Write one overlay with an expected revision."},
			{Name: "tuning.restore", Class: ClassLive, Help: "Restore one overlay revision."},
			{Name: "tuning.reset", Class: ClassLive, Help: "Reset one overlay to its factory default."},
		}},
		{ID: "backup", Title: "Backups", LogChannel: "backup", Planned: later, Commands: []CommandSpec{
			{Name: "backup.snapshot", Class: ClassMaintenance, Help: "Take a backup."},
			{Name: "backup.list", Class: ClassLive, Help: "List snapshots."},
			{Name: "backup.restore", Class: ClassMaintenance, Help: "Restore a snapshot."},
			{Name: "backup.prune", Class: ClassMaintenance, Help: "Prune old snapshots."},
		}},
		{ID: "logs", Title: "Logs", LogChannel: "logs", Planned: later, Reads: []Read{
			{Name: "logs.timeline", Help: "Redacted client log timeline by player, account, time, outcome or MID."},
		}},
		{ID: "apk", Title: "APK build", LogChannel: "apk", Planned: later, Commands: []CommandSpec{
			{Name: "apk.build", Class: ClassMaintenance, Help: "Build the Android client APK."},
		}},
	}
}
