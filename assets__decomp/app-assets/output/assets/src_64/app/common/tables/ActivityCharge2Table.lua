local var_0_0 = class("ActivityChargeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.gift_open_ = {}
	arg_1_0.gift_operation_card_nums_ = {}
	arg_1_0.gift_operation_stone_nums_ = {}
	arg_1_0.default_partner_ = {}

	import("app.common.tables.TableParser").parse("activity_charge2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.gift_open_[var_2_0] = tonumber(arg_2_0.gift_operation)
		arg_1_0.gift_operation_card_nums_[var_2_0] = tonumber(arg_2_0.gift_operation_card_nums)
		arg_1_0.gift_operation_stone_nums_[var_2_0] = tonumber(arg_2_0.gift_operation_stone_nums)
		arg_1_0.default_partner_[var_2_0] = tonumber(arg_2_0.default_partner)
	end)
end

function var_0_0.recharge(arg_3_0, arg_3_1)
	return arg_3_0.recharge_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or {}
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.gifts(arg_6_0)
	return arg_6_0.gift_ or {}
end

function var_0_0.giftOpen(arg_7_0, arg_7_1)
	return arg_7_0.gift_open_[arg_7_1] or 0
end

function var_0_0.giftsOpen(arg_8_0, arg_8_1)
	return arg_8_0.gift_open_ or {}
end

function var_0_0.giftOperationCardNums(arg_9_0, arg_9_1)
	return arg_9_0.gift_operation_card_nums_[arg_9_1] or 0
end

function var_0_0.giftOperationStoneNums(arg_10_0, arg_10_1)
	return arg_10_0.gift_operation_stone_nums_[arg_10_1] or 0
end

function var_0_0.defaultPartner(arg_11_0)
	return arg_11_0.default_partner_[1]
end

return var_0_0
