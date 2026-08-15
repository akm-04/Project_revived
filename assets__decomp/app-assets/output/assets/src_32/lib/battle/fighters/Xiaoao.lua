local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.35
local var_0_7 = 40011370
local var_0_8 = 0.8
local var_0_9 = 40011371
local var_0_10 = 40011374
local var_0_11 = 0.1
local var_0_12 = 10001304

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyExtraHarmCount = 0
	arg_2_0.isAddGreenBuff = false
	arg_2_0.records_.blue_buff_remove = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and not arg_3_0.isAddGreenBuff then
		arg_3_0.isAddGreenBuff = true

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1.hero_:getDistanceType() ~= var_0_2.DistanceType.QIANPAI then
				local var_3_0 = var_0_4.new({
					tableID = var_0_7,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByID(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
					fighter = arg_3_0,
					target = iter_3_1
				})

				iter_3_1:addBuffs({
					var_3_0
				})
			end
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_3.target:getTeamType() == arg_3_0:getTeamType() and iter_3_3.target:isHasBuffByID(var_0_9) and iter_3_3:getType() == var_0_2.BuffType.CONTINUE_HARM then
				local var_3_1 = false

				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					if arg_3_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)] and type(arg_3_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)]) == "table" and arg_3_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)][iter_3_3.target.fighterIndex] and arg_3_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)][iter_3_3.target.fighterIndex][1] == iter_3_3:getTableID() then
						var_3_1 = true

						table.remove(arg_3_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)][iter_3_3.target.fighterIndex], 1)
					end
				else
					local var_3_2 = var_0_8

					if arg_3_0.isStarBlue_ then
						var_3_2 = var_3_2 + var_0_11
					end

					var_3_1 = var_0_2.weightedChoise({
						var_3_2,
						1 - var_3_2
					}) == 1

					if var_3_1 then
						if not arg_3_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)] then
							arg_3_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)] = {}
						end

						if not arg_3_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)][iter_3_3.target.fighterIndex] then
							arg_3_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)][iter_3_3.target.fighterIndex] = {}
						end

						table.insert(arg_3_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)][iter_3_3.target.fighterIndex], iter_3_3:getTableID())
					end
				end

				if var_3_1 then
					iter_3_3.target:removeBuffs(iter_3_3)
				end
			end
		end
	end
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.blueBuffRemove = arg_4_1.blue_buff_remove
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.blue_buff_remove = arg_5_0.records_.blue_buff_remove

	return var_5_0
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and arg_6_0.isStarEnergy_ then
		local var_6_0 = var_0_4.new({
			tableID = var_0_10,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)),
			skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy),
			fighter = arg_6_0,
			target = arg_6_1.target
		})

		arg_6_1.target:addBuffs({
			var_6_0
		})
	end
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	if arg_7_1.rootID_ == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_7_0

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
				local var_7_1 = iter_7_1:getBuffs()
				local var_7_2

				for iter_7_2 = 1, #var_7_1 do
					local var_7_3 = var_7_1[iter_7_2]

					if var_7_3 and var_7_3:getType() == var_0_2.BuffType.CONTINUE_HARM and (not var_7_2 and var_7_3:getTime() < 2700 or var_7_2 and var_7_3:getTime() > var_7_2:getTime() and var_7_3:getTime() < 2700) then
						var_7_2 = var_7_3
					end
				end

				if var_7_2 then
					iter_7_1:removeBuffs(var_7_2)

					if not var_7_0 or var_7_2:getTime() > var_7_0:getTime() then
						var_7_0 = var_7_2
					end
				end
			end
		end

		if var_7_0 then
			arg_7_0.energyExtraHarmCount = var_7_0:getTime()
		else
			arg_7_0.energyExtraHarmCount = 0
		end
	end

	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if arg_8_4 > 0 and arg_8_1.skillID == arg_8_0:getEnergySkillID() then
		arg_8_4 = arg_8_4 * (1 + arg_8_0.energyExtraHarmCount / 30 * 0.1)
	end

	return var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
end

function var_0_3.updateUnitDataBySpecialHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	local var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and var_9_2 > 0 and arg_9_1.target:getTeamType() == arg_9_0:getTeamType() and arg_9_1.fighter:getTeamType() ~= arg_9_0:getTeamType() and arg_9_1.attackType == var_0_2.AttackType.AP and arg_9_1.target:getSummonType() == var_0_2.summonMonsterType.None and arg_9_1.target.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI and var_0_2.weightedChoise({
		var_0_6,
		1 - var_0_6
	}) == 1 then
		var_9_2 = 0
	end

	return var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5
end

function var_0_3.deathFeedback(arg_10_0, arg_10_1)
	var_0_3.super.deathFeedback(arg_10_0, arg_10_1)

	if arg_10_1:getTeamType() == arg_10_0:getTeamType() and arg_10_1:getSummonType() == var_0_2.summonMonsterType.None then
		local var_10_0 = {}

		for iter_10_0, iter_10_1 in ipairs(arg_10_0.selfTeam_) do
			if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None then
				table.insert(var_10_0, iter_10_1)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			if arg_10_0.isStarPurple_ then
				local var_10_1 = arg_10_0:createAttackUnits(var_10_0, var_0_12)

				for iter_10_2, iter_10_3 in ipairs(var_10_1) do
					table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
					table.insert(arg_10_0.records_.special_units, iter_10_3)
				end
			else
				local var_10_2 = arg_10_0:createAttackUnits(var_10_0, arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				for iter_10_4, iter_10_5 in ipairs(var_10_2) do
					table.insert(arg_10_0.moveAttackUnits_, iter_10_5)
					table.insert(arg_10_0.records_.special_units, iter_10_5)
				end
			end
		end
	end
end

return var_0_3
