local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Mingzhiguangxiu", var_0_1.ctx.battle.requireFighter("Mingzhiguangxiu"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 200
local var_0_7 = 35
local var_0_8 = 5

function var_0_4.init(arg_1_0)
	var_0_4.super.init(arg_1_0)

	arg_1_0.pugongCount = 0
end

function var_0_4.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_4.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getPugongID() then
		arg_2_0.pugongCount = arg_2_0.pugongCount + 1
	elseif arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		arg_2_0.pugongCount = 0
	end
end

function var_0_4.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_4.super.getOrbOfFrontSkill(arg_3_0)

	if var_3_0 == arg_3_0:getPugongID() and arg_3_0.pugongCount >= var_0_8 then
		var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
	end

	return var_3_0
end

function var_0_4.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	if not arg_4_5 and arg_4_2 > 0 and arg_4_1.attackType == var_0_2.AttackType.AD then
		arg_4_2 = math.max(arg_4_2 - (var_0_6 + var_0_7 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)), 0)
	end

	return var_0_4.super.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
end

return var_0_4
