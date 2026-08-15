local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wenchou", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 5
local var_0_10 = 20010099
local var_0_11 = 20010100
local var_0_12 = 10000157
local var_0_13 = 10000165
local var_0_14 = 10000164
local var_0_15 = 9
local var_0_16 = 0.8
local var_0_17 = -0.004
local var_0_18 = 0.8
local var_0_19 = -0.004
local var_0_20 = 0
local var_0_21 = 0.02
local var_0_22 = 80010051
local var_0_23 = 10000866
local var_0_24 = 10000867
local var_0_25 = 0.2
local var_0_26 = 5
local var_0_27 = 1
local var_0_28 = 10001050
local var_0_29 = 80010050
local var_0_30 = 300
local var_0_31 = 0.3
local var_0_32 = 90
local var_0_33 = 80020051
local var_0_34 = 2
local var_0_35 = 10001050
local var_0_36 = 80020050
local var_0_37 = 10010081
local var_0_38 = var_0_2.tables.elementEquip
local var_0_39 = 20001455
local var_0_40 = 10002183
local var_0_41 = 0.2
local var_0_42 = 40012334
local var_0_43 = 40012335

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energySkilled_ = nil
	arg_1_0.leftCount_ = nil
	arg_1_0.shanbiCount_ = 0
	arg_1_0.harmSkills_ = {}
	arg_1_0.harmBuffs_ = {}
	arg_1_0.extraAp_ = 0
	arg_1_0.skinKillGasNum_ = 0
	arg_1_0.skinAddHarmRate_ = 0
	arg_1_0.records_.skin_add_gas = {}
	arg_1_0.skinAddGas = {}
	arg_1_0.skinWenchouJudgeDelay_ = 2
	arg_1_0.skinWenchouJudge_ = false
	arg_1_0.skinPartner_ = nil
	arg_1_0.skinWaitTimeCount_ = 0
	arg_1_0.skinSkillCD_ = 0
	arg_1_0.isSkinSkillType_ = false
	arg_1_0.skinShowEffect_ = nil
	arg_1_0.skin2Partner_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.skinWenchouJudge_ then
		if arg_2_0.skinWenchouJudgeDelay_ > 0 then
			arg_2_0.skinWenchouJudgeDelay_ = arg_2_0.skinWenchouJudgeDelay_ - 1
		else
			arg_2_0.skinWenchouJudge_ = true

			for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
				if iter_2_1.hero_:getTableID() == var_0_28 or iter_2_1.hero_:beforeAwakenID() == var_0_28 then
					if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_22 and iter_2_1.isSkinSkillOn_ and iter_2_1.skinSkillID_ == var_0_29 then
						arg_2_0.skinPartner_ = iter_2_1
						iter_2_1.skinPartner_ = arg_2_0

						if not iter_2_1.skinKillGasNum_ or iter_2_1.skinKillGasNum_ < arg_2_0.skinKillGasNum_ then
							iter_2_1.skinKillGasNum_ = arg_2_0.skinKillGasNum_
						end
					end

					if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_33 and iter_2_1.isSkinSkillOn_ and iter_2_1.skinSkillID_ == var_0_36 then
						arg_2_0.skin2Partner_ = iter_2_1
						iter_2_1.skin2Partner_ = arg_2_0
					end

					break
				end
			end
		end
	end

	if arg_2_0.skinKillGasNum_ >= var_0_26 and arg_2_0:canUseSkinSkill() then
		arg_2_0:useSkinSkill()
	end

	if var_0_1.ctx.battle.walk2NextBattle_ and arg_2_0.skinKillGasNum_ > 0 then
		arg_2_0.skinKillGasNum_ = 0

		arg_2_0:updateStateNumber()
	end

	if arg_2_0:hasElementEquipByID(var_0_39) and var_0_1.ctx.battle.count % 30 == 0 then
		if arg_2_0:isHasBuffByID(var_0_43) then
			local var_2_0 = var_0_39
			local var_2_1 = var_0_38:battleAttr(var_2_0, arg_2_0:getElementEquipLevelByID(var_2_0))
			local var_2_2 = arg_2_0.hero_:getElementEquipActiveRate(var_2_0)
			local var_2_3 = math.abs(var_2_1 * var_2_2)
			local var_2_4 = 0
			local var_2_5 = 0

			for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
				if not iter_2_3:isDeath() then
					if iter_2_3:getBuffsByID(var_0_42) then
						var_2_4 = var_2_4 + var_2_3 * #iter_2_3:getBuffsByID(var_0_42)
					end

					if iter_2_3:getBuffsByID(var_0_11) then
						local var_2_6 = #iter_2_3:getBuffsByID(var_0_11)

						if var_2_6 > 0 then
							local var_2_7 = iter_2_3:getBuffByID(var_0_11)

							var_2_5 = math.abs(var_2_5 + var_2_7:getAttr() * var_2_6)
						end
					end
				end
			end

			arg_2_0:getBuffByID(var_0_43).manualRevise = (var_2_4 + var_2_5) * var_0_41 or 0

			local var_2_8 = arg_2_0.hero_:getBattleAttr(var_0_2.AttributeType.AP)
			local var_2_9, var_2_10 = arg_2_0:getBuffAttrChange(var_0_2.AttributeType.AP)
			local var_2_11 = math.max(1 + var_2_10, 0) * var_2_8 + var_2_9

			arg_2_0.___attrCache[var_0_2.AttributeType.AP] = math.max(var_2_11, 0)
		else
			local var_2_12 = arg_2_0:createNewBuffs({
				var_0_43
			}, arg_2_0, var_0_40)

			arg_2_0:addBuffs(var_2_12)
		end
	end
