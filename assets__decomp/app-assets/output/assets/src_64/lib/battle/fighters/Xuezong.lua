local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuezong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.cabinetSkillTable
local var_0_10 = {
	0.2,
	0.3,
	0.5
}
local var_0_11 = 0
local var_0_12 = 0.005
local var_0_13 = 0.0035
local var_0_14 = 20100004
local var_0_15 = 0.4

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount = 0
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.GreenAllyPrizeSkills = {
			10002200,
			10002194,
			10002195
		}
		arg_2_0.GreenEnemyPrizeSkills = {
			10002201,
			10002196,
			10002197
		}
		arg_2_0.EnergyPrizeSkills = {
			0,
			10002198,
			10002199
		}
	else
		arg_2_0.GreenAllyPrizeSkills = {
			10001584,
			10001578,
			10001579
		}
		arg_2_0.GreenEnemyPrizeSkills = {
			10001585,
			10001580,
			10001581
		}
		arg_2_0.EnergyPrizeSkills = {
			0,
			10001582,
			10001583
		}
	end
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)

	if var_3_0 == arg_3_0:getEnergySkillID() then
		local var_3_1 = arg_3_0:getGreenOrEnergyPrize()

		if var_3_1 > 1 then
			return arg_3_0.EnergyPrizeSkills[var_3_1]
		end
	end

	return var_3_0
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if not arg_4_0.extraSkillJudge then
		arg_4_0.extraSkillJudge = true
		arg_4_0.extraSkillLevel = arg_4_0.hero_:skillBook()[tostring(var_0_14)] or 0
	end
end

function var_0_3.getGreenOrEnergyPrize(arg_5_0)
	local var_5_0 = var_0_13 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * arg_5_0.purpleCount

	if arg_5_0.extraSkillLevel > 0 then
		var_5_0 = var_5_0 + arg_5_0.extraSkillLevel * var_0_9:attrValues(var_0_14) * arg_5_0.purpleCount * 0.01
	end

	local var_5_1 = {
		var_0_10[1],
		var_0_10[2],
		var_0_10[3]
	}

	for iter_5_0, iter_5_1 in ipairs(var_5_1) do
		if var_5_0 > 0 then
			deltaProb = math.min(iter_5_1, var_5_0)
			var_5_1[iter_5_0] = var_5_1[iter_5_0] - deltaProb
			var_5_1[3] = var_5_1[3] + deltaProb
		end
	end

	local var_5_2 = var_0_2.weightedChoise(var_5_1)

	if var_5_2 == 3 then
		arg_5_0.firstPrizeHit = true

		if arg_5_0.skinSkillIndex_ == 1 then
			arg_5_0.purpleCount = arg_5_0.purpleCount * 0.5
		else
			arg_5_0.purpleCount = 0
		end
	elseif arg_5_0.skinSkillIndex_ == 1 then
		arg_5_0.purpleCount = arg_5_0.purpleCount + 1 + var_0_15
	else
		arg_5_0.purpleCount = arg_5_0.purpleCount + 1
	end

	return var_5_2
end

function var_0_3.getBluePrizeProb(arg_6_0)
	local var_6_0 = var_0_13 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * arg_6_0.purpleCount

	if arg_6_0.extraSkillLevel > 0 then
		var_6_0 = var_6_0 + arg_6_0.extraSkillLevel * var_0_9:attrValues(var_0_14) * arg_6_0.purpleCount * 0.01
	end

	local var_6_1 = var_0_11 + var_0_12 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
	local var_6_2 = math.min(1, var_6_1 + var_6_0)

	prize = var_0_2.weightedChoise({
		var_6_2,
		1 - var_6_2
	})

	if prize == 1 then
		arg_6_0.firstPrizeHit = true
	end

	return prize
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1.skillID
	local var_7_1 = arg_7_1.target

	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if var_7_0 == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_7_2
		local var_7_3

		if var_7_1:getTeamType() == arg_7_0:getTeamType() then
			local var_7_4 = arg_7_0:getGreenOrEnergyPrize()

			var_7_3 = arg_7_0.GreenAllyPrizeSkills[var_7_4]
		else
			local var_7_5 = arg_7_0:getGreenOrEnergyPrize()

			var_7_3 = arg_7_0.GreenEnemyPrizeSkills[var_7_5]
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_6 = arg_7_0:createAttackUnits({
				var_7_1
			}, var_7_3)

			for iter_7_0, iter_7_1 in ipairs(var_7_6) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD2(arg_8_0, arg_8_1, arg_8_2)
	return {
		var_0_6.A3(arg_8_0, arg_8_1)[1],
		var_0_6.B3(arg_8_0, arg_8_1)[1]
	}
end

function var_0_3.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if arg_9_1.skillID == arg_9_1.fighter:getPugongID() and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_9_0:getBluePrizeProb() == 1 then
		arg_9_4 = 0

		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_1.fighter
		}, arg_9_1.fighter:getPugongID())

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			iter_9_1:setExtraHarm(arg_9_1.basicHarm)
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

return var_0_3
