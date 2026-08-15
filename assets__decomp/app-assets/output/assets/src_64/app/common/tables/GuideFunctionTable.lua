local var_0_0 = class("GuideFunctionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.windowName_ = {}
	arg_1_0.stype_ = {}
	arg_1_0.para_ = {}
	arg_1_0.guideNewId_ = {}
	arg_1_0.wndGuidetime_ = {}
	arg_1_0.wndGuideIDs_ = {}

	import("app.common.tables.TableParser").parse("guide_function.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.windowName_[var_2_0] = arg_2_0.window_name

		if not arg_1_0.wndGuidetime_[arg_1_0.windowName_[var_2_0]] then
			arg_1_0.wndGuidetime_[arg_1_0.windowName_[var_2_0]] = 1
			arg_1_0.wndGuideIDs_[arg_1_0.windowName_[var_2_0]] = {}
			arg_1_0.wndGuideIDs_[arg_1_0.windowName_[var_2_0]][arg_1_0.wndGuidetime_[arg_1_0.windowName_[var_2_0]]] = var_2_0
		else
			arg_1_0.wndGuidetime_[arg_1_0.windowName_[var_2_0]] = arg_1_0.wndGuidetime_[arg_1_0.windowName_[var_2_0]] + 1
			arg_1_0.wndGuideIDs_[arg_1_0.windowName_[var_2_0]][arg_1_0.wndGuidetime_[arg_1_0.windowName_[var_2_0]]] = var_2_0
		end

		arg_1_0.stype_[var_2_0] = tonumber(arg_2_0.stype)
		arg_1_0.para_[var_2_0] = xyd.splitToNumber(arg_2_0.para, "|")
		arg_1_0.guideNewId_[var_2_0] = tonumber(arg_2_0.guide_new_id)
	end)
end

function var_0_0.checkGuide(arg_3_0, arg_3_1)
	return arg_3_0.wndGuidetime_[arg_3_1] or 0
end

function var_0_0.getGuideWnd(arg_4_0)
	return arg_4_0.wndGuidetime_ or {}
end

function var_0_0.getGuideWndIDs(arg_5_0, arg_5_1)
	return arg_5_0.wndGuideIDs_[arg_5_1] or {}
end

function var_0_0.windowName(arg_6_0, arg_6_1)
	return arg_6_0.windowName_[arg_6_1] or ""
end

function var_0_0.stype(arg_7_0, arg_7_1)
	return arg_7_0.stype_[arg_7_1] or 0
end

function var_0_0.para(arg_8_0, arg_8_1)
	return arg_8_0.para_[arg_8_1] or {}
end

function var_0_0.guideNewId(arg_9_0, arg_9_1)
	return arg_9_0.guideNewId_[arg_9_1] or 0
end

return var_0_0
