local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhitianxinchang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 0.5
local var_0_9 = 0.003
local var_0_10 = 0.2
local var_0_11 = 0.1
local var_0_12 = 0.005
local var_0_13 = 0.8
local var_0_14 = 0.005
local var_0_15 = 0.04
local var_0_16 = 0.002
local var_0_17 = 0.3
local var_0_18 = -0.001
local var_0_19 = {
	40010277,
	40010278
}
local var_0_20 = 10000480
local var_0_21 = {
	40010276,
	40010279
}
local var_0_22 = 10000486
local var_0_23 = 10000485
local var_0_24 = 10
local var_0_25 = 15
local var_0_26 = 10
local var_0_27 = 20
local var_0_28 = 360
local var_0_29 = 60020113
local var_0_30 = 60
local var_0_31 = 80010113

function var_0_3.singleLoop(arg_1_0)
	if arg_1_0.skinSkillID_ == var_0_31 then
		local var_1_0 = arg_1_0:getHp() / arg_1_0:getHpLimit()
		local var_1_1 = var_0_3.super.getCurrentAckSpeed
		local var_1_2 = var_0_3.super.getADBaoJiHarm

		function arg_1_0.getCurrentAckSpeed(arg_2_0)
			return var_1_1(arg_2_0) * (2 - var_1_0)
		end

		function arg_1_0.getADBaoJiHarm(arg_3_0)
			return var_1_2(arg_3_0) + (1 - var_1_0) * 15000
		end

		var_0_3.super.singleLoop(arg_1_0)

		arg_1_0.getCurrentAckSpeed = var_1_1
		arg_1_0.getADBaoJiHarm = var_1_2
	else
		var_0_3.super.singleLoop(arg_1_0)
	end
end

function var_0_3.init(arg_4_0)
	var_0_3.super.init(arg_4_0)

	arg_4_0.crisisHp_ = 0
	arg_4_0.beginJump_ = false
	arg_4_0.isEnergyMove_ = false
	arg_4_0.greenBackCount_ = nil
	arg_4_0.greenBeforeCount_ = nil
	arg_4_0.energyBackCount_ = nil
	arg_4_0.energyBeforeCount_ = nil
	arg_4_0.purpleCD_ = 0
	arg_4_0.twiceAwakenTriggerTime = 0
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		if arg_5_1.target:isDeath() then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_0 = {}

				for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
					if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
						table.insert(var_5_0, iter_5_1)
					end
				end

				local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_20)

				for iter_5_2, iter_5_3 in ipairs(var_5_1) do
					iter_5_3:setExtraHarm(arg_5_1.target:getOverflowHarm())
					table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
					table.insert(arg_5_0.records_.special_units, iter_5_3)
				end
			end

			if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
				local var_5_2 = 0

				for iter_5_4, iter_5_5 in ipairs(arg_5_0.sideTeam_) do
					if not iter_5_5:isDeath() and iter_5_5:isHasBuffByID(var_0_19[1]) then
						iter_5_5:removeBuffByID(var_0_19[1])
						iter_5_5:removeBuffByID(var_0_19[2])

						var_5_2 = var_5_2 + 1
					end
				end

				local var_5_3 = arg_5_0:getDCureRate() * var_5_2 * arg_5_0:getHpLimit() * (var_0_15 + var_0_16 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

				arg_5_0:updateHp(arg_5_0:getHp() + var_5_3)
				arg_5_0.fighterModel:playHPDeltas({
					{
						var_5_3,
						false
					}
				}, nil)
			end
		end

		if arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) <= 0 then
			arg_5_0.energyBackCount_ = var_0_26
		end

		arg_5_0.isEnergyMove_ = true

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_5_0:getNearestTarget() then
			local var_5_4 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
			local var_5_5 = var_0_6:attackIndex(var_5_4)

			arg_5_0:playAttack(var_5_5)

			arg_5_0.unitSkills_ = var_0_5.new({
				fighter = arg_5_0,
				skillID = var_5_4
			})

			arg_5_0:beginAttackEnd(arg_5_0.unitSkills_)
		end
	elseif arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		local var_5_6

		if arg_5_1.skillID == arg_5_0:getPugongID() then
			var_5_6 = var_0_10
		elseif var_0_6:father(arg_5_1.skillID) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			var_5_6 = math.min(var_0_8 + var_0_9 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), 1)

			local var_5_7 = arg_5_1.target:getX()
			local var_5_8 = arg_5_1.target:getY()
			local var_5_9

			if arg_5_0:getTeamType() == var_0_2.TeamType.A then
				var_5_9 = -1

				arg_5_0:flipX(false)
			else
				var_5_9 = 1

				arg_5_0:flipX(true)
			end

			arg_5_0:x(var_5_7 + 100 * var_5_9)
			arg_5_0:y(var_5_8)

			if arg_5_1.skillID == var_0_23 then
				arg_5_0.greenBackCount_ = var_0_24
			end
		end

		if var_5_6 and not arg_5_1.target:isDeath() and arg_5_1.target:getTeamType() ~= arg_5_0:getTeamType() and var_0_2.weightedChoise({
			var_5_6,
			1 - var_5_6
		}) == 1 then
			local var_5_10 = arg_5_0:getSkillLevelByID(var_0_29)

			if var_5_10 > 0 and arg_5_0.twiceAwakenTriggerTime < var_0_1.ctx.battle.count then
				arg_5_0:explodeForceBuff(arg_5_1.target, var_5_10)

				arg_5_0.twiceAwakenTriggerTime = var_0_1.ctx.battle.count + var_0_30
			end

			arg_5_1.target:addBuffs(arg_5_0:newBuff(var_0_19, arg_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)))
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0 = arg_6_0:getSkillLevelByID(arg_6_1.skillID)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_6_1.skillID == arg_6_0:getPugongID() and arg_6_1.target:isHasBuffByID(var_0_19[1]) then
		arg_6_4 = arg_6_4 * (1 + var_0_11 + var_0_12 * var_6_0)
	elseif arg_6_1.skillID == var_0_20 then
		arg_6_4 = arg_6_4 * (var_0_13 + var_0_14 * var_6_0)
	end

	return var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
