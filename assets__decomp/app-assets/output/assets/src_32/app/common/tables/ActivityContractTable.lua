local var_0_0 = class("ActivityContractTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rarity_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.vipLimit_ = {}
	arg_1_0.raritys_ = {}

	import("app.common.tables.TableParser").parse("activity_contract.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.rarity_[var_2_0] = tonumber(arg_2_0.rarity)

		if not arg_1_0.raritys_[tonumber(arg_2_0.rarity)] then
			arg_1_0.raritys_[tonumber(arg_2_0.rarity)] = true
		end

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.vipLimit_[var_2_0] = tonumber(arg_2_0.vip_limit)
	end)
end

function var_0_0.rarity(arg_3_0, arg_3_1)
	return arg_3_0.rarity_[arg_3_1] or 0
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemID_[arg_4_1] or 0
end

function var_0_0.itemNum(arg_5_0, arg_5_1)
	return arg_5_0.itemNum_[arg_5_1] or 0
end

function var_0_0.rate(arg_6_0, arg_6_1)
	return arg_6_0.rate_[arg_6_1] or 0
end

function var_0_0.vipLimit(arg_7_0, arg_7_1)
	return arg_7_0.vipLimit_[arg_7_1] or 0
end

function var_0_0.raritys(arg_8_0)
	return arg_8_0.raritys_
end

function var_0_0.itemIDs(arg_9_0)
	return arg_9_0.itemID_
end

return var_0_0
