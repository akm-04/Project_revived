local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Xusheng", var_0_1.ctx.battle.requireFighter("Xusheng"))
local var_0_5 = 0
local var_0_6 = 0.001

function var_0_4.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_4.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_4 > 0 and arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_1_6 = arg_1_6 + arg_1_4 * (var_0_5 + var_0_6 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

return var_0_4