end

function var_0_3.updateBaseInfo(arg_3_0)
	var_0_3.super.updateBaseInfo(arg_3_0)

	if arg_3_0.leftCount_ and not arg_3_0:isDeath() then
		arg_3_0.leftCount_ = math.max(arg_3_0.leftCount_ - 1, 0)

		if arg_3_0.leftCount_ < 1 then
			arg_3_0:energySkillAttack()
		end
	end

	arg_3_0.shanbiCount_ = math.max(arg_3_0.shanbiCount_ - 1, 0)
end

function var_0_3.die(arg_4_0)
	var_0_3.super.die(arg_4_0)

	local var_4_0 = arg_4_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_4_0, iter_4_1 in ipairs(var_4_0) do
		if not iter_4_1:isDeath() or iter_4_1:canReborn() then
			iter_4_1:removeBuffByID(var_0_10)
			iter_4_1:removeBuffByID(var_0_11)
		end
	end
end

function var_0_3.addBuffs(arg_5_0, arg_5_1)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_5_0 = var_0_16 + arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_17

		for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
			if iter_5_1.fighter:getTeamType() ~= arg_5_0:getTeamType() and (iter_5_1:isApUnable() or iter_5_1:isAdUnable()) then
				if arg_5_0.harmBuffs_[tostring(iter_5_1:getTableID())] then
					iter_5_1.leftCount_ = var_5_0 * iter_5_1:getTime()
				end

				arg_5_0.harmBuffs_[tostring(iter_5_1:getTableID())] = true
			end
		end
	end

	var_0_3.super.addBuffs(arg_5_0, arg_5_1)
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_37 and arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_33 and arg_6_1:getTime() > 0 then
		local var_6_0 = (1 - arg_6_0:getHp() / arg_6_0:getHpLimit()) * arg_6_1:getTime() * var_0_34

		arg_6_1:setExtraTime(var_6_0)
	end

	if arg_6_1:getTableID() == var_0_42 and arg_6_0:hasElementEquipByID(var_0_39) then
		local var_6_1 = var_0_39

		arg_6_1.manualRevise = var_0_38:battleAttr(var_6_1, arg_6_0:getElementEquipLevelByID(var_6_1)) * arg_6_0.hero_:getElementEquipActiveRate(var_6_1)
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	if var_0_6:father(arg_7_1.skillID) == arg_7_0:getEnergySkillID() and arg_7_1.fighter == arg_7_0 then
		arg_7_0.energySkilled_ = true

		if not arg_7_0.leftCount_ then
			arg_7_0.leftCount_ = 0
		end
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_7_0.harmSkills_[tostring(arg_7_1.skillID)] then
			local var_7_0 = var_0_18 + arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_19

			if arg_7_1.fighter:isBoss() then
				var_7_0 = 1 - (1 - var_7_0) * 0.3
			end

			arg_7_2 = var_7_0 * arg_7_2
		end

		arg_7_0.harmSkills_[tostring(arg_7_1.skillID)] = true
	end

	return var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
