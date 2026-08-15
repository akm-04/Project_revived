local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hanlingdi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = 90
local var_0_6 = 10000999
local var_0_7 = {
	40011100,
	40011101
}
local var_0_8 = 10000998
local var_0_9 = 10001022
local var_0_10 = 40011111
local var_0_11 = 40011102
local var_0_12 = 40011103
local var_0_13 = 0
local var_0_14 = 0.3
local var_0_15 = {
	40012102,
	40012103
}
local var_0_16 = {
	40012112,
	40012113
}
local var_0_17 = 80010181

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("crit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isEnergyType_ = false
	arg_2_0.energyAttackCount_ = 0
	arg_2_0.blueTargets_ = {}
	arg_2_0.greenTargets_ = {}
end

function var_0_3.die(arg_3_0)
	arg_3_0.isEnergyType_ = false

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if (not iter_3_1:isDeath() or iter_3_1 == arg_3_0) and (iter_3_1:isHasBuffByID(var_0_7[1]) or iter_3_1:isHasBuffByID(var_0_7[2])) then
			iter_3_1:removeBuffByID(var_0_7[1])
			iter_3_1:removeBuffByID(var_0_7[2])
		end
	end

	return var_0_3.super.die(arg_3_0)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_0.isEnergyType_ and arg_4_0.energyAttackCount_ > 0 then
		arg_4_0.energyAttackCount_ = arg_4_0.energyAttackCount_ - 1

		if arg_4_0.energyAttackCount_ <= 0 then
			local var_4_0 = arg_4_0:getTargets(var_0_6)

			if next(var_4_0) then
				local var_4_1 = arg_4_0:createAttackUnits(var_4_0, var_0_6)

				for iter_4_0, iter_4_1 in ipairs(var_4_1) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
					table.insert(arg_4_0.records_.special_units, iter_4_1)
				end
			end

			arg_4_0.energyAttackCount_ = var_0_5
		end
	end

	if arg_4_0.isEnergyType_ and var_0_1.ctx.battle.count % 30 < 1 and arg_4_0:getNearestTarget() then
		arg_4_0:updateEnergyTo(arg_4_0:getEnergy() - 100)

		if arg_4_0:getEnergy() < 1 then
			arg_4_0.isEnergyType_ = false

			for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfTeam_) do
				if not iter_4_3:isDeath() then
					iter_4_3:removeBuffByID(var_0_7[1])
					iter_4_3:removeBuffByID(var_0_7[2])
				end
			end
		end
	end

	if next(arg_4_0.blueTargets_) then
		for iter_4_4, iter_4_5 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			local var_4_2 = iter_4_5.harm
			local var_4_3 = iter_4_5.target
			local var_4_4 = iter_4_5.isBaoji

			if var_4_2 > 0 and not var_4_3:isDeath() and arg_4_0.blueTargets_[var_4_3] and var_4_4 then
				var_4_3:removeBuffByID(var_0_11)
				var_4_3:removeBuffByID(var_0_12)

				arg_4_0.blueTargets_[var_4_3] = false
			end
		end
	end

	if arg_4_0.isSkinSkillOn_ then
		for iter_4_6, iter_4_7 in ipairs(arg_4_0:getInfoByKey("crit_info")) do
			local var_4_5 = iter_4_7.unit.fighter

			if var_4_5:getTeamType() == arg_4_0:getTeamType() and not var_4_5:isDeath() and not var_4_5:isAffected() then
				local var_4_6 = var_0_15

				for iter_4_8, iter_4_9 in ipairs(arg_4_0.selfTeam_) do
					if (iter_4_9.__cname == "Hanxiandi" or iter_4_9.__cname == "Hanshaodi") and not iter_4_9:isDeath() and not iter_4_9:isAffected() then
						var_4_6 = var_0_16

						break
					end
				end

				local var_4_7 = arg_4_0:createNewBuffs(var_4_6, var_4_5, var_0_17)

				var_4_5:addBuffs(var_4_7)
			end
		end
	end
