local var_0_0 = class("ActivityLvbuStoryTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.name_ = {}
	arg_1_0.img_ = {}
	arg_1_0.position_ = {}
	arg_1_0.choose_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.bg_ = {}
	arg_1_0.time_ = {}
	arg_1_0.trends_ = {}
	arg_1_0.expression_ = {}
	arg_1_0.chooseIds_ = {}
	arg_1_0.nextId_ = {}
	arg_1_0.battleId_ = {}
	arg_1_0.isFalse_ = {}
	arg_1_0.dialogNum_ = 0

	import("app.common.tables.TableParser").parse("story" .. tostring(arg_1_1), function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.img_[var_2_0] = arg_2_0.img
		arg_1_0.position_[var_2_0] = tonumber(arg_2_0.position)
		arg_1_0.choose_[var_2_0] = arg_2_0.choose
		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.bg_[var_2_0] = arg_2_0.bg
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.trends_[var_2_0] = tonumber(arg_2_0.trends)
		arg_1_0.expression_[var_2_0] = tonumber(arg_2_0.expression)
		arg_1_0.chooseIds_[var_2_0] = xyd.splitToNumber(arg_2_0.choose_id, "|")
		arg_1_0.nextId_[var_2_0] = tonumber(arg_2_0.next_id)
		arg_1_0.battleId_[var_2_0] = tonumber(arg_2_0.battle_id)
		arg_1_0.isFalse_[var_2_0] = tonumber(arg_2_0.is_false)
		arg_1_0.dialogNum_ = arg_1_0.dialogNum_ + 1
	end)
end

function var_0_0.getDialogNum(arg_3_0)
	return arg_3_0.dialogNum_
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1]
end

function var_0_0.img(arg_5_0, arg_5_1)
	return arg_5_0.img_[arg_5_1]
end

function var_0_0.position(arg_6_0, arg_6_1)
	return arg_6_0.position_[arg_6_1]
end

function var_0_0.choose(arg_7_0, arg_7_1)
	return arg_7_0.choose_[arg_7_1]
end

function var_0_0.dialog(arg_8_0, arg_8_1)
	return arg_8_0.dialog_[arg_8_1]
end

function var_0_0.bg(arg_9_0, arg_9_1)
	return arg_9_0.bg_[arg_9_1]
end

function var_0_0.time(arg_10_0, arg_10_1)
	return arg_10_0.time_[arg_10_1]
end

function var_0_0.trends(arg_11_0, arg_11_1)
	return arg_11_0.trends_[arg_11_1] or 0
end

function var_0_0.expression(arg_12_0, arg_12_1)
	return arg_12_0.expression_[arg_12_1]
end

function var_0_0.chooseIds(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.chooseIds_[arg_13_1]

	for iter_13_0 = #var_13_0, 1, -1 do
		if var_13_0[iter_13_0] == 0 then
			table.remove(var_13_0, iter_13_0)
		end
	end

	return var_13_0 or {}
end

function var_0_0.nextId(arg_14_0, arg_14_1)
	return arg_14_0.nextId_[arg_14_1] or 0
end

function var_0_0.battleId(arg_15_0, arg_15_1)
	return arg_15_0.battleId_[arg_15_1]
end

function var_0_0.isFalse(arg_16_0, arg_16_1)
	return arg_16_0.isFalse_[arg_16_1]
end

function var_0_0.decodeString(arg_17_0, arg_17_1)
	return string.gsub(arg_17_1, "\\n", "\n")
end

return var_0_0
