local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseZhugejin", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = 80038005
local var_0_9 = 80038006
local var_0_10 = 40010354
local var_0_11 = 40010179
local var_0_12 = 80038007
local var_0_13 = 80038008
local var_0_14 = 80038009
local var_0_15 = 1
local var_0_16 = 10

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isViolent_ = false
	arg_1_0.isEnergyBuff_ = false
	arg_1_0.purpleCount_ = nil
	arg_1_0.energyCount_ = nil
	arg_1_0.apMarrow_ = 0
	arg_1_0.adMarrow_ = 0
end

function var_0_3.canAttack(arg_2_0)
	if arg_2_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.canAttack(arg_2_0)
	end
end

function var_0_3.checkEnergySkill(arg_3_0)
	if arg_3_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_3_0)
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	local function var_4_0(arg_5_0, arg_5_1, arg_5_2)
		local var_5_0 = {}

		for iter_5_0, iter_5_1 in ipairs(arg_5_0) do
			local var_5_1 = var_0_7.new({
				tableID = iter_5_1,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0:getSkillLevelByID(arg_5_2),
				skillID = arg_5_2,
				fighter = arg_4_0,
				target = arg_5_1
			})

			var_5_1:setIsHit(true)
			var_5_1:setDirection(arg_4_0:getFighterModel():getFlipX())
			table.insert(var_5_0, var_5_1)
		end

		return var_5_0
	end

	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		arg_6_0.isEnergyBuff_ = true
		arg_6_0.energyCount_ = var_0_5:time(var_0_11)

		arg_6_0:setImmuneControl(true)
	elseif arg_6_1.skillID == var_0_8 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_1.target

		if var_6_0:isHasBuffByID(var_0_10) then
			local var_6_1 = {
				var_6_0
			}
			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_0_9)

			for iter_6_0, iter_6_1 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	local var_7_0, var_7_1, var_7_2, var_7_3 = var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)

	if var_7_0 > 0 then
		if arg_7_1.attackType == var_0_2.AttackType.AD then
			arg_7_0.adMarrow_ = arg_7_0.adMarrow_ + 1

			if arg_7_0.isEnergyBuff_ then
				arg_7_0.adMarrow_ = arg_7_0.adMarrow_ + 1
			end
		elseif arg_7_1.attackType == var_0_2.AttackType.AP then
			arg_7_0.apMarrow_ = arg_7_0.apMarrow_ + 1

			if arg_7_0.isEnergyBuff_ then
				arg_7_0.apMarrow_ = arg_7_0.apMarrow_ + 1
			end
		end
	end

	return var_7_0, var_7_1, var_7_2, var_7_3
end

function var_0_3.getOrbOfFrontSkill(arg_8_0)
	local var_8_0 = var_0_3.super.getOrbOfFrontSkill(arg_8_0)
	local var_8_1 = var_0_4:buffOrb(var_8_0)

	if var_8_1 ~= 0 and arg_8_0.isViolent_ then
		return var_8_1
	end

	return var_8_0
end

function var_0_3.getUnitData(arg_9_0, arg_9_1)
	local var_9_0
	local var_9_1
	local var_9_2
	local var_9_3
	local var_9_4
	local var_9_5

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = unpack(arg_9_1.reportData_.calculate[tostring(var_0_1.ctx.battle.count)])

		if arg_9_1.skillID == var_0_12 then
			arg_9_0.adMarrow_ = 0
			arg_9_0.apMarrow_ = 0
		end
	else
		var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = arg_9_0:calculateUnitData(arg_9_1)
		var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = arg_9_1.target:updateUnitDataByTargetHunqi(arg_9_1, var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)
		var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = arg_9_1.target:updateUnitDataByTarget(arg_9_1, var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)

		if not var_0_4:isReflect(arg_9_1.skillID) then
			var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = arg_9_0:updateUnitDataByFighterElement(arg_9_1, var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)
			var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = arg_9_0:updateUnitDataByFighterHunqi(arg_9_1, var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)
			var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = arg_9_0:updateUnitDataByFighter(arg_9_1, var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)
		end

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
			if not iter_9_1:isDeath() and not var_0_4:isTriggerSkill(arg_9_1.skillID) and not var_0_4:isReflect(arg_9_1.skillID) then
				var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = iter_9_1:updateUnitDataBySpecialHero(arg_9_1, var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)
			end
		end

		for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_3:isDeath() and not var_0_4:isTriggerSkill(arg_9_1.skillID) and not var_0_4:isReflect(arg_9_1.skillID) then
				var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = iter_9_3:updateUnitDataBySpecialHero(arg_9_1, var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)
			end
		end

		arg_9_1:recordData(var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5)
	end

	return var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_1.skillID == var_0_12 then
		arg_10_4 = arg_10_4 + (arg_10_0.adMarrow_ + arg_10_0.apMarrow_) * (var_0_15 + var_0_16 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
		arg_10_0.adMarrow_ = 0
		arg_10_0.apMarrow_ = 0
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.toDoPerFrames(arg_11_0)
	if arg_11_0:isDeath() then
		return
	end

	if arg_11_0.energyCount_ then
		arg_11_0.energyCount_ = arg_11_0.energyCount_ - 1

		if arg_11_0.energyCount_ <= 0 then
			arg_11_0.energyCount_ = nil
			arg_11_0.isEnergyBuff_ = false

			arg_11_0:setImmuneControl(false)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_11_0

				if arg_11_0.adMarrow_ <= arg_11_0.apMarrow_ then
					var_11_0 = var_0_14
				else
					var_11_0 = var_0_13
				end

				local var_11_1 = var_0_6.B8(arg_11_0, var_11_0)
				local var_11_2 = arg_11_0:createAttackUnits(var_11_1, var_11_0)

				for iter_11_0, iter_11_1 in ipairs(var_11_2) do
					table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
					table.insert(arg_11_0.records_.special_units, iter_11_1)
				end

				local var_11_3 = var_0_6.B8(arg_11_0, var_0_12)
				local var_11_4 = arg_11_0:createAttackUnits(var_11_3, var_0_12)

				for iter_11_2, iter_11_3 in ipairs(var_11_4) do
					table.insert(arg_11_0.moveAttackUnits_, iter_11_3)
					table.insert(arg_11_0.records_.special_units, iter_11_3)
				end
			end
		end
	end
end

return var_0_3
