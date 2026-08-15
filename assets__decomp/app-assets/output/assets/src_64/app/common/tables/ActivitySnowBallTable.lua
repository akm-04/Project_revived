local var_0_0 = class("ActivitySnowBallTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.speed_ = {}

	import("app.common.tables.TableParser").parse("activity_snowball.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.model_id)

		arg_1_0.speed_[var_2_0] = arg_2_0.base_speed
	end)
end

function var_0_0.speed(arg_3_0, arg_3_1)
	return arg_3_0.speed_[arg_3_1] or 0
end

return var_0_0
