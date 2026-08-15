local var_0_0 = class("GuildWarRedPoint")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.nextStep = 110
end

function var_0_0.getGuildWarRedPointData(arg_3_0)
	local var_3_0 = 1

	if arg_3_0.nextStep == 110 then
		local var_3_1 = xyd.db.openGameData():prepare("SELECT * FROM guildWarRedPoint WHERE id = ?")

		var_3_1:bind_values(var_3_0)
		var_3_1:step()
		var_3_1:reset()

		for iter_3_0 in var_3_1:nrows() do
			arg_3_0.nextStep = iter_3_0.step

			break
		end
	end

	return arg_3_0.nextStep
end

function var_0_0.setGuildWarRedPointData(arg_4_0, arg_4_1)
	if arg_4_1 == nil then
		return
	end

	local var_4_0 = 1
	local var_4_1 = arg_4_1

	arg_4_0.nextStep = var_4_1

	local var_4_2 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO guildWarRedPoint (id, step) VALUES (?, ?)\n    ")

	var_4_2:bind_values(var_4_0, var_4_1)
	var_4_2:step()
	var_4_2:reset()
end

return var_0_0