end

function var_0_3.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_8_0.shanbiCount_ < 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_6 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_8_7 = var_0_6:init(var_8_6) + var_0_6:step(var_8_6) * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if (arg_8_1.attackType == var_0_2.AttackType.AD or arg_8_1.attackType == var_0_2.AttackType.AP) and var_8_2 <= var_8_7 and var_8_2 > 0 then
			arg_8_0.shanbiCount_ = var_0_15 * var_0_1.ctx.battleConst.frames
			arg_8_0.harmSkills_[tostring(arg_8_1.skillID)] = true

			arg_8_0:specialAttack(arg_8_1.fighter)

			local var_8_8 = {
				arg_8_0
			}
			local var_8_9 = arg_8_0:createAttackUnits(var_8_8, var_0_14)

			for iter_8_0, iter_8_1 in ipairs(var_8_9) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
				table.insert(arg_8_0.records_.special_units, iter_8_1)
			end

			var_8_2 = 0
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	local var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_22 and arg_9_0.skinAddHarmRate_ > 0 then
			var_9_2 = var_9_2 * (1 + arg_9_0.skinAddHarmRate_)
		end
	elseif arg_9_1.skillID == var_0_22 and var_9_2 > 0 then
		var_9_2 = var_9_2 + math.abs(arg_9_0:getHpLimit() - arg_9_0:getHp()) * var_0_31
	end

	return var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5
end

function var_0_3.specialAttack(arg_10_0, arg_10_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_10_1:isDeath() or arg_10_1:isAffected() then
		return
	end

	if arg_10_0.isEnergySkill_ and arg_10_0:isCreatingUnits() then
		return
	end

	if arg_10_0.energySkilled_ ~= true then
		return
	end

	local var_10_0 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_10_1 = var_0_6:sound(var_10_0)

	var_0_1.ctx.battle.pushSoundQueue(var_10_1)

	local var_10_2 = var_0_6:attackIndex(var_10_0)

	arg_10_0:playAttack(var_10_2)

	arg_10_0.unitSkills_ = var_0_5.new({
		fighter = arg_10_0,
		skillID = var_10_0
	})

	arg_10_0:beginAttackEnd(arg_10_0.unitSkills_)

	arg_10_0.manualTarget_ = {
		arg_10_1
	}
	arg_10_0.extraAp_ = arg_10_0.extraAp_ + arg_10_0:getEnergy() * (var_0_21 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_20)

	arg_10_0:updateEnergyTo(0)
end

function var_0_3.energySkillAttack(arg_11_0)
	if arg_11_0:isDeath() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_11_0.leftCount_ = var_0_9 * var_0_1.ctx.battleConst.frames

	local var_11_0 = var_0_12
	local var_11_1 = var_0_4.B2(arg_11_0, var_11_0)
	local var_11_2 = arg_11_0:createAttackUnits(var_11_1, var_11_0)

	for iter_11_0, iter_11_1 in ipairs(var_11_2) do
		table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
		table.insert(arg_11_0.records_.special_units, iter_11_1)
	end

	local var_11_3 = arg_11_0:createAttackUnits({
		arg_11_0
	}, var_0_13)

	for iter_11_2, iter_11_3 in ipairs(var_11_3) do
		table.insert(arg_11_0.moveAttackUnits_, iter_11_3)
		table.insert(arg_11_0.records_.special_units, iter_11_3)
	end
end

function var_0_3.checkEnergySkill(arg_12_0)
	if arg_12_0.energySkilled_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_12_0)
