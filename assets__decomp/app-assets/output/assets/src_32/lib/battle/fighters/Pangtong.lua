local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pangtong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.battleConfig
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.elementEquip
local var_0_10 = 20010239
local var_0_11 = 21010239
local var_0_12 = 10010147
local var_0_13 = 10000340
local var_0_14 = 10000341
local var_0_15 = 10000788
local var_0_16 = 10000789
local var_0_17 = 7
local var_0_18 = 0
local var_0_19 = 3
local var_0_20 = 15
local var_0_21 = 0.5
local var_0_22 = 0.2
local var_0_23 = 10000785
local var_0_24 = 10000786
local var_0_25 = 0.5
local var_0_26 = {
	40010856
}
local var_0_27 = 1
local var_0_28 = 3
local var_0_29 = 5
local var_0_30 = 80010087
local var_0_31 = 20001509
local var_0_32 = 40012754
local var_0_33 = 40012755
local var_0_34 = 40012756
local var_0_35 = 3
local var_0_36 = 5
local var_0_37 = 0.1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.baoji_ = false
	arg_1_0.magicCount_ = 0
	arg_1_0.elementBuffCount = 0
	arg_1_0.elementMagicCount = 0
	arg_1_0.addElementBuff = false

	arg_1_0:updateStateNumber()
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	arg_2_0.isEnergyBuff_ = arg_2_0:isHasBuffByID(var_0_12)
	arg_2_0.isBlueBuff_ = arg_2_0:isHasBuffByID(var_0_10) or arg_2_0:isHasBuffByID(var_0_11)
end

function var_0_3.checkEnergySkill(arg_3_0)
	if arg_3_0.isEnergyBuff_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_3_0)
end

function var_0_3.getOrbOfFrontSkill(arg_4_0)
	local var_4_0 = arg_4_0:getFrontSkill()

	if arg_4_0.isEnergyBuff_ then
		if var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_4_0.magicCount_ > 0 then
			var_4_0 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
		end

		local var_4_1 = var_0_6:buffOrb(var_4_0)

		if var_4_1 > 0 and arg_4_0:getSkillLevelByID(var_4_1) > 0 then
			if arg_4_0.baoji_ then
				if arg_4_0.isSkinSkillOn_ then
					return var_0_16
				end

				return var_0_14
			else
				return var_4_1
			end
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_4_0)
end

function var_0_3.popSkillByType(arg_5_0)
	if arg_5_0.isEnergyBuff_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_5_0:baojiPredict()
	end

	return var_0_3.super.popSkillByType(arg_5_0)
end

function var_0_3.baojiPredict(arg_6_0)
	local var_6_0 = arg_6_0:getNearestTarget()

	if not var_6_0 then
		return
	end

	local var_6_1 = arg_6_0:getAPBaoJi() / (var_0_5.mokangBaojiParam1 * math.max(var_6_0:getDMoKang() - arg_6_0:getDMoKang(), 0) + var_0_5.mokangBaojiParam2)
	local var_6_2 = math.min(1, var_6_1)

	if var_0_2.weightedChoise({
		var_6_2,
		1 - var_6_2
	}) == 1 then
		arg_6_0.baoji_ = true
	end
end

function var_0_3.calculateUnitData(arg_7_0, arg_7_1)
	if arg_7_1.skillID == var_0_13 or arg_7_1.skillID == var_0_14 or arg_7_1.skillID == var_0_15 or arg_7_1.skillID == var_0_16 then
		arg_7_0.baoji_ = false

		local var_7_0 = (arg_7_1.skillID == var_0_14 or arg_7_1.skillID == var_0_16) and 1 or 0

		return arg_7_1:calculateWithSpecialData(nil, var_7_0)
	end

	return var_0_3.super.calculateUnitData(arg_7_0, arg_7_1)
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	local var_8_0 = arg_8_1.target

	if var_8_0:isDeath() then
		return
	end

	if var_0_6:father(arg_8_1.skillID) == arg_8_0:getEnergySkillID() and var_8_0 == arg_8_0 then
		arg_8_0.baoji_ = true

		arg_8_0:updateMagicCount(5)
	end
end

function var_0_3.getSkinChildSkillTargets(arg_9_0, arg_9_1)
	if not arg_9_1 then
		return {}
	end

	local var_9_0 = {}
	local var_9_1 = var_0_6:scope(var_0_24) / 2
	local var_9_2, var_9_3 = arg_9_1:getPos()

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		local var_9_4, var_9_5 = iter_9_1:getPos()

		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and var_9_1 >= math.abs(var_9_2 - var_9_4) and iter_9_1 ~= arg_9_1 then
			table.insert(var_9_0, iter_9_1)
		end
	end

	return var_9_0
