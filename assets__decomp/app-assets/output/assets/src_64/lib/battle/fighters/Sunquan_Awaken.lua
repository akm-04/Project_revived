local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunquan", var_0_1.ctx.battle.requireFighter("Sunquan"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 40010056
local var_0_6 = 60010056

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakenSkillTimes_ = 3
	arg_1_0.playEnergySkill_ = nil
	arg_1_0.copyMonsterID = 80000220
end

function var_0_3.calculateUnitData(arg_2_0, arg_2_1)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.calculateUnitData(arg_2_0, arg_2_1)
	local var_2_6 = arg_2_1.target

	if arg_2_1.skillID == var_0_5 and var_2_2 > 0 and arg_2_0.awakenSkillTimes_ > 0 and arg_2_0.playEnergySkill_ then
		if var_2_6.__cname ~= "Sunquan" then
			var_2_5 = var_2_5 + arg_2_0:getMp()
		end

		arg_2_0.awakenSkillTimes_ = arg_2_0.awakenSkillTimes_ - 1
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.getMp(arg_3_0)
	if not arg_3_0.mp_ then
		arg_3_0.mp_ = var_0_4:mp(var_0_6) + var_0_4:mpStep(var_0_6) * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	end

	return arg_3_0.mp_
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.playEnergySkill_ = true
	end

	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)
end

return var_0_3
