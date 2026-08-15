local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caofang", var_0_1.ctx.battle.requireFighter("Caofang"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0
local var_0_6 = 0.002
local var_0_7 = 5
local var_0_8 = 60010145

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeSkillCD_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.awakeSkillCD_ > 0 then
		arg_2_0.awakeSkillCD_ = arg_2_0.awakeSkillCD_ - 1
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.skillID == var_0_8 then
		arg_3_4 = arg_3_4 + arg_3_0.AwakeHarm_
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_1.attackType ~= var_0_2.AttackType.Cure and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 and arg_4_4 > 0 and arg_4_0.awakeSkillCD_ < 1 then
		local var_4_0 = var_0_5 + var_0_6 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		if var_0_2.weightedChoise({
			var_4_0,
			1 - var_4_0
		}) == 1 then
			arg_4_0.AwakeHarm_ = arg_4_4
			arg_4_4 = 0

			local var_4_1 = arg_4_0:createAttackUnits({
				arg_4_1.fighter
			}, var_0_8)

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end

			arg_4_0.awakeSkillCD_ = var_0_7
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

return var_0_3
