local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Daqiao", var_0_1.ctx.battle.requireFighter("Daqiao"))
local var_0_4 = 10010004
local var_0_5 = 0
local var_0_6 = 0.002
local var_0_7 = 0.08
local var_0_8 = 0.24

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.twiceAwakeCount = 0
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:getTableID() == var_0_4 then
		arg_2_0.twiceAwakeCount = arg_2_0.twiceAwakeCount + 1
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_4 > 0 and arg_3_1.target:getTeamType() == arg_3_0:getTeamType() then
		if arg_3_1.attackType == var_0_2.AttackType.AP then
			arg_3_4 = arg_3_4 - arg_3_4 * (var_0_5 + var_0_6 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))
		elseif arg_3_1.attackType == var_0_2.AttackType.AD then
			arg_3_4 = arg_3_4 - arg_3_4 * math.min(var_0_8, var_0_7 * arg_3_0.twiceAwakeCount)
		end
	end

	return var_0_3.super.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

return var_0_3
