local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shamoke", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000515
local var_0_7 = 10000522
local var_0_8 = {
	40010341
}
local var_0_9 = {
	40010340
}
local var_0_10 = 0.003
local var_0_11 = 200
local var_0_12 = 50
local var_0_13 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueTargets_ = {}
	arg_1_0.isMad_ = false
	arg_1_0.greenCount_ = 0
	arg_1_0.energySkillCD_ = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) == arg_2_1.rootID_ then
		arg_2_0.blueTargets_ = {}
	elseif arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) == arg_2_1.rootID_ then
		arg_2_0.greenCount_ = var_0_12
	elseif arg_2_0:getEnergySkillID() == arg_2_1.rootID_ then
		arg_2_0.energySkillCD_ = var_0_13
	end
end

function var_0_3.selectTargetByTypeD1(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0
	local var_3_1

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() then
			local var_3_2 = iter_3_1.hero_:getMainAttr(var_0_2.AttributeType.STRENGTH)

			if not var_3_1 or var_3_2 < var_3_1 then
				var_3_0 = iter_3_1
				var_3_1 = var_3_2
			end
		end
	end

	return {
		var_3_0
	}
end

function var_0_3.selectTargetByTypeD2(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = var_0_5:distance(arg_4_1)
	local var_4_1 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and var_4_0 >= math.abs(iter_4_1:getX() - arg_4_0:getX()) then
			table.insert(var_4_1, iter_4_1)
		end
	end

	if not next(var_4_1) then
		return {}
	else
		return {
			var_4_1[math.random(#var_4_1)]
		}
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.target

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_1 = arg_5_1.target:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
		local var_5_2 = var_0_5:scope(var_0_6) * 0.5
		local var_5_3 = {}

		for iter_5_0, iter_5_1 in ipairs(var_5_1) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1 ~= var_5_0 and iter_5_1 ~= arg_5_0 and var_5_2 >= math.abs(iter_5_1:getX() - var_5_0:getX()) then
				table.insert(var_5_3, iter_5_1)
			end
		end

		local var_5_4 = arg_5_0:createAttackUnits(var_5_3, var_0_6)

		for iter_5_2, iter_5_3 in ipairs(var_5_4) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	end

	if var_0_5:father(arg_5_1.skillID) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if not arg_5_0.blueTargets_[var_5_0] then
			arg_5_0.blueTargets_[var_5_0] = 1
		else
			arg_5_0.blueTargets_[var_5_0] = arg_5_0.blueTargets_[var_5_0] + 1
		end

		if arg_5_0.blueTargets_[var_5_0] == 2 then
			local var_5_5 = arg_5_0:newBuff(var_0_8, var_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			var_5_0:addBuffs(var_5_5)
		end
	end
end

function var_0_3.distributeBuff(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == unpack(var_0_9) then
		arg_6_1.leftCount_ = arg_6_1.leftCount_ / (1 - arg_6_0:getDKongzhi() / 100)
	end

	var_0_3.super.distributeBuff(arg_6_0, arg_6_1)
end

function var_0_3.checkEnergySkill(arg_7_0)
	if arg_7_0.energySkillCD_ > 0 then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_7_0)
	end
end

function var_0_3.toDoPerFrames(arg_8_0)
	if arg_8_0:isDeath() then
		return
	end

	if arg_8_0.energySkillCD_ > 0 then
		arg_8_0.energySkillCD_ = arg_8_0.energySkillCD_ - 1
	end

	if var_0_1.ctx.battle.count == 1 and arg_8_0.energy_ and arg_8_0.energy_ >= var_0_2.ENERGY_DECIMAL_BASE then
		arg_8_0.energy_ = 0

		local var_8_0 = var_0_2.split(arg_8_0.fighterIndex, "|")
		local var_8_1 = tonumber(var_8_0[2])

		if arg_8_0.bottomWnd and not tolua.isnull(arg_8_0.bottomWnd) then
			arg_8_0.bottomWnd:setMPProgress(0, var_8_1)
		end
	end

	if arg_8_0.greenCount_ > 0 then
		arg_8_0.greenCount_ = arg_8_0.greenCount_ - 1

		if arg_8_0.greenCount_ < 1 and arg_8_0.unitSkills_ and arg_8_0.unitSkills_.rootID_ == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			local var_8_2 = unpack(arg_8_0:selectTargetByTypeD1())

			if var_8_2 then
				local var_8_3 = arg_8_0:getX() - var_8_2:getX() > 0 and 1 or -1
				local var_8_4
				local var_8_5 = var_8_3 == 1 and true or false

				arg_8_0:x(var_8_2:getX() + var_8_3 * 100)
				arg_8_0:y(var_8_2:getY())
				arg_8_0:flipX(var_8_5)
			end
		end
	end

	if arg_8_0:getEnergy() >= var_0_2.ENERGY_DECIMAL_BASE and not arg_8_0.isMad_ and not arg_8_0:noOneAlive() then
		arg_8_0:addBuffs(arg_8_0:newBuff(var_0_9, arg_8_0, arg_8_0:getEnergySkillID()))

		arg_8_0.isMad_ = true
		arg_8_0.count_ = 0

		arg_8_0:playAttack(5)
	end

	if arg_8_0.isMad_ then
		arg_8_0.count_ = arg_8_0.count_ + 1

		if not arg_8_0:isHasBuffByID(unpack(var_0_9)) then
			arg_8_0:updateEnergyTo(0)

			arg_8_0.isMad_ = false

			if arg_8_0:getNearestTarget() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_8_6 = var_0_5:scope(var_0_7) * 0.5
				local var_8_7 = {}

				for iter_8_0, iter_8_1 in ipairs(arg_8_0.targetTeam_) do
					if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1 ~= arg_8_0 and var_8_6 >= math.abs(iter_8_1:getX() - arg_8_0:getX()) then
						table.insert(var_8_7, iter_8_1)
					end
				end

				local var_8_8 = arg_8_0:createAttackUnits(var_8_7, var_0_7)

				for iter_8_2, iter_8_3 in ipairs(var_8_8) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
					table.insert(arg_8_0.records_.special_units, iter_8_3)
				end
			end
		end
	end
end

function var_0_3.isBreakImmortal(arg_9_0)
	if arg_9_0.isMad_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_9_0)
	end
end

function var_0_3.energyDecimalBase(arg_10_0)
	return var_0_11
end

function var_0_3.energyAction(arg_11_0, arg_11_1)
	if arg_11_1 == arg_11_0:getEnergySkillID() then
		arg_11_0:getFighterModel():playEnergyEffect_()
		arg_11_0:updateEnergyTo(arg_11_0:getEnergy() - (1 - arg_11_0:getDMP() / var_0_2.PERCENT_BASE) * var_0_11)

		if arg_11_0:getTeamType() == var_0_2.TeamType.A or arg_11_0.isInArena_ then
			arg_11_0:addBlackLayer()
		end
	end
end

function var_0_3.getADJianShang(arg_12_0)
	local var_12_0 = var_0_3.super.getADJianShang(arg_12_0)
	local var_12_1 = arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_12_1 > 0 then
		var_12_0 = var_12_0 - arg_12_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_12_1 * var_0_10

		if var_12_0 <= 0 then
			var_12_0 = 0.05
		end
	end

	return var_12_0
end

function var_0_3.getAPJianShang(arg_13_0)
	local var_13_0 = var_0_3.super.getAPJianShang(arg_13_0)
	local var_13_1 = arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_13_1 > 0 then
		var_13_0 = var_13_0 - arg_13_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_13_1 * var_0_10

		if var_13_0 <= 0 then
			var_13_0 = 0.05
		end
	end

	return var_13_0
end

function var_0_3.newBuff(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		local var_14_1 = var_0_4.new({
			tableID = iter_14_1,
			start = var_0_1.ctx.battle.count,
			level = arg_14_0:getSkillLevelByID(arg_14_3),
			skillID = arg_14_3,
			fighter = arg_14_0,
			target = arg_14_2
		})

		var_14_1:setIsHit(true)
		var_14_1:setDirection(arg_14_0:getFighterModel():getFlipX())
		table.insert(var_14_0, var_14_1)
	end

	return var_14_0
end

function var_0_3.noOneAlive(arg_15_0)
	for iter_15_0, iter_15_1 in ipairs(arg_15_0.sideTeam_) do
		if not iter_15_1:isDeath() then
			return false
		end
	end

	return true
end

return var_0_3
