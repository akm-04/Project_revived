local var_0_0 = class("ActivityDiglettTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.point_ = {}
	arg_1_0.type_ = {}
	arg_1_0.upTime_ = {}
	arg_1_0.stayTime_ = {}
	arg_1_0.downTime_ = {}
	arg_1_0.icon1_ = {}
	arg_1_0.icon2_ = {}
	arg_1_0.icon3_ = {}

	import("app.common.tables.TableParser").parse("activity_diglett_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.upTime_[var_2_0] = tonumber(arg_2_0.up_time)
		arg_1_0.stayTime_[var_2_0] = tonumber(arg_2_0.stay_time)
		arg_1_0.downTime_[var_2_0] = tonumber(arg_2_0.down_time)
		arg_1_0.icon1_[var_2_0] = arg_2_0.icon1
		arg_1_0.icon2_[var_2_0] = arg_2_0.icon2
		arg_1_0.icon3_[var_2_0] = arg_2_0.icon3
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.point(arg_4_0, arg_4_1)
	return arg_4_0.point_[arg_4_1] or 0
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 0
end

function var_0_0.upTime(arg_6_0, arg_6_1)
	return arg_6_0.upTime_[arg_6_1] or 0
end

function var_0_0.stayTime(arg_7_0, arg_7_1)
	return arg_7_0.stayTime_[arg_7_1] or 0
end

function var_0_0.downTime(arg_8_0, arg_8_1)
	return arg_8_0.downTime_[arg_8_1] or 0
end

function var_0_0.icon1(arg_9_0, arg_9_1)
	return arg_9_0.icon1_[arg_9_1] or ""
end

function var_0_0.icon2(arg_10_0, arg_10_1)
	return arg_10_0.icon2_[arg_10_1] or ""
end

function var_0_0.icon3(arg_11_0, arg_11_1)
	return arg_11_0.icon3_[arg_11_1] or ""
end

return var_0_0
