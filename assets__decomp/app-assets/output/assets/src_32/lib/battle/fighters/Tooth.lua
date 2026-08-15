local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Tooth", var_0_1.ctx.battle.getRequire("BaseFighter"))

function var_0_3.singleLoop(arg_1_0)
	var_0_3.super.singleLoop(arg_1_0)

	if var_0_1.ctx.battle.teamBEnd and not arg_1_0:isDeath() then
		arg_1_0:updateHp(0)
		arg_1_0:die()

		return
	end
end

return var_0_3
