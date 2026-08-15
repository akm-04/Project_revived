local var_0_0 = class("LibraryCGTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.bg_ = {}
	arg_1_0.limit_ = {}
	arg_1_0.time_ = {}
	arg_1_0.effect_ = {}

	import("app.common.tables.TableParser").parse("library_background", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.bg_[var_2_0] = arg_2_0.background
		arg_1_0.limit_[var_2_0] = tonumber(arg_2_0.limit)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.finish_time)
		arg_1_0.effect_[var_2_0] = tonumber(arg_2_0.effect)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getIDs(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.getBG(arg_4_0, arg_4_1)
	return arg_4_0.bg_[arg_4_1] or ""
end

function var_0_0.getLimit(arg_5_0, arg_5_1)
	return arg_5_0.limit_[arg_5_1] or 0
end

function var_0_0.getTime(arg_6_0, arg_6_1)
	return arg_6_0.time_[arg_6_1] or 0
end

function var_0_0.getEffect(arg_7_0, arg_7_1)
	return arg_7_0.effect_[arg_7_1] or 1
end

return var_0_0
