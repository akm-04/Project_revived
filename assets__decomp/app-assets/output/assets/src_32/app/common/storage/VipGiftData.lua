local var_0_0 = class("VipGiftData")

function var_0_0.ctor(arg_1_0)
	return
end

function var_0_0.reset(arg_2_0)
	return
end

function var_0_0.getVipGiftData(arg_3_0)
	local var_3_0 = xyd.db.openGameData():prepare("SELECT * FROM gitTable")

	var_3_0:bind_values()
	var_3_0:step()
	var_3_0:reset()

	for iter_3_0 in var_3_0:nrows() do
		return iter_3_0
	end
end

function var_0_0.isUpdated(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:getVipGiftData()
	local var_4_1, var_4_2 = arg_4_0:dealResponse(arg_4_1)

	if var_4_0 and var_4_1 == var_4_0.charges and var_4_2 == var_4_0.giftbags then
		return false
	end

	return true
end

function var_0_0.updateVipGiftData(arg_5_0, arg_5_1)
	if arg_5_1 == nil then
		return
	end

	local var_5_0 = xyd.db.openGameData()
	local var_5_1 = var_5_0:prepare("DELETE FROM gitTable")

	var_5_1:bind_values()
	var_5_1:step()
	var_5_1:reset()

	local var_5_2, var_5_3 = arg_5_0:dealResponse(arg_5_1)
	local var_5_4 = var_5_0:prepare("        INSERT OR REPLACE INTO gitTable (charges, giftbags) VALUES (?, ?)\n    ")

	var_5_4:bind_values(var_5_2, var_5_3)
	var_5_4:step()
	var_5_4:reset()
end

function var_0_0.dealResponse(arg_6_0, arg_6_1)
	local var_6_0 = ""
	local var_6_1 = ""

	if type(arg_6_1.charges) == "table" then
		for iter_6_0, iter_6_1 in ipairs(arg_6_1.charges) do
			var_6_0 = var_6_0 .. string.format("%d|", iter_6_1.charge_id)
		end
	else
		var_6_0 = arg_6_1.charges
	end

	if type(arg_6_1.giftbags) == "table" then
		for iter_6_2, iter_6_3 in ipairs(arg_6_1.giftbags) do
			var_6_1 = var_6_1 .. string.format("%d|", iter_6_3.charge_id)
		end
	else
		var_6_1 = arg_6_1.giftbags
	end

	return var_6_0, var_6_1
end

return var_0_0
