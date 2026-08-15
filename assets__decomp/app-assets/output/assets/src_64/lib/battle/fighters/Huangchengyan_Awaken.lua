local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangchengyan", var_0_1.ctx.battle.requireFighter("Huangchengyan"))
local var_0_4 = 10000
local var_0_5 = 0
local var_0_6 = 1
local var_0_7 = 40011028
local var_0_8 = 10000971
local var_0_9 = 40011029
local var_0_10 = 40011030
local var_0_11 = 10000922
local var_0_12 = 80010174
local var_0_13 = {
	40011592
}
local var_0_14 = {
	40011590,
	40011591
}
local var_0_15 = 0.005

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_4 > 0 and arg_1_1.skillID == arg_1_0:getPugongID() and arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		local var_1_0 = var_0_6 + var_0_5 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

		arg_1_0.greenCureNum_ = arg_1_0.greenCureNum_ + var_1_0 * arg_1_4
	elseif arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_1_1 = arg_1_0.greenCureNum_

		if var_1_1 > var_0_4 then
			var_1_1 = var_0_4
		end

		arg_1_5 = arg_1_5 + var_1_1
		arg_1_5 = arg_1_5 + arg_1_5 * (arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_15)
		arg_1_0.greenCureNum_ = 0
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

return var_0_3
