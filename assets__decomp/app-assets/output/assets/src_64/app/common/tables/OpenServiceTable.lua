local var_0_0 = class("OpenServiceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.reward_ = {}
	arg_1_0.condition_ = {}

	import("app.common.tables.TableParser").parse("activity_openserver.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.reward_[var_2_0] = tonumber(arg_2_0.reward)
		arg_1_0.condition_[var_2_0] = tonumber(arg_2_0.condition)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1]
end

function var_0_0.reward(arg_4_0, arg_4_1)
	return arg_4_0.reward_[arg_4_1]
end

function var_0_0.condition(arg_5_0, arg_5_1)
	return arg_5_0.condition_[arg_5_1]
end

return var_0_0
