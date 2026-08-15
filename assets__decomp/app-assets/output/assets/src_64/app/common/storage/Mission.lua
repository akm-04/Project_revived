local var_0_0 = class("Mission")

function var_0_0.ctor(arg_1_0)
	arg_1_0:load_()
end

function var_0_0.persist(arg_2_0, arg_2_1, arg_2_2)
	if not arg_2_0.loaded_ then
		return
	end

	local var_2_0 = xyd.db.openGameData():prepare("        INSERT OR REPLACE INTO mission (tableID, isNew) VALUES (?, ?)\n    ")

	var_2_0:bind_values(arg_2_1, arg_2_2)
	var_2_0:step()
	var_2_0:reset()
end

function var_0_0.deleteItem(arg_3_0, arg_3_1)
	if not arg_3_0.loaded_ then
		return
	end

	local var_3_0 = xyd.db.openGameData():prepare("        DELETE FROM mission where tableID = ?\n    ")

	var_3_0:bind_values(arg_3_1)
	var_3_0:step()
	var_3_0:reset()

	arg_3_0.data[arg_3_1] = nil
end

function var_0_0.reset(arg_4_0)
	arg_4_0.data = {}

	xyd.db.openGameData():exec("        DELETE FROM mission;\n    ")
end

function var_0_0.load_(arg_5_0)
	local var_5_0 = xyd.db.openGameData():prepare("SELECT * FROM mission")

	arg_5_0.data = {}

	for iter_5_0 in var_5_0:nrows() do
		arg_5_0.data[tonumber(iter_5_0.tableID)] = tonumber(iter_5_0.isNew)
	end

	arg_5_0.loaded_ = true
end

function var_0_0.isNew(arg_6_0, arg_6_1)
	if not arg_6_0.loaded_ then
		return false
	end

	if arg_6_0.data[arg_6_1] == nil then
		return false
	end

	return arg_6_0.data[arg_6_1]
end

return var_0_0
