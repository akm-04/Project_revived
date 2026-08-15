local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mao", var_0_1.ctx.battle.getRequire("BaseFighter"))

function var_0_3.updateHp(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = arg_1_0:getHp()

	var_0_3.super.updateHp(arg_1_0, arg_1_1, arg_1_2)

	local var_1_1 = arg_1_0:getHp()

	if var_1_1 < var_1_0 and arg_1_0.summoner and not arg_1_0.summoner:isDeath() then
		arg_1_0.summoner:updateHp(arg_1_0.summoner:getHp() - var_1_1 + var_1_0)
	end
end

return var_0_3
