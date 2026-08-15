local var_0_0 = class("ActivityGirslTreasureTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.dropboxID_ = {}
	arg_1_0.guaranteed_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("activity_girls_treasure.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.dropboxID_[var_2_0] = tonumber(arg_2_0.dropbox_id)
		arg_1_0.guaranteed_[var_2_0] = tonumber(arg_2_0.guaranteed)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.dropboxID(arg_4_0, arg_4_1)
	return arg_4_0.dropboxID_[arg_4_1] or 0
end

function var_0_0.guaranteed(arg_5_0, arg_5_1)
	return arg_5_0.guaranteed_[arg_5_1] or 0
end

function var_0_0.rate(arg_6_0, arg_6_1)
	return arg_6_0.rate_[arg_6_1] or 0
end

function var_0_0.time(arg_7_0, arg_7_1)
	return arg_7_0.time_[arg_7_1] or 0
end

function var_0_0.names(arg_8_0)
	return arg_8_0.name_
end

return var_0_0
