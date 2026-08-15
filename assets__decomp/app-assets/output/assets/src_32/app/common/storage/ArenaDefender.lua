local var_0_0 = class("ArenaDefender")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.heroData = {}
end

function var_0_0.getArenaDefenderData(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1 or 1

	if arg_3_0.heroData[var_3_0] == nil then
		local var_3_1 = xyd.db.openGameData():prepare("SELECT * FROM arenaDefender WHERE id = ?")

		var_3_1:bind_values(var_3_0)
		var_3_1:step()
		var_3_1:reset()

		for iter_3_0 in var_3_1:nrows() do
			arg_3_0.heroData[var_3_0] = iter_3_0.heroData

			print(iter_3_0.heroData)

			break
		end
	end

	if arg_3_0.heroData[var_3_0] == nil then
		return nil
	end

	local var_3_2 = {}

	for iter_3_1 in string.gmatch(arg_3_0.heroData[var_3_0], "[-]?%d+") do
		table.insert(var_3_2, tonumber(iter_3_1))
	end

	return var_3_2
end

function var_0_0.setArenaDefenderData(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_2 == nil then
		return
	end

	local var_4_0 = arg_4_1 or 1
	local var_4_1 = ""

	for iter_4_0, iter_4_1 in ipairs(arg_4_2) do
		var_4_1 = var_4_1 .. string.format("%d|", iter_4_1)
	end

	arg_4_0.heroData[var_4_0] = var_4_1

	local var_4_2 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO arenaDefender (id, heroData) VALUES (?, ?)\n    ")

	var_4_2:bind_values(var_4_0, var_4_1)
	var_4_2:step()
	var_4_2:reset()
end

return var_0_0
