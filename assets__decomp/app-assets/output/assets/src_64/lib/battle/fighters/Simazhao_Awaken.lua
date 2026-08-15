local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Simazhao", var_0_1.ctx.battle.requireFighter("Simazhao"))
local var_0_4 = 0
local var_0_5 = 30

function var_0_3.getAP(arg_1_0)
	return var_0_3.super.getAP(arg_1_0) + arg_1_0:getAwakeAP()
end

function var_0_3.getAwakeAP(arg_2_0)
	return (1 - arg_2_0:getHp() / arg_2_0:getHpLimit()) * (var_0_4 + var_0_5 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
end

return var_0_3
