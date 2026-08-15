local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Bulianshi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 10000413
local var_0_9 = {
	40010122
}
local var_0_10 = {
	40010131
}
local var_0_11 = 80010102
local var_0_12 = 10001154
local var_0_13 = 300
local var_0_14 = 40011263
local var_0_15 = 40010134
local var_0_16 = 40010135
local var_0_17 = 40011265
local var_0_18 = 80020102
local var_0_19 = 10002089
local var_0_20 = 10002071
local var_0_21 = 0.25
local var_0_22 = 0.4
local var_0_23 = var_0_2.tables.elementEquip
local var_0_24 = 20001487
local var_0_25 = {
	40012549,
	40012550
}
local var_0_26 = {
	40012551,
	40012552
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 2 then
		arg_2_0.EnergyFirstSkill = 10002074
		arg_2_0.EnergySecondSkill = 10002075
		arg_2_0.EnergyLastSkill = 10002076
		arg_2_0.PurpleExtraSkill = 10002073
	else
		arg_2_0.EnergyFirstSkill = 10000407
		arg_2_0.EnergySecondSkill = 10000408
		arg_2_0.EnergyLastSkill = 10000409
		arg_2_0.PurpleExtraSkill = 10000406
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.flyTime_ = nil
	arg_3_0.dropTime1_ = nil
	arg_3_0.dropTime2_ = nil
	arg_3_0.flyTarget_ = nil
	arg_3_0.dropTarget_ = nil
	arg_3_0.energyTarget_ = nil
	arg_3_0.skinTarget_ = nil
	arg_3_0.skin2ExtraHarm_ = 0
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.flyTime_ then
		arg_4_0:attackFly(arg_4_0.flyTarget_)

		arg_4_0.flyTime_ = math.max(0, arg_4_0.flyTime_ - 1)

		if arg_4_0.flyTime_ == 0 then
			arg_4_0.flyTime_ = nil
			arg_4_0.flyTarget_ = nil
		end
	end

	if arg_4_0.dropTime1_ or arg_4_0.dropTime2_ then
		arg_4_0:attackDrop(arg_4_0.dropTarget_)

		if arg_4_0.dropTime1_ > 0 then
			arg_4_0.dropTime1_ = math.max(0, arg_4_0.dropTime1_ - 1)
		else
			arg_4_0.dropTime2_ = math.max(0, arg_4_0.dropTime2_ - 1)
		end

		if arg_4_0.dropTime2_ == 0 then
			arg_4_0.dropTime2_ = nil
			arg_4_0.dropTime1_ = nil
			arg_4_0.dropTarget_ = nil
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			local var_4_0 = iter_4_1.target

			if var_4_0 and not var_4_0:isDeath() and not var_4_0:isAffected() and var_4_0:getTeamType() ~= arg_4_0:getTeamType() and arg_4_0:isFlyBuff(iter_4_1) then
				arg_4_0:addExtraPurpleSkill(iter_4_1.target)
			end
		end
	end

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_11 and var_0_1.ctx.battle.count > 0 and var_0_1.ctx.battle.count % var_0_13 == 0 then
		if arg_4_0.skinTarget_ then
			arg_4_0.skinTarget_:removeBuffByID(var_0_15)
			arg_4_0.skinTarget_:removeBuffByID(var_0_16)
			arg_4_0.skinTarget_:removeBuffByID(var_0_17)
		end

		local var_4_1 = 1

		for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfTeam_) do
			if iter_4_3 ~= arg_4_0 and iter_4_3:getSummonType() == var_0_2.summonMonsterType.None and (not arg_4_0.skinTarget_ or var_4_1 > iter_4_3:getHp() / iter_4_3:getHpLimit()) then
				arg_4_0.skinTarget_ = iter_4_3
				var_4_1 = iter_4_3:getHp() / iter_4_3:getHpLimit()
			end
		end

		if arg_4_0.skinTarget_ then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_2 = arg_4_0:createAttackUnits({
					arg_4_0.skinTarget_
				}, var_0_12)

				for iter_4_4, iter_4_5 in ipairs(var_4_2) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
					table.insert(arg_4_0.records_.special_units, iter_4_5)
				end
			end

			for iter_4_6, iter_4_7 in ipairs(arg_4_0:getBuffs()) do
				if iter_4_7:getTableID() == var_0_15 or iter_4_7:getTableID() == var_0_16 or iter_4_7:getTableID() == var_0_17 then
					local var_4_3 = var_0_4.new({
						tableID = iter_4_7:getTableID(),
						start = var_0_1.ctx.battle.count,
						level = arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
						skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
						fighter = arg_4_0,
						target = arg_4_0.skinTarget_
					})

					arg_4_0.skinTarget_:addBuffs({
						var_4_3
					})
				end
			end
		end
	end
