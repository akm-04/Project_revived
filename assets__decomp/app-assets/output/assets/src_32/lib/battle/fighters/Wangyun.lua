local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wangyun", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40010532
local var_0_7 = 40010543
local var_0_8 = 10000611
local var_0_9 = 40010535
local var_0_10 = 10000641
local var_0_11 = 0.6
local var_0_12 = 0.1
local var_0_13 = 0.005
local var_0_14 = 0.6
local var_0_15 = 0.1
local var_0_16 = 0.005
local var_0_17 = 0.6
local var_0_18 = 0
local var_0_19 = 0.5
local var_0_20 = 40010542
local var_0_21 = 5
local var_0_22 = 80010140
local var_0_23 = {
	10001274,
	10001275,
	10001276,
	10001277,
	10001278
}
local var_0_24 = {
	10010140,
	10001279,
	10001280,
	10001281,
	10001282
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyBuff_ = false
	arg_1_0.greenTargets_ = {}
	arg_1_0.blueTargets_ = {}
	arg_1_0.skinRateCount = 1
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0:isDeath() and arg_2_0.isEnergyBuff_ and not arg_2_0:isHasBuffByID(var_0_6) then
		arg_2_0.isEnergyBuff_ = false

		arg_2_0:setImmuneControl(false)
		arg_2_0:energyEndCheck()
	end
end

function var_0_3.playShanbi(arg_3_0, arg_3_1)
	var_0_3.super.playShanbi(arg_3_0, arg_3_1)

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_22 then
		arg_3_0.skinRateCount = arg_3_0.skinRateCount + 1

		if arg_3_0.skinRateCount > var_0_21 then
			arg_3_0.skinRateCount = var_0_21
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_4_0)
	local var_4_0 = var_0_3.super.getOrbOfFrontSkill(arg_4_0)

	if var_0_5:father(var_4_0) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_22 then
		var_4_0 = var_0_23[arg_4_0.skinRateCount]
	elseif var_4_0 == arg_4_0:getPugongID() and arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_22 then
		var_4_0 = var_0_24[arg_4_0.skinRateCount]
	end

	return var_4_0
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if var_0_5:father(arg_5_1.rootID_) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or var_0_5:father(arg_5_1.rootID_) == arg_5_0:getPugongID() then
		arg_5_0.skinRateCount = 1
	end
end

function var_0_3.energyEndCheck(arg_6_0)
	if arg_6_0:getHp() / arg_6_0:getHpLimit() >= 0.5 then
		local var_6_0 = arg_6_0:newBuff({
			var_0_7
		}, arg_6_0, arg_6_0:getEnergySkillID())

		arg_6_0:addBuffs(var_6_0)
	else
		arg_6_0:updateHp(arg_6_0:getHpLimit() * 0.8)
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if var_0_5:father(arg_7_1.skillID) == arg_7_0:getEnergySkillID() and arg_7_1.target == arg_7_0 then
		arg_7_0.isEnergyBuff_ = true

		arg_7_0:setImmuneControl(true)
	elseif arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if not arg_7_0.blueTargets_[arg_7_1.target] then
			arg_7_0.blueTargets_[arg_7_1.target] = true
		else
			local var_7_0 = arg_7_0:newBuff({
				var_0_20
			}, arg_7_1.target, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_7_1.target:addBuffs(var_7_0)
		end
	end
end

function var_0_3.applyHurtFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	if arg_8_2 > 0 and arg_8_1.attackType ~= var_0_2.AttackType.CURE then
		arg_8_0:purpleSkillHandle()
	end

	return var_0_3.super.applyHurtFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
end

function var_0_3.purpleSkillHandle(arg_9_0)
	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_9_0 = {
		arg_9_0
	}
	local var_9_1 = arg_9_0:createAttackUnits(var_9_0, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	for iter_9_0, iter_9_1 in ipairs(var_9_1) do
		table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
		table.insert(arg_9_0.records_.special_units, iter_9_1)
	end
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	if arg_10_1:getSkillID() == var_0_10 then
		local var_10_0 = 0
		local var_10_1 = arg_10_1.target

		if not arg_10_0.greenTargets_[var_10_1] then
			arg_10_0.greenTargets_[var_10_1] = true
		else
			var_10_0 = arg_10_1:getAttr() * var_0_11
		end

		arg_10_1.manualRevise = var_10_0

		local var_10_2 = var_0_2.tables.dbuff
		local var_10_3 = arg_10_1:getTableID()
	elseif arg_10_1:getTableID() == var_0_9 then
		arg_10_1:setForceTarget(arg_10_0)
	end
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	if arg_11_1.skillID == var_0_10 then
		local var_11_0 = 0

		if arg_11_0.greenTargets_[arg_11_1.target] then
			var_11_0 = math.min(var_0_14, var_0_12 + var_0_13 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
		end

		arg_11_4 = arg_11_4 * (1 + var_11_0)
	elseif arg_11_1.skillID == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_11_1 = 0

		if arg_11_0.blueTargets_[arg_11_1.target] then
			var_11_1 = math.min(var_0_17, var_0_15 + var_0_16 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
		end

		arg_11_4 = arg_11_4 * (1 + var_11_1)
	end

	if arg_11_4 > 0 and var_0_5:father(arg_11_1.skillID) ~= arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_5:father(arg_11_1.skillID) ~= arg_11_0:getPugongID() and arg_11_0.isSkinSkillOn_ and arg_11_0.skinSkillID_ == var_0_22 then
		arg_11_4 = arg_11_4 * arg_11_0.skinRateCount
		arg_11_0.skinRateCount = 1
	end

	return var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
end

function var_0_3.die(arg_12_0)
	var_0_3.super.die(arg_12_0)

	if arg_12_0.isEnergyBuff_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_12_0 = {}

		for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
			if not iter_12_1:isDeath() and not iter_12_1:isAffected() then
				table.insert(var_12_0, iter_12_1)
			end
		end

		local var_12_1 = arg_12_0:createAttackUnits(var_12_0, var_0_8)

		for iter_12_2, iter_12_3 in ipairs(var_12_1) do
			table.insert(arg_12_0.moveAttackUnits_, iter_12_3)
			table.insert(arg_12_0.records_.special_units, iter_12_3)
		end

		arg_12_0.isEnergyBuff_ = false
	end
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_1 = var_0_4.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(arg_13_3),
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_1:setIsHit(true)
		var_13_1:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_0, var_13_1)
	end

	return var_13_0
end

return var_0_3
