local var_0_0 = class("ActivitiesIds")

function var_0_0.ctor(arg_1_0)
	arg_1_0:reset()
end

function var_0_0.reset(arg_2_0)
	arg_2_0.activityIds = {}
end

function var_0_0.getAllActivitiesIds(arg_3_0, arg_3_1)
	arg_3_0:reset()

	local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM activitiesIdFlag WHERE playerID = ?")

	var_3_0:bind_values(arg_3_1)
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		table.insert(arg_3_0.activityIds, iter_3_0.activity_id)
	end

	return arg_3_0.activityIds
end

function var_0_0.isActivityExist(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = xyd.db.openGameData():prepare("SELECT * FROM activitiesIdFlag WHERE playerID = ? AND activity_id = ?")

	var_4_0:bind_values(arg_4_1, tostring(arg_4_2))
	var_4_0:step()
	var_4_0:reset()

	for iter_4_0 in var_4_0:nrows() do
		if iter_4_0 then
			return true
		end
	end

	return false
end

function var_0_0.getFlagById(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.db.openGameData():prepare("SELECT * FROM activitiesIdFlag WHERE playerID = ? AND activity_id = ?")

	var_5_0:bind_values(arg_5_1, arg_5_2)
	var_5_0:step()
	var_5_0:reset()

	for iter_5_0 in var_5_0:nrows() do
		return iter_5_0.flag
	end
end

function var_0_0.setFlagById(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = xyd.db.openGameData():prepare("UPDATE activitiesIdFlag SET flag = ? WHERE playerID = ? AND activity_id = ?")

	var_6_0:bind_values(arg_6_1, arg_6_2, arg_6_3)
	var_6_0:step()
	var_6_0:reset()
end

function var_0_0.setActivitiesIds(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_1 == nil or arg_7_2 == nil then
		return
	end

	local var_7_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO activitiesIdFlag (playerID, activity_id) VALUES (?, ?)\n    ")

	var_7_0:bind_values(arg_7_1, arg_7_2)
	var_7_0:step()
	var_7_0:reset()
end

function var_0_0.deleteAllActivitiesIds(arg_8_0, arg_8_1)
	local var_8_0 = xyd.db.openGameData():prepare("DELETE FROM activitiesIdFlag WHERE playerID = ?")

	var_8_0:bind_values(arg_8_1)
	var_8_0:step()
	var_8_0:reset()

	arg_8_0.activityIds = {}
end

function var_0_0.deleteActivitiesId(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = xyd.db.openGameData():prepare("DELETE FROM activitiesIdFlag WHERE playerID = ? AND activity_id = ?")

	var_9_0:bind_values(arg_9_1, tostring(arg_9_2))
	var_9_0:step()
	var_9_0:reset()
end

return var_0_0
