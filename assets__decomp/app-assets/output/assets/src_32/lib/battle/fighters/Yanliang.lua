local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yanliang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 20010089
local var_0_8 = 60
local var_0_9 = 60
local var_0_10 = var_0_2.tables.skill
local var_0_11 = var_0_2.tables.hero
local var_0_12 = var_0_2.tables.model
local var_0_13 = 80010050
local var_0_14 = 10000864
local var_0_15 = 10000865
local var_0_16 = 0.5
local var_0_17 = 5
local var_0_18 = 0.6
local var_0_19 = 10001051
local var_0_20 = 80010051
local var_0_21 = 300
local var_0_22 = 90
local var_0_23 = 80020050
local var_0_24 = 2
local var_0_25 = 0.5
local var_0_26 = 10001051
local var_0_27 = 80020051
local var_0_28 = 2
local var_0_29 = var_0_2.tables.elementEquip
local var_0_30 = 20001456
local var_0_31 = 10002182

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.harmCount_ = 0
	arg_1_0.skillRush_ = {}
	arg_1_0.canRush_ = nil
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
	arg_1_0.skinWaitAddGasNum_ = 0
	arg_1_0.skin2Partner_ = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.skinWenchouJudge_ then
		if arg_2_0.skinWenchouJudgeDelay_ > 0 then
			arg_2_0.skinWenchouJudgeDelay_ = arg_2_0.skinWenchouJudgeDelay_ - 1
		else
			arg_2_0.skinWenchouJudge_ = true

			for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
				if iter_2_1.hero_:getTableID() == var_0_19 or iter_2_1.hero_:beforeAwakenID() == var_0_19 then
					if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_13 and iter_2_1.isSkinSkillOn_ and iter_2_1.skinSkillID_ == var_0_20 then
						arg_2_0.skinPartner_ = iter_2_1
						iter_2_1.skinPartner_ = arg_2_0

						if not iter_2_1.skinKillGasNum_ or iter_2_1.skinKillGasNum_ < arg_2_0.skinKillGasNum_ then
							iter_2_1.skinKillGasNum_ = arg_2_0.skinKillGasNum_
						end
					end

					if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_23 and iter_2_1.isSkinSkillOn_ and iter_2_1.skinSkillID_ == var_0_27 then
						arg_2_0.skin2Partner_ = iter_2_1
						iter_2_1.skin2Partner_ = arg_2_0
					end

					break
				end
			end
		end
	end

	if arg_2_0.skinKillGasNum_ >= var_0_17 and arg_2_0:canUseSkinSkill() then
		arg_2_0:useSkinSkill()
	end

	if var_0_1.ctx.battle.walk2NextBattle_ and arg_2_0.skinKillGasNum_ > 0 then
		arg_2_0.skinKillGasNum_ = 0

		arg_2_0:updateStateNumber()
	end

	if arg_2_0.skinWaitAddGasNum_ > 0 and not next(arg_2_0.skillRush_) then
		arg_2_0:updateKillGasNum(arg_2_0.skinWaitAddGasNum_, true)

		arg_2_0.skinWaitAddGasNum_ = 0
	end
end

