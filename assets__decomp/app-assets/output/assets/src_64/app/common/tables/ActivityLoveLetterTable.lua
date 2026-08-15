local var_0_0 = class("ActivityLoveLetterTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.rarity_ = {}
	arg_1_0.item_id_ = {}
	arg_1_0.item_num_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.vip_limit_ = {}

	import("app.common.tables.TableParser").parse("activity_love_letter.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.rarity_[var_2_0] = tonumber(arg_2_0.rarity)
		arg_1_0.item_id_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.item_num_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.vip_limit_[var_2_0] = tonumber(arg_2_0.vip_limit)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.rarity(arg_4_0, arg_4_1)
	return arg_4_0.rarity_[arg_4_1] or ""
end

function var_0_0.itemID(arg_5_0, arg_5_1)
	return arg_5_0.item_id_[arg_5_1] or ""
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return arg_6_0.item_num_[arg_6_1] or ""
end

function var_0_0.rate(arg_7_0, arg_7_1)
	return arg_7_0.rate_[arg_7_1] or ""
end

function var_0_0.VIPLimit(arg_8_0, arg_8_1)
	return arg_8_0.vip_limit_[arg_8_1] or ""
end

return var_0_0
