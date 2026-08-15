local var_0_0 = class("SchoolStoryTalkTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.position_ = {}
	arg_1_0.left_img_ = {}
	arg_1_0.right_img_ = {}
	arg_1_0.expression_ = {}
	arg_1_0.bg_ = {}

	local var_1_0 = "talk" .. arg_1_1

	if type(arg_1_1) == "string" then
		var_1_0 = arg_1_1
	end

	import("app.common.tables.TableParser").parse(var_1_0, function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.position_[var_2_0] = tonumber(arg_2_0.position)
		arg_1_0.left_img_[var_2_0] = tonumber(arg_2_0.l_img)
		arg_1_0.right_img_[var_2_0] = tonumber(arg_2_0.r_img)
		arg_1_0.expression_[var_2_0] = tonumber(arg_2_0.expression)
		arg_1_0.bg_[var_2_0] = tonumber(arg_2_0.bg)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.dialog(arg_4_0, arg_4_1)
	return arg_4_0.dialog_[arg_4_1] or ""
end

function var_0_0.position(arg_5_0, arg_5_1)
	return arg_5_0.position_[arg_5_1]
end

function var_0_0.leftImg(arg_6_0, arg_6_1)
	return arg_6_0.left_img_[arg_6_1] or 0
end

function var_0_0.rightImg(arg_7_0, arg_7_1)
	return arg_7_0.right_img_[arg_7_1] or 0
end

function var_0_0.expression(arg_8_0, arg_8_1)
	return arg_8_0.expression_[arg_8_1]
end

function var_0_0.bg(arg_9_0, arg_9_1)
	return arg_9_0.bg_[arg_9_1]
end

function var_0_0.ids(arg_10_0)
	return arg_10_0.ids_
end

return var_0_0
