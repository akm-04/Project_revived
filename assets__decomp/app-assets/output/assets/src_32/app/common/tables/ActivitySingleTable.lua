local var_0_0 = class("ActivitySingleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.mission_ = {}
	arg_1_0.privity_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_single.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.mission_[var_2_0] = xyd.split(arg_2_0.mission, "|")
		arg_1_0.privity_[var_2_0] = xyd.splitToNumber(arg_2_0.privity, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.mission(arg_3_0, arg_3_1)
	return arg_3_0.mission_[arg_3_1] or ""
end

function var_0_0.privity(arg_4_0, arg_4_1)
	return arg_4_0.privity_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.days(arg_6_0)
	return #arg_6_0.mission_ or 0
end

return var_0_0
