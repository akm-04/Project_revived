local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Tangzi", var_0_1.ctx.battle.requireFighter("Tangzi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.battleConfig
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = -0.1
local var_0_9 = 0.005

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_4 > 0 and arg_1_0:checkHasContinueBuff(arg_1_1.target) then
		arg_1_4 = arg_1_4 + arg_1_4 * (var_0_8 + var_0_9 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

function var_0_3.checkHasContinueBuff(arg_2_0, arg_2_1)
	for iter_2_0, iter_2_1 in pairs(arg_2_1:getBuffs()) do
		if iter_2_1:getType() == var_0_2.BuffType.CONTINUE_HARM then
			return true
		end
	end

	return false
end

return var_0_3
