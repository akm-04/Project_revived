local var_0_0 = class("ThrowSandbagBuffTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.wij_ = {}
	arg_1_0.speed_ = {}
	arg_1_0.effect_ = {}
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("dodge_buff.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.wij_[var_2_0] = tonumber(arg_2_0.wij)
		arg_1_0.speed_[var_2_0] = tonumber(arg_2_0.speed)
		arg_1_0.effect_[var_2_0] = tonumber(arg_2_0.effect)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1]
end

function var_0_0.wij(arg_4_0, arg_4_1)
	return arg_4_0.wij_[arg_4_1]
end

function var_0_0.speed(arg_5_0, arg_5_1)
	return arg_5_0.speed_[arg_5_1]
end

function var_0_0.effect(arg_6_0, arg_6_1)
	return arg_6_0.effect_[arg_6_1]
end

function var_0_0.time(arg_7_0, arg_7_1)
	return arg_7_0.time_[arg_7_1]
end

return var_0_0
