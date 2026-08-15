local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caofang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 5
local var_0_6 = 40010635
local var_0_7 = 10000660
local var_0_8 = 0
local var_0_9 = 0.002
local var_0_10 = 0
local var_0_11 = 0.002

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueSkillCD_ = 0
	arg_1_0.greenDirection_ = 1
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) == arg_2_1.skillID then
		local var_2_0
		local var_2_1 = arg_2_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
		local var_2_2 = arg_2_0.greenDirection_ * var_2_1
		local var_2_3

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				local var_2_4 = iter_2_1:getX() * var_2_2

				if not var_2_3 or var_2_3 < var_2_4 then
					var_2_0 = iter_2_1
					var_2_3 = var_2_4
				end
			end
		end

		if var_2_0 then
			arg_2_0:x(var_2_0:getX() + var_2_2 * 50)
			arg_2_0:y(var_2_0:getY())

			if var_2_2 == 1 then
				arg_2_0:flipX(true)
			else
				arg_2_0:flipX(false)
			end
		end

		arg_2_0.greenDirection_ = arg_2_0.greenDirection_ * -1
	end
end

function var_0_3.applyHurtFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_3_1.attackType ~= var_0_2.AttackType.CURE and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = var_0_11 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) + var_0_10

		if var_0_2.weightedChoise({
			var_3_0,
			1 - var_3_0
		}) == 1 then
			local var_3_1 = arg_3_0:createAttackUnits({
				arg_3_1.fighter
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end

	return var_0_3.super.applyHurtFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5)
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_1.skillID == var_0_7 then
		arg_4_5 = arg_4_5 + arg_4_0.blueReHarm_
	end

	return var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_1.attackType ~= var_0_2.AttackType.Cure and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_5_0:isHasBuffByID(var_0_6) and arg_5_4 > 0 and arg_5_0.blueSkillCD_ < 1 then
		local var_5_0 = var_0_8 + var_0_9 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if var_0_2.weightedChoise({
			var_5_0,
			1 - var_5_0
		}) == 1 then
			arg_5_0.blueReHarm_ = arg_5_4
			arg_5_4 = 0

			local var_5_1 = arg_5_0:createAttackUnits({
				arg_5_0
			}, var_0_7)

			for iter_5_0, iter_5_1 in ipairs(var_5_1) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end

			arg_5_0.blueSkillCD_ = var_0_5
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0.blueSkillCD_ > 0 then
		arg_6_0.blueSkillCD_ = arg_6_0.blueSkillCD_ - 1
	end
end

return var_0_3