function var_0_3.applyBuffMoves(arg_3_0)
	var_0_3.super.applyBuffMoves(arg_3_0)

	if next(arg_3_0.skillRush_) == nil or var_0_1.ctx.battle.isReleased(arg_3_0.fighterModel) or arg_3_0:isDeath() or not arg_3_0:acttionInBlack() then
		return
	end

	local var_3_0, var_3_1 = unpack(arg_3_0.skillRush_[1])

	table.remove(arg_3_0.skillRush_, 1)

	if var_3_0 ~= 0 or var_3_1 ~= 0 then
		if arg_3_0.purpleTarget_ then
			arg_3_0.purpleTarget_:moveByX(var_3_0, false)
			arg_3_0.purpleTarget_:moveByY(var_3_1, false)
		end

		arg_3_0:moveByX(var_3_0, false)
		arg_3_0:moveByY(var_3_1, false)

		if arg_3_0:getX() <= -1 * arg_3_0:getFighterModel():getWidth() / 2 and var_3_0 < 0 then
			arg_3_0:x(arg_3_0:getFighterModel():getWidth() / 2 + var_0_2.STAGE_WIDTH)

			if arg_3_0.rushUnit_ then
				arg_3_0.rushUnit_.iniX_ = arg_3_0:getX()
			end

			if arg_3_0.purpleTarget_ then
				arg_3_0.purpleTarget_:x(arg_3_0:getFighterModel():getWidth() / 2 + var_0_2.STAGE_WIDTH - 50)
			end
		elseif arg_3_0:getX() >= var_0_2.STAGE_WIDTH + arg_3_0:getFighterModel():getWidth() / 2 and var_3_0 > 0 then
			arg_3_0:x(-1 * arg_3_0:getFighterModel():getWidth() / 2)

			if arg_3_0.rushUnit_ then
				arg_3_0.rushUnit_.iniX_ = arg_3_0:getX()
			end

			if arg_3_0.purpleTarget_ then
				arg_3_0.purpleTarget_:x(-1 * arg_3_0:getFighterModel():getWidth() / 2 + 50)
			end
		end
	end

	if next(arg_3_0.skillRush_) == nil and arg_3_0.rushUnit_ then
		arg_3_0.rushUnit_:arrive()

		arg_3_0.rushUnit_.arrived = true
		arg_3_0.rushUnit_ = nil

		arg_3_0:removePurpleBuff()

		arg_3_0.purpleTarget_ = nil
	end
end

