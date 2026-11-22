package operatorgrant

import "gxb.local/backend/v2/internal/application/operator"

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
