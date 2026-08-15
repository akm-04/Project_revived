local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhitianxinchangSP", var_0_1.ctx.battle.requireFighter("ZhitianxinchangSP"))
local var_0_4 = 0.3
local var_0_5 = 0.005
local var_0_6 = 0.2
local var_0_7 = 0.005
local var_0_8 = 0.1
local var_0_9 = 0.005
local var_0_10 = 0
local var_0_11 = 0.03
local var_0_12 = 0
local var_0_13 = 0.03

function var_0_3.getADBaoJi(arg_1_0)
	local var_1_0 = (var_0_4 + var_0_5 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)) * (arg_1_0:getHp() / arg_1_0:getHpLimit() * 0.8 + 0.2)

	return var_0_3.super.getADBaoJi(arg_1_0) * (1 + var_1_0)
end

function var_0_3.getADBaoJiHarm(arg_2_0)
	local var_2_0 = (var_0_6 + var_0_7 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)) * (arg_2_0:getHp() / arg_2_0:getHpLimit() * 0.8 + 0.2)

	return var_0_3.super.getADBaoJiHarm(arg_2_0) * (1 + var_2_0)
end

function var_0_3.getHuJia(arg_3_0)
	local var_3_0 = (var_0_12 + var_0_13 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)) * (arg_3_0:getHp() / arg_3_0:getHpLimit() * -0.8 + 1)

	return var_0_3.super.getHuJia(arg_3_0) * (1 + var_3_0)
end

function var_0_3.getMoKang(arg_4_0)
	local var_4_0 = (var_0_10 + var_0_11 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)) * (arg_4_0:getHp() / arg_4_0:getHpLimit() * -0.8 + 1)

	return var_0_3.super.getMoKang(arg_4_0) * (1 + var_4_0)
end

function var_0_3.getCurrentAckSpeed(arg_5_0)
	local var_5_0 = var_0_3.super.getCurrentAckSpeed(arg_5_0)
	local var_5_1 = (var_0_8 + var_0_9 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)) * (arg_5_0:getHp() / arg_5_0:getHpLimit() * -0.8 + 1)

	return math.min(var_5_0 * (1 + var_5_1), var_0_2.MAX_ATTACK_SPEED)
end

return var_0_3
