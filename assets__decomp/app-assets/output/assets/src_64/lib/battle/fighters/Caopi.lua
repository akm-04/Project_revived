local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caopi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.model
local var_0_6 = 0.22
local var_0_7 = 0.002
local var_0_8 = 10000317
local var_0_9 = 10000302
local var_0_10 = 10000304
local var_0_11 = 10000305
local var_0_12 = 10000306
local var_0_13 = 170
local var_0_14 = 900
local var_0_15 = 1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.jumpBackCount_ = nil
	arg_1_0.jumpDelayCount_ = nil
	arg_1_0.jumpBeforeEnergy_ = nil
	arg_1_0.jumpBefore_ = nil
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)
	arg_2_0:jumpStateUpdate()
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_9 then
		local var_3_0 = arg_3_1.target:getX() > arg_3_0:getX() and arg_3_1.target:getX() - 50 or arg_3_1.target:getX() + 50

		arg_3_0.jumpBeforeEnergy_ = arg_3_0:getX()

		arg_3_0:x(var_3_0)
	elseif arg_3_1.skillID == var_0_12 then
		arg_3_0:combo()
	elseif arg_3_1.skillID == var_0_11 then
		arg_3_0:energyJumpBack()
	end

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or var_0_1.ctx.battle.count % 2 > 0 then
		return
	end

	local var_3_1 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_3_1.skillID == arg_3_0:getPugongID() then
		local var_3_2 = arg_3_0:selectTargetByTypeD1(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_3_1)
		local var_3_3 = arg_3_0:createAttackUnits(var_3_2, var_3_1)

		for iter_3_0, iter_3_1 in ipairs(var_3_3) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}
	local var_4_1 = var_0_4:scope(arg_4_1)

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and var_4_1 > math.abs(arg_4_2.target:getX() - iter_4_1:getX()) then
			table.insert(var_4_0, iter_4_1)
		end
	end

	return var_4_0
end

