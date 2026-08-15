local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fengxian", var_0_1.ctx.battle.requireFighter("Fengxian"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0.1
local var_0_6 = 0.003
local var_0_7 = 10001690
local var_0_8 = 40012672
local var_0_9 = 40012671

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	local var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if var_1_2 > 0 and arg_1_1.attackType == var_0_2.AttackType.AD and arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		var_1_4 = var_1_4 + var_1_2 * (var_0_5 + var_0_6 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	return var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_7 and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_2_0 = arg_2_0:createNewBuffs({
			var_0_8
		}, arg_2_1.target, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_2_1.target:addBuffs(var_2_0)

		local var_2_1 = arg_2_0:createNewBuffs({
			var_0_9
		}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_2_0:addBuffs(var_2_1)
	end
end

return var_0_3
