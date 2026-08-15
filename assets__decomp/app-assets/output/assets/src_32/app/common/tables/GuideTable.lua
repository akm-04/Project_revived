local var_0_0 = class("GuideTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.descs_ = {}
	arg_1_0.clickPos_ = {}
	arg_1_0.clickSize_ = {}
	arg_1_0.arrowDir_ = {}
	arg_1_0.dialogPos_ = {}
	arg_1_0.lr_ = {}

	import("app.common.tables.TableParser").parse("guide.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.descs_[var_2_0] = arg_2_0.desc
		arg_1_0.clickPos_[var_2_0] = xyd.splitToNumber(arg_2_0.click_pos, "|")
		arg_1_0.clickSize_[var_2_0] = xyd.splitToNumber(arg_2_0.click_size, "|")
		arg_1_0.arrowDir_[var_2_0] = tonumber(arg_2_0.arrow_direction)
		arg_1_0.dialogPos_[var_2_0] = xyd.splitToNumber(arg_2_0.dialog_pos, "|")
		arg_1_0.lr_[var_2_0] = tonumber(arg_2_0.lr)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.descs_[arg_3_1]
end

function var_0_0.clickPos(arg_4_0, arg_4_1)
	return arg_4_0.clickPos_[arg_4_1] or {}
end

function var_0_0.clickSize(arg_5_0, arg_5_1)
	return arg_5_0.clickSize_[arg_5_1] or {}
end

function var_0_0.arrowDir(arg_6_0, arg_6_1)
	return arg_6_0.arrowDir_[arg_6_1] or nil
end

function var_0_0.dialogPos(arg_7_0, arg_7_1)
	return arg_7_0.dialogPos_[arg_7_1] or {}
end

function var_0_0.lr(arg_8_0, arg_8_1)
	return arg_8_0.lr_[arg_8_1] or 0
end

return var_0_0
