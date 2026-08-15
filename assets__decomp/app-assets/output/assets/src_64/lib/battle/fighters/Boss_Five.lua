local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Five", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = {
	81220002,
	81220003,
	81220004,
	81220005,
	81220006,
	81220007,
	81220008,
	81220009
}
local var_0_11 = {
	10002408,
	10002409
}
local var_0_12 = {
	10002410,
	10002411
}
local var_0_13 = {
	40012607,
	40012608
}
local var_0_14 = 0.6
local var_0_15 = 0.0025
local var_0_16 = 2700
local var_0_17 = 40012610
local var_0_18 = 0.05
local var_0_19 = 0.5
local var_0_20 = {
	40012612,
	40012613,
	40012614,
	40012615
}
local var_0_21 = 0.01
local var_0_22 = {
	40012616,
	40012617,
	40012618,
	40012619
}
local var_0_23 = 0.05
local var_0_24 = 1
local var_0_25 = 40012620
local var_0_26 = 10002424
local var_0_27 = 0.8
local var_0_28 = 50
local var_0_29 = 10002412
local var_0_30 = 5000
local var_0_31 = 0.5
local var_0_32 = 0.5
local var_0_33 = 0.2
local var_0_34 = 40012622

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("buff_harm")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.PurpleHarmCount = 0
	arg_2_0.PurpleCDCount = 0
	arg_2_0.StageOneBuffHarmCount = 0
	arg_2_0.StageTwoTarget = nil
	arg_2_0.StageTwoHarmFighter_ = {}
	arg_2_0.StageThreeCure = 0
	arg_2_0.LastSkillColor = nil
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_10[2] then
		local var_3_0, var_3_1 = arg_3_0:getPos()
		local var_3_2, var_3_3 = arg_3_1.target:getPos()

		if var_3_0 < var_3_2 then
			arg_3_1.target:pos(var_3_0 + 50, var_3_3)
		else
			arg_3_1.target:pos(var_3_0 - 50, var_3_3)
		end
	elseif arg_3_1.skillID == var_0_10[4] then
		local var_3_4 = arg_3_1.target:getBuffs()
		local var_3_5
		local var_3_6 = 0

		for iter_3_0, iter_3_1 in ipairs(var_3_4) do
			if var_0_9:dbuffType(iter_3_1:getTableID()) > 0 and iter_3_1:canRemove() and var_3_6 < 2 and (not var_3_5 or iter_3_1:getStartTime() > var_3_5:getStartTime()) then
				var_3_5 = iter_3_1
			end

			if var_3_5 then
				var_3_6 = var_3_6 + 1

				arg_3_1.target:removeBuffs(var_3_5)

				var_3_5 = nil
			end
		end
	elseif arg_3_1.skillID == var_0_11[2] then
		arg_3_0:greenJump(arg_3_1)
	end
end

