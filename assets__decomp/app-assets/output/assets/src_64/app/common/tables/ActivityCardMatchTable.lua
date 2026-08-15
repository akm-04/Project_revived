local var_0_0 = class("ActivityCardMatchTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.set_ = {}
	arg_1_0.rate_ = {}

	import("app.common.tables.TableParser").parse("activity_card_match.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.set_[var_2_0] = tonumber(arg_2_0.set)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
	end)
end

function var_0_0.itemId(arg_3_0, arg_3_1)
	return arg_3_0.itemId_[arg_3_1] or 0
end

function var_0_0.itemNum(arg_4_0, arg_4_1)
	return arg_4_0.itemNum_[arg_4_1] or 0
end

function var_0_0.set(arg_5_0, arg_5_1)
	return arg_5_0.set_[arg_5_1] or 0
end

function var_0_0.rate(arg_6_0, arg_6_1)
	return arg_6_0.rate_[arg_6_1] or 0
end

return var_0_0
