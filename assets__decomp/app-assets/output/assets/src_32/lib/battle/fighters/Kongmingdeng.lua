local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Kongmingdeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.02
local var_0_7 = 0.2
local var_0_8 = 10001238
local var_0_9 = 600
local var_0_10 = 0.05
local var_0_11 = 180
local var_0_12 = 43
local var_0_13 = 48
local var_0_14 = 1.2
local var_0_15 = 400
local var_0_16 = 40011325
local var_0_17 = 2
local var_0_18 = {
	40011315,
	40011323,
	40011324
}
local var_0_19 = 0.2
local var_0_20 = 0.001
local var_0_21 = 0.1
local var_0_22 = 0.2
local var_0_23 = 80010200
local var_0_24 = 0.1
local var_0_25 = 20000
local var_0_26 = 40011313
local var_0_27 = 40011314
local var_0_28 = 40011315
local var_0_29 = 40011934
local var_0_30 = 40011935
local var_0_31 = 40011936
local var_0_32 = var_0_2.tables.elementEquip
local var_0_33 = 20001454
local var_0_34 = 40012323
local var_0_35 = math.abs

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyHarmRecords = {}
	arg_2_0.energyRate = {}
	arg_2_0.blueEffect_ = nil
	arg_2_0.blueCount = 0
	arg_2_0.bluePosX_ = 0
	arg_2_0.bluePosY_ = 0
	arg_2_0.isAddPurpleBuff = false
	arg_2_0.purpleTargets = {}
	arg_2_0.purpleCount = 0
	arg_2_0.blueAfterCount_ = 0
	arg_2_0.skinMarkTargets_ = {}
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.isSkinSkillOn_ then
		arg_3_0.ENERGY_LAMP_BUFF = var_0_29
		arg_3_0.BLUE_LAMP_BUFF = var_0_30
		arg_3_0.PURPLE_LAMP_BUFF = var_0_31
	else
		arg_3_0.ENERGY_LAMP_BUFF = var_0_26
		arg_3_0.BLUE_LAMP_BUFF = var_0_27
		arg_3_0.PURPLE_LAMP_BUFF = var_0_28
	end
end

function var_0_3.isLamp(arg_4_0, arg_4_1)
	if arg_4_1:getBuffByID(arg_4_0.ENERGY_LAMP_BUFF) or arg_4_1:getBuffByID(arg_4_0.BLUE_LAMP_BUFF) or arg_4_1:getBuffByID(arg_4_0.PURPLE_LAMP_BUFF) then
		return true
	end

	return false
end

function var_0_3.checkIsInBlueEffect(arg_5_0, arg_5_1)
	if arg_5_0.blueEffect_ and arg_5_0.bluePosX_ ~= 0 and not arg_5_1:isDeath() and not arg_5_1:isAffected() and arg_5_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
		if var_0_35(arg_5_1:getX() - arg_5_0.bluePosX_) < var_0_15 / 2 then
			return true
		else
			return false
		end
	end

	return false
end

function var_0_3.moveUnitArrive(arg_6_0, arg_6_1)
	if arg_6_1.resource then
		arg_6_1.resource:stop()
	end

	arg_6_1:arrive()

	if arg_6_1:getAreaResource() then
		local var_6_0 = arg_6_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_6_1.fighter:getY() or arg_6_1.desY_
		local var_6_1 = arg_6_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_6_1.fighter:getX() or arg_6_1.desX_

		arg_6_1:getAreaResource():addTo(var_0_1.ctx.battle.unitLayer)

		if var_0_5:father(arg_6_1.skillID) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			arg_6_0.bluePosX_ = var_6_1
			var_6_0 = 550
			arg_6_0.bluePosY_ = var_6_0
			arg_6_0.blueEffect_ = arg_6_1:getAreaResource()

			arg_6_0.blueEffect_:setVisible(true)

			arg_6_0.blueCount = var_0_13 + var_0_14 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		end

		arg_6_1:getAreaResource():pos(var_6_1, var_6_0)
		arg_6_1:getAreaResource():playOnce()
		arg_6_1:getAreaResource():flipX(arg_6_1.fighter:getX() > arg_6_1.desX_)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_6_2 = arg_6_1:getReportUnits()

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			table.insert(arg_6_0.applyUnits_, iter_6_1)
		end
	else
		local var_6_3 = arg_6_0:getTargets(arg_6_1.skillID, arg_6_1)

		if next(var_6_3) then
			local var_6_4 = arg_6_1:createAttacks(var_6_3)

			for iter_6_2, iter_6_3 in ipairs(var_6_4) do
				table.insert(arg_6_0.applyUnits_, iter_6_3)
			end
		end
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	local var_7_0, var_7_1, var_7_2, var_7_3 = var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)

	if arg_7_0:isCreatingUnits() and var_0_5:father(arg_7_0.unitSkills_.rootID_) == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		var_7_3 = true
	end

	return var_7_0, var_7_1, var_7_2, var_7_3
