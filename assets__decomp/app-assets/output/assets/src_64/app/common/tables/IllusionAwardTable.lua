local var_0_0 = class("IllusionAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.range_ = {}
	arg_1_0.illusionCoin_ = {}
	arg_1_0.item_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.rangeTable_ = {}

	import("app.common.tables.TableParser").parse("paradise_person_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.illusionCoin_[var_2_0] = tonumber(arg_2_0.paradise_coin_num)
		arg_1_0.item_[var_2_0] = xyd.splitToNumber(arg_2_0.item_ids, "|")
		arg_1_0.itemNum_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")

		table.insert(arg_1_0.rangeTable_, arg_1_0.range_[var_2_0])
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.range(arg_4_0, arg_4_1)
	return arg_4_0.range_[arg_4_1] or 0
end

function var_0_0.illusionCoin(arg_5_0, arg_5_1)
	return arg_5_0.illusionCoin_[arg_5_1] or 0
end

function var_0_0.item(arg_6_0, arg_6_1)
	return arg_6_0.item_[arg_6_1] or {}
end

function var_0_0.itemNum(arg_7_0, arg_7_1)
	return arg_7_0.itemNum_[arg_7_1]
end

function var_0_0.getID(arg_8_0, arg_8_1)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.range_) do
		if arg_8_1 <= iter_8_1 then
			return iter_8_0
		end
	end

	return 0
end

return var_0_0