end

function var_0_3.energyDecimalBase(arg_5_0)
	return var_0_3.super.energyDecimalBase(arg_5_0) * 0.8
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_1.rootID_ == arg_6_0:getEnergySkillID() then
		arg_6_0.isEnergyType_ = true
		arg_6_0.energyAttackCount_ = var_0_5
	end
end

function var_0_3.getDMP(arg_7_0)
	return arg_7_0:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE * var_0_2.PERCENT_BASE
end

function var_0_3.checkEnergySkill(arg_8_0)
	if arg_8_0.isEnergyType_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_8_0)
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	local var_9_0 = arg_9_1.skillID
	local var_9_1 = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_9_1 > 0 and (var_9_0 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_9_0 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) then
		local var_9_2 = var_9_1 * var_0_13 + var_0_14
		local var_9_3 = math.min(1, var_9_2)

		if var_0_2.weightedChoise({
			var_9_3,
			1 - var_9_3
		}) == 1 then
			local var_9_4 = arg_9_0:createAttackUnits({
				arg_9_0
			}, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_9_0, iter_9_1 in ipairs(var_9_4) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
				table.insert(arg_9_0.records_.special_units, iter_9_1)
			end
		end
	end

	if var_9_0 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_9_5 = arg_9_0:getBuffs()

		for iter_9_2 = #var_9_5, 1, -1 do
			local var_9_6 = var_9_5[iter_9_2]

			if var_9_6 and arg_9_0:checkCanClean(var_9_6) then
				arg_9_0:removeBuffs(var_9_6)
			end
		end
	end
end

function var_0_3.checkCanClean(arg_10_0, arg_10_1)
	if arg_10_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and arg_10_1:getType() == var_0_2.BuffType.MOVE_SKILL_LIMIT then
		local var_10_0 = var_0_4:dbuffType(arg_10_1:getTableID())

		if var_10_0 == var_0_2.DBuffType.XUAN_YUN or var_10_0 == var_0_2.DBuffType.SHI_HUA or var_10_0 == var_0_2.DBuffType.BING_DONG then
			return true
		end
	end

	return false
end

function var_0_3.buffAddAction(arg_11_0, arg_11_1)
	var_0_3.super.buffAddAction(arg_11_0, arg_11_1)

	if arg_11_1:getTableID() == var_0_11 then
		arg_11_0.blueTargets_[arg_11_1.target] = true
	elseif arg_11_1:getTableID() == var_0_10 then
		arg_11_0.greenTargets_[arg_11_1.target] = true
	end
end

function var_0_3.buffRemoveAction(arg_12_0, arg_12_1)
	var_0_3.super.buffRemoveAction(arg_12_0, arg_12_1)

	if arg_12_1:getTableID() == var_0_11 then
		arg_12_0.blueTargets_[arg_12_1.target] = false
	elseif arg_12_1:getTableID() == var_0_10 then
		arg_12_0.greenTargets_[arg_12_1.target] = false
	end
end

function var_0_3.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	local var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5 = var_0_3.super.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)

	if arg_13_1.skillID == var_0_6 then
		-- block empty
	end

	return var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5
end

function var_0_3.updateUnitDataBySpecialHero(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)

	if arg_14_4 > 0 and arg_14_3 and arg_14_0.greenTargets_[arg_14_1.target] then
		arg_14_4 = arg_14_4 * 2
	end

	return arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7
end

function var_0_3.unitAfterCreate(arg_15_0, arg_15_1, arg_15_2)
	var_0_3.super.unitAfterCreate(arg_15_0, arg_15_1, arg_15_2)

	if arg_15_1 and arg_15_1.skillID == var_0_8 then
		local var_15_0 = arg_15_0:getTargets(var_0_9)

		if next(var_15_0) then
			arg_15_1:setDesition(var_15_0[1]:getX())
		end
	end
end

return var_0_3