end

function var_0_3.isFlyBuff(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1:getTableID()

	if var_0_6:type(var_5_0) == var_0_2.BuffType.MOVE and var_0_6:y(var_5_0) > 0 then
		return true
	else
		return false
	end
end

function var_0_3.attackFly(arg_6_0, arg_6_1)
	if not arg_6_1:isDeath() then
		if arg_6_0.flyTime_ <= 4 then
			arg_6_1:moveByY(-arg_6_0.flySpeed_)
		else
			arg_6_1:moveByY(arg_6_0.flySpeed_)
		end

		if not arg_6_0.flyBuff_ and arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_6_0.flyBuff_ = true

			arg_6_0:addExtraPurpleSkill(arg_6_1)
		end
	end
end

function var_0_3.attackDrop(arg_7_0, arg_7_1)
	if not arg_7_1:isDeath() then
		if arg_7_0.dropTime1_ > 0 then
			arg_7_1:moveByY(arg_7_0.dropSpeed1_)
		else
			arg_7_1:moveByY(-arg_7_0.dropSpeed2_)
		end

		if not arg_7_0:getFlipX() and arg_7_1:getX() < var_0_2.STAGE_WIDTH then
			arg_7_1:moveByX(17)
		elseif arg_7_0:getFlipX() and arg_7_1:getX() > 0 then
			arg_7_1:moveByY(-17)
		end

		if not arg_7_0.dropBuff_ and arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_7_0.dropBuff_ = true

			arg_7_0:addExtraPurpleSkill(arg_7_1)
		end
	end
end

function var_0_3.addExtraPurpleSkill(arg_8_0, arg_8_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_8_0:isDeath() then
		return
	end

	local var_8_0 = {
		arg_8_1
	}
	local var_8_1 = arg_8_0:createAttackUnits(var_8_0, arg_8_0.PurpleExtraSkill)

	for iter_8_0, iter_8_1 in ipairs(var_8_1) do
		table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
		table.insert(arg_8_0.records_.special_units, iter_8_1)
	end

	local var_8_2 = {
		arg_8_0
	}
	local var_8_3 = arg_8_0:createAttackUnits(var_8_2, var_0_8)

	for iter_8_2, iter_8_3 in ipairs(var_8_3) do
		table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
		table.insert(arg_8_0.records_.special_units, iter_8_3)
	end
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	var_0_3.super.deathFeedback(arg_9_0, arg_9_1)

	if arg_9_1 == arg_9_0.energyTarget_ then
		arg_9_0:addBuffs(arg_9_0:newBuff(var_0_10, arg_9_0, arg_9_0:getEnergySkillID()))
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	if arg_10_4 > 0 and arg_10_0.isSkinSkillOn_ and arg_10_0.skinTarget_ and arg_10_0.skinTarget_:isHasBuffByID(var_0_14) and arg_10_1.target == arg_10_0.skinTarget_ then
		arg_10_1.target = arg_10_0
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.die(arg_11_0)
	for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_1:isDeath() and iter_11_1:isHasBuffByID(var_0_14) then
			iter_11_1:removeBuffByID(var_0_14)
		end
	end

	var_0_3.super.die(arg_11_0)
end

function var_0_3.applySingleUnit(arg_12_0, arg_12_1)
	if arg_12_1.skillID == arg_12_0.EnergyFirstSkill then
		arg_12_0.flyTime_ = var_0_5:pretime(arg_12_0.EnergySecondSkill) - var_0_5:pretime(arg_12_0.EnergyFirstSkill)
		arg_12_0.flySpeed_ = (arg_12_0:getY() + 300 - arg_12_1.target:getY()) / arg_12_0.flyTime_
		arg_12_0.flyTarget_ = arg_12_1.target
		arg_12_0.energyTarget_ = arg_12_1.target
		arg_12_0.flyBuff_ = false

		arg_12_1.target:unsetMaskColor()
		arg_12_0:addElementBuff(arg_12_1.target)
		arg_12_0:addSelfTeamElementBuff()
	end

	var_0_3.super.applySingleUnit(arg_12_0, arg_12_1)

	if arg_12_1.skillID == arg_12_0.EnergyLastSkill then
		local var_12_0 = var_0_5:pretime(arg_12_0.EnergySecondSkill) - var_0_5:pretime(arg_12_0.EnergyFirstSkill)

		arg_12_0.dropTime1_ = var_12_0 / 4
		arg_12_0.dropTime2_ = var_12_0 * 3 / 4
		arg_12_0.dropSpeed1_ = 400 / var_12_0
		arg_12_0.dropSpeed2_ = (arg_12_1.target:getY() - arg_12_0:getY() + 100) * 4 / (var_12_0 * 3)
		arg_12_0.dropTarget_ = arg_12_1.target
		arg_12_0.dropBuff_ = false
		arg_12_0.energyTarget_ = nil

		arg_12_0:addElementBuff(arg_12_1.target)
	end

	if arg_12_1.skillID == arg_12_0.EnergySecondSkill then
		arg_12_0:addElementBuff(arg_12_1.target)
	end

	if arg_12_1.skillID == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_12_1.skillID == var_0_19 then
		arg_12_0:addExtraGreenBuff()
		arg_12_0:addElementBuff(arg_12_1.target)
		arg_12_0:addSelfTeamElementBuff()
	end

	if arg_12_0.isSkinSkillOn_ and arg_12_0.skinSkillID_ == var_0_18 and not arg_12_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and next(arg_12_1.target.buffs_) ~= nil then
		for iter_12_0 = #arg_12_1.target.buffs_, 1, -1 do
			local var_12_1 = arg_12_1.target.buffs_[iter_12_0]
			local var_12_2 = arg_12_0:isFlyBuff(var_12_1)

			if var_12_1 and var_12_2 then
				local var_12_3 = arg_12_0:createAttackUnits({
					arg_12_0
				}, var_0_20)

				for iter_12_1, iter_12_2 in ipairs(var_12_3) do
					table.insert(arg_12_0.moveAttackUnits_, iter_12_2)
					table.insert(arg_12_0.records_.special_units, iter_12_2)
				end
			end
		end
	end
end

function var_0_3.addElementBuff(arg_13_0, arg_13_1)
	if arg_13_0:hasElementEquipByID(var_0_24) then
		local var_13_0 = arg_13_0:createNewBuffs(var_0_25, arg_13_1, arg_13_0:getEnergySkillID())

		arg_13_1:addBuffs(var_13_0)
	end
end

function var_0_3.addSelfTeamElementBuff(arg_14_0)
	if arg_14_0:hasElementEquipByID(var_0_24) then
		local var_14_0 = var_0_24
		local var_14_1 = var_0_23:battleAttr(var_14_0, arg_14_0:getElementEquipLevelByID(var_14_0))
		local var_14_2 = arg_14_0.hero_:getElementEquipActiveRate(var_14_0)
		local var_14_3 = arg_14_0:createNewBuffs(var_0_26, arg_14_0, arg_14_0:getEnergySkillID())

		for iter_14_0, iter_14_1 in ipairs(var_14_3) do
			iter_14_1.manualRevise = var_14_1 * var_14_2
		end

		arg_14_0:addBuffs(var_14_3)

		local var_14_4 = arg_14_0:getExtraElementTarget(arg_14_0, arg_14_0:getEnergySkillID())

		for iter_14_2, iter_14_3 in ipairs(var_14_4) do
			if not iter_14_3:isDeath() and not iter_14_3:isAffected() then
				local var_14_5 = arg_14_0:createNewBuffs(var_0_26, iter_14_3, arg_14_0:getEnergySkillID())

				for iter_14_4, iter_14_5 in ipairs(var_14_5) do
					iter_14_5.manualRevise = var_14_1 * var_14_2
				end

				iter_14_3:addBuffs(var_14_5)
			end
		end
	end
end

function var_0_3.getExtraElementTarget(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = var_0_7.A2(arg_15_1, arg_15_2)
	local var_15_1
	local var_15_2

	for iter_15_0, iter_15_1 in pairs(var_15_0) do
		if iter_15_1 ~= arg_15_0 and (not var_15_1 or var_15_2 > iter_15_1:getHp() / iter_15_1:getHpLimit() or var_15_2 == iter_15_1:getHp() / iter_15_1:getHpLimit() and var_15_1:getHp() > iter_15_1:getHp()) then
			var_15_1 = iter_15_1
			var_15_2 = var_15_1:getHp() / var_15_1:getHpLimit()
		end
	end

	if var_15_1 then
		return {
			var_15_1
		}
	else
		return {}
	end
end

function var_0_3.addExtraGreenBuff(arg_16_0)
	for iter_16_0, iter_16_1 in ipairs(arg_16_0.selfTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() then
			iter_16_1:addBuffs(arg_16_0:newBuff(var_0_9, iter_16_1, arg_16_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)))
		end
	end
end

function var_0_3.calculateUnitData(arg_17_0, arg_17_1)
	local var_17_0, var_17_1, var_17_2, var_17_3, var_17_4, var_17_5 = var_0_3.super.calculateUnitData(arg_17_0, arg_17_1)

	if arg_17_1.skillID == arg_17_0.EnergyLastSkill and not var_17_1 and not var_17_0 then
		var_17_1 = true
		var_17_2 = var_17_2 * (arg_17_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_17_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		var_17_2 = var_17_2 * math.max(0.01, arg_17_1.target:getADBaoJiJianShang())
	end

	if arg_17_0.isSkinSkillOn_ and arg_17_0.skinSkillID_ == var_0_18 and not arg_17_1.target:isDeath() and next(arg_17_1.target.buffs_) ~= nil then
		for iter_17_0 = #arg_17_1.target.buffs_, 1, -1 do
			local var_17_6 = arg_17_1.target.buffs_[iter_17_0]
			local var_17_7 = arg_17_0:isFlyBuff(var_17_6)

			if var_17_6 and var_17_7 then
				arg_17_0.skin2ExtraHarm_ = var_17_2 * var_0_21
				var_17_2 = var_17_2 * (1 + var_0_21)
			end
		end
	end

	return var_17_0, var_17_1, var_17_2, var_17_3, var_17_4, var_17_5
end

function var_0_3.updateUnitDataByFighter(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4, arg_18_5, arg_18_6, arg_18_7)
	local var_18_0, var_18_1, var_18_2, var_18_3, var_18_4, var_18_5 = var_0_3.super.updateUnitDataByFighter(arg_18_0, arg_18_1, arg_18_2, arg_18_3, arg_18_4, arg_18_5, arg_18_6, arg_18_7)

	if arg_18_1.skillID == var_0_20 then
		var_18_3 = arg_18_0.skin2ExtraHarm_ * var_0_22
		arg_18_0.skin2ExtraHarm_ = 0
	end

	return var_0_3.super.updateUnitDataByFighter(arg_18_0, arg_18_1, var_18_0, var_18_1, var_18_2, var_18_3, var_18_4, var_18_5)
end

function var_0_3.selectTargetByTypeD1(arg_19_0, arg_19_1, arg_19_2)
	return {
		arg_19_0.energyTarget_
	}
end

function var_0_3.selectTargetByTypeD2(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_0:getX()
	local var_20_1
	local var_20_2
	local var_20_3 = var_0_5:distance(arg_20_1)

	for iter_20_0, iter_20_1 in ipairs(arg_20_0.sideTeam_) do
		if not iter_20_1:isDeath() and not iter_20_1:isAffected() and iter_20_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_20_4 = math.abs(var_20_0 - iter_20_1:getX())

			if var_20_4 <= var_20_3 and (not var_20_1 or var_20_4 < var_20_1) then
				var_20_1 = var_20_4
				var_20_2 = iter_20_1
			end
		end
	end

	return {
		var_20_2
	}
end

function var_0_3.newBuff(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = {}

	for iter_21_0, iter_21_1 in ipairs(arg_21_1) do
		local var_21_1 = var_0_4.new({
			tableID = iter_21_1,
			start = var_0_1.ctx.battle.count,
			level = arg_21_0:getSkillLevelByID(arg_21_3),
			skillID = arg_21_3,
			fighter = arg_21_0,
			target = arg_21_2
		})

		var_21_1:setIsHit(true)
		var_21_1:setDirection(arg_21_0:getFighterModel():getFlipX())
		table.insert(var_21_0, var_21_1)
	end

	return var_21_0
end

function var_0_3.checkEnergySkill(arg_22_0)
	if not next(arg_22_0:selectTargetByTypeD2(arg_22_0:getEnergySkillID())) then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_22_0)
	end
end

return var_0_3
