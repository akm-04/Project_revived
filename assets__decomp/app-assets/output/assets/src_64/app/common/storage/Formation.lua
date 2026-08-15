local var_0_0 = class("Formation")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.reset(arg_2_0)
	arg_2_0.formationData = {}
end

function var_0_0.getFormationTable(arg_3_0, arg_3_1)
	if arg_3_0.formationData[arg_3_1] == nil then
		local var_3_0 = xyd.db.openGameData()
		local var_3_1 = arg_3_0.selfPlayer.playerID
		local var_3_2 = var_3_0:prepare("SELECT * FROM formation WHERE formationID = ? AND playerID = ?")

		var_3_2:bind_values(arg_3_1, var_3_1)
		var_3_2:step()
		var_3_2:reset()

		for iter_3_0 in var_3_2:nrows() do
			arg_3_0.formationData[arg_3_1] = iter_3_0.formationData

			print(iter_3_0.formationData)

			break
		end
	end

	if arg_3_0.formationData[arg_3_1] == nil then
		return nil
	end

	return xyd.luaStringSplit(arg_3_0.formationData[arg_3_1], ",")
end

function var_0_0.getFormationData(arg_4_0, arg_4_1)
	if arg_4_0:getFormationTable(arg_4_1) == nil then
		return nil
	end

	local var_4_0 = {}
	local var_4_1 = xyd.luaStringSplit(arg_4_0.formationData[arg_4_1], ",")

	if var_4_1 then
		for iter_4_0 = 1, #var_4_1 do
			local var_4_2 = {}

			for iter_4_1 in string.gmatch(var_4_1[iter_4_0], "[-]?%d+") do
				table.insert(var_4_2, tonumber(iter_4_1))
			end

			table.insert(var_4_0, var_4_2)
		end
	end

	return var_4_0
end

function var_0_0.setFormationData(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_1 == nil or arg_5_2 == nil then
		return
	end

	local var_5_0 = ""

	if type(arg_5_2) == "table" then
		for iter_5_0, iter_5_1 in ipairs(arg_5_2) do
			var_5_0 = var_5_0 .. string.format("%d|", iter_5_1)
		end
	else
		var_5_0 = arg_5_2
	end

	arg_5_0.formationData[arg_5_1] = var_5_0

	local var_5_1 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO formation (formationID, playerID, formationData) VALUES (?, ?, ?)\n    ")
	local var_5_2 = arg_5_0.selfPlayer.playerID

	var_5_1:bind_values(arg_5_1, var_5_2, var_5_0)
	var_5_1:step()
	var_5_1:reset()
end

function var_0_0.clearFormationData(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_1 == nil or arg_6_2 == nil then
		return
	end

	local var_6_0 = xyd.db.openGameData():prepare("DELETE FROM formation WHERE playerID = ? AND formationID = ?")

	var_6_0:bind_values(arg_6_2, arg_6_1)
	var_6_0:step()
	var_6_0:reset()
	arg_6_0:reset()
end

return var_0_0
