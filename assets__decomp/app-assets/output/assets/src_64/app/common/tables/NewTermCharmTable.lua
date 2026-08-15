local var_0_0 = class("NewTermCharmTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.charm_ = {}
	arg_1_0.charmGift_ = {}
	arg_1_0.giftName_ = {}
	arg_1_0.giftText_ = {}

	import("app.common.tables.TableParser").parse("activity_lianyi_charm.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.charm_[var_2_0] = tonumber(arg_2_0.charm)
		arg_1_0.charmGift_[var_2_0] = tonumber(arg_2_0.charm_gift)
		arg_1_0.giftName_[var_2_0] = arg_2_0.gift_name
		arg_1_0.giftText_[var_2_0] = arg_2_0.gift_text
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.charm(arg_4_0, arg_4_1)
	return arg_4_0.charm_[arg_4_1]
end

function var_0_0.charmGift(arg_5_0, arg_5_1)
	return arg_5_0.charmGift_[arg_5_1]
end

function var_0_0.giftName(arg_6_0, arg_6_1)
	return arg_6_0.giftName_[arg_6_1]
end

function var_0_0.giftText(arg_7_0, arg_7_1)
	return arg_7_0.giftText_[arg_7_1]
end

return var_0_0
