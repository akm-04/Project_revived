local var_0_0 = class("EditNameScene", import("app.common.ui.BaseScene"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onEnterTransitionFinish(arg_2_0)
	var_0_0.super.onEnterTransitionFinish(arg_2_0)
	xyd.WindowManager.get():openWindow("edit_name")
end

return var_0_0