end

function var_0_3.getAP(arg_10_0)
	local var_10_0 = arg_10_0.magicCount_ * (var_0_18 + var_0_19 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

	return var_0_3.super.getAP(arg_10_0) + var_10_0
end

function var_0_3.getUnitData(arg_11_0, arg_11_1)
	local var_11_0
	local var_11_1
	local var_11_2
	local var_11_3
	local var_11_4
	local var_11_5

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = unpack(arg_11_1.reportData_.calculate[tostring(var_0_1.ctx.battle.count)])

		if (var_0_6:father(arg_11_1.skillID) == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_11_1.skillID == var_0_13 or arg_11_1.skillID == var_0_14 or arg_11_1.skillID == var_0_15 or arg_11_1.skillID == var_0_16) and arg_11_0.magicCount_ > 0 then
			arg_11_0:updateMagicCount(-1)
		end
	else
		var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = arg_11_0:calculateUnitData(arg_11_1)
		var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = arg_11_1.target:updateUnitDataByTargetHunqi(arg_11_1, var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)
		var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = arg_11_1.target:updateUnitDataByTarget(arg_11_1, var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)

		if not var_0_6:isReflect(arg_11_1.skillID) then
			var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = arg_11_0:updateUnitDataByFighterElement(arg_11_1, var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)
			var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = arg_11_0:updateUnitDataByFighterHunqi(arg_11_1, var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)
			var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = arg_11_0:updateUnitDataByFighter(arg_11_1, var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)
		end

		for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
			if not iter_11_1:isDeath() and not var_0_6:isTriggerSkill(arg_11_1.skillID) and not var_0_6:isReflect(arg_11_1.skillID) then
				var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = iter_11_1:updateUnitDataBySpecialHero(arg_11_1, var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)
			end
		end

		for iter_11_2, iter_11_3 in ipairs(arg_11_0.sideTeam_) do
			if not iter_11_3:isDeath() and not var_0_6:isTriggerSkill(arg_11_1.skillID) and not var_0_6:isReflect(arg_11_1.skillID) then
				var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = iter_11_3:updateUnitDataBySpecialHero(arg_11_1, var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)
			end
		end

		arg_11_1:recordData(var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5)
		arg_11_0:useSkinXixue(arg_11_1, var_11_2)
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.useSkinXixue(arg_12_0, arg_12_1, arg_12_2)
	if not arg_12_0.isSkinSkillOn_ or arg_12_0.magicCount_ < var_0_27 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_12_2 > 0 and (arg_12_1.skillID == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_12_1.skillID == var_0_13 or arg_12_1.skillID == var_0_14 or arg_12_1.skillID == var_0_15 or arg_12_1.skillID == var_0_16 or var_0_24) then
		local var_12_0 = arg_12_0:createAttackUnits({
			arg_12_0
		}, var_0_23)
		local var_12_1 = arg_12_2 * var_0_22

		for iter_12_0, iter_12_1 in ipairs(var_12_0) do
			iter_12_1.change_cure = var_12_1

			table.insert(arg_12_0.moveAttackUnits_, iter_12_1)
			table.insert(arg_12_0.records_.special_units, iter_12_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	local var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5 = var_0_3.super.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)

	if var_13_2 > 0 and arg_13_0.isSkinSkillOn_ and arg_13_0.magicCount_ >= var_0_28 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_13_1 and (var_0_6:father(arg_13_1.skillID) == arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_13_1.skillID == var_0_16) then
		local var_13_6 = arg_13_0:getSkinChildSkillTargets(arg_13_1.target)
		local var_13_7 = arg_13_0:createAttackUnits(var_13_6, var_0_24)
		local var_13_8 = var_0_25 * var_13_2

		for iter_13_0, iter_13_1 in ipairs(var_13_7) do
			iter_13_1.change_harm = var_13_8

			table.insert(arg_13_0.moveAttackUnits_, iter_13_1)
			table.insert(arg_13_0.records_.special_units, iter_13_1)
		end
	end

	if var_0_6:father(arg_13_1.skillID) == arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_13_1.skillID == var_0_13 or arg_13_1.skillID == var_0_14 or arg_13_1.skillID == var_0_15 or arg_13_1.skillID == var_0_16 then
		if arg_13_0.magicCount_ > 0 then
			arg_13_0:updateMagicCount(-1)
		else
			var_13_2 = var_13_2 * 0.5
		end
	elseif arg_13_1.skillID == var_0_23 and arg_13_1.change_cure and arg_13_1.change_cure > 0 then
		var_13_3 = var_13_3 + arg_13_1.change_cure
	elseif arg_13_1.skillID == var_0_24 and arg_13_1.change_harm and arg_13_1.change_harm > 0 then
		var_13_2 = var_13_2 + arg_13_1.change_harm * arg_13_1.target:getAPJianShang()
	end

	return var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5
end

function var_0_3.applyHurtFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5)
	if var_0_6:type(arg_14_1.skillID) == var_0_2.AttackType.AP and arg_14_2 > 0 and arg_14_0.isBlueBuff_ and not arg_14_0:isDeath() then
		arg_14_0:updateMagicCount(1)

		local var_14_0 = arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_21 + var_0_20

		arg_14_0:updateEnergyBy(var_14_0)
	end

	return var_0_3.super.applyHurtFighter(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5)
