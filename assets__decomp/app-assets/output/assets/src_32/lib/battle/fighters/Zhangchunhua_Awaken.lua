local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangchunhua", var_0_1.ctx.battle.requireFighter("Zhangchunhua"))
local var_0_4 = 0
local var_0_5 = 0.005

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_1_4 > 0 then
		for iter_1_0, iter_1_1 in ipairs(arg_1_1.target:getBuffs()) do
			if iter_1_1:getType() == var_0_2.BuffType.CONTINUE_HARM then
				arg_1_4 = arg_1_4 + arg_1_4 * (var_0_4 + var_0_5 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				break
			end
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
end

return var_0_3
