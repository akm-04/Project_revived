local var_0_0 = class("BattleSpecialStoryTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.names_ = {}
	arg_1_0.lImg_ = {}
	arg_1_0.rImg_ = {}
	arg_1_0.positions_ = {}
	arg_1_0.choose_ = {}
	arg_1_0.chooseID_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.bg_ = {}
	arg_1_0.nextID_ = {}
	arg_1_0.result_ = {}

	import("app.common.tables.TableParser").parse("special" .. tostring(arg_1_1), function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.lImg_[var_2_0] = arg_2_0.l_img
		arg_1_0.rImg_[var_2_0] = arg_2_0.r_img
		arg_1_0.positions_[var_2_0] = tonumber(arg_2_0.position)
		arg_1_0.choose_[var_2_0] = arg_2_0.choose
		arg_1_0.chooseID_[var_2_0] = xyd.splitToNumber(arg_2_0.choose_id, "|")
		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.bg_[var_2_0] = arg_2_0.bg
		arg_1_0.nextID_[var_2_0] = tonumber(arg_2_0.next_id)
		arg_1_0.result_[var_2_0] = xyd.splitToNumber(arg_2_0.result, "|")
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.names_[arg_3_1]
end

function var_0_0.lImg(arg_4_0, arg_4_1)
	return arg_4_0.lImg_[arg_4_1] or ""
end

function var_0_0.rImg(arg_5_0, arg_5_1)
	return arg_5_0.rImg_[arg_5_1] or ""
end

function var_0_0.position(arg_6_0, arg_6_1)
	return arg_6_0.positions_[arg_6_1] or 0
end

function var_0_0.choose(arg_7_0, arg_7_1)
	return arg_7_0.choose_[arg_7_1] or ""
end

function var_0_0.chooseID(arg_8_0, arg_8_1)
	return arg_8_0.chooseID_[arg_8_1] or -1
end

function var_0_0.sound(arg_9_0, arg_9_1)
	return arg_9_0.sounds_[arg_9_1]
end

function var_0_0.dialog(arg_10_0, arg_10_1)
	return arg_10_0.dialog_[arg_10_1] or ""
end

function var_0_0.bg(arg_11_0, arg_11_1)
	return arg_11_0.bg_[arg_11_1] or ""
end

function var_0_0.nextID(arg_12_0, arg_12_1)
	return arg_12_0.nextID_[arg_12_1] or -1
end

function var_0_0.result(arg_13_0, arg_13_1)
	return arg_13_0.result_[arg_13_1] or {}
end

return var_0_0
