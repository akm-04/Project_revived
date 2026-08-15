local var_0_0 = class("GraduationWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:addBlockLayer()
end

return var_0_0
