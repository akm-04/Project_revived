function var_0_1.closeLeagueRoom(arg_6_0)
	if arg_6_0.leagueSocket_ ~= nil then
		arg_6_0.leagueSocket_:close()
		arg_6_0.leagueSocket_ = nil
	end
	arg_6_0.leagueChatRoomID_ = nil
end