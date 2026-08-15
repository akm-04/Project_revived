local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Degula", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 300
local var_0_8 = 300
local var_0_9 = 30010038
local var_0_10 = 10000235
local var_0_11 = 10000234
local var_0_12 = 40010039
local var_0_13 = 80010066
local var_0_14 = 10001139
local var_0_15 = 40011244
local var_0_16 = 0.4
local var_0_17 = 330
local var_0_18 = 80020066
local var_0_19 = 20
local var_0_20 = 0.01
local var_0_21 = 80030066
local var_0_22 = 10001872
local var_0_23 = 10001871
local var_0_24 = 10002126
local var_0_25 = 40012264

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyBuff_ = false
	arg_1_0.greenSkillCount_ = 0
	arg_1_0.blueCount_ = nil
	arg_1_0.skinCureTargets = {}
	arg_1_0.skinCount = 0
	arg_1_0.isAwakeTwiceBuff_ = false
	arg_1_0.createAwakeTwiceSkill_ = false
	arg_1_0.hadCreateAwakeTwiceSkill_ = false

	arg_1_0:listenInfo("harm_info")
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	if arg_2_0.isEnergyBuff_ and var_0_1.ctx.battle.count % 30 < 1 and arg_2_0:getNearestTarget() then
		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			if not arg_2_0.isAwakeTwiceBuff_ then
				arg_2_0:updateEnergyTo(arg_2_0:getEnergy() - 100)

				if arg_2_0:getEnergy() < 1 then
					arg_2_0.createAwakeTwiceSkill_ = true
				end
			end
		else
			arg_2_0:updateEnergyTo(arg_2_0:getEnergy() - 100)

			if arg_2_0:getEnergy() < 1 then
				arg_2_0.isEnergyBuff_ = false

				local var_2_0 = var_0_6:buffs(arg_2_0:getEnergySkillID())

				for iter_2_0, iter_2_1 in ipairs(var_2_0) do
					arg_2_0:removeBuffByID(iter_2_1)
				end
			end
		end
	end

	if arg_2_0.greenSkillCount_ > 0 then
		arg_2_0.greenSkillCount_ = arg_2_0.greenSkillCount_ - 1

		if arg_2_0.greenSkillCount_ % 30 < 1 and arg_2_0:getNearestTarget() then
			arg_2_0:updateGreenSkillState()
		end
	end

	arg_2_0.blueCount_ = arg_2_0.blueCount_ and arg_2_0.blueCount_ + 1
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and not arg_3_0:isDeath() then
		if arg_3_0:isHasBuffByID(var_0_25) then
			arg_3_0.hadCreateAwakeTwiceSkill_ = true
		elseif not arg_3_0:isHasBuffByID(var_0_25) and arg_3_0.hadCreateAwakeTwiceSkill_ == true then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_0 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_24)

				for iter_3_0, iter_3_1 in ipairs(var_3_0) do
					iter_3_1.cureHp = cure

					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end
			end

			arg_3_0.hadCreateAwakeTwiceSkill_ = false
			arg_3_0.isEnergyBuff_ = false

			local var_3_1 = var_0_6:buffs(arg_3_0:getEnergySkillID())

			for iter_3_2, iter_3_3 in ipairs(var_3_1) do
				arg_3_0:removeBuffByID(iter_3_3)
			end

			arg_3_0.isAwakeTwiceBuff_ = false
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_0.createAwakeTwiceSkill_ == true then
		local var_3_2 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_3 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_3_2)

			for iter_3_4, iter_3_5 in ipairs(var_3_3) do
				iter_3_5.cureHp = cure

				table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
				table.insert(arg_3_0.records_.special_units, iter_3_5)
			end
		end

		arg_3_0.createAwakeTwiceSkill_ = false
	end

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_13 then
		arg_3_0.skinCount = arg_3_0.skinCount + 1

		if arg_3_0.skinCount > var_0_17 and not arg_3_0:isDeath() then
			arg_3_0.skinCount = 0

			for iter_3_6, iter_3_7 in pairs(arg_3_0.selfTeam_) do
				if iter_3_7:getSummonType() ~= var_0_2.summonMonsterType.Pet and not iter_3_7:isDeath() then
					local var_3_4 = var_0_5.new({
						tableID = var_0_15,
						start = var_0_1.ctx.battle.count,
						level = arg_3_0:getSkillLevelByID(var_0_13),
						skillID = var_0_13,
						fighter = arg_3_0,
						target = iter_3_7
					})

					iter_3_7:addBuffs({
						var_3_4
					})
				end
			end
		end
	end

	for iter_3_8, iter_3_9 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
		if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_13 and iter_3_9.fighter:getBuffByID(var_0_15) and iter_3_9.fighter:getTeamType() == arg_3_0:getTeamType() and iter_3_9.target:getTeamType() ~= arg_3_0:getTeamType() and iter_3_9.fighter:getSummonType() == var_0_2.summonMonsterType.None and not iter_3_9.fighter:isDeath() then
			local var_3_5 = iter_3_9.harm * var_0_16

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_6 = arg_3_0:createAttackUnits({
					iter_3_9.fighter
				}, var_0_14)

				for iter_3_10, iter_3_11 in ipairs(var_3_6) do
					iter_3_11.cureHp = var_3_5

					table.insert(arg_3_0.moveAttackUnits_, iter_3_11)
					table.insert(arg_3_0.records_.special_units, iter_3_11)
				end
			end
		end
	end

	if arg_3_0.skinSkillID_ == var_0_18 and not arg_3_0.skinSkillUsed then
		arg_3_0.skinSkillUsed = true

		for iter_3_12, iter_3_13 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_13:isDeath() and iter_3_13:getSummonType() == var_0_2.summonMonsterType.None and not iter_3_13.DegulaSkinMark then
				local var_3_7 = iter_3_13.updateHp
				local var_3_8 = iter_3_13.updateEnergyBy

				function iter_3_13.updateHp(arg_4_0, arg_4_1, arg_4_2)
					local var_4_0 = arg_4_0:getHp()

					var_3_7(arg_4_0, arg_4_1, arg_4_2)

					local var_4_1 = arg_4_0:getHp()

					if arg_4_1 > arg_4_0:getHp() then
						local var_4_2 = (var_4_1 - var_4_0) * var_0_20

						var_3_8(arg_4_0, var_4_2, arg_4_2)
					end
				end

				function iter_3_13.updateEnergyBy(arg_5_0, arg_5_1, arg_5_2)
					if arg_5_1 > 0 then
						local var_5_0 = arg_5_0:getHp() + arg_5_1 * var_0_19

						var_3_7(arg_5_0, var_5_0, arg_5_2)
					end

					var_3_8(arg_5_0, arg_5_1, arg_5_2)
				end

				iter_3_13.DegulaSkinMark = true
			end
		end
	end
