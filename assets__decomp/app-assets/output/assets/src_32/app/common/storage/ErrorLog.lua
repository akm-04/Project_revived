local var_0_0 = class("ErrorLog")

function var_0_0.ctor(arg_1_0)
	local var_1_0 = xyd.db.openLogData()

	pcall(handler(var_1_0, var_1_0.exec), "        ALTER TABLE errorlog ADD COLUMN isCrash INT NOT NULL DEFAULT 0;\n    ")
	pcall(handler(var_1_0, var_1_0.exec), "        ALTER TABLE errorlog ADD COLUMN dump TEXT NOT NULL DEFAULT \"\";\n    ")
	pcall(handler(var_1_0, var_1_0.exec), "        ALTER TABLE errorlog ADD COLUMN app_v TEXT NOT NULL DEFAULT \"\";\n    ")

	arg_1_0.recentErrorLog_ = ""
end

function var_0_0.getAll(arg_2_0)
	local var_2_0 = xyd.db.openLogData():prepare("SELECT rowid, * FROM errorlog")
	local var_2_1 = {}

	for iter_2_0 in var_2_0:nrows() do
		table.insert(var_2_1, iter_2_0)
	end

	var_2_0:reset()

	return var_2_1
end

function var_0_0.add(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	if arg_3_1 == arg_3_0.recentErrorLog_ then
		return
	end

	arg_3_0.recentErrorLog_ = arg_3_1
	arg_3_2 = arg_3_2 and 1 or 0
	arg_3_3 = arg_3_3 or ""

	local var_3_0 = xyd.db.openLogData():prepare("        INSERT INTO errorlog (time, app_v, version, isCrash, dump, log) VALUES (?, ?, ?, ?, ?, ?)\n    ")

	var_3_0:bind_values(xyd.ServerTime.get():getServerTime(), xyd.getVersionName(), xyd.version(), arg_3_2, arg_3_3, arg_3_1)
	var_3_0:step()
	var_3_0:reset()
end

function var_0_0.delete(arg_4_0, arg_4_1)
	if arg_4_1 == nil or #arg_4_1 <= 0 then
		return
	end

	local var_4_0 = true
	local var_4_1 = "("

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		if var_4_0 then
			var_4_0 = false
		else
			var_4_1 = var_4_1 .. ","
		end

		var_4_1 = var_4_1 .. iter_4_1.rowid
	end

	local var_4_2 = var_4_1 .. ")"
	local var_4_3 = xyd.db.openLogData():prepare("DELETE FROM errorlog WHERE rowid IN " .. var_4_2)

	var_4_3:step()
	var_4_3:reset()
end

return var_0_0
