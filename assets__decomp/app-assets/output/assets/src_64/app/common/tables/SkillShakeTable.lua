local var_0_0 = class("SkillShakeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.lev_ = {}
	arg_1_0.duraTime_ = {}
	arg_1_0.strength_ = {}

	import("app.common.tables.TableParser").parse("skill_shake.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.level)

		arg_1_0.name_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.desc_[var_2_0] = tonumber(arg_2_0.range)
	end)
end

function var_0_0.time(arg_3_0, arg_3_1)
	return arg_3_0.duraTime_[arg_3_1] or 0
end

function var_0_0.range(arg_4_0, arg_4_1)
	return arg_4_0.strength_[arg_4_1] or 0
end

return var_0_0
