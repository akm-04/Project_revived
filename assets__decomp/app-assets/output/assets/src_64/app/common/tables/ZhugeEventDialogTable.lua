local var_0_0 = class("ZhugeEventDialogTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.dialog_ = {}
	arg_1_0.next_ = {}
	arg_1_0.coinRate_ = {}
	arg_1_0.resultType_ = {}
	arg_1_0.resultNum_ = {}
	arg_1_0.skillType_ = {}

	import("app.common.tables.TableParser").parse("zhuge_event_dialog.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.next_[var_2_0] = xyd.splitToNumber(arg_2_0.next, "|")
		arg_1_0.coinRate_ = xyd.splitToNumber(arg_2_0.coin_rate, "|")
		arg_1_0.resultType_[var_2_0] = tonumber(arg_2_0.result_type)
		arg_1_0.resultNum_[var_2_0] = tonumber(arg_2_0.result_num)
		arg_1_0.skillType_[var_2_0] = tonumber(arg_2_0.skill_type)
	end)
end

function var_0_0.dialog(arg_3_0, arg_3_1)
	return arg_3_0.dialog_[arg_3_1] or ""
end

function var_0_0.next(arg_4_0, arg_4_1)
	return arg_4_0.next_[arg_4_1] or {}
end

function var_0_0.coinRate(arg_5_0, arg_5_1)
	return arg_5_0.coinRate_[arg_5_1] or {}
end

function var_0_0.resultType(arg_6_0, arg_6_1)
	return arg_6_0.resultType_[arg_6_1] or 0
end

function var_0_0.resultNum(arg_7_0, arg_7_1)
	return arg_7_0.resultNum_[arg_7_1] or 0
end

function var_0_0.skillType(arg_8_0, arg_8_1)
	return arg_8_0.skillType_[arg_8_1] or 0
end

return var_0_0
