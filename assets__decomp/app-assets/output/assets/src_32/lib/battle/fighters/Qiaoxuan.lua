local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Qiaoxuan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 40011901
local var_0_6 = 200
local var_0_7 = 40011890
local var_0_8 = 40011892
local var_0_9 = 80010238
local var_0_10 = 5
local var_0_11 = 40012704
local var_0_12 = {
	40012705,
	40012706
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isDefenceForm = false
	arg_1_0.skinCount = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.GreenAttackSkill = 10002525
		arg_2_0.GreenDefenceSkill = 10002526
		arg_2_0.BlueAttackSkill = 10002527
		arg_2_0.BlueDefenceSkill = 10002528
		arg_2_0.PurpleSkillMap = {
			[arg_2_0.GreenAttackSkill] = 10002519,
			[arg_2_0.GreenDefenceSkill] = 10002520,
			[arg_2_0.BlueAttackSkill] = 10002521,
			[arg_2_0.BlueDefenceSkill] = 10002522
		}
	else
		arg_2_0.GreenAttackSkill = 20030238
		arg_2_0.GreenDefenceSkill = 20040238
		arg_2_0.BlueAttackSkill = 30020238
		arg_2_0.BlueDefenceSkill = 30030238
		arg_2_0.PurpleSkillMap = {
			[arg_2_0.GreenAttackSkill] = 10001757,
			[arg_2_0.GreenDefenceSkill] = 10001758,
			[arg_2_0.BlueAttackSkill] = 10001759,
			[arg_2_0.BlueDefenceSkill] = 10001760
		}
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0.GreenAttackSkill or arg_3_1.skillID == arg_3_0.GreenDefenceSkill or arg_3_1.skillID == arg_3_0.BlueAttackSkill or arg_3_1.skillID == arg_3_0.BlueDefenceSkill then
		arg_3_0:purpleSkill(arg_3_1)

		if arg_3_0.skinSkillIndex_ == 1 then
			arg_3_0.skinCount = arg_3_0.skinCount + 1

			if arg_3_0.skinCount >= var_0_10 then
				local var_3_0 = arg_3_0:createNewBuffs({
					var_0_11
				}, arg_3_0, var_0_9, arg_3_0:getLevel())

				arg_3_0:addBuffs(var_3_0)

				for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
					local var_3_1 = arg_3_0:createNewBuffs(var_0_12, iter_3_1, var_0_9)

					iter_3_1:addBuffs(var_3_1)
				end

				arg_3_0.skinCount = 0
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 30 == 0 then
		arg_4_0:checkTransform()
	end
end

function var_0_3.checkTransform(arg_5_0)
	local var_5_0 = 0
	local var_5_1 = 0

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_5_0 = var_5_0 + 1
		end
	end

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_3:isDeath() and iter_5_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_5_1 = var_5_1 + 1
		end
	end

	arg_5_0.isDefenceForm = var_5_0 < var_5_1
end

function var_0_3.getOrbOfFrontSkill(arg_6_0)
	local var_6_0 = var_0_3.super.getOrbOfFrontSkill(arg_6_0)

	if var_0_4:father(var_6_0) == arg_6_0:getPugongID() then
		return var_6_0
	end

	local var_6_1 = var_0_4:buffOrb(var_6_0)

	if var_6_1 ~= 0 and arg_6_0.isDefenceForm then
		return var_6_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_6_0)
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	local var_7_0 = arg_7_1.target

	if arg_7_5 > 0 and var_7_0:getTeamType() == arg_7_0:getTeamType() and arg_7_1.skillID == arg_7_0.BlueDefenceSkill and var_7_0:isHasBuffByID(var_0_7) then
		arg_7_5 = 2 * arg_7_5
	elseif arg_7_4 > 0 and arg_7_1.skillID == arg_7_0.GreenAttackSkill and var_7_0:isHasBuffByID(var_0_8) then
		arg_7_4 = 2 * arg_7_4
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_0:isHasBuffByID(var_0_5) then
		local var_8_0 = arg_8_1.target

		if arg_8_4 > 0 and var_8_0:getTeamType() == arg_8_0:getTeamType() and arg_8_0:isIgnoreHarm(arg_8_1) then
			arg_8_4 = 0
		end
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.isIgnoreHarm(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1:getIniPos()
	local var_9_1 = math.abs(arg_9_0:getX() - arg_9_1.fighter:getX()) <= var_0_6

	return math.abs(arg_9_0:getX() - arg_9_1.target:getX()) <= var_0_6 and not var_9_1
end

function var_0_3.purpleSkill(arg_10_0, arg_10_1)
	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_10_0 = arg_10_0.PurpleSkillMap[arg_10_1.skillID]

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_10_1 = arg_10_0:createAttackUnits({
				arg_10_0
			}, var_10_0, arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_10_0, iter_10_1 in ipairs(var_10_1) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
				table.insert(arg_10_0.records_.special_units, iter_10_1)
			end
		end
	end
end

return var_0_3