end

function var_0_3.updateStateNumber(arg_15_0, arg_15_1)
	var_0_3.super.updateStateNumber(arg_15_0, arg_15_1)

	if arg_15_1 and arg_15_0.isSkinSkillOn_ then
		if arg_15_1 >= var_0_29 and not arg_15_0:isHasBuffByID(var_0_26[1]) then
			local var_15_0 = arg_15_0:newBuff(var_0_26, arg_15_0, arg_15_0:getEnergySkillID())

			arg_15_0:addBuffs(var_15_0)
		elseif arg_15_1 < var_0_29 and arg_15_0:isHasBuffByID(var_0_26[1]) then
			for iter_15_0 = 1, #var_0_26 do
				arg_15_0:removeBuffByID(var_0_26[iter_15_0])
			end
		end
	end
end

function var_0_3.updateMagicCount(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.magicCount_

	arg_16_0.magicCount_ = arg_16_0.magicCount_ + arg_16_1
	arg_16_0.magicCount_ = math.min(arg_16_0.magicCount_, var_0_17)
	arg_16_0.magicCount_ = math.max(arg_16_0.magicCount_, 0)

	local var_16_1 = arg_16_0.magicCount_

	arg_16_0:updateStateNumber(var_16_1)

	if arg_16_0:hasElementEquipByID(var_0_31) and var_16_1 < var_16_0 then
		arg_16_0.elementMagicCount = arg_16_0.elementMagicCount + var_16_0 - var_16_1

		if arg_16_0.elementBuffCount < var_0_36 and math.floor(arg_16_0.elementMagicCount / var_0_35) > arg_16_0.elementBuffCount then
			local var_16_2 = arg_16_0:createNewBuffs({
				var_0_32
			}, arg_16_0, var_0_30)

			arg_16_0:addBuffs(var_16_2)
		end
	end
end

function var_0_3.newBuff(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	local var_17_0 = {}

	for iter_17_0, iter_17_1 in ipairs(arg_17_1) do
		local var_17_1 = var_0_4.new({
			tableID = iter_17_1,
			start = var_0_1.ctx.battle.count,
			level = arg_17_0:getSkillLevelByID(arg_17_3),
			skillID = arg_17_3,
			fighter = arg_17_0,
			target = arg_17_2
		})

		var_17_1:setIsHit(true)
		var_17_1:setDirection(arg_17_0:getFighterModel():getFlipX())
		table.insert(var_17_0, var_17_1)
	end

	return var_17_0
end

function var_0_3.toDoPerFrames(arg_18_0)
	if arg_18_0:isDeath() then
		return
	end

	if not arg_18_0.addElementBuff and arg_18_0:hasElementEquipByID(var_0_31) then
		arg_18_0.addElementBuff = true

		local var_18_0 = arg_18_0:createNewBuffs({
			var_0_33
		}, arg_18_0, var_0_30)

		arg_18_0:addBuffs(var_18_0)
	end
end

function var_0_3.neverDieFeedBack(arg_19_0, arg_19_1)
	if arg_19_1 == arg_19_0 then
		local var_19_0 = arg_19_0:createNewBuffs({
			var_0_34
		}, arg_19_0, var_0_30)

		var_19_0[1].manualDharm = arg_19_0:getHpLimit() * var_0_37

		arg_19_0:addBuffs(var_19_0)
		arg_19_0:updateMagicCount(var_0_17)
	end
end

function var_0_3.buffAddAction(arg_20_0, arg_20_1)
	var_0_3.super.buffAddAction(arg_20_0, arg_20_1)

	if arg_20_1:getTableID() == var_0_32 then
		local var_20_0 = var_0_31

		arg_20_1.manualRevise = var_0_9:battleAttr(var_20_0, arg_20_0:getElementEquipLevelByID(var_20_0)) * arg_20_0.hero_:getElementEquipActiveRate(var_20_0)
	end
end

return var_0_3
