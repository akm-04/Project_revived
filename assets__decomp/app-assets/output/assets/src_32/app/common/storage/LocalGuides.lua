local var_0_0 = class("LocalGuides")

function var_0_0.ctor(arg_1_0)
	return
end

function var_0_0.reset(arg_2_0)
	return
end

function var_0_0.getLocalGuideID(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM localGuides WHERE playerID = ? AND localGuideID = ?")

	var_3_0:bind_values(arg_3_1, arg_3_2)
	var_3_0:step()
	var_3_0:reset()

	local var_3_1 = 0

	for iter_3_0 in var_3_0:nrows() do
		var_3_1 = var_3_1 + 1
	end

	return var_3_1
end

function var_0_0.setLocalGuideID(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO localGuides (playerID, localGuideID) VALUES (?, ?)\n    ")

	var_4_0:bind_values(arg_4_1, arg_4_2)
	var_4_0:step()
	var_4_0:reset()
end

return var_0_0
