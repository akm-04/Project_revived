local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xusheng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 0.18
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_7 = 10000364
local var_0_8 = 120
local var_0_9 = 20010257
local var_0_10 = 20010258
local var_0_11 = 3
local var_0_12 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_13 = var_0_2.tables.skinSkill
local var_0_14 = 0.1
local var_0_15 = 1
local var_0_16 = 80010093
local var_0_17 = 80020093
local var_0_18 = 2
local var_0_19 = var_0_2.tables.elementEquip
local var_0_20 = 20001469
local var_0_21 = 10002239
local var_0_22 = 0.25

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.count = false
	arg_1_0.isBlueSkillExist = false
	arg_1_0.accumulateHarm = 0
	arg_1_0.criticalHp = 0
	arg_1_0.specialAttackCount = 0
	arg_1_0.skinAttackCount_ = 0
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_16 then
		arg_2_4 = arg_2_4 * (1 + math.min(arg_2_0.skinAttackCount_ * var_0_14, var_0_15))
	elseif arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_17 then
		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_17)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end

		arg_2_4 = arg_2_4 * (1 + (arg_2_0:getHpLimit() - arg_2_0:getHp()) / arg_2_0:getHpLimit() * 2)
	elseif arg_2_0:hasElementEquipByID(var_0_20) and arg_2_1.skillID == var_0_21 then
		local var_2_1 = var_0_20

		arg_2_5 = var_0_19:battleAttr(var_2_1, arg_2_0:getElementEquipLevelByID(var_2_1)) * arg_2_0.hero_:getElementEquipActiveRate(var_2_1) * arg_2_0:getHpLimit()
	end

	return var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)

	if not arg_3_0.count and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		arg_3_0.isBlueSkillExist = true
		arg_3_0.criticalHp = arg_3_0:getHpLimit() * var_0_4
		arg_3_0.count = true
	end

	if arg_3_0.isSpecialAttack then
		arg_3_0.specialAttackCount = arg_3_0.specialAttackCount - 1

		if arg_3_0.specialAttackCount <= 0 then
			arg_3_0.isSpecialAttack = false
		end

		arg_3_0:specialAttack()
	end
end

function var_0_3.fliterBuffs(arg_4_0, arg_4_1)
	local function var_4_0(arg_5_0)
		for iter_5_0, iter_5_1 in ipairs(arg_5_0) do
			if iter_5_1:getTableID() == var_0_9 then
				return true
			end
		end

		return false
	end

	if arg_4_0:isBreakImmortal() and var_4_0(arg_4_1) then
		return arg_4_1
	else
		return var_0_3.super.fliterBuffs(arg_4_0, arg_4_1)
	end
end

function var_0_3.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	if arg_6_0:isDeath() then
		return var_0_3.super.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	end

	if arg_6_0.isBlueSkillExist and arg_6_1.attackType ~= var_0_2.AttackType.CURE and arg_6_1.attactType ~= var_0_2.AttackType.None then
		local var_6_0 = 1

		if arg_6_1.attackType == var_0_2.AttackType.AD then
			if arg_6_0:getADJianShang() > 1 then
				var_6_0 = 1
			else
				var_6_0 = arg_6_0:getADJianShang()
			end
		elseif arg_6_1.attackType == var_0_2.AttackType.AP then
			var_6_0 = arg_6_0:getAPJianShang() > 1 and 1 or arg_6_0:getAPJianShang()
		end

		local var_6_1 = math.max(0.15, var_6_0)

		arg_6_0.accumulateHarm = arg_6_0.accumulateHarm + arg_6_2 / var_6_1

		if arg_6_0.accumulateHarm >= arg_6_0.criticalHp and arg_6_0.criticalHp > 0 then
			local var_6_2 = math.min(var_0_11, math.floor(arg_6_0.accumulateHarm / arg_6_0.criticalHp))
			local var_6_3 = arg_6_0.accumulateHarm % arg_6_0.criticalHp

			arg_6_0.isSpecialAttack = true
			arg_6_0.specialAttackCount = arg_6_0.specialAttackCount + var_6_2
			arg_6_0.accumulateHarm = var_6_3
		end
	end

	return var_0_3.super.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
end

function var_0_3.specialAttack(arg_7_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_7_0:isDeath() then
		return
	end

	local var_7_0 = {
		arg_7_0
	}
	local var_7_1 = arg_7_0:createAttackUnits(var_7_0, var_0_7)

	for iter_7_0, iter_7_1 in ipairs(var_7_1) do
		table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
		table.insert(arg_7_0.records_.special_units, iter_7_1)
	end

	local var_7_2 = var_0_12.B8(arg_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))
	local var_7_3 = arg_7_0:createAttackUnits(var_7_2, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	for iter_7_2, iter_7_3 in ipairs(var_7_3) do
		table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
		table.insert(arg_7_0.records_.special_units, iter_7_3)
	end

	local var_7_4 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_7_5 = var_0_5:sound(var_7_4)

	var_0_1.ctx.battle.pushSoundQueue(var_7_5)

	arg_7_0.skinAttackCount_ = arg_7_0.skinAttackCount_ + 1

	arg_7_0:updateEnergyBy(var_0_8)
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_0:hasElementEquipByID(var_0_20) and (arg_8_1:getTableID() == var_0_9 or arg_8_1:getTableID() == var_0_10) then
		local var_8_0 = arg_8_1:getTime() * var_0_22

		arg_8_1:setExtraTime(var_8_0)
	end
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_0:hasElementEquipByID(var_0_20) and arg_9_1:getTableID() == var_0_9 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_21)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end
end

return var_0_3