function var_0_3.greenJump(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.target
	local var_4_1 = math.max(var_4_0:getX() - 10, 640)
	local var_4_2 = arg_4_0.fighterModel:getPosition()

	if var_4_2 < 640 then
		var_4_1 = var_4_2
	end

	arg_4_0:x(var_4_1)
end

function var_0_3.getOrbOfFrontSkill(arg_5_0)
	local var_5_0 = var_0_3.super.getFrontSkill(arg_5_0)

	if arg_5_0:isHasBuffByID(var_0_20[1]) and (var_5_0 == arg_5_0:getPugongID() or var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) then
		if arg_5_0.LastSkillColor == var_0_2.SKILL_INDEX.Green then
			var_5_0 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
			arg_5_0.LastSkillColor = var_0_2.SKILL_INDEX.Blue
		elseif arg_5_0.LastSkillColor == var_0_2.SKILL_INDEX.Blue then
			var_5_0 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
			arg_5_0.LastSkillColor = var_0_2.SKILL_INDEX.Green
		end
	end

	if var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_5_0.LastSkillColor = var_0_2.SKILL_INDEX.Green
	elseif var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_5_0.LastSkillColor = var_0_2.SKILL_INDEX.Blue
	end

	return var_5_0
end

function var_0_3.toDoPerFrames(arg_6_0)
	var_0_3.super.toDoPerFrames(arg_6_0)

	if arg_6_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0:getSkillLevelByID(var_0_10[5]) > 0 then
		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_0
		}, var_0_10[5])

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end

	if arg_6_0:isHasBuffByID(var_0_22[1]) and arg_6_0:getSkillLevelByID(var_0_10[5]) > 0 then
		for iter_6_2, iter_6_3 in ipairs(arg_6_0:getInfoByKey("buff_harm")) do
			local var_6_1 = iter_6_3.buff
			local var_6_2 = var_6_1.target
			local var_6_3 = var_6_1.fighter
			local var_6_4 = iter_6_3.harm

			if var_6_2 == arg_6_0 and var_6_4 > 0 and var_6_1:getType() == var_0_2.BuffType.CONTINUE_HARM then
				arg_6_0.StageOneBuffHarmCount = arg_6_0.StageOneBuffHarmCount + var_6_4
			end

			if arg_6_0.StageOneBuffHarmCount / arg_6_0:getHpLimit() >= var_0_23 and arg_6_0:isHasBuffByID(var_0_22[1]) then
				arg_6_0:removeBuffByID(var_0_22[1])
				arg_6_0:removeBuffByID(var_0_22[2])
				arg_6_0:removeBuffByID(var_0_22[3])

				local var_6_5 = arg_6_0:createNewBuffs({
					var_0_22[4]
				}, arg_6_0, var_0_10[5])

				arg_6_0:addBuffs(var_6_5)

				arg_6_0.StageOneBuffHarmCount = 0
			end
		end
	end

	if arg_6_0:getSkillLevelByID(var_0_10[3]) > 0 then
		for iter_6_4, iter_6_5 in ipairs(arg_6_0:getInfoByKey("buff_harm")) do
			local var_6_6 = iter_6_5.buff
			local var_6_7 = var_6_6.target
			local var_6_8 = var_6_6.fighter
			local var_6_9 = iter_6_5.harm

			if var_6_7 == arg_6_0 and var_6_9 > 0 and var_6_6:getType() == var_0_2.BuffType.CONTINUE_HARM then
				arg_6_0.PurpleHarmCount = arg_6_0.PurpleHarmCount + var_6_9

				local var_6_10 = arg_6_0.PurpleHarmCount / arg_6_0:getHpLimit()
				local var_6_11 = var_0_1.ctx.battle.count - arg_6_0.PurpleCDCount

				if var_6_10 >= var_0_19 and (arg_6_0.PurpleCDCount == 0 or var_6_11 >= var_0_16) then
					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_6_12 = arg_6_0:createAttackUnits({
							arg_6_0
						}, var_0_10[3])

						for iter_6_6, iter_6_7 in ipairs(var_6_12) do
							table.insert(arg_6_0.moveAttackUnits_, iter_6_7)
							table.insert(arg_6_0.records_.special_units, iter_6_7)
						end
					end

					arg_6_0.PurpleCDCount = var_0_1.ctx.battle.count
					arg_6_0.PurpleHarmCount = 0
				end
			end
		end
	end

	if arg_6_0:getSkillLevelByID(var_0_10[6]) > 0 then
		for iter_6_8, iter_6_9 in ipairs(arg_6_0:getInfoByKey("harm_info")) do
			local var_6_13 = iter_6_9.harm
			local var_6_14 = iter_6_9.fighter
			local var_6_15 = iter_6_9.target

			if not var_6_14:isDeath() and var_6_14:getTeamType() ~= arg_6_0:getTeamType() and var_6_14:getSummonType() == var_0_2.summonMonsterType.None and var_6_15 == arg_6_0 then
				if not arg_6_0.StageTwoHarmFighter_[var_6_14] then
					arg_6_0.StageTwoHarmFighter_[var_6_14] = 0
				end

				arg_6_0.StageTwoHarmFighter_[var_6_14] = arg_6_0.StageTwoHarmFighter_[var_6_14] + var_6_13
			end
		end
	end

	if arg_6_0:getSkillLevelByID(var_0_10[6]) > 0 and var_0_1.ctx.battle.count ~= 0 and var_0_1.ctx.battle.count % 300 == 0 and next(arg_6_0.StageTwoHarmFighter_) then
		local var_6_16
		local var_6_17

		for iter_6_10, iter_6_11 in pairs(arg_6_0.StageTwoHarmFighter_) do
			if not var_6_16 or var_6_16 < iter_6_11 then
				var_6_17 = iter_6_10
				var_6_16 = iter_6_11
			end
		end

		local var_6_18 = arg_6_0:createNewBuffs({
			var_0_25
		}, var_6_17, var_0_10[6])

		var_6_17:addBuffs(var_6_18)

		arg_6_0.StageTwoHarmFighter_ = {}
	end

	if arg_6_0:getSkillLevelByID(var_0_10[7]) > 0 and var_0_1.ctx.battle.count == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_19 = arg_6_0:createAttackUnits({
			arg_6_0
		}, var_0_10[7])

		for iter_6_12, iter_6_13 in ipairs(var_6_19) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_13)
			table.insert(arg_6_0.records_.special_units, iter_6_13)
		end
	end

	if arg_6_0:getSkillLevelByID(var_0_10[8]) > 0 and var_0_1.ctx.battle.count ~= 0 and var_0_1.ctx.battle.count % 300 == 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_20 = arg_6_0:getTargets(var_0_10[8])
		local var_6_21 = arg_6_0:createAttackUnits(var_6_20, var_0_10[8])

		for iter_6_14, iter_6_15 in ipairs(var_6_21) do
			iter_6_15.extraHarmRate = #var_6_20 * var_0_33

			table.insert(arg_6_0.moveAttackUnits_, iter_6_15)
			table.insert(arg_6_0.records_.special_units, iter_6_15)
		end
	end