end

function var_0_3.getLampNum(arg_8_0)
	local var_8_0 = 0

	for iter_8_0, iter_8_1 in pairs(arg_8_0.selfTeam_) do
		if arg_8_0:isLamp(iter_8_1) then
			var_8_0 = var_8_0 + 1
		end
	end

	for iter_8_2, iter_8_3 in pairs(arg_8_0.sideTeam_) do
		if arg_8_0:isLamp(iter_8_3) then
			var_8_0 = var_8_0 + 1
		end
	end

	return var_8_0
end

function var_0_3.toDoPerFrames(arg_9_0)
	var_0_3.super.toDoPerFrames(arg_9_0)

	for iter_9_0, iter_9_1 in ipairs(arg_9_0:getInfoByKey("harm_info")) do
		if iter_9_1.target and iter_9_1.target:getBuffByID(arg_9_0.ENERGY_LAMP_BUFF) and iter_9_1.harm and iter_9_1.harm > 0 then
			if arg_9_0.energyHarmRecords[iter_9_1.target] then
				arg_9_0.energyHarmRecords[iter_9_1.target] = arg_9_0.energyHarmRecords[iter_9_1.target] + iter_9_1.harm
			else
				arg_9_0.energyHarmRecords[iter_9_1.target] = iter_9_1.harm
			end
		end

		if arg_9_0.isSkinSkillOn_ and iter_9_1.skillID ~= var_0_23 and iter_9_1.harm > 0 and iter_9_1.type == var_0_2.AttackType.AP and iter_9_1.fighter:getTeamType() == arg_9_0:getTeamType() and iter_9_1.target:getTeamType() ~= arg_9_0:getTeamType() then
			for iter_9_2, iter_9_3 in pairs(arg_9_0.sideTeam_) do
				if arg_9_0:isLamp(iter_9_3) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_9_0 = arg_9_0:createAttackUnits({
						iter_9_3
					}, var_0_23)

					for iter_9_4, iter_9_5 in ipairs(var_9_0) do
						iter_9_5.skin_harm = math.min(iter_9_1.harm * var_0_24, var_0_25)

						table.insert(arg_9_0.moveAttackUnits_, iter_9_5)
						table.insert(arg_9_0.records_.special_units, iter_9_5)
					end
				end
			end
		end
	end

	for iter_9_6, iter_9_7 in pairs(arg_9_0.energyHarmRecords) do
		if iter_9_6:getBuffByID(arg_9_0.ENERGY_LAMP_BUFF) and iter_9_7 >= iter_9_6:getHpLimit() * var_0_7 then
			iter_9_6:removeBuffByID(arg_9_0.ENERGY_LAMP_BUFF)
		end
	end

	if arg_9_0.blueCount > 0 then
		arg_9_0.blueCount = arg_9_0.blueCount - 1

		if arg_9_0.blueCount <= 0 then
			arg_9_0.bluePosX_ = 0
			arg_9_0.bluePosY_ = 0
			arg_9_0.blueCount = 0

			arg_9_0:finishBlueEffect()
		else
			arg_9_0:addOrRemoveBlueBuff()
		end
	end

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_9_0.isAddPurpleBuff then
		arg_9_0.isAddPurpleBuff = true

		for iter_9_8, iter_9_9 in ipairs(arg_9_0.selfTeam_) do
			if not iter_9_9:isDeath() and iter_9_9:getSummonType() == var_0_2.summonMonsterType.None and iter_9_9 ~= arg_9_0 then
				local var_9_1 = arg_9_0:createNewBuffs({
					var_0_16
				}, iter_9_9, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

				iter_9_9:addBuffs(var_9_1)
			end
		end
	end

	if arg_9_0.blueAfterCount_ and arg_9_0.blueAfterCount_ > 0 then
		arg_9_0.blueAfterCount_ = arg_9_0.blueAfterCount_ - 1

		if arg_9_0.blueAfterCount_ <= 0 then
			arg_9_0:removeAllBlueBuffs()
		end
	end

	if var_0_1.ctx.battle.count % 10 == 0 and arg_9_0:hasElementEquipByID(var_0_33) and not arg_9_0:isDeath() then
		for iter_9_10, iter_9_11 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_11:isDeath() and iter_9_11:getSummonType() == var_0_2.summonMonsterType.None and iter_9_11 ~= arg_9_0 and iter_9_11:getHp() <= iter_9_11:getHpLimit() * var_0_21 and not arg_9_0.skinMarkTargets_[iter_9_11] then
				local var_9_2 = var_0_33
				local var_9_3 = var_0_32:battleAttr(var_9_2, arg_9_0:getElementEquipLevelByID(var_9_2))
				local var_9_4 = var_0_32:skillIDs(var_9_2)
				local var_9_5 = var_0_32:buffIDs(var_9_2)
				local var_9_6 = arg_9_0.hero_:getElementEquipActiveRate(var_9_2)
				local var_9_7 = arg_9_0:createNewBuffs(var_9_5, iter_9_11, var_9_4[1])

				for iter_9_12, iter_9_13 in ipairs(var_9_7) do
					iter_9_13:setExtraTime(var_9_3 * var_9_6)
				end

				iter_9_11:addBuffs(var_9_7)

				arg_9_0.skinMarkTargets_[iter_9_11] = true
			end
		end
	end

	if var_0_1.ctx.battle.count % 10 == 0 and arg_9_0:hasElementEquipByID(var_0_33) then
		for iter_9_14, iter_9_15 in pairs(arg_9_0.skinMarkTargets_) do
			if iter_9_15 and not iter_9_14:isDeath() and iter_9_14:isHasBuffByID(var_0_34) and iter_9_14:getHp() >= iter_9_14:getHpLimit() * var_0_22 then
				iter_9_14:setHp(iter_9_14:getHpLimit() * var_0_22)
			end
		end
	end
end

function var_0_3.addPurpleBuffs(arg_10_0, arg_10_1)
	for iter_10_0, iter_10_1 in pairs(var_0_18) do
		local var_10_0 = var_0_4.new({
			tableID = arg_10_0.PURPLE_LAMP_BUFF,
			start = var_0_1.ctx.battle.count,
			level = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			skillID = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_10_0,
			target = arg_10_1
		})

		arg_10_1:addBuffs({
			var_10_0
		})
	end
end

function var_0_3.neverDieFeedBack(arg_11_0, arg_11_1)
	if arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) and not arg_11_0.purpleTargets[arg_11_1] and arg_11_0.purpleCount <= var_0_17 then
		arg_11_1:updateHp(arg_11_1:getHpLimit() * (var_0_19 + var_0_20 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)))
		arg_11_1:removeBuffByID(var_0_16)
		arg_11_0:addPurpleBuffs(arg_11_1)

		arg_11_0.purpleCount = arg_11_0.purpleCount + 1

		if arg_11_0.purpleCount >= var_0_17 then
			for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
				if iter_11_1:isHasBuffByID(var_0_16) then
					iter_11_1:removeBuffByID(var_0_16)
				end
			end
		end
	end
