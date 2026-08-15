local var_0_0 = class("ActivitySevenLoginTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.gift_tip_ = {}
	arg_1_0.glow_item_ = {}
	arg_1_0.gift_icon_ = {}

	import("app.common.tables.TableParser").parse("activity_week.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.gift_tip_[var_2_0] = arg_2_0.gift_tip
		arg_1_0.glow_item_[var_2_0] = xyd.splitToNumber(arg_2_0.glow_item, "|")
		arg_1_0.gift_icon_[var_2_0] = arg_2_0.gift_icon
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or {}
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.giftTip(arg_5_0, arg_5_1)
	return arg_5_0.gift_tip_[arg_5_1]
end

function var_0_0.glowItem(arg_6_0, arg_6_1)
	return arg_6_0.glow_item_[arg_6_1] or {}
end

function var_0_0.giftIcon(arg_7_0, arg_7_1)
	return arg_7_0.gift_icon_[arg_7_1] or ""
end

function var_0_0.gifts(arg_8_0)
	return arg_8_0.gift_ or {}
end

return var_0_0
