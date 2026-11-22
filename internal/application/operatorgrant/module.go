package operatorgrant

import (
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
)

// Module is the grant module (I11A_OPERATOR_COMMANDS_V1 M2/M8): catalogue
// checked grant.items, inline up to InlineRecipientLimit recipients and a bulk
// job above it.
func (commands Commands) Module() operator.Module {
	return operator.Module{
		ID:         "grant",
		Title:      "Grants",
		Role:       operator.RoleRoot,
		LogChannel: "grant",
		Screen:     operator.Screen{Tab: "Grants", Columns: []string{"semantic_key", "player_count", "applied", "refused", "state"}},
		Commands: []operator.CommandSpec{
			{Name: CommandGrantItems, Class: operator.ClassLive, Help: "Grant catalogue lines to players, one server or every player.", Fields: []operator.Field{
				operator.NewField("target", operator.FieldObject, true, "exactly one of player_ids, server_id or global"),
				operator.NewField("lines", operator.FieldArray, true, "one to fifty {id, amount} lines; amount 1 to the grant cap"),
			}, Handler: commands.grantHandler},
		},
	}
}

// Module is the mail module (I11A_OPERATOR_COMMANDS_V1 M1/M11): GM mail with a
// fixed or read-based expiry, inline or as a bulk job like grant.items.
func (commands MailCommands) Module() operator.Module {
	return operator.Module{
		ID:         "mail",
		Title:      "Mail",
		Role:       operator.RoleRoot,
		LogChannel: "mail",
		Screen:     operator.Screen{Tab: "Mail", Columns: []string{"semantic_key", "player_count", "applied", "refused", "state"}},
		Commands: []operator.CommandSpec{
			{Name: CommandMailSend, Class: operator.ClassLive, Help: "Send GM mail to players, one server or everyone.", Fields: []operator.Field{
				operator.NewField("target", operator.FieldObject, true, "exactly one of player_ids, server_id or global"),
				operator.NewField("title", operator.FieldString, true, "mail title").Bounded(1, MaxMailTitleRunes),
				operator.NewField("body", operator.FieldString, true, "mail body").Bounded(1, MaxMailBodyRunes),
				operator.NewField("attachments", operator.FieldArray, false, "up to fifty {id, amount} lines"),
				operator.NewField("expire", operator.FieldObject, true, "exactly one of fixed (RFC3339), after_read (seconds) or on_read (true)"),
			}, Handler: commands.sendHandler},
		},
	}
}

// Module is the redeem module (I11A_OPERATOR_COMMANDS_V1 M4): per-player-once
// codes through the redeem owner. redeem.list is bound by the edge.
func (commands RedeemCommands) Module() operator.Module {
	return operator.Module{
		ID:         "redeem",
		Title:      "Redeem codes",
		Role:       operator.RoleRoot,
		LogChannel: "redeem",
		Screen:     operator.Screen{Tab: "Redeem", Columns: []string{"code", "state", "used", "total_cap", "ends_at"}},
		Commands: []operator.CommandSpec{
			{Name: CommandRedeemCreate, Class: operator.ClassLive, Help: "Create a code; one use per player.", Fields: []operator.Field{
				operator.NewField("code", operator.FieldString, false, "the code; generated when omitted").Bounded(1, MaxRedeemCodeLength),
				operator.NewField("lines", operator.FieldArray, true, "one to fifty {id, amount} lines"),
				operator.NewField("expires_at", operator.FieldString, false, "RFC3339 end"),
				operator.NewField("total_cap", operator.FieldInt, false, "total uses over all players"),
			}, Handler: commands.createHandler},
			{Name: CommandRedeemDisable, Class: operator.ClassLive, Help: "Disable a code.", Fields: []operator.Field{
				operator.NewField("code", operator.FieldString, true, "the code"),
			}, Handler: commands.disableHandler},
		},
		Reads: []operator.Read{
			{Name: "redeem.list", Help: "Codes with lines, caps, uses and state.", Fields: []operator.Field{
				operator.NewField("after", operator.FieldString, false, "cursor of the previous page"),
				operator.NewField("limit", operator.FieldInt, false, "page size").Bounded(1, appi5.MaxRedeemListLimit),
			}},
		},
	}
}
