local var_0_0 = class("washInfo")

function var_0_0.ctor(arg_1_0)
	arg_1_0.loaded_ = true
end

function var_0_0.persist(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	if not arg_2_0.loaded_ then
		return
	end

	local var_2_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO washInfo (playerID, heroID, isPet) VALUES (?, ?, ?)\n    ")
	local var_2_1 = arg_2_1 or 0
	local var_2_2 = arg_2_2 or 0
	local var_2_3 = arg_2_3 or 0

	var_2_0:bind_values(var_2_1, var_2_2, var_2_3)
	var_2_0:step()
	var_2_0:reset()
end

function var_0_0.getWashInfo(arg_3_0, arg_3_1)
	local var_3_0 = 0
	local var_3_1 = 0

	for iter_3_0 in xyd.db.openGameData():prepare("SELECT * FROM washInfo"):nrows() do
		if arg_3_1 == tonumber(iter_3_0.playerID) then
			local var_3_2 = tonumber(iter_3_0.heroID)
			local var_3_3 = tonumber(iter_3_0.isPet)

			return var_3_2, var_3_3
		end
	end
end

return var_0_0
