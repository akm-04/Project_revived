local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dingge", var_0_1.ctx.battle.getRequire("BaseFighter"))

function var_0_3.applyHurtFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5)
	arg_1_2 = 0
	arg_1_3 = 0

	return var_0_3.super.applyHurtFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5)
end

return var_0_3
