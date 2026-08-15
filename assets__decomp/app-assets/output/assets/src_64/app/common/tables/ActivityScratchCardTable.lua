local var_0_0 = class("ActivityScratchCardTable ")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_ = {}
	arg_1_0.multiplier_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("activity_scratch_card.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.multiplier_[var_2_0] = tonumber(arg_2_0.more_num)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.getGiftID(arg_3_0, arg_3_1)
	return tonumber(arg_3_0.gift_[arg_3_1]) or 0
end

function var_0_0.getMultiplier(arg_4_0, arg_4_1)
	return arg_4_0.multiplier_[arg_4_1] or 0
end

function var_0_0.getIcon(arg_5_0, arg_5_1)
	return arg_5_0.icon_[arg_5_1] or ""
end

function var_0_0.isMultiplierCard(arg_6_0, arg_6_1)
	if arg_6_0.multiplier_[arg_6_1] and arg_6_0.multiplier_[arg_6_1] > 1 then
		return true
	else
		return false
	end
end

function var_0_0.allcount(arg_7_0)
	return #arg_7_0.gift_
end

return var_0_0
