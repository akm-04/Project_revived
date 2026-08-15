local var_0_0 = class("RecallStoryTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.name_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.position_ = {}
	arg_1_0.lImg_ = {}
	arg_1_0.rImg_ = {}
	arg_1_0.time_ = {}
	arg_1_0.trends_ = {}
	arg_1_0.expression_ = {}
	arg_1_0.movement_ = {}
	arg_1_0.ids_ = {}

	import("app.common.tables.TableParser").parse("recall_story" .. tostring(arg_1_1), function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.position_[var_2_0] = tonumber(arg_2_0.position)
		arg_1_0.lImg_[var_2_0] = tonumber(arg_2_0.l_img)
		arg_1_0.rImg_[var_2_0] = tonumber(arg_2_0.r_img)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.trends_[var_2_0] = tonumber(arg_2_0.trends)
		arg_1_0.expression_[var_2_0] = tonumber(arg_2_0.expression)
		arg_1_0.movement_[var_2_0] = tonumber(arg_2_0.movement)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.dialog(arg_4_0, arg_4_1)
	return arg_4_0.dialog_[arg_4_1] or ""
end

function var_0_0.position(arg_5_0, arg_5_1)
	return arg_5_0.position_[arg_5_1] or 0
end

function var_0_0.lImg(arg_6_0, arg_6_1)
	return arg_6_0.lImg_[arg_6_1] or 0
end

function var_0_0.rImg(arg_7_0, arg_7_1)
	return arg_7_0.rImg_[arg_7_1] or 0
end

function var_0_0.time(arg_8_0, arg_8_1)
	return arg_8_0.time_[arg_8_1] or 0
end

function var_0_0.trends(arg_9_0, arg_9_1)
	return arg_9_0.trends_[arg_9_1] or 0
end

function var_0_0.expression(arg_10_0, arg_10_1)
	return arg_10_0.expression_[arg_10_1] or 0
end

function var_0_0.movement(arg_11_0, arg_11_1)
	return arg_11_0.movement_[arg_11_1] or 0
end

function var_0_0.ids(arg_12_0)
	return arg_12_0.ids_
end

return var_0_0
