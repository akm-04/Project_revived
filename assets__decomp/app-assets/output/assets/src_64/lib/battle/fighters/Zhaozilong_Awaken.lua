local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhaozilong", var_0_1.ctx.battle.requireFighter("Zhaozilong"))
local var_0_4 = 0.1
local var_0_5 = 0.005

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeAtkedCount = 0
	arg_1_0.awakeExtraHarm = 0
end

function var_0_3.updateUnitDataByTarget(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_4 > 0 then
		arg_2_0.awakeAtkedCount = arg_2_0.awakeAtkedCount + 1

		if arg_2_0.awakeAtkedCount >= 3 then
			arg_2_0.awakeAtkedCount = 0
			arg_2_0.awakeExtraHarm = arg_2_4 * (var_0_4 + var_0_5 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
			arg_2_4 = 0
			arg_2_3 = false
			arg_2_6 = 0
			arg_2_7 = 0
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_4 > 0 then
		arg_3_4 = arg_3_4 + arg_3_0.awakeExtraHarm
		arg_3_0.awakeExtraHarm = 0
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

return var_0_3
