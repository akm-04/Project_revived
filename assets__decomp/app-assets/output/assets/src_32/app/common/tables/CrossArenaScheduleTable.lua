local var_0_0 = class("CrossArenaScheduleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("cross_arena_schedule.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
	end)
end

function var_0_0.time(arg_3_0, arg_3_1)
	return arg_3_0.time_[arg_3_1] or 0
end

return var_0_0