function var_0_3.selectTargetByTypeD3(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}
	local var_4_1 = {}
	local var_4_2, var_4_3 = var_0_5.getTeam(arg_4_0)

	for iter_4_0, iter_4_1 in ipairs(var_4_2) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			table.insert(var_4_0, iter_4_1)
		end
	end

	for iter_4_2, iter_4_3 in ipairs(var_4_0) do
		if not iter_4_3:isHasBuffByID(var_0_7) then
			table.insert(var_4_1, iter_4_3)
		end
	end

	if not var_0_5.timeSeed_ then
		var_0_5.timeSeed_ = 1
	end

	math.randomseed(tonumber(tostring(os.time() + var_0_5.timeSeed_):reverse():sub(1, 6)))

	local var_4_4 = math.random(tonumber(os.time()))

	math.randomseed(var_4_4)

	var_0_5.timeSeed_ = var_4_4

	if next(var_4_1) ~= nil then
		return {
			var_4_1[math.random(#var_4_1)]
		}
	elseif next(var_4_0) ~= nil then
		return {
			var_4_0[math.random(#var_4_0)]
		}
	else
		return {}
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.target

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_13 then
		arg_5_0:checkSkinSkill()
	elseif arg_5_1.skillID == var_0_15 then
		arg_5_0.skinSkillCD_ = var_0_1.ctx.battle.count

		arg_5_0:updateKillGasNum(-var_0_17)

		arg_5_0.isSkinSkillType_ = false

		arg_5_0:setImmuneControl(false)
	elseif arg_5_1.skillID == var_0_14 then
		local var_5_1, var_5_2 = arg_5_1.target:getPos()

		arg_5_0:pos(var_5_1 + 80, var_5_2)
		arg_5_0:flipX(false)
	end

	if arg_5_1.skillID ~= arg_5_0:getEnergySkillID() or var_5_0:isDeath() then
		return
	end

	local var_5_3 = arg_5_0:getFlipX() and -1 or 1
	local var_5_4 = arg_5_0:getX() + 100 * var_5_3
	local var_5_5 = math.max(var_5_0:getFighterModel():getWidth() / 2, var_5_4)
	local var_5_6 = math.min(var_0_2.STAGE_WIDTH - arg_5_0:getFighterModel():getWidth() / 2, var_5_5)
	local var_5_7 = arg_5_0:getY() - var_5_0:getY()
	local var_5_8 = var_5_7 - var_5_7 % 10

	var_5_0:pos(var_5_6, var_5_0:getY() + var_5_8)
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_1.targetsCount then
		var_6_2 = var_6_2 * arg_6_1.targetsCount
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_6_6 = arg_6_0.harmCount_

		var_6_2 = var_6_2 * math.min(var_6_6, var_0_8)

		if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_13 and arg_6_0.skinAddHarmRate_ > 0 then
			var_6_2 = var_6_2 * (1 + arg_6_0.skinAddHarmRate_)
		end

		if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_23 then
			var_6_2 = var_6_2 + arg_6_0:getAD() * var_0_24

			if arg_6_0.skin2Partner_ and not arg_6_0.skin2Partner_:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_7 = arg_6_0:createAttackUnits({
					arg_6_0.skin2Partner_
				}, var_0_23)

				for iter_6_0, iter_6_1 in ipairs(var_6_7) do
					iter_6_1.cureHp = var_6_2 * var_0_25

					table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
					table.insert(arg_6_0.records_.special_units, iter_6_1)
				end
			end
		end
	elseif arg_6_1.skillID == var_0_23 and arg_6_1.cureHp then
		var_6_3 = var_6_3 + arg_6_1.cureHp
	elseif arg_6_1.skillID == var_0_31 and arg_6_0:hasElementEquipByID(var_0_30) and var_6_3 > 0 then
		local var_6_8 = var_0_30
		local var_6_9 = var_0_29:battleAttr(var_6_8, arg_6_0:getElementEquipLevelByID(var_6_8))
		local var_6_10 = arg_6_0.hero_:getElementEquipActiveRate(var_6_8)

		var_6_3 = math.max(arg_6_0:getHpLimit() - arg_6_0:getHp(), 0) * var_6_9 * var_6_10
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.getAD(arg_7_0)
	local var_7_0 = var_0_3.super.getAD(arg_7_0)

	if arg_7_0.isSkinSkillOn_ and arg_7_0.skinSkillID_ == var_0_23 and arg_7_0.skin2Partner_ then
		var_7_0 = var_7_0 + var_7_0 * (1 - arg_7_0.skin2Partner_:getHp() / arg_7_0.skin2Partner_:getHpLimit()) * var_0_28
	end

	return var_7_0
end

function var_0_3.moveUnitArrive(arg_8_0, arg_8_1)
	if arg_8_1.resource then
		arg_8_1.resource:stop()
	end

	arg_8_1:arrive()

	if arg_8_1:getAreaResource() then
		local var_8_0 = arg_8_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_8_1.fighter:getY() or arg_8_1.desY_
		local var_8_1 = arg_8_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_8_1.fighter:getX() or arg_8_1.desX_

		arg_8_1:getAreaResource():addTo(var_0_1.ctx.battle.unitLayer)
		arg_8_1:getAreaResource():pos(var_8_1, var_8_0)
		arg_8_1:getAreaResource():playOnce()
		arg_8_1:getAreaResource():flipX(arg_8_1.fighter:getX() > arg_8_1.desX_)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_8_2 = arg_8_1:getReportUnits()

		for iter_8_0, iter_8_1 in ipairs(var_8_2) do
			table.insert(arg_8_0.applyUnits_, iter_8_1)
		end
	else
		local var_8_3 = arg_8_0:getTargets(arg_8_1.skillID, arg_8_1)

		if next(var_8_3) then
			local var_8_4 = arg_8_1:createAttacks(var_8_3)

			for iter_8_2, iter_8_3 in ipairs(var_8_4) do
				if arg_8_1.skillID == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
					iter_8_3.targetsCount = #var_8_4
				end

				table.insert(arg_8_0.applyUnits_, iter_8_3)
			end
		end
	end
end

function var_0_3.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	if arg_9_2 > 0 then
		arg_9_0.harmCount_ = arg_9_0.harmCount_ + 1

		if arg_9_0.harmCount_ > 0 and arg_9_0.harmCount_ % 10 < 1 then
			arg_9_0.canRush_ = true
		end
	end

	if arg_9_0:isDeath() then
		return var_0_3.super.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	end

	if not arg_9_0:isDeath() and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_9_0:acttionInBlack() and arg_9_0:isCreatingUnits() ~= true and arg_9_0.canRush_ and not arg_9_0:isBattleUnable() and next(arg_9_0.skillRush_) == nil then
		arg_9_0:specialAttack()
	end

	return var_0_3.super.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
end

function var_0_3.specialAttack(arg_10_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_10_0.canRush_ = nil
	arg_10_0.harmCount_ = 0

	local var_10_0 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_10_1 = var_0_10:sound(var_10_0)

	var_0_1.ctx.battle.pushSoundQueue(var_10_1)

	local var_10_2 = var_0_10:attackIndex(var_10_0)

	arg_10_0:playAttack(var_10_2)

	arg_10_0.unitSkills_ = var_0_4.new({
		fighter = arg_10_0,
		skillID = var_10_0
	})

	arg_10_0:beginAttackEnd(arg_10_0.unitSkills_)
end

function var_0_3.createUnits(arg_11_0)
	local var_11_0, var_11_1 = arg_11_0.unitSkills_:getFront()

	if var_0_10:father(var_11_1) == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_11_2 = arg_11_0:getFighterModel():getWidth() + var_0_2.STAGE_WIDTH
		local var_11_3 = var_0_9

		if arg_11_0.rushUnit_ then
			arg_11_0.rushUnit_:arrive()

			arg_11_0.rushUnit_.arrived = true
			arg_11_0.rushUnit_ = nil

			arg_11_0:removePurpleBuff()

			arg_11_0.purpleTarget_ = nil
		end

		arg_11_0.skillRush_ = {}

		local var_11_4 = arg_11_0:getFlipX() and -1 or 1

		for iter_11_0 = 1, var_11_3 do
			table.insert(arg_11_0.skillRush_, {
				var_11_4 * var_11_2 / var_11_3,
				0
			})
		end
	end

	var_0_3.super.createUnits(arg_11_0)
end

function var_0_3.unitAfterCreate(arg_12_0, arg_12_1, arg_12_2)
	if arg_12_1 and arg_12_1.skillID == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_12_0.rushUnit_ = arg_12_1
	end
end

function var_0_3.isHurtBreak(arg_13_0, arg_13_1, arg_13_2)
	if arg_13_1 > arg_13_0:getHpLimit() * var_0_2.SHOW_HURT_EFFECT_RATE and arg_13_0.isEnergySkill_ ~= true and not arg_13_0:isPause() and next(arg_13_0.rushUnit_ or {}) == nil or arg_13_2:isForceBreak() then
		return true
	end

	return false
end

function var_0_3.checkSkillBreak(arg_14_0, arg_14_1, arg_14_2)
	var_0_3.super.checkSkillBreak(arg_14_0, arg_14_1, arg_14_2)

	if arg_14_1 == var_0_2.BreakSkillType.AD then
		if arg_14_0:isAdBreakImmortal() or arg_14_0:isBreakImmortal() then
			return
		end

		if next(arg_14_0.skillRush_) then
			arg_14_0.skillRush_ = {}

			if arg_14_0:getX() > var_0_2.STAGE_WIDTH - arg_14_0:getFighterModel():getWidth() / 2 then
				arg_14_0:x(var_0_2.STAGE_WIDTH - arg_14_0:getFighterModel():getWidth() / 2)
			elseif arg_14_0:getX() < arg_14_0:getFighterModel():getWidth() / 2 then
				arg_14_0:x(arg_14_0:getFighterModel():getWidth() / 2)
			end
		end

		if arg_14_0.rushUnit_ then
			arg_14_0.rushUnit_:arrive()

			arg_14_0.rushUnit_.arrived = true
			arg_14_0.rushUnit_ = nil

			arg_14_0:removePurpleBuff()

			arg_14_0.purpleTarget_ = nil
		end
	end
end

function var_0_3.clickAvatar(arg_15_0, arg_15_1)
	if arg_15_1.name == "ended" and var_0_1.ctx.battle.autoA ~= true and arg_15_0.energy_ >= arg_15_0:energyDecimalBase() then
		if next(arg_15_0.skillRush_) then
			arg_15_0.skillRush_ = {}

			if arg_15_0:getX() > var_0_2.STAGE_WIDTH - arg_15_0:getFighterModel():getWidth() / 2 then
				arg_15_0:x(var_0_2.STAGE_WIDTH - arg_15_0:getFighterModel():getWidth() / 2)
			elseif arg_15_0:getX() < arg_15_0:getFighterModel():getWidth() / 2 then
				arg_15_0:x(arg_15_0:getFighterModel():getWidth() / 2)
			end
		end

		if arg_15_0.rushUnit_ then
			arg_15_0.rushUnit_:arrive()

			arg_15_0.rushUnit_.arrived = true
			arg_15_0.rushUnit_ = nil

			arg_15_0:removePurpleBuff()

			arg_15_0.purpleTarget_ = nil
		end
	end
end

function var_0_3.removePurpleBuff(arg_16_0)
	return
end

function var_0_3.checkSkinSkill(arg_17_0)
	local var_17_0 = false

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_17_0.skinAddGas[tostring(var_0_1.ctx.battle.count)] then
			var_17_0 = true
		end
	else
		var_17_0 = var_0_2.weightedChoise({
			var_0_18,
			1 - var_0_18
		}) == 1

		if var_17_0 then
			arg_17_0.records_.skin_add_gas[tostring(var_0_1.ctx.battle.count)] = 1
		end
	end

	if var_17_0 then
		arg_17_0.skinWaitAddGasNum_ = arg_17_0.skinWaitAddGasNum_ + 1
	end
end

function var_0_3.setupReport(arg_18_0, arg_18_1)
	var_0_3.super.setupReport(arg_18_0, arg_18_1)

	arg_18_0.skinAddGas = arg_18_1.skin_add_gas
end

function var_0_3.writeReport(arg_19_0)
	local var_19_0 = var_0_3.super.writeReport(arg_19_0)

	var_19_0.skin_add_gas = arg_19_0.records_.skin_add_gas

	return var_19_0
end

function var_0_3.updateKillGasNum(arg_20_0, arg_20_1, arg_20_2)
	if not arg_20_1 then
		return
	end

	arg_20_0.skinKillGasNum_ = arg_20_0.skinKillGasNum_ + arg_20_1

	if arg_20_2 and arg_20_0.skinPartner_ and not arg_20_0.skinPartner_:isDeath() then
		arg_20_0.skinPartner_:updateKillGasNum(arg_20_1)
	end

	arg_20_0:updateStateNumber(arg_20_0.skinKillGasNum_)
end

function var_0_3.canUseSkinSkill(arg_21_0)
	if arg_21_0.isSkinSkillType_ then
		return false
	end

	if not arg_21_0:acttionInBlack() or arg_21_0:isBattleUnable() or next(arg_21_0.skillRush_) or arg_21_0:isCreatingUnits() then
		return false
	end

	if arg_21_0.skinSkillCD_ > 0 and var_0_1.ctx.battle.count - arg_21_0.skinSkillCD_ < var_0_22 then
		return false
	end

	return true
end

function var_0_3.useSkinSkill(arg_22_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_22_0 = var_0_13
	local var_22_1 = var_0_10:sound(var_22_0)

	var_0_1.ctx.battle.pushSoundQueue(var_22_1)

	local var_22_2 = var_0_10:attackIndex(var_22_0)

	arg_22_0:playAttack(var_22_2)

	arg_22_0.unitSkills_ = var_0_4.new({
		fighter = arg_22_0,
		skillID = var_22_0
	})

	arg_22_0:beginAttackEnd(arg_22_0.unitSkills_)
end

function var_0_3.beginAttackEnd(arg_23_0, arg_23_1)
	var_0_3.super.beginAttackEnd(arg_23_0, arg_23_1)

	if arg_23_1.rootID_ == var_0_13 then
		arg_23_0.isSkinSkillType_ = true

		arg_23_0:playSkinSkillEffect()
		arg_23_0:setImmuneControl(true)
	elseif arg_23_0.isSkinSkillType_ then
		arg_23_0.skinSkillCD_ = var_0_1.ctx.battle.count

		arg_23_0:updateKillGasNum(-var_0_17)

		arg_23_0.isSkinSkillType_ = false

		arg_23_0:setImmuneControl(false)
	end
end

function var_0_3.selectTargetByTypeD1(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = -1
	local var_24_1

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.sideTeam_) do
		if not iter_24_1:isDeath() and not iter_24_1:isAffected() and iter_24_1:getSummonType() == var_0_2.summonMonsterType.None and var_24_0 < iter_24_1.harms * iter_24_1:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE then
			var_24_1 = iter_24_1
			var_24_0 = iter_24_1.harms * iter_24_1:getEnergy() / var_0_2.ENERGY_DECIMAL_BASE
		end
	end

	return {
		var_24_1
	}
end

function var_0_3.checkKilling(arg_25_0, arg_25_1)
	var_0_3.super.checkKilling(arg_25_0, arg_25_1)

	if arg_25_1 and var_0_10:father(arg_25_1.skillID) == var_0_13 then
		arg_25_0.skinAddHarmRate_ = arg_25_0.skinAddHarmRate_ + var_0_16
	end
end

function var_0_3.playSkinSkillEffect(arg_26_0)
	if not arg_26_0.isSkinSkillType_ or not arg_26_0.skinPartner_ or not arg_26_0.skinPartner_.isSkinSkillType_ or var_0_1.ctx.battle.isSpecialSkill or var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	var_0_1.ctx.battle.isSpecialSkill = true

	var_0_1.ctx.battle.stopAllFighter()
	var_0_1.ctx.battle.blackLayer:show()

	if arg_26_0.skinShowEffect_ then
		arg_26_0.skinShowEffect_:removeSelf()
	end

	local var_26_0 = var_0_1.ctx.battle.getSpine(var_0_13, "area", 1)

	var_26_0:addTo(var_0_1.ctx.battle.unitLayer)

	if var_0_1.ctx.battle.isUnlimitBattle then
		var_26_0:pos(var_0_2.UNLIMIT_STAGE_WIDTH * 0.5, var_0_2.UNLIMIT_STAGE_HEIGHT * 0.5 - 50)
	else
		var_26_0:pos(var_0_2.STAGE_WIDTH * 0.5, var_0_2.STAGE_HEIGHT * 0.5)
	end

	var_26_0:playOnce(function()
		var_0_1.ctx.battle.isSpecialSkill = false

		arg_26_0.skinShowEffect_:hide()
		var_0_1.ctx.battle.resumeAllFighter()
		var_0_1.ctx.battle.blackLayer:hide()
	end)

	arg_26_0.skinShowEffect_ = var_26_0
end

function var_0_3.buffAddAction(arg_28_0, arg_28_1)
	var_0_3.super.buffAddAction(arg_28_0, arg_28_1)

	local var_28_0 = arg_28_1:getTableID()

	if arg_28_0:hasElementEquipByID(var_0_30) and (arg_28_1:dBuffType() == var_0_2.DBuffType.XUAN_YUN or var_0_6:x(var_28_0) > 0 or var_0_6:y(var_28_0) > 0) then
		arg_28_0:useElementSkill(arg_28_0)
	end
end

function var_0_3.useElementSkill(arg_29_0, arg_29_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_29_0 = arg_29_0:createAttackUnits({
		arg_29_1
	}, var_0_31)

	for iter_29_0, iter_29_1 in ipairs(var_29_0) do
		table.insert(arg_29_0.moveAttackUnits_, iter_29_1)
		table.insert(arg_29_0.records_.special_units, iter_29_1)
	end
end

return var_0_3
