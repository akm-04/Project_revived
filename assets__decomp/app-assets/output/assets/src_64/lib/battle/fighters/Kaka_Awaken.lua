local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Kaka"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 30010047
local var_0_6 = 2

function var_0_3.dHarmBuffBreakFeedback(arg_1_0, arg_1_1, arg_1_2)
	if arg_1_1 and not arg_1_1:isDeath() then
		local var_1_0 = arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_6

		arg_1_1:updateEnergyBy(var_1_0)
	end
end

return var_0_3
