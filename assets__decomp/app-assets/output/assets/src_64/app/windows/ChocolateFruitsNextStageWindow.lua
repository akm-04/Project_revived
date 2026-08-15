local var_0_0 = class("ChocolateFruitsNextStageWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
	var_0_2.performWithDelayGlobal(function()
		arg_3_0.callback()
	end, 3)
end

function var_0_0.layout(arg_5_0)
	return
end

return var_0_0
