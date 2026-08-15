local var_0_0 = class("ActivityChocolateSlotTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rate_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.content_ = {}
	arg_1_0.isRarest_ = {}

	import("app.common.tables.TableParser").parse("activity_chocolate_slot.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.content_[var_2_0] = xyd.splitToNumber(arg_2_0.content, "|")
		arg_1_0.isRarest_[var_2_0] = tonumber(arg_2_0.is_rarest)
	end)
end

function var_0_0.rate(arg_3_0, arg_3_1)
	return arg_3_0.rate_[arg_3_1] or 0
end

function var_0_0.giftId(arg_4_0, arg_4_1)
	return arg_4_0.giftId_[arg_4_1] or 0
end

function var_0_0.content(arg_5_0, arg_5_1)
	return arg_5_0.content_[arg_5_1] or {}
end

function var_0_0.isRarest(arg_6_0, arg_6_1)
	return arg_6_0.isRarest_[arg_6_1] or 0
end

return var_0_0