end

function var_0_3.getAP(arg_13_0)
	return arg_13_0.extraAp_ + var_0_3.super.getAP(arg_13_0)
end

function var_0_3.applySingleUnit(arg_14_0, arg_14_1)
	var_0_3.super.applySingleUnit(arg_14_0, arg_14_1)

	if arg_14_1.skillID == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_14_0.isSkinSkillOn_ and arg_14_0.skinSkillID_ == var_0_22 then
		arg_14_0:checkSkinSkill()
	elseif arg_14_1.skillID == var_0_24 then
		arg_14_0.skinSkillCD_ = var_0_1.ctx.battle.count

		arg_14_0:updateKillGasNum(-var_0_26)

		arg_14_0.isSkinSkillType_ = false

		arg_14_0:setImmuneControl(false)
	elseif arg_14_1.skillID == var_0_23 then
		local var_14_0, var_14_1 = arg_14_1.target:getPos()

		arg_14_0:pos(var_14_0 - 80, var_14_1)
		arg_14_0:flipX(true)
	elseif var_0_6:father(arg_14_1.skillID) == arg_14_0:getEnergySkillID() and arg_14_1.fighter == arg_14_0 and arg_14_0:hasElementEquipByID(var_0_39) then
		local var_14_2 = arg_14_0:createNewBuffs({
			var_0_42
		}, arg_14_1.target, var_0_40)

		arg_14_1.target:addBuffs(var_14_2)
	end
end

function var_0_3.checkSkinSkill(arg_15_0)
	local var_15_0 = false

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_15_0.skinAddGas[tostring(var_0_1.ctx.battle.count)] then
			var_15_0 = true
		end
	else
		var_15_0 = var_0_2.weightedChoise({
			var_0_27,
			1 - var_0_27
		}) == 1

		if var_15_0 then
			arg_15_0.records_.skin_add_gas[tostring(var_0_1.ctx.battle.count)] = 1
		end
	end

	if var_15_0 then
		arg_15_0:updateKillGasNum(1, true)
	end
end

function var_0_3.setupReport(arg_16_0, arg_16_1)
	var_0_3.super.setupReport(arg_16_0, arg_16_1)

	arg_16_0.skinAddGas = arg_16_1.skin_add_gas
end

function var_0_3.writeReport(arg_17_0)
	local var_17_0 = var_0_3.super.writeReport(arg_17_0)

	var_17_0.skin_add_gas = arg_17_0.records_.skin_add_gas

	return var_17_0
end

function var_0_3.updateKillGasNum(arg_18_0, arg_18_1, arg_18_2)
	if not arg_18_1 then
		return
	end

	arg_18_0.skinKillGasNum_ = arg_18_0.skinKillGasNum_ + arg_18_1

	if arg_18_2 and arg_18_0.skinPartner_ and not arg_18_0.skinPartner_:isDeath() then
		arg_18_0.skinPartner_:updateKillGasNum(arg_18_1)
	end

	arg_18_0:updateStateNumber(arg_18_0.skinKillGasNum_)
end

function var_0_3.canUseSkinSkill(arg_19_0)
	if arg_19_0.isSkinSkillType_ then
		return false
	end

	if not arg_19_0:acttionInBlack() or arg_19_0:isBattleUnable() or arg_19_0:isCreatingUnits() then
		return false
	end

	if arg_19_0.skinSkillCD_ > 0 and var_0_1.ctx.battle.count - arg_19_0.skinSkillCD_ < var_0_32 then
		return false
	end

	return true
