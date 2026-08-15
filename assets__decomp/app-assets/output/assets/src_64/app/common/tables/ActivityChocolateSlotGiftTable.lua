local var_0_0 = class("ActivityChocolateSlotGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids = {}
	arg_1_0.level_ = {}
	arg_1_0.show_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_chocolate_slot_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.show_[var_2_0] = xyd.splitToNumber(arg_2_0.show, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)

		table.insert(arg_1_0.ids, var_2_0)
	end)
end

function var_0_0.id(arg_3_0)
	return arg_3_0.ids or {}
end

function var_0_0.level(arg_4_0, arg_4_1)
	return arg_4_0.level_[arg_4_1] or 0
end

function var_0_0.show(arg_5_0, arg_5_1)
	return arg_5_0.show_[arg_5_1] or {}
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or 0
end

return var_0_0