end

function var_0_3.distributeBuff(arg_7_0, arg_7_1)
	var_0_3.super.distributeBuff(arg_7_0, arg_7_1)

	if arg_7_1:getType() == var_0_2.BuffType.CONTINUE_HARM and arg_7_0:isHasBuffByID(var_0_22[4]) then
		arg_7_1.manualHarmRevise = arg_7_1.manualHarmRevise + arg_7_1:getHarm() * var_0_24
	end

	if arg_7_1.fighter:isHasBuffByID(var_0_25) then
		local var_7_0 = arg_7_1.manualHarmRevise
		local var_7_1 = arg_7_1:getHarm()

		arg_7_1.manualHarmRevise = arg_7_1.manualHarmRevise - var_7_1 * (1 - var_0_27)
	end
end

function var_0_3.applyHurtFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0, var_8_1, var_8_2, var_8_3 = var_0_3.super.applyHurtFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)

	if var_8_0 > 0 then
		arg_8_0.PurpleHarmCount = arg_8_0.PurpleHarmCount + var_8_0

		local var_8_4 = arg_8_0.PurpleHarmCount / arg_8_0:getHpLimit()
		local var_8_5 = var_0_1.ctx.battle.count - arg_8_0.PurpleCDCount

		if var_8_4 >= var_0_19 and (arg_8_0.PurpleCDCount == 0 or var_8_5 >= var_0_16) then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_8_6 = arg_8_0:createAttackUnits({
					arg_8_0
				}, var_0_10[3])

				for iter_8_0, iter_8_1 in ipairs(var_8_6) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
					table.insert(arg_8_0.records_.special_units, iter_8_1)
				end
			end

			arg_8_0.PurpleCDCount = var_0_1.ctx.battle.count
			arg_8_0.PurpleHarmCount = 0
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3
end

