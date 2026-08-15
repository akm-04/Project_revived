local var_0_0 = class("AllNightBossTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.battleID_ = {}

	import("app.common.tables.TableParser").parse("activity_polar_night_boss.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.battleID_[var_2_0] = tonumber(arg_2_0.battle_id)
	end)
end

function var_0_0.battleID(arg_3_0, arg_3_1)
	return arg_3_0.battleID_[arg_3_1]
end

return var_0_0
