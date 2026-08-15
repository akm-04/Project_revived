local var_0_0 = class("ActivityConsumeGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.num_ = {}
	arg_1_0.rare_ = {}

	import("app.common.tables.TableParser").parse("activity_consume_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.nums)
		arg_1_0.rare_[var_2_0] = tonumber(arg_2_0.is_valua)
	end)
end

function var_0_0.itemID(arg_3_0, arg_3_1)
	return arg_3_0.itemID_[arg_3_1] or 0
end

function var_0_0.num(arg_4_0, arg_4_1)
	return arg_4_0.num_[arg_4_1] or 0
end

function var_0_0.isRare(arg_5_0, arg_5_1)
	return arg_5_0.rare_[arg_5_1] or 0
end

function var_0_0.getItems(arg_6_0)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.itemID_) do
		table.insert(var_6_0, iter_6_1)
	end

	return var_6_0
end

function var_0_0.getItemNum(arg_7_0)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in pairs(arg_7_0.num_) do
		table.insert(var_7_0, iter_7_1)
	end

	return var_7_0
end

return var_0_0
