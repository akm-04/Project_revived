local var_0_0 = class("ActivityPetGrowUpTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.name_ = {}
	arg_1_0.price_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.giftlist_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.modelID_ = {}

	import("app.common.tables.TableParser").parse("activity_petgrowup.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.gift_[var_2_0] = xyd.splitToNumber(arg_2_0.gift, "|")
		arg_1_0.giftlist_[var_2_0] = arg_2_0.gift_list
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.modelID_[var_2_0] = xyd.splitToNumber(arg_2_0.model_id, "|")
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.price(arg_4_0, arg_4_1)
	return arg_4_0.price_[arg_4_1] or 0
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or {}
end

function var_0_0.giftlist(arg_6_0, arg_6_1)
	return arg_6_0.giftlist_[arg_6_1] or {}
end

function var_0_0.icon(arg_7_0, arg_7_1)
	return arg_7_0.icon_[arg_7_1]
end

function var_0_0.allCounts(arg_8_0, arg_8_1)
	return #arg_8_0.name_
end

function var_0_0.modelID(arg_9_0, arg_9_1)
	return arg_9_0.modelID_[arg_9_1] or {}
end

return var_0_0
