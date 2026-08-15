local var_0_0 = class("CGShowDataTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.funcType_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.pos_ = {}
	arg_1_0.params_ = {}
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("open_story" .. (arg_1_1 or ""), function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.funcType_[var_2_0] = tonumber(arg_2_0.func_type)
		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.scale_[var_2_0] = tonumber(arg_2_0.scale)
		arg_1_0.pos_[var_2_0] = xyd.splitToNumber(arg_2_0.position, "|")
		arg_1_0.params_[var_2_0] = arg_2_0.params
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.funcType(arg_4_0, arg_4_1)
	return arg_4_0.funcType_[arg_4_1]
end

function var_0_0.dialog(arg_5_0, arg_5_1)
	return arg_5_0.dialog_[arg_5_1]
end

function var_0_0.scale(arg_6_0, arg_6_1)
	return arg_6_0.scale_[arg_6_1]
end

function var_0_0.pos(arg_7_0, arg_7_1)
	return arg_7_0.pos_[arg_7_1] or {}
end

function var_0_0.params(arg_8_0, arg_8_1)
	return arg_8_0.params_[arg_8_1]
end

function var_0_0.time(arg_9_0, arg_9_1)
	return arg_9_0.time_[arg_9_1] or 0
end

return var_0_0
