local var_0_0 = class("StoryDataTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.names_ = {}
	arg_1_0.iconsL_ = {}
	arg_1_0.iconsR_ = {}
	arg_1_0.iconsM_ = {}
	arg_1_0.positions_ = {}
	arg_1_0.texts_ = {}
	arg_1_0.sounds_ = {}
	arg_1_0.times_ = {}
	arg_1_0.trends_ = {}
	arg_1_0.faces_ = {}
	arg_1_0.functions_ = {}
	arg_1_0.dialogNum_ = 0

	import("app.common.tables.TableParser").parse("story" .. tostring(arg_1_1), function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.positions_[var_2_0] = tonumber(arg_2_0.position)

		if arg_2_0.img then
			arg_1_0.iconsL_[var_2_0] = arg_1_0.positions_[var_2_0] == 1 and arg_2_0.img
			arg_1_0.iconsR_[var_2_0] = arg_1_0.positions_[var_2_0] == 2 and arg_2_0.img
			arg_1_0.iconsM_[var_2_0] = arg_1_0.positions_[var_2_0] == 3 and arg_2_0.img
		else
			arg_1_0.iconsL_[var_2_0] = arg_2_0.l_img
			arg_1_0.iconsR_[var_2_0] = arg_2_0.r_img
			arg_1_0.iconsM_[var_2_0] = arg_2_0.m_img
		end

		arg_1_0.texts_[var_2_0] = arg_2_0.dialog
		arg_1_0.trends_[var_2_0] = tonumber(arg_2_0.trends)
		arg_1_0.faces_[var_2_0] = arg_2_0.expression
		arg_1_0.sounds_[var_2_0] = arg_2_0.sound
		arg_1_0.times_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.functions_[var_2_0] = tonumber(arg_2_0.functions)
		arg_1_0.dialogNum_ = arg_1_0.dialogNum_ + 1
	end)
end

function var_0_0.getDialogNum(arg_3_0)
	return arg_3_0.dialogNum_
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.names_[arg_4_1]
end

function var_0_0.iconL(arg_5_0, arg_5_1)
	return arg_5_0.iconsL_[arg_5_1] or ""
end

function var_0_0.iconR(arg_6_0, arg_6_1)
	return arg_6_0.iconsR_[arg_6_1] or ""
end

function var_0_0.iconM(arg_7_0, arg_7_1)
	return arg_7_0.iconsM_[arg_7_1] or ""
end

function var_0_0.position(arg_8_0, arg_8_1)
	return arg_8_0.positions_[arg_8_1]
end

function var_0_0.text(arg_9_0, arg_9_1)
	return arg_9_0.texts_[arg_9_1]
end

function var_0_0.sound(arg_10_0, arg_10_1)
	return arg_10_0.sounds_[arg_10_1]
end

function var_0_0.decodeString(arg_11_0, arg_11_1)
	return string.gsub(arg_11_1, "\\n", "\n")
end

function var_0_0.trends(arg_12_0, arg_12_1)
	return arg_12_0.trends_[arg_12_1] or 0
end

function var_0_0.face(arg_13_0, arg_13_1)
	return arg_13_0.faces_[arg_13_1]
end

function var_0_0.time(arg_14_0, arg_14_1)
	return arg_14_0.times_[arg_14_1] or -1
end

function var_0_0.functions(arg_15_0, arg_15_1)
	return arg_15_0.functions_[arg_15_1] or 0
end

return var_0_0
