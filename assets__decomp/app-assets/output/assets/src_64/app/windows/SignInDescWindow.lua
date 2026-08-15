local var_0_0 = class("SignInDescWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("rule_title"):setString(var_0_1:translation("SIGN_IN_RULE_TITLE"))
	arg_2_0:nodeByName("rule_txt"):setString(var_0_1:translation("SIGN_IN_RULE"))
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

return var_0_0
