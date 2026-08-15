local var_0_0 = class("ActivityServerCandleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.itemIds_ = {}
	arg_1_0.itemNums_ = {}
	arg_1_0.random_ = {}

	import("app.common.tables.TableParser").parse("activity_server_candle.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.itemIds_[var_2_0] = xyd.splitToNumber(arg_2_0.item_ids, "|")
		arg_1_0.itemNums_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")
		arg_1_0.random_[var_2_0] = tonumber(arg_2_0.random)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.itemIds(arg_4_0, arg_4_1)
	return arg_4_0.itemIds_[arg_4_1] or {}
end

function var_0_0.itemNums(arg_5_0, arg_5_1)
	return arg_5_0.itemNums_[arg_5_1] or {}
end

function var_0_0.random(arg_6_0, arg_6_1)
	return arg_6_0.random_[arg_6_1] or 0
end

return var_0_0
