local var_0_0 = class("SuperRichGuideWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "super_rich_guide"
local var_0_2 = xyd.tables.translation

function var_0_0.open(arg_1_0)
	arg_1_0 = arg_1_0 or {}

	return xyd.WindowManager.get():openWindow(var_0_1, arg_1_0)
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.callback = arg_2_2.callback
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	return
end

return var_0_0