end

function var_0_3.createAttacks(arg_6_0)
	local var_6_0 = arg_6_0.unitSkills_

	if not var_6_0 then
		return
	end

	local var_6_1 = var_0_6:mp(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
	local var_6_2 = var_0_6:mpStep(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
	local var_6_3 = 0

	if arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		var_6_3 = var_6_1 + var_6_2 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	if var_6_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_6_0.reportSkills_, 1)
		end

		arg_6_0.unitSkills_ = nil

		return
	end

	local var_6_4, var_6_5 = var_6_0:getFront()

	while var_6_4 and var_6_4 < 1 do
		arg_6_0:createUnits(var_6_0)
		var_6_0:popQueue()

		local var_6_6

		var_6_4, var_6_6 = var_6_0:getFront()

		if not arg_6_0:isCreatingUnits() then
			arg_6_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_6_0.reportSkills_, 1)
			end

			arg_6_0:updateEnergyBy(var_6_0:getRemp() + var_6_3)
			arg_6_0:popFrontSkill()
		end
	end
end

function var_0_3.energyDecimalBase(arg_7_0)
	return var_0_2.ENERGY_DECIMAL_BASE * 0.5
end

function var_0_3.checkEnergySkill(arg_8_0)
	if arg_8_0.isEnergyBuff_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_8_0)
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	local var_9_0 = arg_9_1.target

	if var_9_0:isDeath() then
		return
	end

	local var_9_1 = var_0_6:father(arg_9_1.skillID)

	if arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		arg_9_0.isAwakeTwiceBuff_ = true
	end

	if var_9_1 == arg_9_0:getEnergySkillID() and var_9_0 == arg_9_0 then
		arg_9_0.isEnergyBuff_ = true

		if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_21 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_9_2 = arg_9_0:createAttackUnits({
				arg_9_0
			}, var_0_22)

			for iter_9_0, iter_9_1 in ipairs(var_9_2) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
				table.insert(arg_9_0.records_.special_units, iter_9_1)
			end
		end
	end

	if var_9_1 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_9_0.blueCount_ = 0
	end

	if arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_21 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_3 = arg_9_0:selectTargetByTypeD1(var_0_23)
		local var_9_4 = arg_9_0:createAttackUnits(var_9_3, var_0_23)

		for iter_9_2, iter_9_3 in ipairs(var_9_4) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
			table.insert(arg_9_0.records_.special_units, iter_9_3)
		end
	end