end

function var_0_3.deathFeedback(arg_7_0, arg_7_1)
	var_0_3.super.deathFeedback(arg_7_0, arg_7_1)
	arg_7_0:explodeForceBuff(arg_7_1, 0)
end

function var_0_3.explodeForceBuff(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1:getTeamType() ~= arg_8_0:getTeamType() and arg_8_1:isHasBuffByID(var_0_19[1]) then
		local var_8_0 = var_0_1.ctx.battle.getSpine(var_0_22, "hurt", 1)

		var_8_0:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_8_0:pos(arg_8_1:getX(), arg_8_1:getY())
		var_8_0:setScale(0.5)
		var_8_0:playOnce()

		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
			local var_8_1 = {}
			local var_8_2 = var_0_6:scope(arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) * 0.5

			for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
				if not iter_8_1:isDeath() and not iter_8_1:isAffected() and var_8_2 >= math.abs(iter_8_1:getX() - arg_8_1:getX()) then
					table.insert(var_8_1, iter_8_1)
				end
			end

			local var_8_3 = arg_8_0:createAttackUnits(var_8_1, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			for iter_8_2, iter_8_3 in ipairs(var_8_3) do
				if arg_8_2 > 0 then
					iter_8_3.basicHarm = iter_8_3.basicHarm + math.min(iter_8_3.target:getHpLimit() * 0.05, arg_8_2 * 50) + arg_8_2 * 30
				end

				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end
		end
	end
end

function var_0_3.isInvisible(arg_9_0)
	if arg_9_0.beginJump_ then
		return true
	else
		return var_0_3.super.isInvisible(arg_9_0)
	end
end

function var_0_3.die(arg_10_0)
	var_0_3.super.die(arg_10_0)

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and iter_10_1:isHasBuffByID(var_0_19[1]) then
			iter_10_1:removeBuffByID(var_0_19[1])
			iter_10_1:removeBuffByID(var_0_19[2])
		end
	end
end

function var_0_3.beginAttackEnd(arg_11_0, arg_11_1)
	if arg_11_1.rootID_ == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_11_0.greenPreX_ = arg_11_0:getX()
		arg_11_0.greenPreY_ = arg_11_0:getY()
		arg_11_0.greenBeforeCount_ = var_0_25
		arg_11_0.beginJump_ = true
	elseif arg_11_1.rootID_ == arg_11_0:getEnergySkillID() then
		arg_11_0.energyPreX_ = arg_11_0:getX()
		arg_11_0.energyPreY_ = arg_11_0:getY()
		arg_11_0.energyBeforeCount_ = var_0_27
	end

	var_0_3.super.beginAttackEnd(arg_11_0, arg_11_1)
end

function var_0_3.toDoPerFrames(arg_12_0)
	if arg_12_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_12_0.twiceAwakenTriggerTime = 0
	end

	if arg_12_0.beginJump_ and not arg_12_0:isCreatingUnits() then
		arg_12_0.beginJump_ = false
	end

	if arg_12_0.greenBackCount_ then
		arg_12_0.greenBackCount_ = arg_12_0.greenBackCount_ - 1

		if arg_12_0.greenBackCount_ <= 0 then
			if not arg_12_0.isEnergyMove_ then
				arg_12_0:x(arg_12_0.greenPreX_ or arg_12_0:getX())
				arg_12_0:y(arg_12_0.greenPreY_ or arg_12_0:getY())
			else
				arg_12_0:x(arg_12_0.energyPreX_)
				arg_12_0:y(arg_12_0.energyPreY_)

				arg_12_0.energyPreX_ = nil
				arg_12_0.energyPreY_ = nil
				arg_12_0.energyBackCount_ = nil
				arg_12_0.isEnergyMove_ = false
			end

			arg_12_0.greenPreX_ = nil
			arg_12_0.greenPreY_ = nil
			arg_12_0.greenBackCount_ = nil
			arg_12_0.beginJump_ = false
		end
	end

	if arg_12_0.energyBackCount_ then
		arg_12_0.energyBackCount_ = arg_12_0.energyBackCount_ - 1

		if arg_12_0.energyBackCount_ <= 0 then
			arg_12_0:x(arg_12_0.energyPreX_)
			arg_12_0:y(arg_12_0.energyPreY_)

			arg_12_0.energyPreX_ = nil
			arg_12_0.energyPreY_ = nil
			arg_12_0.energyBackCount_ = nil
			arg_12_0.isEnergyMove_ = false
			arg_12_0.beginJump_ = false
		end
	end

	if arg_12_0.energyBeforeCount_ then
		arg_12_0.energyBeforeCount_ = arg_12_0.energyBeforeCount_ - 1

		if arg_12_0.energyBeforeCount_ <= 0 then
			local var_12_0 = unpack(arg_12_0:selectTargetByTypeD1())
			local var_12_1

			if arg_12_0:getTeamType() == var_0_2.TeamType.A then
				var_12_1 = -1

				arg_12_0:flipX(false)
			else
				var_12_1 = 1

				arg_12_0:flipX(true)
			end

			if var_12_0 then
				arg_12_0:x(var_12_0:getX() + var_12_1 * 200)
				arg_12_0:y(var_12_0:getY())
			end

			arg_12_0.energyBeforeCount_ = nil
		end
	end

	if arg_12_0.greenBeforeCount_ then
		arg_12_0.greenBeforeCount_ = arg_12_0.greenBeforeCount_ - 1

		if arg_12_0.greenBeforeCount_ <= 0 then
			local var_12_2 = arg_12_0:getNearestTarget()
			local var_12_3

			if arg_12_0:getTeamType() == var_0_2.TeamType.A then
				var_12_3 = -1

				arg_12_0:flipX(false)
			else
				var_12_3 = 1

				arg_12_0:flipX(true)
			end

			if var_12_2 then
				arg_12_0:x(var_12_2:getX() + var_12_3 * 100)
				arg_12_0:y(var_12_2:getY())
			end

			arg_12_0.greenBeforeCount_ = nil
		end
	end

	if arg_12_0.purpleCD_ > 0 then
		arg_12_0.purpleCD_ = arg_12_0.purpleCD_ - 1
	end
end

function var_0_3.energyMoveToTarget(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_1:getX()
	local var_13_1 = arg_13_1:getY()
	local var_13_2

	if arg_13_0:getTeamType() == var_0_2.TeamType.A then
		var_13_2 = -1

		arg_13_0:flipX(false)
	else
		var_13_2 = 1

		arg_13_0:flipX(true)
	end

	arg_13_0:x(var_13_0 + 200 * var_13_2)
	arg_13_0:y(var_13_1)
end

function var_0_3.updateHp(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0:getHp()

	var_0_3.super.updateHp(arg_14_0, arg_14_1, arg_14_2)

	local var_14_1 = arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_14_1 > 0 and arg_14_0.purpleCD_ <= 0 then
		local var_14_2 = arg_14_0:getHp()

		if var_14_2 > 0 and var_14_2 < var_14_0 then
			arg_14_0.crisisHp_ = arg_14_0.crisisHp_ + var_14_0 - var_14_2

			if arg_14_0.crisisHp_ >= (var_0_17 + var_0_18 * var_14_1) * arg_14_0:getHpLimit() then
				arg_14_0:addBuffs(arg_14_0:newBuff(var_0_21, arg_14_0, arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))

				arg_14_0.crisisHp_ = 0
				arg_14_0.purpleCD_ = var_0_28

				local var_14_3 = arg_14_0:getSkillLevelByID(var_0_29)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_14_3 > 0 and arg_14_0:getNearestTarget() then
					local var_14_4 = arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
					local var_14_5 = var_0_6:attackIndex(var_14_4)

					arg_14_0.greenPreX_ = arg_14_0:getX()
					arg_14_0.greenPreY_ = arg_14_0:getY()
					arg_14_0.greenBeforeCount_ = var_0_25
					arg_14_0.beginJump_ = true

					arg_14_0:playAttack(var_14_5)

					arg_14_0.unitSkills_ = var_0_5.new({
						fighter = arg_14_0,
						skillID = var_14_4
					})

					arg_14_0:beginAttackEnd(arg_14_0.unitSkills_)
				end
			end
		end
	end
end

function var_0_3.newBuff(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		local var_15_1 = var_0_4.new({
			tableID = iter_15_1,
			start = var_0_1.ctx.battle.count,
			level = arg_15_0:getSkillLevelByID(arg_15_3),
			skillID = arg_15_3,
			fighter = arg_15_0,
			target = arg_15_2
		})

		var_15_1:setIsHit(true)
		var_15_1:setDirection(arg_15_0:getFighterModel():getFlipX())
		table.insert(var_15_0, var_15_1)
	end

	return var_15_0
end

function var_0_3.selectTargetByTypeD1(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0
	local var_16_1

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and iter_16_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_16_2 = iter_16_1:getHp() / iter_16_1:getHpLimit()

			if not var_16_0 or var_16_2 < var_16_0 then
				var_16_1 = iter_16_1
				var_16_0 = var_16_2
			end
		end
	end

	return {
		var_16_1
	}
end

return var_0_3
