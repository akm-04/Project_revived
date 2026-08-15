local var_0_0 = class("AcademyArenaResourceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.actionPoint_ = {}
	arg_1_0.summonPoint_ = {}
	arg_1_0.agilityPoint_ = {}
	arg_1_0.default_ = {}

	import("app.common.tables.TableParser").parse("supremacy_resource.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.actionPoint_[var_2_0] = tonumber(arg_2_0.action_point)
		arg_1_0.summonPoint_[var_2_0] = tonumber(arg_2_0.summon_point)
		arg_1_0.agilityPoint_[var_2_0] = tonumber(arg_2_0.agility_point)
		arg_1_0.default_[var_2_0] = tonumber(arg_2_0.default)
	end)
end

function var_0_0.actionPoint(arg_3_0, arg_3_1)
	return arg_3_0.actionPoint_[arg_3_1] or 0
end

function var_0_0.summonPoint(arg_4_0, arg_4_1)
	return arg_4_0.summonPoint_[arg_4_1] or 0
end

function var_0_0.agilityPoint(arg_5_0, arg_5_1)
	return arg_5_0.agilityPoint_[arg_5_1] or 0
end

return var_0_0