function var_0_3.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_1.fighter:isHasBuffByID(var_0_25) then
		arg_9_4 = arg_9_4 * (1 - var_0_27)
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if (arg_10_1.skillID == var_0_12[1] or arg_10_1.skillID == var_0_12[2]) and arg_10_4 > 0 then
		arg_10_4 = arg_10_4 + arg_10_4 * (arg_10_0:getHp() / arg_10_0:getHpLimit()) * var_0_14
	elseif arg_10_1.skillID == var_0_10[2] then
		local var_10_0, var_10_1 = arg_10_0:getPos()
		local var_10_2, var_10_3 = arg_10_1.target:getPos()

		arg_10_4 = arg_10_4 + arg_10_4 * math.abs(var_10_0 - var_10_2 - 50) * var_0_15
	end

	if arg_10_1.target:isHasBuffByID(var_0_25) then
		local var_10_4 = arg_10_0:createAttackUnits({
			arg_10_0
		}, var_0_26)

		for iter_10_0, iter_10_1 in ipairs(var_10_4) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end
	end

	if arg_10_0:getSkillLevelByID(var_0_10[7]) > 0 and arg_10_4 > 0 and arg_10_0.StageThreeCure > 0 then
		local var_10_5 = math.min(var_0_30, arg_10_0.StageThreeCure * var_0_31)

		arg_10_0.StageThreeCure = 0
		arg_10_4 = arg_10_4 + var_10_5
	end

	if arg_10_0:getSkillLevelByID(var_0_10[7]) > 0 and arg_10_1.skillID == var_0_29 and arg_10_1.extraCure then
		arg_10_5 = arg_10_1.extraCure + arg_10_5
	end

	if arg_10_0:getSkillLevelByID(var_0_10[8]) > 0 and arg_10_1.extraHarmRate then
		arg_10_4 = arg_10_4 * (0.8 + arg_10_1.extraHarmRate)
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.updateUnitDataBySpecialHero(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if arg_11_0:getSkillLevelByID(var_0_10[7]) > 0 and arg_11_5 > 0 and arg_11_1.target:getTeamType() ~= arg_11_0:getTeamType() then
		local var_11_0 = arg_11_0:createAttackUnits({
			arg_11_0
		}, var_0_29)

		for iter_11_0, iter_11_1 in ipairs(var_11_0) do
			iter_11_1.extraCure = arg_11_5 * var_0_32

			table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
			table.insert(arg_11_0.records_.special_units, iter_11_1)
		end
	end

	if arg_11_0:getSkillLevelByID(var_0_10[7]) > 0 and arg_11_1.target == arg_11_0 and arg_11_5 > 0 and arg_11_0.StageThreeCure == 0 then
		arg_11_0.StageThreeCure = arg_11_5
	end

	return arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7
end

function var_0_3.selectTargetByTypeD1(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {}

	if arg_12_2 and arg_12_2.manualTargets_ then
		return arg_12_2.manualTargets_
	end

	local var_12_1 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() and iter_12_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
			local var_12_2, var_12_3 = iter_12_1.fighterModel:getPosition()

			table.insert(var_12_1, iter_12_1)
		end
	end

	if #var_12_1 == 0 then
		return var_12_0
	end

	for iter_12_2, iter_12_3 in ipairs(var_12_1) do
		local var_12_4, var_12_5 = iter_12_3.fighterModel:getPosition()
		local var_12_6, var_12_7 = arg_12_0.fighterModel:getPosition()

		if var_12_4 < var_12_6 then
			table.insert(var_12_0, iter_12_3)
		end
	end

	return var_12_0
end

function var_0_3.selectTargetByTypeD2(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}

	if arg_13_2 and arg_13_2.manualTargets_ then
		return arg_13_2.manualTargets_
	end

	local var_13_1 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and iter_13_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
			local var_13_2, var_13_3 = iter_13_1.fighterModel:getPosition()

			table.insert(var_13_1, iter_13_1)
		end
	end

	if #var_13_1 == 0 then
		return var_13_0
	end

	for iter_13_2, iter_13_3 in ipairs(var_13_1) do
		local var_13_4, var_13_5 = iter_13_3.fighterModel:getPosition()
		local var_13_6, var_13_7 = arg_13_0.fighterModel:getPosition()

		if var_13_6 <= var_13_4 then
			table.insert(var_13_0, iter_13_3)
		end
	end

	return var_13_0
end

function var_0_3.selectTargetByTypeD3(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0
	local var_14_1
	local var_14_2, var_14_3 = var_0_4.getTeam(arg_14_0)

	for iter_14_0, iter_14_1 in ipairs(var_14_3) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and (not var_14_0 or var_14_0 < math.abs(iter_14_1:getX() - arg_14_0:getX())) then
			var_14_1 = iter_14_1
			var_14_0 = math.abs(iter_14_1:getX() - arg_14_0:getX())
		end
	end

	if not var_14_1 then
		return {}
	end

	local var_14_4
	local var_14_5

	for iter_14_2, iter_14_3 in ipairs(var_14_3) do
		if not iter_14_3:isDeath() and not iter_14_3:isAffected() and iter_14_3 ~= var_14_1 and (not var_14_4 or var_14_4 < math.abs(iter_14_3:getX() - arg_14_0:getX())) then
			var_14_5 = iter_14_3
			var_14_4 = math.abs(iter_14_3:getX() - arg_14_0:getX())
		end
	end

	if not var_14_5 then
		return {
			var_14_1
		}
	end

	return {
		var_14_1,
		var_14_5
	}
end

function var_0_3.buffAddAction(arg_15_0, arg_15_1)
	var_0_3.super.buffAddAction(arg_15_0, arg_15_1)

	if arg_15_1:getTableID() == var_0_17 then
		arg_15_1.manualHarmRevise = arg_15_1.target:getHpLimit() * var_0_18
	elseif arg_15_1:getTableID() == var_0_13[1] then
		arg_15_1.resetXchange_ = -200 * (arg_15_0:getFlipX() and -1 or 1)
	elseif arg_15_1:getTableID() == var_0_13[2] then
		arg_15_1.resetXchange_ = 200 * (arg_15_0:getFlipX() and -1 or 1)
	elseif arg_15_1:getTableID() == var_0_34 then
		local var_15_0 = arg_15_0:getFlipX() and -1 or 1

		if arg_15_1.target.fighterModel:getX() < arg_15_0.fighterModel:getX() then
			var_15_0 = var_15_0 * -1
		end

		arg_15_1.resetXchange_ = 200 * var_15_0
	elseif arg_15_1:getTableID() == var_0_20[4] then
		arg_15_1.manualHarmRevise = arg_15_1.target:getHpLimit() * var_0_21
	end
end

function var_0_3.isBoss(arg_16_0)
	return true
end

function var_0_3.isBreakImmortal(arg_17_0)
	return true
end

return var_0_3
