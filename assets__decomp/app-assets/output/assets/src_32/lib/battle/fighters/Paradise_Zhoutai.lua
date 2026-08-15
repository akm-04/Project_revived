local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseZhoutai", var_0_1.ctx.battle.requireFighter("ElementBoss"))

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	local var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_1_6 = arg_1_1.target:getHp()
		local var_1_7 = arg_1_1.target:getHpLimit()

		var_1_2 = var_1_2 * (1 + var_1_6 * var_1_6 * 0.5 / (var_1_7 * var_1_7))
	end

	return var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5
end

function var_0_3.isHurtBreak(arg_2_0, arg_2_1, arg_2_2)
	return false
end

return var_0_3
