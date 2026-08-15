local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lidian", var_0_1.ctx.battle.requireFighter("Lidian"))
local var_0_4 = 0.003

function var_0_3.getADBaoJi(arg_1_0)
	return var_0_3.super.getADBaoJi(arg_1_0) * var_0_4 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
end

function var_0_3.getHuJia(arg_2_0)
	return var_0_3.super.getHuJia(arg_2_0) * var_0_4 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
end

function var_0_3.getMoKang(arg_3_0)
	return var_0_3.super.getMoKang(arg_3_0) * var_0_4 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
end

return var_0_3
