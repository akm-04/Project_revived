local var_0_0 = class("RagnarokGachaTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.isPrevisible_ = {}
	arg_1_0.balloonType_ = {}

	import("app.common.tables.TableParser").parse("activity_ragnarok_gacha.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.isPrevisible_[var_2_0] = tonumber(arg_2_0.is_previsible)
		arg_1_0.balloonType_[var_2_0] = tonumber(arg_2_0.balloon_type)
	end)
end

function var_0_0.getItemIds(arg_3_0)
	return arg_3_0.itemId_ or {}
end

function var_0_0.getIdByInfo(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}
	local var_4_1

	for iter_4_0 = 1, #arg_4_0.itemId_ do
		if arg_4_1 == arg_4_0.itemId_[iter_4_0] then
			table.insert(var_4_0, iter_4_0)
		end
	end

	for iter_4_1 = 1, #var_4_0 do
		if arg_4_2 == arg_4_0:getItemNumById(var_4_0[iter_4_1]) then
			var_4_1 = var_4_0[iter_4_1]
		end
	end

	return var_4_1
end

function var_0_0.getItemIdById(arg_5_0, arg_5_1)
	return arg_5_0.itemId_[arg_5_1] or 0
end

function var_0_0.getItemNumById(arg_6_0, arg_6_1)
	return arg_6_0.itemNum_[arg_6_1] or 0
end

function var_0_0.isPrevisible(arg_7_0, arg_7_1)
	return arg_7_0.isPrevisible_[arg_7_1] or 0
end

function var_0_0.balloonType(arg_8_0, arg_8_1)
	return arg_8_0.balloonType_[arg_8_1] or 5
end

return var_0_0
