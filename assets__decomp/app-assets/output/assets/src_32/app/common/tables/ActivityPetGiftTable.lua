local var_0_0 = class("ActivityPetGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.discount_ = {}
	arg_1_0.price_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.discount_price_ = {}
	arg_1_0.name_ = {}
	arg_1_0.giftlist_ = {}
	arg_1_0.pag_path_ = {}
	arg_1_0.vip_grade = {}
	arg_1_0.but_count = {}
	arg_1_0.detailIcon_ = {}
	arg_1_0.detailText_ = {}

	import("app.common.tables.TableParser").parse("activity_petgift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.discount_[var_2_0] = tonumber(arg_2_0.discount)
		arg_1_0.price_[var_2_0] = arg_2_0.price
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.discount_price_[var_2_0] = tonumber(arg_2_0.discount_price)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.giftlist_[var_2_0] = arg_2_0.gift_list
		arg_1_0.pag_path_[var_2_0] = arg_2_0.icon
		arg_1_0.vip_grade[var_2_0] = tonumber(arg_2_0.vip)
		arg_1_0.but_count[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.detailIcon_[var_2_0] = xyd.splitToNumber(arg_2_0.detail_icon, "|")
		arg_1_0.detailText_[var_2_0] = arg_2_0.detail_text
	end)
end

function var_0_0.buyCount(arg_3_0, arg_3_1)
	return arg_3_0.but_count[arg_3_1] or 0
end

function var_0_0.vip(arg_4_0, arg_4_1)
	return arg_4_0.vip_grade[arg_4_1]
end

function var_0_0.icon(arg_5_0, arg_5_1)
	return arg_5_0.pag_path_[arg_5_1]
end

function var_0_0.gift_list(arg_6_0, arg_6_1)
	return arg_6_0.giftlist_[arg_6_1] or " "
end

function var_0_0.name(arg_7_0, arg_7_1)
	return arg_7_0.name_[arg_7_1] or " "
end

function var_0_0.discount(arg_8_0, arg_8_1)
	return arg_8_0.discount_[arg_8_1] or 10
end

function var_0_0.price(arg_9_0, arg_9_1)
	return arg_9_0.price_[arg_9_1] or {}
end

function var_0_0.gift(arg_10_0, arg_10_1)
	return arg_10_0.gift_[arg_10_1] or 0
end

function var_0_0.discount_price(arg_11_0, arg_11_1)
	return arg_11_0.discount_price_[arg_11_1] or arg_11_0.price_[arg_11_1]
end

function var_0_0.allcount(arg_12_0)
	return arg_12_0.gift_
end

function var_0_0.detailText(arg_13_0, arg_13_1)
	return arg_13_0.detailText_[arg_13_1] or ""
end

function var_0_0.detailIcon(arg_14_0, arg_14_1)
	return arg_14_0.detailIcon_[arg_14_1] or {}
end

return var_0_0
