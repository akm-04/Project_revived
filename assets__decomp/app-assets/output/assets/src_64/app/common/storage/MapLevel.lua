local var_0_0 = class("MapLevel")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.levels = {}
end

function var_0_0.getLevel(arg_3_0, arg_3_1)
	if arg_3_0.levels[arg_3_1] == nil then
		local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM mapLevel WHERE id = ?")

		var_3_0:bind_values(arg_3_1)
		var_3_0:step()
		var_3_0:reset()

		for iter_3_0 in var_3_0:nrows() do
			arg_3_0.levels[arg_3_1] = iter_3_0.level

			print(iter_3_0.level)

			break
		end
	end

	return arg_3_0.levels[arg_3_1]
end

function var_0_0.setLevel(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_1 == nil or arg_4_2 == nil then
		return
	end

	arg_4_0.levels[arg_4_1] = arg_4_2

	local var_4_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO mapLevel (id, level) VALUES (?, ?)\n    ")

	var_4_0:bind_values(arg_4_1, arg_4_2)
	var_4_0:step()
	var_4_0:reset()
end

return var_0_0
