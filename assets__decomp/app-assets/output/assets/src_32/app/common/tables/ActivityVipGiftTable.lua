local var_0_0 = class("ActivityVipGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.price_ = {}
	arg_1_0.buy_limit_ = {}
	arg_1_0.gift_id_ = {}
	arg_1_0.gift_choice_ = {}
	arg_1_0.gift_choice_num_ = {}
	arg_1_0.discount_price_ = {}
	arg_1_0.name_ = {}
	arg_1_0.drop_desc_ = {}
	arg_1_0.drop_icon_ = {}
	arg_1_0.type_ = {}
	arg_1_0.vip_limit_ = {}
	arg_1_0.week_ = {}

	import("app.common.tables.TableParser").parse("activity_vipoff.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.price_[var_2_0] = arg_2_0.price
		arg_1_0.buy_limit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.gift_id_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.gift_choice_[var_2_0] = xyd.splitToNumber(arg_2_0.gift_choice, "|")
		arg_1_0.gift_choice_num_[var_2_0] = tonumber(arg_2_0.gift_choice_num)
		arg_1_0.discount_price_[var_2_0] = tonumber(arg_2_0.discount_price)
		arg_1_0.drop_desc_[var_2_0] = xyd.split(arg_2_0.drop_desc, "|")
		arg_1_0.drop_icon_[var_2_0] = arg_2_0.drop_icon
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.vip_limit_[var_2_0] = tonumber(arg_2_0.vip_limit)
		arg_1_0.week_[var_2_0] = tonumber(arg_2_0.week)
	end)
end

function var_0_0.level_limit(arg_3_0, arg_3_1)
	return arg_3_0.vip_limit_[arg_3_1]
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or " "
end

function var_0_0.price(arg_5_0, arg_5_1)
	return arg_5_0.price_[arg_5_1] or {}
end

function var_0_0.buylimit(arg_6_0, arg_6_1)
	return arg_6_0.buy_limit_[arg_6_1] or 0
end

function var_0_0.getWeekByType(arg_7_0, arg_7_1)
	for iter_7_0 = 1, #arg_7_0.week_ do
		if arg_7_0:type(iter_7_0) == arg_7_1 then
			return arg_7_0:week(iter_7_0)
		end
	end
end

function var_0_0.week(arg_8_0, arg_8_1)
	return arg_8_0.week_[arg_8_1] or 0
end

function var_0_0.giftid(arg_9_0, arg_9_1)
	return arg_9_0.gift_id_[arg_9_1] or 0
end

function var_0_0.giftChoice(arg_10_0, arg_10_1)
	return arg_10_0.gift_choice_[arg_10_1] or {}
end

function var_0_0.giftChoiceNum(arg_11_0, arg_11_1)
	return arg_11_0.gift_choice_num_[arg_11_1]
end

function var_0_0.dropDesc(arg_12_0, arg_12_1)
	return arg_12_0.drop_desc_[arg_12_1] or {}
end

function var_0_0.dropIcon(arg_13_0, arg_13_1)
	return arg_13_0.drop_icon_[arg_13_1] or ""
end

function var_0_0.type(arg_14_0, arg_14_1)
	return arg_14_0.week_[arg_14_1] or 0
end

function var_0_0.discount_price(arg_15_0, arg_15_1)
	return arg_15_0.discount_price_[arg_15_1] or arg_15_0.price_[arg_15_1]
end

function var_0_0.allcount(arg_16_0)
	return #arg_16_0.gift_id_
end

return var_0_0
