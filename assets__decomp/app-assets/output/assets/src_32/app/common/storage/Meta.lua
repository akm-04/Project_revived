local var_0_0 = class("Meta")

function var_0_0.ctor(arg_1_0)
	arg_1_0:load_()
end

function var_0_0.persist(arg_2_0)
	if not arg_2_0.loaded_ then
		return
	end

	local var_2_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO meta (id, sid, regionID, regionName, playerID, playerName) VALUES (0, ?, ?, ?, ?, ?)\n    ")

	var_2_0:bind_values(arg_2_0.sid, arg_2_0.regionID, arg_2_0.regionName, arg_2_0.playerID, arg_2_0.playerName)
	var_2_0:step()
	var_2_0:reset()
end

function var_0_0.load_(arg_3_0)
	arg_3_0.sid = ""
	arg_3_0.regionID = 0
	arg_3_0.regionName = ""
	arg_3_0.playerID = 0
	arg_3_0.playerName = ""

	local var_3_0 = xyd.db.openGameData()

	for iter_3_0 in var_3_0:prepare("SELECT * FROM meta"):nrows() do
		arg_3_0.sid = iter_3_0.sid
		arg_3_0.regionID = tonumber(iter_3_0.regionID)
		arg_3_0.regionName = iter_3_0.regionName
		arg_3_0.playerID = tonumber(iter_3_0.playerID)
		arg_3_0.playerName = iter_3_0.playerName

		break
	end

	if arg_3_0.sid == nil then
		assert(var_3_0:exec("            ALTER TABLE meta ADD COLUMN sid TEXT NOT NULL DEFAULT \"\";\n        ") == sqlite3.OK)

		arg_3_0.sid = ""
	end

	arg_3_0.loaded_ = true
end

return var_0_0
