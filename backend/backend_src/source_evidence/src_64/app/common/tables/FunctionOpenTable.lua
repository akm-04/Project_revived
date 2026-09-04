local var_0_0 = class("FunctionOpenTable")
local var_0_1 = "function.lua"

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.stages_ = {}
	arg_1_0.levels_ = {}
	arg_1_0.vips_ = {}
	arg_1_0.energies_ = {}
	arg_1_0.conditions_ = {}
	arg_1_0.icons_ = {}
	arg_1_0.isOnLevelupWnd_ = {}
	arg_1_0.level_tips_ = {}
	arg_1_0.openControl_ = {}
	arg_1_0.tip_ = {}
	arg_1_0.isPopUp_ = {}
	arg_1_0.fxNum_ = {}
	arg_1_0.functionPic_ = {}
	arg_1_0.functionDesc_ = {}

	import("app.common.tables.TableParser").parse(var_0_1, function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name

		local var_2_1 = arg_2_0.level
		local var_2_2 = xyd.splitToNumber(arg_2_0.level, "|")

		if #var_2_2 >= 2 then
			local var_2_3 = var_2_2[1]
			local var_2_4 = var_2_2[2]

			if var_2_3 == 1 then
				arg_1_0.levels_[var_2_0] = var_2_4
			elseif var_2_3 == 2 then
				arg_1_0.stages_[var_2_0] = var_2_4
			elseif var_2_3 == 3 then
				arg_1_0.vips_[var_2_0] = var_2_4
			elseif var_2_3 == 6 then
				arg_1_0.levels_[var_2_0] = var_2_4
			elseif var_2_3 == 7 then
				arg_1_0.levels_[var_2_0] = var_2_4
			end
		else
			arg_1_0.energies_[var_2_0] = 500
		end

		arg_1_0.conditions_[var_2_0] = tonumber(arg_2_0.condition) or 0
		arg_1_0.icons_[var_2_0] = tonumber(arg_2_0.icon) or 0
		arg_1_0.isOnLevelupWnd_[var_2_0] = tonumber(arg_2_0.is_on_levelup_wnd) or 0
		arg_1_0.level_tips_[var_2_0] = tonumber(arg_2_0.level_tips) or 0
		arg_1_0.openControl_[var_2_0] = tonumber(arg_2_0.open_control) or 0
		arg_1_0.tip_[var_2_0] = arg_2_0.tip
		arg_1_0.isPopUp_[var_2_0] = tonumber(arg_2_0.is_function_show) or 0
		arg_1_0.fxNum_[var_2_0] = tonumber(arg_2_0.fx_num) or 0
		arg_1_0.functionPic_[var_2_0] = arg_2_0.function_pic
		arg_1_0.functionDesc_[var_2_0] = arg_2_0.function_desc
	end)
end

function var_0_0.levelTips(arg_3_0, arg_3_1)
	return arg_3_0.level_tips_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.names_[arg_4_1]
end

function var_0_0.stage(arg_5_0, arg_5_1)
	return arg_5_0.stages_[arg_5_1] or 0
end

function var_0_0.level(arg_6_0, arg_6_1)
	return arg_6_0.levels_[arg_6_1] or 1
end

function var_0_0.vip(arg_7_0, arg_7_1)
	return arg_7_0.vips_[arg_7_1] or 0
end

function var_0_0.energy(arg_8_0, arg_8_1)
	return arg_8_0.energies_[arg_8_1] or 0
end

function var_0_0.condition(arg_9_0, arg_9_1)
	return arg_9_0.conditions_[arg_9_1] or 0
end

function var_0_0.icon(arg_10_0, arg_10_1)
	return arg_10_0.icons_[arg_10_1] or 0
end

function var_0_0.is_open(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)
	if arg_11_0:level(arg_11_1) > 0 and arg_11_2 < arg_11_0:level(arg_11_1) then
		return false
	end

	if arg_11_0:stage(arg_11_1) > 0 and arg_11_3 < arg_11_0:stage(arg_11_1) then
		return false
	end

	if arg_11_0:vip(arg_11_1) > 0 and arg_11_4 < arg_11_0:vip(arg_11_1) then
		return false
	end

	if arg_11_0:energy(arg_11_1) > 0 and arg_11_5 < arg_11_0:energy(arg_11_1) then
		return false
	end

	return true
end

function var_0_0.show_tip(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_0.conditions_[arg_12_1] > 0 and arg_12_2 >= arg_12_0.conditions_[arg_12_1] then
		return true
	else
		return false
	end
end

function var_0_0.show_icon(arg_13_0, arg_13_1, arg_13_2)
	if arg_13_0.icons_[arg_13_1] > 0 and arg_13_2 >= arg_13_0.icons_[arg_13_1] then
		return true
	else
		return false
	end
end

function var_0_0.getAllOpenIDByStageID(arg_14_0, arg_14_1)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in pairs(arg_14_0.stages_) do
		if iter_14_1 <= arg_14_1 and iter_14_1 > 0 then
			table.insert(var_14_0, iter_14_0)
		end
	end

	return var_14_0
end

function var_0_0.getAllOpenIDByLevel(arg_15_0, arg_15_1)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in pairs(arg_15_0.levels_) do
		if iter_15_1 <= arg_15_1 and iter_15_1 > 0 then
			table.insert(var_15_0, iter_15_0)
		end
	end

	return var_15_0
end

function var_0_0.isOnLevelupWnd(arg_16_0, arg_16_1)
	return arg_16_0.isOnLevelupWnd_[arg_16_1] or 0
end

function var_0_0.open_control(arg_17_0, arg_17_1)
	return arg_17_0.openControl_[arg_17_1] or 0
end

function var_0_0.tip(arg_18_0, arg_18_1)
	return arg_18_0.tip_[arg_18_1] or ""
end

function var_0_0.isPopUp(arg_19_0, arg_19_1)
	return arg_19_0.isPopUp_[arg_19_1] or 0
end

function var_0_0.fxNum(arg_20_0, arg_20_1)
	return arg_20_0.fxNum_[arg_20_1] or 0
end

function var_0_0.functionPic(arg_21_0, arg_21_1)
	return arg_21_0.functionPic_[arg_21_1] or ""
end

function var_0_0.functionDesc(arg_22_0, arg_22_1)
	return arg_22_0.functionDesc_[arg_22_1] or ""
end

return var_0_0
