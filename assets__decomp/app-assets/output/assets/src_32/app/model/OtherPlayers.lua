local var_0_0 = class("OtherPlayers", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.HEROS, handler(arg_2_0, arg_2_0.herosEvent_))
end

function var_0_0.getPlayerByID(arg_3_0, arg_3_1)
	if not arg_3_0.players_ then
		return nil
	end

	for iter_3_0, iter_3_1 in pairs(arg_3_0.players_) do
		if iter_3_1.playerID == arg_3_1 then
			return iter_3_1
		end
	end

	return nil
end

function var_0_0.herosEvent_(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:getPlayerByID(arg_4_1.userdata.player_id)

	if var_4_0 == nil then
		return
	end

	var_4_0:herosEvent_(arg_4_1)
end

function var_0_0.deletePlayer(arg_5_0, arg_5_1)
	if not arg_5_0.players_ then
		return
	end

	local var_5_0

	for iter_5_0 = 1, #arg_5_0.players_ do
		if arg_5_0.players_[iter_5_0].playerID == arg_5_1 then
			var_5_0 = iter_5_0

			break
		end
	end

	if var_5_0 then
		table.remove(arg_5_0.players_, var_5_0)
	end
end

return var_0_0
