local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhitianxinchang", var_0_1.ctx.battle.requireFighter("Zhitianxinchang"))
local var_0_4 = 0.1
local var_0_5 = 0.001
local var_0_6 = {
	40010277,
	40010278
}

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	if arg_1_1.target and arg_1_1.target:isHasBuffByID(var_0_6[1]) then
		arg_1_4 = arg_1_4 * (1 + var_0_4 + var_0_5 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	return var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
end

return var_0_3
