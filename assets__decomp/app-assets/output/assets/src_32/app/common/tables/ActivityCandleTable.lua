local var_0_0 = class("ActivityCandleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.activityID_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_candle.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.activityID_[var_2_0] = tonumber(arg_2_0.activity_id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.activityID(arg_4_0, arg_4_1)
	return arg_4_0.activityID_[arg_4_1] or 0
end

function var_0_0.activityIDs(arg_5_0)
	return arg_5_0.activityID_
end

return var_0_0
