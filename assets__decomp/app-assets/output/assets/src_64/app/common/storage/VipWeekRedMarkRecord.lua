local var_0_0 = class("VipWeekRedMarkRecord")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	return
end

function var_0_0.getVipWeekRedMarkByPlayer(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0:reset()

	local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM vipWeekRedMark WHERE playerID = ? AND serverID = ?")

	var_3_0:bind_values(arg_3_1, tonumber(arg_3_2))
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		return iter_3_0.flag
	end
end

function var_0_0.setFlagByPlayer(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = xyd.db.openGameData():prepare("UPDATE vipWeekRedMark SET flag = ? WHERE playerID = ? AND serverID = ?")

	var_4_0:bind_values(arg_4_1, arg_4_2, tonumber(arg_4_3))
	var_4_0:step()
	var_4_0:reset()
end

function var_0_0.addVipWeekRedMarkRecord(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO vipWeekRedMark (playerID, serverID, flag) VALUES (?, ?, ?)\n    ")

	var_5_0:bind_values(arg_5_2, tonumber(arg_5_3), arg_5_1)
	var_5_0:step()
	var_5_0:reset()
end

return var_0_0
