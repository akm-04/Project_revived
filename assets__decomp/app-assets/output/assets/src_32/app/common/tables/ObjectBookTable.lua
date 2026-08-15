local var_0_0 = class("ObjectBookTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.des_ = {}
	arg_1_0.desNumber_ = {}
	arg_1_0.desStep_ = {}
	arg_1_0.classType_ = {}
	arg_1_0.skill_ = {}
	arg_1_0.targets_ = {}
	arg_1_0.bookType_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.buffs_ = {}
	arg_1_0.number_ = {}
	arg_1_0.stepUp_ = {}
	arg_1_0.power_ = {}
	arg_1_0.stepPower_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.init_ = {}
	arg_1_0.stepAttr_ = {}
	arg_1_0.stepType_ = {}
	arg_1_0.stepStart_ = {}
	arg_1_0.step_ = {}

	import("app.common.tables.TableParser").parse("object_book.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.des_[var_2_0] = arg_2_0.des
		arg_1_0.desNumber_[var_2_0] = xyd.splitToNumber(arg_2_0.des_number, "|")
		arg_1_0.desStep_[var_2_0] = xyd.splitToNumber(arg_2_0.des_step, "|")
		arg_1_0.classType_[var_2_0] = tonumber(arg_2_0.class_type)
		arg_1_0.skill_[var_2_0] = tonumber(arg_2_0.skill)
		arg_1_0.targets_[var_2_0] = tonumber(arg_2_0.target)
		arg_1_0.bookType_[var_2_0] = tonumber(arg_2_0.book_type)
		arg_1_0.attr_[var_2_0] = xyd.splitToNumber(arg_2_0.attr, "|")
		arg_1_0.buffs_[var_2_0] = xyd.splitToNumber(arg_2_0.buff, "|")
		arg_1_0.number_[var_2_0] = xyd.splitToNumber(arg_2_0.number, "|")
		arg_1_0.stepUp_[var_2_0] = xyd.splitToNumber(arg_2_0.step_up, "|")
		arg_1_0.power_[var_2_0] = tonumber(arg_2_0.power)
		arg_1_0.stepPower_[var_2_0] = tonumber(arg_2_0.step_power)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.stepType_[var_2_0] = xyd.splitToNumber(arg_2_0.step_type, "|")
		arg_1_0.stepStart_[var_2_0] = xyd.splitToNumber(arg_2_0.step_start, "|")
		arg_1_0.step_[var_2_0] = xyd.splitToNumber(arg_2_0.step, "|")
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.des(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_2 or 1
	local var_4_1 = arg_4_0.des_[arg_4_1]
	local var_4_2 = arg_4_0:desNumber(arg_4_1)
	local var_4_3 = arg_4_0:desStep(arg_4_1)

	for iter_4_0 = 1, #var_4_2 do
		local var_4_4, var_4_5 = string.find(var_4_1, "%%d")

		var_4_1 = (string.sub(var_4_1, 1, var_4_4 - 1) or "") .. tostring(var_4_2[iter_4_0] + var_4_3[iter_4_0] * var_4_0) .. (var_4_1.sub(var_4_1, var_4_5 + 1) or "")
	end

	return var_4_1
end

function var_0_0.desNumber(arg_5_0, arg_5_1)
	return arg_5_0.desNumber_[arg_5_1] or {}
end

function var_0_0.desStep(arg_6_0, arg_6_1)
	return arg_6_0.desStep_[arg_6_1] or 0
end

function var_0_0.classType(arg_7_0, arg_7_1)
	return arg_7_0.classType_[arg_7_1] or 0
end

function var_0_0.skill(arg_8_0, arg_8_1)
	return arg_8_0.skill_[arg_8_1] or 0
end

function var_0_0.target(arg_9_0, arg_9_1)
	return arg_9_0.targets_[arg_9_1] or 1
end

function var_0_0.bookType(arg_10_0, arg_10_1)
	return arg_10_0.bookType_[arg_10_1] or 0
end

function var_0_0.attr(arg_11_0, arg_11_1)
	return arg_11_0.attr_[arg_11_1] or {}
end

function var_0_0.buffs(arg_12_0, arg_12_1)
	return arg_12_0.buffs_[arg_12_1] or {}
end

function var_0_0.number(arg_13_0, arg_13_1)
	return arg_13_0.number_[arg_13_1] or {}
end

function var_0_0.stepUp(arg_14_0, arg_14_1)
	return arg_14_0.stepUp_[arg_14_1] or {}
end

function var_0_0.power(arg_15_0, arg_15_1)
	return arg_15_0.power_[arg_15_1] or 0
end

function var_0_0.stepPower(arg_16_0, arg_16_1)
	return arg_16_0.stepPower_[arg_16_1] or 0
end

function var_0_0.icon(arg_17_0, arg_17_1)
	return arg_17_0.icon_[arg_17_1] or ""
end

function var_0_0.stepType(arg_18_0, arg_18_1)
	return arg_18_0.stepType_[arg_18_1] or {}
end

function var_0_0.stepStart(arg_19_0, arg_19_1)
	return arg_19_0.stepStart_[arg_19_1] or {}
end

function var_0_0.step(arg_20_0, arg_20_1)
	return arg_20_0.step_[arg_20_1] or {}
end

return var_0_0