end

function function_name(...)
	return
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_11_0, iter_11_1)
		end
	end

	return var_11_0
end

function var_0_3.getDMP(arg_12_0)
	return arg_12_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_0_2.PERCENT_BASE
end

function var_0_3.moveUnitArrive(arg_13_0, arg_13_1)
	if var_0_6:father(arg_13_1.skillID) == arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_13_0.greenSkillCount_ = var_0_8
		arg_13_0.greenUnit_ = arg_13_1
	end

	var_0_3.super.moveUnitArrive(arg_13_0, arg_13_1)
end

function var_0_3.updateGreenSkillState(arg_14_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_14_0 = arg_14_0.greenUnit_.skillID
	local var_14_1 = arg_14_0:getTargets(var_14_0, arg_14_0.greenUnit_)
	local var_14_2 = arg_14_0:createAttackUnits(var_14_1, var_14_0)

	for iter_14_0, iter_14_1 in ipairs(var_14_2) do
		table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
		table.insert(arg_14_0.records_.special_units, iter_14_1)
	end
end

function var_0_3.buffRemoveAction(arg_15_0, arg_15_1)
	if arg_15_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_15_0 = arg_15_1:getRemoveSkill()

	if arg_15_0:isApUnable() then
		var_15_0 = var_0_10
	end

	local var_15_1 = var_0_6:sound(var_15_0)

	var_0_1.ctx.battle.pushSoundQueue(var_15_1)

	arg_15_0.specialSkills_ = var_0_4.new({
		fighter = arg_15_0,
		skillID = var_15_0
	})

	arg_15_0:beginAttackEnd(arg_15_0.specialSkills_)
end

function var_0_3.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
	arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7 = var_0_3.super.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)

	if arg_16_1.skillID == var_0_10 then
		arg_16_4 = arg_16_4 * math.min(arg_16_0.blueCount_ * arg_16_0.blueCount_ / 22500, 1)
	end

	if arg_16_1.skillID == var_0_14 and arg_16_1.cureHp then
		arg_16_5 = arg_16_1.cureHp
	end

	return arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7
end

function var_0_3.checkUnitBuffs(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0, var_17_1, var_17_2, var_17_3, var_17_4 = var_0_3.super.checkUnitBuffs(arg_17_0, arg_17_1, arg_17_2)

	if arg_17_1.skillID == var_0_10 then
		local var_17_5 = math.min(arg_17_0.blueCount_ * arg_17_0.blueCount_ / 22500, 1)

		for iter_17_0, iter_17_1 in ipairs(var_17_0) do
			var_17_0[iter_17_0].leftCount_ = var_17_0[iter_17_0].leftCount_ * var_17_5
		end
	end

	return var_17_0, var_17_1, var_17_2, var_17_3, var_17_4
end

function var_0_3.checkSkillBreak(arg_18_0, arg_18_1, arg_18_2)
	if arg_18_1 == var_0_2.BreakSkillType.AP and arg_18_0:isHasBuffByID(var_0_9) then
		arg_18_0:removeBuffByID(var_0_9)
	end

	var_0_3.super.checkSkillBreak(arg_18_0, arg_18_1, arg_18_2)
end

return var_0_3
