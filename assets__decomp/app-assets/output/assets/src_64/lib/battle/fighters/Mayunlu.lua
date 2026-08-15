local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mayunlu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.model
local var_0_9 = {
	40010368,
	40010369,
	40010370
}
local var_0_10 = 270
local var_0_11 = 40010371
local var_0_12 = 40010361
local var_0_13 = 40010358
local var_0_14 = 40010360
local var_0_15 = {
	40010365
}
local var_0_16 = {
	40010362,
	40010363,
	40010364
}
local var_0_17 = 270
local var_0_18 = 40010366
local var_0_19 = 40010367
local var_0_20 = 10000525
local var_0_21 = 10000526
local var_0_22 = 10000527
local var_0_23 = 10000529
local var_0_24 = 300
local var_0_25 = 900
local var_0_26 = 0.1
local var_0_27 = 0.001

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isFuse_ = false
	arg_2_0.purpleFuseTargets_ = {}
	arg_2_0.purpleNotFuseTargets_ = {}
	arg_2_0.blueArea_ = {}
	arg_2_0.energyArea_ = {}
	arg_2_0.blueSideEffectTargets_ = {}
	arg_2_0.blueSelfEffectTargets_ = {}
	arg_2_0.energyEffectTargets_ = {}
	arg_2_0.readyToChange_ = false
	arg_2_0.greenSkillCount_ = 300
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_0.readyToChange_ then
		arg_3_0.readyToChange_ = false
	end

	if var_0_7:father(arg_3_1.rootID_) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_3_0.readyToChange_ = true
		arg_3_0.isFuse_ = not arg_3_0.isFuse_

		if arg_3_0.isFuse_ then
			arg_3_0.greenSkillCount_ = var_0_25
		else
			arg_3_0.greenSkillCount_ = var_0_24
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.target
	local var_4_1 = arg_4_1.skillID
	local var_4_2 = arg_4_0.isFuse_

	if arg_4_0.readyToChange_ then
		var_4_2 = not var_4_2
	end

	if not var_4_2 then
		if var_4_1 == arg_4_0:getEnergySkillID() then
			arg_4_0:setEnergyEffect(arg_4_1)
		elseif var_4_1 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			if arg_4_0:isMagicCursed(var_4_0) then
				arg_4_0:addGreenStunBuff(var_4_0, var_4_1)
			end
		elseif var_4_1 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			arg_4_0:setBlueEffect(arg_4_1)
		end
	else
		if var_4_1 == var_0_7:buffOrb(arg_4_0:getEnergySkillID()) then
			if arg_4_0:isMagicCursed(var_4_0) then
				arg_4_0:addEnergyFearBuff(var_4_0, var_4_1)
			end
		elseif var_4_1 == var_0_7:buffOrb(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) and arg_4_0:isMagicCursed(var_4_0) then
			arg_4_0:addGreenStunBuff(var_4_0, var_4_1)
		end

		if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
			arg_4_0:addMagicCursedBuff(var_4_0, var_4_1)
		end
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("attack_info")) do
			local var_5_0 = iter_5_1.fighter_
			local var_5_1 = var_5_0:getBuffByID(var_0_18)

			if var_5_1 and var_5_1.fighter == arg_5_0 then
				if not arg_5_0.purpleNotFuseTargets_[var_5_0] then
					arg_5_0.purpleNotFuseTargets_[var_5_0] = 1
				else
					arg_5_0.purpleNotFuseTargets_[var_5_0] = arg_5_0.purpleNotFuseTargets_[var_5_0] + 1
				end

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_5_2 = arg_5_0:createAttackUnits({
						var_5_0
					}, var_0_20)

					for iter_5_2, iter_5_3 in ipairs(var_5_2) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
						table.insert(arg_5_0.records_.special_units, iter_5_3)
					end
				end

				if var_0_7:father(iter_5_1.rootID_) == var_5_0:getEnergySkillID() or arg_5_0.purpleNotFuseTargets_[var_5_0] >= 2 then
					if var_0_7:father(iter_5_1.rootID_) == var_5_0:getEnergySkillID() then
						arg_5_0:purpleExtraAttack(2, var_5_0)
					else
						arg_5_0:purpleExtraAttack(1, var_5_0)
					end

					arg_5_0.purpleNotFuseTargets_[var_5_0] = 0

					var_5_0:removeBuffByID(var_0_18)
				end
			end

			local var_5_3 = var_5_0:getBuffByID(var_0_19)

			if var_5_3 and var_5_3.fighter == arg_5_0 then
				if not arg_5_0.purpleFuseTargets_[var_5_0] then
					arg_5_0.purpleFuseTargets_[var_5_0] = 1
				else
					arg_5_0.purpleFuseTargets_[var_5_0] = arg_5_0.purpleFuseTargets_[var_5_0] + 1
				end

				arg_5_0:purpleExtraAttack(3, var_5_0)

				if arg_5_0.purpleFuseTargets_[var_5_0] >= 2 then
					arg_5_0.purpleFuseTargets_[var_5_0] = 0

					var_5_0:removeBuffByID(var_0_19)
				end
			end
		end
	end

	if next(arg_5_0.energyArea_) then
		local var_5_4 = var_0_7:scope(arg_5_0:getEnergySkillID())

		for iter_5_4 = #arg_5_0.energyArea_, 1, -1 do
			local var_5_5 = arg_5_0.energyArea_[iter_5_4]
			local var_5_6 = var_5_5.time - 1

			var_5_5.time = var_5_6

			if var_5_6 <= 0 then
				var_5_5.effect:removeSelf()

				var_5_5.effect = nil

				table.remove(arg_5_0.energyArea_, iter_5_4)
				arg_5_0:checkEnergyAreaTarget()
			elseif var_5_6 % 10 < 1 then
				local var_5_7 = var_5_5.pos

				for iter_5_5, iter_5_6 in ipairs(arg_5_0.sideTeam_) do
					if not iter_5_6:isDeath() and not iter_5_6:isAffected() and not iter_5_6:isHasBuffByID(var_0_9[1]) and math.abs(iter_5_6:getX() - var_5_7.x) <= var_5_4 * 0.5 then
						arg_5_0:addEnergyAreaBuff(iter_5_6)
						table.insert(arg_5_0.energyEffectTargets_, iter_5_6)
					end
				end

				arg_5_0:checkEnergyAreaTarget()
			end
		end
	end

	if next(arg_5_0.blueArea_) then
		local var_5_8 = var_0_7:scope(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		for iter_5_7 = #arg_5_0.blueArea_, 1, -1 do
			local var_5_9 = arg_5_0.blueArea_[iter_5_7]
			local var_5_10 = var_5_9.time - 1

			var_5_9.time = var_5_10

			if var_5_10 <= 0 then
				var_5_9.effect:removeSelf()
				table.remove(arg_5_0.blueArea_, iter_5_7)
				arg_5_0:checkBlueAreaTarget()
			elseif var_5_10 % 10 < 1 then
				local var_5_11 = var_5_9.pos

				for iter_5_8, iter_5_9 in ipairs(arg_5_0.sideTeam_) do
					if not iter_5_9:isDeath() and not iter_5_9:isAffected() and not iter_5_9:isHasBuffByID(var_0_15[1]) and math.abs(iter_5_9:getX() - var_5_11.x) <= var_5_8 * 0.5 then
						arg_5_0:addBlueSideAreaBuff(iter_5_9)
						table.insert(arg_5_0.blueSideEffectTargets_, iter_5_9)
					end
				end

				for iter_5_10, iter_5_11 in ipairs(arg_5_0.selfTeam_) do
					if not iter_5_11:isDeath() and not iter_5_11:isAffected() and not iter_5_11:isHasBuffByID(var_0_16[1]) and math.abs(iter_5_11:getX() - var_5_11.x) <= var_5_8 * 0.5 then
						arg_5_0:addBlueSelfAreaBuff(iter_5_11)
						table.insert(arg_5_0.blueSelfEffectTargets_, iter_5_11)
					end
				end

				arg_5_0:checkBlueAreaTarget()
			end
		end
	end

	if arg_5_0.greenSkillCount_ > 0 and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and not arg_5_0:isDeath() then
		arg_5_0.greenSkillCount_ = arg_5_0.greenSkillCount_ - 1
	end
end

function var_0_3.updateBaseInfo(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0:acttionInBlack() then
		arg_6_0:clearFunctionsCache()
		arg_6_0:updateNearestTarget()
		arg_6_0:updateLeftInterval()
		arg_6_0:updateStateCount()
		arg_6_0:checkSkillRoll()
		arg_6_0:updateBuffCount()
		arg_6_0:updateEnergyByCount()
	end

	if arg_6_0:getTeamType() == var_0_2.TeamType.A and arg_6_0.bottomWnd and not tolua.isnull(arg_6_0.bottomWnd) then
		if arg_6_0:checkEnergySkill() or arg_6_0:checkGreenSkill() then
			arg_6_0.bottomWnd:updateUIEffect(arg_6_0, var_0_1.ctx.battle.teamA, true)
		else
			arg_6_0.bottomWnd:updateUIEffect(arg_6_0, var_0_1.ctx.battle.teamA, false)
		end
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_6_0.reportEnergy_[1] and arg_6_0.reportEnergy_[1] <= var_0_1.ctx.battle.count then
			arg_6_0.isEnergySkill_ = true
			arg_6_0.leftInterval_ = 0
			arg_6_0.arenaEnergyFull_ = nil

			table.remove(arg_6_0.reportEnergy_, 1)
		end
	elseif arg_6_0:checkEnergySkill() and arg_6_0:isAutoFighter() and not arg_6_0:isCreatingUnits() then
		arg_6_0.isEnergySkill_ = true
		arg_6_0.leftInterval_ = 0
		arg_6_0.arenaEnergyFull_ = nil

		table.insert(arg_6_0.records_.energy, var_0_1.ctx.battle.count)
	end

	if arg_6_0:acttionInBlack() then
		if arg_6_0.unitSkills_ then
			arg_6_0.unitSkills_:updateCount()
		end

		if arg_6_0.specialSkills_ then
			arg_6_0.specialSkills_:updateCount()
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not arg_6_0.isEnergySkill_ and not arg_6_0:checkEnergySkill() and arg_6_0:checkGreenSkill() and arg_6_0:isAutoFighter() and not arg_6_0:isCreatingUnits() then
		arg_6_0:greenAttack()
	end
end

function var_0_3.clickAvatar(arg_7_0, arg_7_1)
	var_0_3.super.clickAvatar(arg_7_0, arg_7_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not arg_7_0.isEnergySkill_ and not arg_7_0:checkEnergySkill() and arg_7_0:checkGreenSkill() and not arg_7_0:isDeath() and arg_7_1.name == "ended" and var_0_1.ctx.battle.autoA ~= true then
		arg_7_0:greenAttack()
	end
end

function var_0_3.checkGreenSkill(arg_8_0)
	if arg_8_0.greenSkillCount_ > 0 then
		return false
	end

	if arg_8_0:isDeath() then
		return false
	end

	if arg_8_0:isAdUnable() or arg_8_0:isApUnable() or arg_8_0:isPugongOnly() or not arg_8_0:getNearestTarget() then
		return false
	end

	return true
end

function var_0_3.greenAttack(arg_9_0)
	local var_9_0

	if not arg_9_0.isFuse_ then
		var_9_0 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	else
		var_9_0 = var_0_7:buffOrb(arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))
	end

	local var_9_1 = var_0_7:sound(var_9_0)

	var_0_1.ctx.battle.pushSoundQueue(var_9_1)

	local var_9_2 = var_0_7:attackIndex(var_9_0)

	arg_9_0:resetLeftInterval()
	arg_9_0:playAttack(var_9_2)

	arg_9_0.unitSkills_ = var_0_5.new({
		fighter = arg_9_0,
		skillID = var_9_0
	})

	arg_9_0:beginAttackEnd(arg_9_0.unitSkills_)
end

function var_0_3.getUnitData(arg_10_0, arg_10_1)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.getUnitData(arg_10_0, arg_10_1)
	local var_10_6 = arg_10_1.skillID

	if var_10_6 == var_0_21 or var_10_6 == var_0_22 and not arg_10_0:isMagicCursed(arg_10_1.target) then
		arg_10_0:addMagicCursedBuff(arg_10_1.target, var_10_6)
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7 = var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	local var_11_0 = arg_11_4
	local var_11_1 = arg_11_1.skillID
	local var_11_2 = arg_11_1.target

	if (var_11_1 == var_0_21 or var_11_1 == var_0_23 or var_11_1 == var_0_22) and arg_11_0:isMagicCursed(var_11_2) then
		arg_11_4 = arg_11_4 * 1.5
	end

	if var_11_2:isHasBuffByID(var_0_12) and arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_11_4 = arg_11_4 + var_11_0 * (var_0_26 + var_0_27 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	return arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7
end

function var_0_3.purpleExtraAttack(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {}

	if arg_12_1 == 1 or arg_12_1 == 2 then
		local var_12_1 = arg_12_1 == 1 and var_0_21 or var_0_22
		local var_12_2 = var_0_7:scope(var_12_1)
		local var_12_3 = arg_12_2:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

		for iter_12_0, iter_12_1 in ipairs(var_12_3) do
			if not iter_12_1:isDeath() and not iter_12_1:isAffected() and math.abs(iter_12_1:getX() - arg_12_2:getX()) <= var_12_2 * 0.5 then
				table.insert(var_12_0, iter_12_1)
			end
		end
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_12_4

	if arg_12_1 == 1 then
		var_12_4 = arg_12_0:createAttackUnits(var_12_0, var_0_21)
	elseif arg_12_1 == 2 then
		var_12_4 = arg_12_0:createAttackUnits(var_12_0, var_0_22)
	elseif arg_12_1 == 3 then
		var_12_4 = arg_12_0:createAttackUnits({
			arg_12_2
		}, var_0_23)
	end

	for iter_12_2, iter_12_3 in ipairs(var_12_4) do
		table.insert(arg_12_0.moveAttackUnits_, iter_12_3)
		table.insert(arg_12_0.records_.special_units, iter_12_3)
	end
end

function var_0_3.checkEnergyAreaTarget(arg_13_0)
	for iter_13_0 = #arg_13_0.energyEffectTargets_, 1, -1 do
		local var_13_0 = arg_13_0.energyEffectTargets_[iter_13_0]

		if not var_13_0:isHasBuffByID(var_0_9[1]) or not arg_13_0:isInEnergyArea(var_13_0) then
			arg_13_0:removeEnergyAreaBuffs(var_13_0)
			table.remove(arg_13_0.energyEffectTargets_, iter_13_0)
		end
	end
end

function var_0_3.checkBlueAreaTarget(arg_14_0)
	for iter_14_0 = #arg_14_0.blueSideEffectTargets_, 1, -1 do
		local var_14_0 = arg_14_0.blueSideEffectTargets_[iter_14_0]

		if not var_14_0:isHasBuffByID(var_0_15[1]) or not arg_14_0:isInBlueArea(var_14_0) then
			arg_14_0:removeBlueSideAreaBuffs(var_14_0)
			table.remove(arg_14_0.blueSideEffectTargets_, iter_14_0)
		end
	end

	for iter_14_1 = #arg_14_0.blueSelfEffectTargets_, 1, -1 do
		local var_14_1 = arg_14_0.blueSelfEffectTargets_[iter_14_1]

		if not var_14_1:isHasBuffByID(var_0_16[1]) or not arg_14_0:isInBlueArea(var_14_1) then
			arg_14_0:removeBlueSelfAreaBuffs(var_14_1)
			table.remove(arg_14_0.blueSelfEffectTargets_, iter_14_1)
		end
	end
end

function var_0_3.getArea(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {
		x = arg_15_1.target:getX(),
		y = arg_15_1.target:getY()
	}
	local var_15_1 = var_0_1.ctx.battle.getSpine(arg_15_1.skillID, "area", 1)

	var_15_1:addTo(var_0_1.ctx.battle.unitBottomLayer)
	var_15_1:pos(var_15_0.x, var_15_0.y)
	var_15_1:playRepeat()

	return {
		pos = var_15_0,
		time = arg_15_2,
		effect = var_15_1
	}
end

function var_0_3.setBlueEffect(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0:getArea(arg_16_1, var_0_17)

	table.insert(arg_16_0.blueArea_, var_16_0)
end

function var_0_3.setEnergyEffect(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0:getArea(arg_17_1, var_0_10)

	table.insert(arg_17_0.energyArea_, var_17_0)
end

function var_0_3.addMagicCursedBuff(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_0:newBuff(arg_18_1, arg_18_2, var_0_12)

	arg_18_1:addBuffs({
		var_18_0
	})
end

function var_0_3.addEnergyFearBuff(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_0:newBuff(arg_19_1, arg_19_2, var_0_11)

	arg_19_1:addBuffs({
		var_19_0
	})
end

function var_0_3.addGreenStunBuff(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0

	if arg_20_0.isFuse_ then
		var_20_0 = var_0_14
	else
		var_20_0 = var_0_13
	end

	local var_20_1 = arg_20_0:newBuff(arg_20_1, arg_20_2, var_20_0)

	arg_20_1:addBuffs({
		var_20_1
	})
end

function var_0_3.addEnergyAreaBuff(arg_21_0, arg_21_1)
	local var_21_0 = {}

	for iter_21_0, iter_21_1 in ipairs(var_0_9) do
		local var_21_1 = arg_21_0:newBuff(arg_21_1, arg_21_0:getEnergySkillID(), iter_21_1)

		table.insert(var_21_0, var_21_1)
	end

	arg_21_1:addBuffs(var_21_0)
end

function var_0_3.addBlueSelfAreaBuff(arg_22_0, arg_22_1)
	local var_22_0 = {}
	local var_22_1 = arg_22_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

	for iter_22_0, iter_22_1 in ipairs(var_0_16) do
		local var_22_2 = arg_22_0:newBuff(arg_22_1, var_22_1, iter_22_1)

		table.insert(var_22_0, var_22_2)
	end

	arg_22_1:addBuffs(var_22_0)
end

function var_0_3.addBlueSideAreaBuff(arg_23_0, arg_23_1)
	local var_23_0 = {}
	local var_23_1 = arg_23_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

	for iter_23_0, iter_23_1 in ipairs(var_0_15) do
		local var_23_2 = arg_23_0:newBuff(arg_23_1, var_23_1, iter_23_1)

		table.insert(var_23_0, var_23_2)
	end

	arg_23_1:addBuffs(var_23_0)
end

function var_0_3.removeEnergyAreaBuffs(arg_24_0, arg_24_1)
	for iter_24_0, iter_24_1 in ipairs(var_0_9) do
		arg_24_1:removeBuffByID(iter_24_1)
	end
end

function var_0_3.removeBlueSelfAreaBuffs(arg_25_0, arg_25_1)
	for iter_25_0, iter_25_1 in ipairs(var_0_16) do
		arg_25_1:removeBuffByID(iter_25_1)
	end
end

function var_0_3.removeBlueSideAreaBuffs(arg_26_0, arg_26_1)
	for iter_26_0, iter_26_1 in ipairs(var_0_15) do
		arg_26_1:removeBuffByID(iter_26_1)
	end
end

function var_0_3.isInBlueArea(arg_27_0, arg_27_1)
	if arg_27_1:isDeath() then
		return false
	end

	local var_27_0 = var_0_7:scope(arg_27_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	for iter_27_0, iter_27_1 in ipairs(arg_27_0.blueArea_) do
		local var_27_1 = iter_27_1.pos

		if math.abs(arg_27_1:getX() - var_27_1.x) <= var_27_0 * 0.5 then
			return true
		end
	end

	return false
end

function var_0_3.isInEnergyArea(arg_28_0, arg_28_1)
	if arg_28_1:isDeath() then
		return false
	end

	local var_28_0 = var_0_7:scope(arg_28_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

	for iter_28_0, iter_28_1 in ipairs(arg_28_0.energyArea_) do
		local var_28_1 = iter_28_1.pos

		if math.abs(arg_28_1:getX() - var_28_1.x) <= var_28_0 * 0.5 then
			return true
		end
	end

	return false
end

function var_0_3.isMagicCursed(arg_29_0, arg_29_1)
	return arg_29_1:isHasBuffByID(var_0_12)
end

function var_0_3.getOrbOfFrontSkill(arg_30_0)
	local var_30_0 = var_0_3.super.getOrbOfFrontSkill(arg_30_0)
	local var_30_1 = var_0_7:buffOrb(var_30_0)

	if var_30_1 > 0 and arg_30_0.isFuse_ then
		return var_30_1
	end

	return var_30_0
end

function var_0_3.newBuff(arg_31_0, arg_31_1, arg_31_2, arg_31_3)
	local var_31_0 = var_0_4.new({
		tableID = arg_31_3,
		start = var_0_1.ctx.battle.count,
		level = arg_31_0:getSkillLevelByID(arg_31_2),
		skillID = arg_31_2,
		fighter = arg_31_0,
		target = arg_31_1
	})

	var_31_0:setIsHit(true)
	var_31_0:setDirection(arg_31_0:getFighterModel():getFlipX())

	return var_31_0
end

function var_0_3.resumeIdle(arg_32_0)
	if not arg_32_0:isDeath() and arg_32_0:getFighterModel() then
		if not arg_32_0.isFuse_ then
			arg_32_0:getFighterModel():idle()
		else
			arg_32_0:getFighterModel():playAnimation_("idle02", true, nil, nil, nil)
		end
	end
end

function var_0_3.die(arg_33_0)
	var_0_3.super.die(arg_33_0)

	if arg_33_0.isFuse_ then
		arg_33_0:getFighterModel():playAnimation_("dead02", false, nil, nil, nil)
	end
end

function var_0_3.modelWalk(arg_34_0)
	if arg_34_0.fighterModel:getScale() ~= 1 then
		arg_34_0.fighterModel:scale(1)
	end

	if not arg_34_0.isFuse_ then
		arg_34_0:getFighterModel():walk(true)
	else
		arg_34_0:getFighterModel():playAnimation_("run02", true, nil, nil, nil)
	end
end

function var_0_3.attacked(arg_35_0)
	if arg_35_0:getFighterModel().currentAnimation_ and (arg_35_0:getFighterModel().currentAnimation_ == "hurt" or arg_35_0:getFighterModel().currentAnimation_ == "hurt02") then
		return
	end

	if arg_35_0.fighterModel:getScale() ~= 1 then
		arg_35_0.fighterModel:scale(1)
	end

	local var_35_0 = var_0_8:hurtDuration(arg_35_0:getModelID())

	arg_35_0.skillRoll_ = var_35_0
	arg_35_0.unableEnergySkill_ = var_0_1.ctx.battle.count + var_35_0

	if not arg_35_0.isFuse_ then
		arg_35_0:getFighterModel():attacked(function()
			if arg_35_0:getFighterModel().currentAnimation_ == "hurt" or arg_35_0:getFighterModel().currentAnimation_ == "hurt02" then
				arg_35_0:resumeIdle()
			end
		end)
	else
		arg_35_0:getFighterModel():playAnimation_("hurt02", false, nil, nil, function()
			if arg_35_0:getFighterModel().currentAnimation_ == "hurt" or arg_35_0:getFighterModel().currentAnimation_ == "hurt02" then
				arg_35_0:resumeIdle()
			end
		end)
	end
end

function var_0_3.playWin(arg_38_0)
	if arg_38_0:isDeath() then
		return
	end

	if not arg_38_0.isFuse_ then
		arg_38_0:getFighterModel():win(true)
	else
		arg_38_0:getFighterModel():playAnimation_("win02", true, nil, nil, nil)
	end
end

function var_0_3.energyAction(arg_39_0, arg_39_1)
	local var_39_0 = arg_39_0:getEnergySkillID()

	if arg_39_1 == var_39_0 or arg_39_1 == var_0_7:buffOrb(var_39_0) then
		arg_39_0:getFighterModel():playEnergyEffect_()
		arg_39_0:updateEnergyTo(arg_39_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		if arg_39_0:getTeamType() == var_0_2.TeamType.A or arg_39_0.isInArena_ then
			arg_39_0:addBlackLayer()
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_40_0, arg_40_1, arg_40_2)
	local function var_40_0(arg_41_0, arg_41_1)
		local var_41_0, var_41_1 = var_0_6.getTeam(arg_41_0)
		local var_41_2 = {}

		table.insert(var_41_2, arg_41_0)

		for iter_41_0, iter_41_1 in ipairs(var_41_0) do
			if not iter_41_1:isDeath() and not iter_41_1:isAffected() and iter_41_1 ~= arg_41_0 and arg_41_1 >= math.abs(iter_41_1:getX() - arg_41_0:getX()) then
				table.insert(var_41_2, iter_41_1)
			end
		end

		return var_41_2
	end

	local var_40_1
	local var_40_2 = 0
	local var_40_3 = var_0_7:scope(arg_40_1) * 0.5
	local var_40_4 = var_0_7:distance(arg_40_1)

	for iter_40_0, iter_40_1 in ipairs(arg_40_0.sideTeam_) do
		if not iter_40_1:isDeath() and not iter_40_1:isAffected() and var_40_4 >= math.abs(iter_40_1:getX() - arg_40_0:getX()) then
			local var_40_5 = var_40_0(iter_40_1, var_40_3)

			if var_40_2 < #var_40_5 then
				var_40_1 = iter_40_1
				var_40_2 = #var_40_5
			end
		end
	end

	return {
		var_40_1
	}
end

return var_0_3