end

function var_0_3.beginAttackEnd(arg_20_0, arg_20_1)
	var_0_3.super.beginAttackEnd(arg_20_0, arg_20_1)

	if arg_20_1.rootID_ == var_0_22 then
		arg_20_0.isSkinSkillType_ = true

		arg_20_0:playSkinSkillEffect()
		arg_20_0:setImmuneControl(true)
	elseif arg_20_0.isSkinSkillType_ then
		arg_20_0.skinSkillCD_ = var_0_1.ctx.battle.count

		arg_20_0:updateKillGasNum(-var_0_26)

		arg_20_0.isSkinSkillType_ = false

		arg_20_0:setImmuneControl(false)
	end
end

function var_0_3.useSkinSkill(arg_21_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_21_0 = var_0_22
	local var_21_1 = var_0_6:sound(var_21_0)

	var_0_1.ctx.battle.pushSoundQueue(var_21_1)

	local var_21_2 = var_0_6:attackIndex(var_21_0)

	arg_21_0:playAttack(var_21_2)

	arg_21_0.unitSkills_ = var_0_5.new({
		fighter = arg_21_0,
		skillID = var_21_0
	})

	arg_21_0:beginAttackEnd(arg_21_0.unitSkills_)
end

function var_0_3.selectTargetByTypeD1(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = -1
	local var_22_1

	for iter_22_0, iter_22_1 in ipairs(arg_22_0.sideTeam_) do
		if not iter_22_1:isDeath() and not iter_22_1:isAffected() and iter_22_1:getSummonType() == var_0_2.summonMonsterType.None and var_22_0 < iter_22_1.harms * iter_22_1:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE then
			var_22_1 = iter_22_1
			var_22_0 = iter_22_1.harms * iter_22_1:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE
		end
	end

	return {
		var_22_1
	}
end

function var_0_3.checkKilling(arg_23_0, arg_23_1)
	var_0_3.super.checkKilling(arg_23_0, arg_23_1)

	if arg_23_1 and var_0_6:father(arg_23_1.skillID) == var_0_22 then
		arg_23_0.skinAddHarmRate_ = arg_23_0.skinAddHarmRate_ + var_0_25
	end
end

function var_0_3.playSkinSkillEffect(arg_24_0)
	if not arg_24_0.isSkinSkillType_ or not arg_24_0.skinPartner_ or not arg_24_0.skinPartner_.isSkinSkillType_ or var_0_1.ctx.battle.isSpecialSkill or var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	var_0_1.ctx.battle.isSpecialSkill = true

	var_0_1.ctx.battle.stopAllFighter()
	var_0_1.ctx.battle.blackLayer:show()

	if arg_24_0.skinShowEffect_ then
		arg_24_0.skinShowEffect_:removeSelf()
	end

	local var_24_0 = var_0_1.ctx.battle.getSpine(var_0_22, "area", 1)

	var_24_0:addTo(var_0_1.ctx.battle.unitLayer)

	if var_0_1.ctx.battle.isUnlimitBattle then
		var_24_0:pos(var_0_2.UNLIMIT_STAGE_WIDTH * 0.5, var_0_2.UNLIMIT_STAGE_HEIGHT * 0.5 - 50)
	else
		var_24_0:pos(var_0_2.STAGE_WIDTH * 0.5, var_0_2.STAGE_HEIGHT * 0.5)
	end

	var_24_0:playOnce(function()
		var_0_1.ctx.battle.isSpecialSkill = false

		arg_24_0.skinShowEffect_:hide()
		var_0_1.ctx.battle.resumeAllFighter()
		var_0_1.ctx.battle.blackLayer:hide()
	end)

	arg_24_0.skinShowEffect_ = var_24_0
end

return var_0_3
