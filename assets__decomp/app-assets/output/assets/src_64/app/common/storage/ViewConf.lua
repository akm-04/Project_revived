local var_0_0 = class("ViewConf")

function var_0_0.ctor(arg_1_0)
	arg_1_0:load_()
end

function var_0_0.persist(arg_2_0)
	if not arg_2_0.loaded_ then
		return
	end

	local var_2_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO viewConf (id, heroViewMode, heroDataSortType, socialViewMode) VALUES (0, ?, ?, ?)\n    ")

	print("persist db:", arg_2_0.heroViewMode)
	print("persist db:", arg_2_0.heroDataSortType)
	print("persist db:", arg_2_0.socialViewMode)
	var_2_0:bind_values(arg_2_0.heroViewMode, arg_2_0.heroDataSortType, arg_2_0.socialViewMode)
	var_2_0:step()
	var_2_0:reset()
end

function var_0_0.reset(arg_3_0)
	arg_3_0:load_()
end

function var_0_0.load_(arg_4_0)
	arg_4_0.loaded_ = false
	arg_4_0.heroViewMode = 1
	arg_4_0.heroDataSortType = 1
	arg_4_0.socialViewMode = 1

	for iter_4_0 in xyd.db.openGameData():prepare("SELECT * FROM viewConf"):nrows() do
		arg_4_0.heroViewMode = tonumber(iter_4_0.heroViewMode)
		arg_4_0.heroDataSortType = tonumber(iter_4_0.heroDataSortType)
		arg_4_0.socialViewMode = tonumber(iter_4_0.socialViewMode)

		print("[db]heroViewMode:", arg_4_0.heroViewMode)
		print("[db]heroDataSortType:", arg_4_0.heroDataSortType)
		print("[db]socialViewMode:", arg_4_0.socialViewMode)

		break
	end

	arg_4_0.loaded_ = true
end

return var_0_0
