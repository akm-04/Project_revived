package identitylifecycle

import "gxb.local/backend/v2/internal/application/operator"

// Module is the session module (I11A_OPERATOR_COMMANDS_V1 M3/T9): the two
// logout commands. No read exists; the client learns on its next request.
func (commands LogoutCommands) Module() operator.Module {
	return operator.Module{
		ID:         "session",
		Title:      "Sessions",
		Role:       operator.RoleRoot,
		LogChannel: "session",
		Screen:     operator.Screen{Tab: "Sessions", Columns: []string{"revoked"}},
		Commands: []operator.CommandSpec{
			{Name: "session.logout", Class: operator.ClassLive, Help: "Revoke every live session of the named players and sessions.", Fields: []operator.Field{
				operator.NewField("player_ids", operator.FieldArray, false, "player ids whose live sessions are revoked"),
				operator.NewField("session_ids", operator.FieldArray, false, "session uuids to revoke"),
			}, AnyOf: []string{"player_ids", "session_ids"}, Handler: commands.logoutHandler},
			{Name: "session.logout_all", Class: operator.ClassLive, Help: "Revoke every live session, or every live session of one logical server.", Fields: []operator.Field{
				operator.NewField("server_id", operator.FieldInt, false, "logical server id; omitted revokes every server"),
			}, Handler: commands.logoutAllHandler},
		},
	}
}
