local var_0_0 = class("SkinSkillRedMark")

function var_0_0.ctor(arg_1_0)
	return
end

function var_0_0.reset(arg_2_0)
	return
end

function var_0_0.getSkinSkillRedMark(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM skinSkillRedMark WHERE playerID = ? AND partnerID = ? ")
	local var_3_1

	var_3_0:bind_values(arg_3_1, arg_3_2)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		var_3_1 = iter_3_0.isShow

		break
	end

	return var_3_1
end

function var_0_0.updateSkinSkillRedMark(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO skinSkillRedMark (playerID, partnerID, isShow) VALUES (?, ?, ?)\n    ")

	var_4_0:bind_values(arg_4_1, arg_4_2, arg_4_3)
	var_4_0:step()
	var_4_0:reset()
end

return var_0_0
