local var_0_0 = class("ArenaReportKeys")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.reportKey = {}
end

function var_0_0.getAllArenaReportKeys(arg_3_0, arg_3_1)
	arg_3_0:reset()

	local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM arenaReportKeys WHERE playerID = ?")

	var_3_0:bind_values(arg_3_1)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		table.insert(arg_3_0.reportKey, iter_3_0.report_key)
	end

	return arg_3_0.reportKey
end

function var_0_0.setArenaReportKeys(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_1 == nil or arg_4_2 == nil then
		return
	end

	local var_4_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO arenaReportKeys (playerID, report_key) VALUES (?, ?)\n    ")

	var_4_0:bind_values(arg_4_1, arg_4_2)
	var_4_0:step()
	var_4_0:reset()
end

function var_0_0.deleteAllReportKeys(arg_5_0, arg_5_1)
	local var_5_0 = xyd.db.openGameData():prepare("DELETE FROM arenaReportKeys WHERE playerID = ?")

	var_5_0:bind_values(arg_5_1)
	var_5_0:step()
	var_5_0:reset()

	arg_5_0.reportKey = {}
end

return var_0_0
