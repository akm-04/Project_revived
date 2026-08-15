local var_0_0 = class("ThrowSandbagGroupTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.num_ = {}
	arg_1_0.group_ = {}
	arg_1_0.wij_ = {}
	arg_1_0.probability_ = {}
	arg_1_0.speed_ = {}

	import("app.common.tables.TableParser").parse("dodge_group.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.group_[var_2_0] = tonumber(arg_2_0.group)
		arg_1_0.wij_[var_2_0] = tonumber(arg_2_0.wij)
		arg_1_0.probability_[var_2_0] = tonumber(arg_2_0.probability)
		arg_1_0.speed_[var_2_0] = tonumber(arg_2_0.speed)
	end)
end

function var_0_0.num(arg_3_0, arg_3_1)
	return arg_3_0.num_[arg_3_1]
end

function var_0_0.group(arg_4_0, arg_4_1)
	return arg_4_0.group_[arg_4_1]
end

function var_0_0.wij(arg_5_0, arg_5_1)
	return arg_5_0.wij_[arg_5_1]
end

function var_0_0.probability(arg_6_0, arg_6_1)
	return arg_6_0.probability_[arg_6_1]
end

function var_0_0.speed(arg_7_0, arg_7_1)
	return arg_7_0.speed_[arg_7_1]
end

return var_0_0