end

function var_0_3.die(arg_12_0)
	var_0_3.super.die(arg_12_0)

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.selfTeam_) do
		if iter_12_1:isHasBuffByID(var_0_16) then
			iter_12_1:removeBuffByID(var_0_16)
		end
	end
end

function var_0_3.removeAllBlueBuffs(arg_13_0)
	for iter_13_0, iter_13_1 in pairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and iter_13_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
			local var_13_0 = iter_13_1:getBuffByID(arg_13_0.BLUE_LAMP_BUFF)

			if var_13_0 and var_13_0.fighter == arg_13_0 then
				iter_13_1:removeBuffByID(arg_13_0.BLUE_LAMP_BUFF)
			end
		end
	end
end

function var_0_3.addOrRemoveBlueBuff(arg_14_0)
	for iter_14_0, iter_14_1 in pairs(arg_14_0.sideTeam_) do
		if not arg_14_0:isLamp(iter_14_1) and not iter_14_1:isDeath() and iter_14_1:getSummonType() ~= var_0_2.summonMonsterType.Pet and not iter_14_1:isBoss() then
			if arg_14_0:checkIsInBlueEffect(iter_14_1) then
				if not iter_14_1:getBuffByID(arg_14_0.BLUE_LAMP_BUFF) then
					local var_14_0 = var_0_4.new({
						tableID = arg_14_0.BLUE_LAMP_BUFF,
						start = var_0_1.ctx.battle.count,
						level = arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
						skillID = arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
						fighter = arg_14_0,
						target = iter_14_1
					})

					iter_14_1:addBuffs({
						var_14_0
					})
				end
			else
				local var_14_1 = iter_14_1:getBuffByID(arg_14_0.BLUE_LAMP_BUFF)

				if var_14_1 and var_14_1.fighter == arg_14_0 then
					iter_14_1:removeBuffByID(arg_14_0.BLUE_LAMP_BUFF)
				end
			end
		end
	end
