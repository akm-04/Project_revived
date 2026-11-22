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

// LogsModule is the backend half of the logs module (OPERATOR_BACKUPS_LOGS_DESIGN
// C1d, C2, C4): the redacted client journal timeline and live tail, plus the
// client clear command. The agent merges its file-source reads and command into
// the same module id.
func LogsModule() Module {
	return Module{
		ID:         "logs",
		Title:      "Logs",
		Role:       RoleRoot,
		LogChannel: "logs",
		Screen:     Screen{Tab: "Logs", Columns: []string{"received_at", "player_id", "mid", "outcome", "http_status"}},
		Reads: []Read{
			{Name: "logs.timeline", Help: "Redacted client log timeline by player, account, time, outcome or MID; newest first.", Fields: []Field{
				NewField("uid", FieldString, false, "account uid"),
				NewField("player_id", FieldInt, false, "player id"),
				NewField("from", FieldString, false, "RFC3339 lower bound"),
				NewField("to", FieldString, false, "RFC3339 upper bound"),
				NewField("outcome", FieldString, false, "journal outcome").WithEnum("OK", "CLIENT_ERROR", "SERVER_ERROR", "UNKNOWN_MID", "UNDECODABLE", "INACTIVE_MODE"),
				NewField("level", FieldString, false, "info, warn or error; ignored when outcome is set").WithEnum("info", "warn", "error"),
				NewField("mid", FieldInt, false, "stock MID"),
				NewField("limit", FieldInt, false, "page size").Bounded(1, 200).WithDefault(50),
				NewField("cursor", FieldString, false, "next_cursor of the previous page"),
			}},
			{Name: "logs.tail", Help: "Client journal rows newer than the cursor, oldest first for the live view.", Fields: []Field{
				NewField("after_cursor", FieldString, false, "cursor of the previous poll"),
				NewField("level", FieldString, false, "info, warn or error").WithEnum("info", "warn", "error"),
				NewField("limit", FieldInt, false, "page size").Bounded(1, 200).WithDefault(100),
			}},
		},
		Commands: []CommandSpec{
			{Name: "logs.clear", Class: ClassLive, Help: "Clear client journal logs by scope; the tool log is never cleared.", Fields: []Field{
				NewField("source", FieldString, true, "the client source").WithEnum("client"),
				NewField("scope", FieldString, true, "all, player or older_than").WithEnum("all", "player", "older_than"),
				NewField("uid", FieldString, false, "account uid for the player scope"),
				NewField("player_id", FieldInt, false, "player id for the player scope"),
				NewField("older_than", FieldString, false, "RFC3339 boundary for the older_than scope"),
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
		{ID: "publication", Title: "Publications", LogChannel: "publication", Planned: later, Commands: []CommandSpec{
			{Name: "publication.install", Class: ClassLive, Help: "Install a revisioned publication set."},
			{Name: "publication.clear", Class: ClassLive, Help: "Clear the active publication set."},
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
		{ID: "apk", Title: "APK build", LogChannel: "apk", Planned: later, Commands: []CommandSpec{
			{Name: "apk.build", Class: ClassMaintenance, Help: "Build the Android client APK."},
		}},
	}
}
