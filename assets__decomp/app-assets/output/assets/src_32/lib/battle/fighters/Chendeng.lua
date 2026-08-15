local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chendeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 40011023
local var_0_8 = 10000919
local var_0_9 = 10000920
local var_0_10 = 0.003
local var_0_11 = 0
local var_0_12 = 40011016
local var_0_13 = 40011025
local var_0_14 = 60
local var_0_15 = 10
local var_0_16 = 6
local var_0_17 = 40011017
local var_0_18 = {
	40011018,
	40011019
}
local var_0_19 = 100
local var_0_20 = 0.3
local var_0_21 = 0
local var_0_22 = 80010173
local var_0_23 = 40011357
local var_0_24 = 600

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyTarget_ = nil
	arg_2_0.greenTargets_ = {}
	arg_2_0.purpleCounselNum_ = 0
	arg_2_0.harmInfo = {}
	arg_2_0.skinSkillCount = 0
	arg_2_0.skinTarget = nil
	arg_2_0.isInitHarm = false
end

function var_0_3.setupSkillLevel(arg_3_0)
	arg_3_0.extraSkillLevel_ = arg_3_0.hero_:getExtraSkillLevel()
	arg_3_0.skillLevelByColor_ = var_0_0.clone(arg_3_0.hero_:getSkillLevel())
	arg_3_0.skillLevelByID_ = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.skillLevelByColor_) do
		arg_3_0.skillLevelByColor_[iter_3_0] = iter_3_1 and iter_3_1 > 0 and iter_3_1 + arg_3_0.extraSkillLevel_ or 0
		arg_3_0.skillLevelByID_[arg_3_0.hero_:getSkillId(iter_3_0)] = iter_3_1 and iter_3_1 > 0 and iter_3_1 + arg_3_0.extraSkillLevel_ or 0
	end

	arg_3_0.skillLevelByID_[arg_3_0:getPugongID()] = arg_3_0:getLevel() + arg_3_0.extraSkillLevel_

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_22 then
		arg_3_0.skillLevelByID_[arg_3_0.skinSkillID_] = arg_3_0:getLevel()
	end

	for iter_3_2, iter_3_3 in pairs(arg_3_0.skillLevelByID_) do
		if iter_3_3 > var_0_2.MAX_SKILL_LEV then
			var_0_2.exitProgram()
		end
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if not arg_4_0.isInitHarm then
		arg_4_0.isInitHarm = true

		for iter_4_0, iter_4_1 in pairs(arg_4_0.selfTeam_) do
			arg_4_0.harmInfo[iter_4_1] = 0
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		local var_4_0 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) * var_0_14 + var_0_15

		for iter_4_2, iter_4_3 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			local var_4_1 = iter_4_3.harm
			local var_4_2 = iter_4_3.target

			if var_4_1 > 0 and not var_4_2:isDeath() and var_4_2:isHasBuffByID(var_0_12) then
				arg_4_0.greenTargets_[var_4_2] = (arg_4_0.greenTargets_[var_4_2] or 0) + var_4_1

				if var_4_0 <= arg_4_0.greenTargets_[var_4_2] then
					arg_4_0.greenTargets_[var_4_2] = 0

					arg_4_0:greenHarmTarget(var_4_2, var_4_0)
					var_4_2:removeBuffByID(var_0_12)
				end
			end
		end
	end

	for iter_4_4, iter_4_5 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
		local var_4_3 = iter_4_5.harm
		local var_4_4 = iter_4_5.fighter

		if not arg_4_0.harmInfo[var_4_4] then
			arg_4_0.harmInfo[var_4_4] = var_4_3
		else
			arg_4_0.harmInfo[var_4_4] = arg_4_0.harmInfo[var_4_4] + var_4_3
		end
	end

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_22 then
		arg_4_0.skinSkillCount = arg_4_0.skinSkillCount - 1

		if arg_4_0.skinSkillCount < 1 then
			local var_4_5

			for iter_4_6, iter_4_7 in ipairs(arg_4_0.selfTeam_) do
				if not iter_4_7:isDeath() and not iter_4_7:isAffected() and arg_4_0.harmInfo[iter_4_7] and iter_4_7:getSummonType() == var_0_2.summonMonsterType.None and (not var_4_5 or arg_4_0.harmInfo[iter_4_7] > arg_4_0.harmInfo[var_4_5]) then
					var_4_5 = iter_4_7
				end
			end

			arg_4_0.skinTarget = var_4_5

			if arg_4_0.skinTarget then
				local var_4_6 = arg_4_0:newBuff({
					var_0_23
				}, arg_4_0.skinTarget, var_0_22)

				arg_4_0.skinTarget:addBuffs(var_4_6)
			end

			arg_4_0.harmInfo = {}

			for iter_4_8, iter_4_9 in pairs(arg_4_0.selfTeam_) do
				arg_4_0.harmInfo[iter_4_9] = 0
			end

			arg_4_0.skinSkillCount = var_0_24
		end

		for iter_4_10, iter_4_11 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			local var_4_7 = iter_4_11.target

			if var_4_7 and not var_4_7:isDeath() and var_4_7 == arg_4_0.skinTarget and var_4_7:isHasBuffByID(var_0_23) and var_0_6:dbuffType(iter_4_11:getTableID()) > 0 and var_0_6:dbuffType(iter_4_11:getTableID()) ~= var_0_2.DBuffType.ATTR_CHANGE and var_0_6:dbuffType(iter_4_11:getTableID()) ~= var_0_2.DBuffType.JIANG_LIAO and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_8 = arg_4_0:createAttackUnits({
					var_4_7
				}, var_0_22)

				for iter_4_12, iter_4_13 in ipairs(var_4_8) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_13)
					table.insert(arg_4_0.records_.special_units, iter_4_13)
				end
			end
		end
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_5_0 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_20 + var_0_21

		arg_5_0.purpleCounselNum_ = arg_5_0.purpleCounselNum_ + var_5_0
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_1:getTableID() == var_0_7 then
		arg_6_0.energyTarget_ = arg_6_1.target
	end
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	var_0_3.super.buffRemoveAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_7 then
		arg_7_0.energyTarget_ = nil
	elseif arg_7_1:getTableID() == var_0_12 and arg_7_0.greenTargets_[arg_7_1.target] and arg_7_0.greenTargets_[arg_7_1.target] > 0 then
		arg_7_0:greenHarmTarget(arg_7_1.target, arg_7_0.greenTargets_[arg_7_1.target])
	elseif arg_7_1:getTableID() == var_0_17 and not arg_7_1.target:isDeath() then
		local var_7_0 = arg_7_0:newBuff(var_0_18, arg_7_1.target, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_7_1.target:addBuffs(var_7_0)
	end
end

function var_0_3.greenHarmTarget(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_0:newBuff({
		var_0_13
	}, arg_8_1, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

	var_8_0[1].manualHarmRevise = arg_8_2 / var_0_16

	arg_8_1:addBuffs(var_8_0)
end

function var_0_3.energySelectTargets(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if not arg_9_2 then
		return {}
	end

	local var_9_0 = var_0_5:scope(arg_9_1) / 2
	local var_9_1 = {}
	local var_9_2, var_9_3 = arg_9_2:getPos()

	if arg_9_3 then
		table.insert(var_9_1, arg_9_2)
	end

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		local var_9_4, var_9_5 = iter_9_1:getPos()

		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and var_9_0 >= math.abs(var_9_2 - var_9_4) and iter_9_1 ~= arg_9_2 then
			table.insert(var_9_1, iter_9_1)
		end
	end

	return var_9_1
end

function var_0_3.updateUnitDataByTarget(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByTarget(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_4 > 0 and arg_10_0.purpleCounselNum_ >= var_0_19 then
		arg_10_4 = 0
		arg_10_2 = true
		arg_10_0.purpleCounselNum_ = 0
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7 = var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if arg_11_4 > 0 and arg_11_1.skillID == var_0_8 and arg_11_1.change_harm and arg_11_1.change_harm > 0 then
		arg_11_4 = arg_11_4 + arg_11_1.change_harm
	end

	return arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7
end

function var_0_3.updateUnitDataBySpecialHero(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)

	if arg_12_4 > 0 and arg_12_1.skillID ~= var_0_8 and arg_12_1.skillID ~= var_0_9 and arg_12_0.energyTarget_ and arg_12_1.target == arg_12_0.energyTarget_ and arg_12_1.fighter:getTeamType() == arg_12_0:getTeamType() then
		local var_12_0 = arg_12_0:energySelectTargets(var_0_8, arg_12_1.target, true)

		if next(var_12_0) then
			local var_12_1 = arg_12_4 * (var_0_10 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_11)

			if arg_12_1.fighter ~= arg_12_0 then
				var_12_1 = arg_12_4 / 2
			end

			local var_12_2 = arg_12_0:createAttackUnits(var_12_0, var_0_8)

			for iter_12_0, iter_12_1 in ipairs(var_12_2) do
				iter_12_1.change_harm = var_12_1

				table.insert(arg_12_0.moveAttackUnits_, iter_12_1)
				table.insert(arg_12_0.records_.special_units, iter_12_1)
			end
		end
	end

	return arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7
end

function var_0_3.deathFeedback(arg_13_0, arg_13_1)
	var_0_3.super.deathFeedback(arg_13_0, arg_13_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_13_0.energyTarget_ and arg_13_0.energyTarget_ == arg_13_1 then
		local var_13_0 = arg_13_0:energySelectTargets(var_0_9, arg_13_1, false)
		local var_13_1 = arg_13_0:createAttackUnits(var_13_0, var_0_9)

		for iter_13_0, iter_13_1 in ipairs(var_13_1) do
			table.insert(arg_13_0.moveAttackUnits_, iter_13_1)
			table.insert(arg_13_0.records_.special_units, iter_13_1)
		end
	end
end

function var_0_3.checkEnergySkill(arg_14_0)
	if arg_14_0.energyTarget_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_14_0)
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

return var_0_3