function var_0_3.selectTargetByTypeD2(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			table.insert(var_5_0, iter_5_1)
		end
	end

	if not next(var_5_0) then
		return {}
	end

	table.sort(var_5_0, function(arg_6_0, arg_6_1)
		return arg_6_0:getX() < arg_6_1:getX()
	end)

	if #var_5_0 == 1 then
		return {
			var_5_0[1]
		}
	elseif #var_5_0 == 2 then
		return math.abs(var_5_0[1]:getX() - arg_5_0:getX()) > math.abs(var_5_0[2]:getX() - arg_5_0:getX()) and {
			var_5_0[2]
		} or {
			var_5_0[1]
		}
	elseif #var_5_0 == 3 then
		return {
			var_5_0[2]
		}
	else
		local var_5_1
		local var_5_2

		for iter_5_2 = 2, #var_5_0 - 1 do
			if not var_5_1 or var_5_1 > var_5_0[iter_5_2 + 1]:getX() - var_5_0[iter_5_2 - 1]:getX() then
				var_5_1 = var_5_0[iter_5_2 + 1]:getX() - var_5_0[iter_5_2 - 1]:getX()
				var_5_2 = var_5_0[iter_5_2]
			end
		end

		return {
			var_5_2
		}
	end
end

function var_0_3.selectTargetByTypeD3(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = var_0_4:distance(arg_7_1)

	if not arg_7_0:getNearestTarget() then
		return {}
	end

	if var_7_0 < math.abs(arg_7_0:getNearestTarget():getX() - arg_7_0:getX()) or arg_7_0:getFlipX() and arg_7_0:getNearestTarget():getX() >= arg_7_0:getX() or not arg_7_0:getFlipX() and arg_7_0:getNearestTarget():getX() <= arg_7_0:getX() then
		if not arg_7_0:getNearestTarget().skillRush_ or not arg_7_0:getNearestTarget().skillRush_[1] then
			local var_7_1 = arg_7_0:getFlipX() and arg_7_0:getX() - var_7_0 or arg_7_0:getX() + var_7_0

			arg_7_0:getNearestTarget():x(var_7_1)
		else
			return {}
		end
	end

	return {
		arg_7_0:getNearestTarget()
	}
end

function var_0_3.selectTargetByTypeD4(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = var_0_4:distance(arg_8_1)
	local var_8_1 = var_0_4:scope(arg_8_1)
	local var_8_2 = {}

	if not arg_8_0:getNearestTarget() or var_8_0 < math.abs(arg_8_0:getNearestTarget():getX() - arg_8_0:getX()) then
		return var_8_2
	end

	table.insert(var_8_2, arg_8_0:getNearestTarget())

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1 ~= arg_8_0:getNearestTarget() and var_8_1 > math.abs(iter_8_1:getX() - arg_8_0:getNearestTarget():getX()) then
			table.insert(var_8_2, iter_8_1)
		end
	end

	arg_8_0:flipX(arg_8_0:getNearestTarget():getX() < arg_8_0:getX())

	return var_8_2
end

function var_0_3.selectTargetByTypeD5(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = var_0_4:distance(arg_9_1)
	local var_9_1 = var_0_4:scope(arg_9_1)
	local var_9_2 = {}
	local var_9_3 = arg_9_0:getX()

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		local var_9_4 = iter_9_1:getX()

		if iter_9_1 ~= arg_9_0 and not iter_9_1:isDeath() and not iter_9_1:isAffected() and var_9_1 >= math.abs(var_9_4 - var_9_3) then
			table.insert(var_9_2, iter_9_1)
		end
	end

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
		local var_9_5 = iter_9_3:getX()

		if not iter_9_3:isDeath() and not iter_9_3:isAffected() and var_9_1 >= math.abs(var_9_5 - var_9_3) then
			table.insert(var_9_2, iter_9_3)
		end
	end

	return var_9_2
end

function var_0_3.updateUnitDataByTarget(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataByTarget(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_6 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
	local var_10_7 = var_0_6 + var_0_7 * var_10_6

	if var_10_2 > 0 and var_10_6 > 0 and var_0_2.weightedChoise({
		var_10_7,
		1 - var_10_7
	}) == 1 then
		local var_10_8 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_10_9 = var_0_4:init(var_10_8) + var_10_6 * var_0_4:step(var_10_8)

		var_10_2 = math.max(0, var_10_2 - var_10_9)

		local var_10_10 = arg_10_0:createAttackUnits({
			arg_10_0
		}, var_0_8)

		for iter_10_0, iter_10_1 in ipairs(var_10_10) do
			table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
			table.insert(arg_10_0.records_.special_units, iter_10_1)
		end
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.combo(arg_11_0)
	arg_11_0:playAttack(7)

	arg_11_0.skillRoll_ = var_0_5:duration(arg_11_0:getModelID(), 7)
end

function var_0_3.jumpTo(arg_12_0)
	if not arg_12_0:canAttack() or not arg_12_0:getNearestTarget() then
		return
	end

	local var_12_0 = arg_12_0:popSkillByType(true)

	if var_12_0 ~= arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		return
	end

	if math.abs(arg_12_0:getX() - arg_12_0:getNearestTarget():getX()) <= var_0_13 then
		return
	end

	arg_12_0.jumpBefore_ = arg_12_0:getX()

	arg_12_0:flipX(arg_12_0:getNearestTarget():getX() < arg_12_0:getX())
	arg_12_0:playAttack(5)

	local var_12_1 = arg_12_0:getNearestTarget():getX()

	var_12_1 = var_12_1 > arg_12_0:getX() and var_12_1 - 50 or var_12_1 + 50

	arg_12_0:delayMove(var_12_1, var_0_4:pretime(var_0_10))

	local var_12_2 = var_0_5:duration(arg_12_0:getModelID(), 5)

	arg_12_0.skillRoll_ = var_12_2

	local var_12_3 = var_0_4:attackIndex(var_12_0)

	arg_12_0.jumpBackCount_ = var_12_2 + var_0_5:duration(arg_12_0:getModelID(), var_12_3) + 5
end

function var_0_3.jumpBack(arg_13_0)
	if arg_13_0:isDeath() or not arg_13_0.jumpBefore_ then
		return
	end

	arg_13_0:flipX(arg_13_0:getX() < arg_13_0.jumpBefore_)
	arg_13_0:playAttack(6)

	arg_13_0.skillRoll_ = var_0_5:duration(arg_13_0:getModelID(), 6)

	arg_13_0:delayMove(arg_13_0.jumpBefore_, var_0_4:pretime(var_0_11))

	arg_13_0.jumpBefore_ = nil
	arg_13_0.jumpBackCount_ = nil
end

function var_0_3.energyJumpBack(arg_14_0)
	if arg_14_0:isDeath() or not arg_14_0.jumpBeforeEnergy_ then
		return
	end

	arg_14_0:flipX(arg_14_0:getX() < arg_14_0.jumpBeforeEnergy_)
	arg_14_0:playAttack(6)

	arg_14_0.skillRoll_ = var_0_5:duration(arg_14_0:getModelID(), 6)

	arg_14_0:delayMove(arg_14_0.jumpBeforeEnergy_, var_0_4:pretime(var_0_11))

	arg_14_0.jumpBeforeEnergy_ = nil
end

function var_0_3.jumpStateUpdate(arg_15_0)
	local function var_15_0()
		local var_16_0
		local var_16_1

		for iter_16_0, iter_16_1 in ipairs(arg_15_0.sideTeam_) do
			if not iter_16_1:isDeath() and not iter_16_1:isAffected() and (not var_16_0 or var_16_0 > iter_16_1:getX()) then
				var_16_0 = iter_16_1:getX()
				var_16_1 = iter_16_1
			end
		end

		return var_16_1
	end

	local function var_15_1()
		local var_17_0
		local var_17_1

		for iter_17_0, iter_17_1 in ipairs(arg_15_0.sideTeam_) do
			if not iter_17_1:isDeath() and not iter_17_1:isAffected() and (not var_17_0 or var_17_0 < iter_17_1:getX()) then
				var_17_0 = iter_17_1:getX()
				var_17_1 = iter_17_1
			end
		end

		return var_17_1
	end

	if not arg_15_0:acttionInBlack() or arg_15_0:isDeath() then
		return
	end

	if arg_15_0.jumpBackCount_ then
		arg_15_0.jumpBackCount_ = arg_15_0.jumpBackCount_ - 1

		if arg_15_0.jumpBackCount_ < 1 then
			arg_15_0:jumpBack()
		end
	end

	if arg_15_0.jumpDelayCount_ then
		arg_15_0.jumpDelayCount_ = arg_15_0.jumpDelayCount_ - 1

		if arg_15_0.jumpDelayCount_ < 1 then
			arg_15_0:x(arg_15_0.jumpToX_)

			arg_15_0.jumpToX_ = nil
			arg_15_0.jumpDelayCount_ = nil

			local var_15_2 = arg_15_0:getNearestTarget()

			if var_15_2 and arg_15_0:getX() - var_15_2:getX() > arg_15_0:getDistance() then
				arg_15_0:x(var_15_2:getX() + arg_15_0:getDistance() - 1)
			elseif var_15_2 and var_15_2:getX() - arg_15_0:getX() > arg_15_0:getDistance() then
				arg_15_0:x(var_15_2:getX() - arg_15_0:getDistance() + 1)
			end
		end
	end
end

function var_0_3.delayMove(arg_18_0, arg_18_1, arg_18_2)
	arg_18_0.jumpToX_ = arg_18_1
	arg_18_0.jumpDelayCount_ = arg_18_2
end

function var_0_3.popSkillByType(arg_19_0, arg_19_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_19_0 = arg_19_0.reportSkills_[1]

		if not var_19_0 then
			return 0
		end

		return var_19_0.rootID_
	end

	if arg_19_0.isEnergySkill_ then
		if arg_19_1 then
			arg_19_0.__popSkillByTypeCache = arg_19_0:getOrbOfFrontSkill()
		end

		return arg_19_0.__popSkillByTypeCache
	end

	if arg_19_0:isApUnable() or arg_19_0:isAttackFriend() then
		if arg_19_1 then
			arg_19_0.__popSkillByTypeCache = arg_19_0:popAdSkill()
		end

		return arg_19_0.__popSkillByTypeCache
	elseif arg_19_0:isAdUnable() and not arg_19_0:isExcuteAdCircle() then
		if arg_19_1 then
			arg_19_0.__popSkillByTypeCache = arg_19_0:popApSkill()
		end

		return arg_19_0.__popSkillByTypeCache
	end

	if arg_19_1 then
		arg_19_0.__popSkillByTypeCache = arg_19_0:popColorSkill()
	end

	return arg_19_0.__popSkillByTypeCache
end

function var_0_3.beginAttack(arg_20_0)
	arg_20_0:jumpTo()
	var_0_3.super.beginAttack(arg_20_0)
end

function var_0_3.beginAttackEnd(arg_21_0, arg_21_1)
	var_0_3.super.beginAttackEnd(arg_21_0, arg_21_1)

	if arg_21_1.rootID_ == arg_21_0:getEnergySkillID() then
		arg_21_0.jumpBackCount_ = nil
	end
end

function var_0_3.isBreakImmortal(arg_22_0)
	if arg_22_0.jumpDelayCount_ or arg_22_0.jumpBeforeEnergy_ then
		return true
	end

	return false
end

function var_0_3.isAffected(arg_23_0)
	if arg_23_0.jumpBackCount_ or arg_23_0.jumpDelayCount_ then
		return true
	end

	return var_0_3.super.isAffected(arg_23_0)
end

function var_0_3.getEnergyRate(arg_24_0)
	local var_24_0 = var_0_3.super.getEnergyRate(arg_24_0)

	if arg_24_0.isSkinSkillOn_ then
		if var_0_1.ctx.battle.count < var_0_14 then
			var_24_0 = var_24_0 + var_0_15
		else
			var_24_0 = math.max(0, var_24_0 - 0.5)
		end
	end

	return var_24_0
end

function var_0_3.getAttackedReEnergy(arg_25_0)
	local var_25_0 = var_0_3.super.getAttackedReEnergy(arg_25_0)

	if arg_25_0.isSkinSkillOn_ then
		if var_0_1.ctx.battle.count < var_0_14 then
			var_25_0 = var_25_0 + var_0_15
		else
			var_25_0 = math.max(0, var_25_0 - 0.5)
		end
	end

	return var_25_0
end

return var_0_3