end

function var_0_3.finishBlueEffect(arg_15_0)
	arg_15_0.blueAfterCount_ = var_0_12

	if arg_15_0.blueEffect_ and var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_15_0.blueEffect_:runActionOnce(cc.FadeOut:create(0.4 / (arg_15_0.timeScale_ or 1)), false, function()
			arg_15_0.blueEffect_:setVisible(false)
			arg_15_0.blueEffect_:setOpacity(255)

			arg_15_0.blueEffect_ = nil
		end, 1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7)
	local var_17_0, var_17_1, var_17_2, var_17_3, var_17_4, var_17_5 = var_0_3.super.updateUnitDataByFighter(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7)

	if arg_17_1.skillID == var_0_8 and arg_17_0.energyRate[arg_17_1.buffTarget] then
		var_17_2 = var_17_2 * (arg_17_0.energyRate[arg_17_1.buffTarget] + 1)
		arg_17_0.energyHarmRecords[arg_17_1.target] = nil
	end

	if var_0_5:father(arg_17_1.skillID) == arg_17_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		var_17_2 = var_17_2 * (1 + arg_17_0:getLampNum() * var_0_10)
	end

	if arg_17_1.skillID == var_0_23 then
		var_17_2 = arg_17_1.skin_harm

		if arg_17_1.target:isHasBuffByID(arg_17_0.ENERGY_LAMP_BUFF) then
			var_17_2 = 2 * var_17_2
		end
	end

	return var_17_0, var_17_1, var_17_2, var_17_3, var_17_4, var_17_5
end

function var_0_3.buffRemoveAction(arg_18_0, arg_18_1)
	var_0_3.super.buffRemoveAction(arg_18_0, arg_18_1)

	if arg_18_1.tableID_ == arg_18_0.ENERGY_LAMP_BUFF and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_18_0.energyHarmRecords[arg_18_1.target] then
			local var_18_0 = math.ceil(arg_18_0.energyHarmRecords[arg_18_1.target] / (arg_18_1.target:getHpLimit() / 100))

			if var_18_0 > var_0_7 / 0.01 then
				var_18_0 = var_0_7 / 0.01
			end

			arg_18_0.energyRate[arg_18_1.target] = var_18_0 * var_0_6
		end

		local var_18_1 = arg_18_0:createAttackUnits(arg_18_0:getEnergyHarmTargets(arg_18_1.target), var_0_8)

		for iter_18_0, iter_18_1 in ipairs(var_18_1) do
			iter_18_1.buffTarget = arg_18_1.target

			table.insert(arg_18_0.moveAttackUnits_, iter_18_1)
			table.insert(arg_18_0.records_.special_units, iter_18_1)
		end
	end
end

function var_0_3.getEnergyHarmTargets(arg_19_0, arg_19_1)
	local var_19_0 = {}

	for iter_19_0, iter_19_1 in pairs(arg_19_0.sideTeam_) do
		if not iter_19_1:isDeath() and not iter_19_1:isAffected() and var_0_35(iter_19_1:getX() - arg_19_1:getX()) < var_0_9 / 2 then
			table.insert(var_19_0, iter_19_1)
		end
	end

	return var_19_0
end

function var_0_3.selectTargetByTypeD1(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0
	local var_20_1

	for iter_20_0, iter_20_1 in ipairs(arg_20_0.sideTeam_) do
		if not iter_20_1:isDeath() and not iter_20_1:isAffected() and iter_20_1:getSummonType() == var_0_2.summonMonsterType.None and not arg_20_0:isLamp(iter_20_1) and not iter_20_1:isBoss() and (not var_20_1 or var_20_1 < iter_20_1.harms) then
			var_20_0 = iter_20_1
			var_20_1 = iter_20_1.harms
		end
	end

	return {
		var_20_0
	}
end

return var_0_3
