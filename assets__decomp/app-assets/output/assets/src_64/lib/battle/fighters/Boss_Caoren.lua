local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caoren", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = 3
local var_0_5 = 2

function var_0_3.getHpRate(arg_1_0)
	return (arg_1_0:getHpLimit() - arg_1_0:getHp()) / arg_1_0:getHpLimit() * 100
end

function var_0_3.getSkinCureRate(arg_2_0)
	return var_0_5 * math.floor(arg_2_0:getHpRate() / var_0_4)
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_0.hero_.isSkinOn_ then
		arg_3_5 = arg_3_5 * (1 + arg_3_0:getSkinCureRate() / 100)
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
