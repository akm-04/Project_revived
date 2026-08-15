local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangzhao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = 300
local var_0_8 = {
	30010050
}
local var_0_9 = 30010049
local var_0_10 = 0.3
local var_0_11 = 0
local var_0_12 = 15
local var_0_13 = 35
local var_0_14 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_15 = var_0_1.ctx.battle.getRequire("MoveUnit")
local var_0_16 = 10001110
local var_0_17 = 80020110
local var_0_18 = {
	160,
	480,
	800,
	1120
}
local var_0_19 = 30
local var_0_20 = 10001100
local var_0_21 = 10001099
local var_0_22 = 10001102
local var_0_23 = 80010112
local var_0_24 = 10001101
local var_0_25 = 80021112
local var_0_26 = 10001104
local var_0_27 = 10001470

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyEffects_ = {}
	arg_1_0.blueTargetsNum_ = 0
	arg_1_0.isGreenSummon_ = false
	arg_1_0.isEnergyEffect_ = false
	arg_1_0.isMove_ = false
	arg_1_0.moveBackCount_ = nil
	arg_1_0.summonMonsters_ = {}
	arg_1_0.skinZhanghongJudgeDelay_ = 2
	arg_1_0.skinZhanghongJudge_ = false
	arg_1_0.skinPartner_ = nil
	arg_1_0.skinShowEffect_ = nil
	arg_1_0.energySkillRegion = {}
	arg_1_0.bombSkillRegion = {}
end

function var_0_3.die(arg_2_0)
	var_0_3.super.die(arg_2_0)

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.summonMonsters_) do
		if not iter_2_1:isDeath() then
			iter_2_1:updateHp(0)
			iter_2_1:die()
		end
	end
end

function var_0_3.createToPosUnit(arg_3_0, arg_3_1)
	local var_3_0 = {
		skillID = arg_3_1,
		count = var_0_0.clone(var_0_1.ctx.battle.count),
		fighter = arg_3_0
	}
	local var_3_1 = var_0_15.new(var_3_0)

	if arg_3_1 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_2 = var_0_14.B30(arg_3_0, arg_3_1)

		if var_3_2 and next(var_3_2) then
			var_3_1:setDesition(var_3_2[1]:getX())
			var_3_1:getPathQueue()
		end
	end

	table.insert(arg_3_0.records_.moveunit, var_3_1)

	var_3_1.recordIndex_ = #arg_3_0.records_.moveunit

	return var_3_1
end

function var_0_3.singleLoop(arg_4_0)
	var_0_3.super.singleLoop(arg_4_0)
	arg_4_0:updateEnergyEffect()
	arg_4_0:updateBombEffect()
end

function var_0_3.updateEnergyEffect(arg_5_0)
	if not arg_5_0:acttionInBlack() then
		return
	end

	if next(arg_5_0.energySkillRegion) ~= nil then
		for iter_5_0 = #arg_5_0.energySkillRegion, 1, -1 do
			local var_5_0 = arg_5_0.energySkillRegion[iter_5_0]

			var_5_0.time = var_5_0.time - 1

			var_5_0.effect:pos(var_5_0.initPos.x + (var_5_0.totalTime - var_5_0.time) * var_5_0.speed, var_5_0.initPos.y)

			for iter_5_1, iter_5_2 in ipairs(var_0_18) do
				if var_5_0.speed > 0 then
					if iter_5_2 <= var_5_0.effect:getX() and var_5_0.notAttack[iter_5_1] == 0 then
						var_5_0.notAttack[iter_5_1] = 1

						arg_5_0:bombSkill(var_5_0.effect:getX(), var_5_0.effect:getY() - iter_5_1 % 2 * 80)
					end
				elseif iter_5_2 >= var_5_0.effect:getX() and var_5_0.notAttack[iter_5_1] == 0 then
					var_5_0.notAttack[iter_5_1] = 1

					arg_5_0:bombSkill(var_5_0.effect:getX(), var_5_0.effect:getY() - iter_5_1 % 2 * 80)
				end
			end

			if var_5_0.time <= 0 then
				var_5_0.effect:removeSelf()

				var_5_0.effect = nil

				table.remove(arg_5_0.energySkillRegion, iter_5_0)
			end
		end
	end
end

function var_0_3.updateBombEffect(arg_6_0)
	if not arg_6_0:acttionInBlack() then
		return
	end

	if next(arg_6_0.bombSkillRegion) ~= nil then
		for iter_6_0 = #arg_6_0.bombSkillRegion, 1, -1 do
			local var_6_0 = arg_6_0.bombSkillRegion[iter_6_0]

			var_6_0.time = var_6_0.time - 1

			if var_6_0.time == 0 then
				arg_6_0.isEnergyEffect_ = true

				local var_6_1 = {
					x = var_6_0.effect:getX(),
					y = var_6_0.effect:getY()
				}
				local var_6_2 = var_0_1.ctx.battle.getSpine(arg_6_0:getEnergySkillID(), "area", 1)

				var_6_2:addTo(var_0_1.ctx.battle.unitBottomLayer)
				var_6_2:pos(var_6_1.x, var_6_1.y)
				var_6_2:setScale(0.5)
				var_6_2:playRepeat()

				local var_6_3 = {
					posX = var_6_1.x,
					posY = var_6_1.y,
					effect = var_6_2
				}

				table.insert(arg_6_0.energyEffects_, var_6_3)
				var_6_0.effect:removeSelf()

				var_6_0.effect = nil

				table.remove(arg_6_0.bombSkillRegion, iter_6_0)
			end
		end
	end
end

function var_0_3.bombSkill(arg_7_0, arg_7_1, arg_7_2)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0:selectTargetByTypeD1(arg_7_1)

		if arg_7_0.skinPartner_ and not arg_7_0.skinPartner_:isDeath() then
			local var_7_1 = arg_7_0:createAttackUnits(var_7_0, var_0_26)

			for iter_7_0, iter_7_1 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		else
			local var_7_2 = arg_7_0:createAttackUnits(var_7_0, var_0_24)

			for iter_7_2, iter_7_3 in ipairs(var_7_2) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end

	local var_7_3 = {
		x = arg_7_1,
		y = arg_7_2
	}
	local var_7_4 = var_0_19
	local var_7_5 = var_0_1.ctx.battle.getSpine(var_0_20, "area", 1)

	var_7_5:addTo(var_0_1.ctx.battle.unitBottomLayer)
	var_7_5:pos(var_7_3.x, var_7_3.y)
	var_7_5:playRepeat()
	var_7_5:flipX(arg_7_0:getTeamType() == var_0_2.TeamType.B)

	local var_7_6 = {
		pos = var_7_3,
		time = var_7_4,
		effect = var_7_5
	}

	table.insert(arg_7_0.bombSkillRegion, var_7_6)
end

function var_0_3.toDoPerFrames(arg_8_0)
	if arg_8_0.moveBackCount_ and not arg_8_0:isDeath() then
		arg_8_0.moveBackCount_ = arg_8_0.moveBackCount_ - 1

		if arg_8_0.moveBackCount_ <= 0 then
			arg_8_0.moveBackCount_ = nil

			arg_8_0:x(arg_8_0.greenPosX_)
			arg_8_0:y(arg_8_0.greenPosY_)

			arg_8_0.isMove_ = false
		end
	end

	if var_0_1.ctx.battle.count % 10 == 0 and next(arg_8_0.energyEffects_) then
		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() then
				if iter_8_1:isHasBuffByID(var_0_8[1]) and not arg_8_0:isInEnergyCircle(iter_8_1) then
					for iter_8_2, iter_8_3 in ipairs(var_0_8) do
						iter_8_1:removeBuffByID(iter_8_3)
					end
				elseif not iter_8_1:isHasBuffByID(var_0_8[1]) and arg_8_0:isInEnergyCircle(iter_8_1) then
					iter_8_1:addBuffs(arg_8_0:newBuff(var_0_8, iter_8_1, arg_8_0:getEnergySkillID()))
				end
			end
		end
	end

	if not arg_8_0.skinZhanghongJudge_ and arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_23 then
		if arg_8_0.skinZhanghongJudgeDelay_ > 0 then
			arg_8_0.skinZhanghongJudgeDelay_ = arg_8_0.skinZhanghongJudgeDelay_ - 1
		else
			arg_8_0.skinZhanghongJudge_ = true

			for iter_8_4, iter_8_5 in ipairs(arg_8_0.selfTeam_) do
				if iter_8_5.hero_:getTableID() == var_0_16 or iter_8_5.hero_:beforeAwakenID() == var_0_16 then
					if iter_8_5.isSkinSkillOn_ and iter_8_5.skinSkillID_ == var_0_17 then
						arg_8_0.skinPartner_ = iter_8_5
						iter_8_5.skinPartner_ = arg_8_0
					end

					break
				end
			end
		end
	end
end

function var_0_3.isBreakImmortal(arg_9_0)
	if arg_9_0.isMove_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_9_0)
	end
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	local var_10_0 = arg_10_1.skillID

	if var_10_0 == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and not arg_10_0.isGreenSummon_ then
		arg_10_0.isGreenSummon_ = true

		local var_10_1 = var_0_4:summonMonster(var_10_0)

		for iter_10_0, iter_10_1 in ipairs(var_10_1) do
			local var_10_2 = arg_10_0:getSkillLevelByID(var_10_0)
			local var_10_3 = arg_10_0.hero_:getColor()
			local var_10_4 = arg_10_1.target:getTeamType() == var_0_2.TeamType.A and 1 or -1
			local var_10_5 = arg_10_1.target:getX() + var_10_4 * 50
			local var_10_6 = arg_10_1.target:getY()
			local var_10_7 = true
			local var_10_8 = var_0_1.ctx.battle.adjustX(var_10_5, arg_10_0)
			local var_10_9 = {
				x = var_10_8,
				y = var_10_6
			}

			arg_10_0:setSummonMonsters(iter_10_1, var_10_2, var_10_3, var_10_9, var_10_7)
			arg_10_0:x(var_10_8)
			arg_10_0:y(var_10_6)

			arg_10_0.moveBackCount_ = var_0_13
		end
	elseif var_10_0 == arg_10_0:getEnergySkillID() and not arg_10_0.isEnergyEffect_ then
		arg_10_0.isEnergyEffect_ = true

		local var_10_10 = {
			x = arg_10_1.target:getX(),
			y = arg_10_1.target:getY()
		}
		local var_10_11 = var_0_1.ctx.battle.getSpine(var_10_0, "area", 1)

		var_10_11:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_10_11:pos(var_10_10.x, var_10_10.y)
		var_10_11:setScale(0.5)
		var_10_11:playRepeat()

		local var_10_12 = {
			posX = var_10_10.x,
			posY = var_10_10.y,
			effect = var_10_11
		}

		table.insert(arg_10_0.energyEffects_, var_10_12)
	elseif var_10_0 == var_0_23 then
		arg_10_0:playSkinSkillEffect()
	elseif var_10_0 == var_0_25 then
		arg_10_0:setImmuneControl(false)
		arg_10_0.skinPartner_:setImmuneControl(false)
		arg_10_0:playSkinSkillEffect()
	end
end

function var_0_3.checkUnitBuffs(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4 = var_0_3.super.checkUnitBuffs(arg_11_0, arg_11_1, arg_11_2)

	for iter_11_0, iter_11_1 in ipairs(var_11_0) do
		if iter_11_1:getTableID() == var_0_9 then
			local var_11_5 = arg_11_0.blueTargetsNum_ * var_0_12

			iter_11_1:setExtraTime(var_11_5)
		end
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4
end

function var_0_3.getTargets(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = var_0_3.super.getTargets(arg_12_0, arg_12_1, arg_12_2)

	if arg_12_1 == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_12_0.blueTargetsNum_ = #var_12_0
	end

	return var_12_0
end

function var_0_3.getOrbOfFrontSkill(arg_13_0)
	local var_13_0 = var_0_3.super.getOrbOfFrontSkill(arg_13_0)

	if var_0_4:father(var_13_0) == arg_13_0:getPugongID() then
		local var_13_1 = arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_13_1 > 0 then
			local var_13_2 = var_0_10 + var_0_11 * var_13_1

			if var_0_2.weightedChoise({
				var_13_2,
				1 - var_13_2
			}) == 1 then
				return arg_13_0.skinSkillID_ == var_0_23 and var_0_27 or arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			end
		end
	elseif var_13_0 == arg_13_0:getEnergySkillID() and arg_13_0.isSkinSkillOn_ and arg_13_0.skinSkillID_ == var_0_23 then
		if arg_13_0.skinPartner_ and not arg_13_0.skinPartner_:isDeath() then
			return var_0_25
		else
			return var_0_23
		end
	end

	return var_13_0
end

function var_0_3.beginAttackEnd(arg_14_0, arg_14_1)
	var_0_3.super.beginAttackEnd(arg_14_0, arg_14_1)

	if arg_14_1.rootID_ == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_14_0.blueTargetsNum_ = 0
	elseif arg_14_1.rootID_ == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_14_0.isGreenSummon_ = false
		arg_14_0.isMove_ = true
		arg_14_0.greenPosX_ = arg_14_0:getX()
		arg_14_0.greenPosY_ = arg_14_0:getY()
	elseif arg_14_1.rootID_ == arg_14_0:getEnergySkillID() then
		arg_14_0.isEnergyEffect_ = false
	elseif arg_14_1.rootID_ == var_0_23 then
		arg_14_0.isEnergyEffect_ = false
	elseif arg_14_1.rootID_ == var_0_25 then
		arg_14_0.isEnergyEffect_ = false

		arg_14_0:playPartnerSkinSkillEffect()
		arg_14_0:setImmuneControl(true)
		arg_14_0.skinPartner_:setImmuneControl(true)
	end
end

function var_0_3.energyAction(arg_15_0, arg_15_1)
	if arg_15_1 == var_0_25 then
		arg_15_0:getFighterModel():playEnergyEffect_()
		arg_15_0:updateEnergyTo(arg_15_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		arg_15_0.skinPartner_:getFighterModel():playEnergyEffect_()
		arg_15_0.skinPartner_:updateEnergyTo(arg_15_0.skinPartner_:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		local var_15_0 = var_0_4:attackIndex(var_0_17)

		arg_15_0.skinPartner_:playAttack(var_15_0)
		arg_15_0:addBlackLayer(arg_15_1)
	elseif arg_15_1 == var_0_23 then
		arg_15_0:getFighterModel():playEnergyEffect_()
		arg_15_0:updateEnergyTo(arg_15_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		arg_15_0:addBlackLayer(arg_15_1)
	else
		var_0_3.super.energyAction(arg_15_0, arg_15_1)
	end
end

function var_0_3.addBlackLayer(arg_16_0, arg_16_1)
	if arg_16_1 == var_0_25 then
		if var_0_1.ctx.battle.isUnlimitBattle then
			if not arg_16_0.isNotFirstEnergySkill_ then
				arg_16_0.isNotFirstEnergySkill_ = true
			else
				return
			end
		end

		if var_0_1.ctx.battle.isEnergySkilling then
			var_0_1.ctx.battle.isEnergySkilling = math.max(var_0_1.ctx.battle.isEnergySkilling, 46)

			arg_16_0:unsetMaskColor()
			arg_16_0:resume()
			arg_16_0.skinPartner_:unsetMaskColor()
			arg_16_0.skinPartner_:resume()

			if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
				transition.scaleTo(arg_16_0.fighterModel, {
					time = 0.2,
					scale = 1.1
				})
				transition.scaleTo(arg_16_0.skinPartner_.fighterModel, {
					time = 0.2,
					scale = 1.1
				})
			end

			arg_16_0.acttionInBlack_ = true
			arg_16_0.skinPartner_.acttionInBlack_ = true

			return
		end

		arg_16_0.acttionInBlack_ = true
		arg_16_0.skinPartner_.acttionInBlack_ = true

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			transition.scaleTo(arg_16_0.fighterModel, {
				time = 0.2,
				scale = 1.1
			})
			transition.scaleTo(arg_16_0.skinPartner_.fighterModel, {
				time = 0.2,
				scale = 1.1
			})
		end

		var_0_1.ctx.battle.stopAllFighter()
		var_0_1.ctx.battle.blackLayer:show()

		var_0_1.ctx.battle.isEnergySkilling = 46
	else
		var_0_3.super.addBlackLayer(arg_16_0)
	end
end

function var_0_3.playPartnerSkinSkillEffect(arg_17_0)
	if not arg_17_0.skinPartner_ or var_0_1.ctx.battle.isSpecialSkill or var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_17_0.skinShowEffect_ then
		arg_17_0.skinShowEffect_:removeSelf()

		arg_17_0.skinShowEffect_ = nil
	end

	local var_17_0 = var_0_1.ctx.battle.getSpine(var_0_22, "area", 1)

	var_17_0:addTo(var_0_1.ctx.battle.unitLayer)

	if var_0_1.ctx.battle.isUnlimitBattle then
		var_17_0:pos(var_0_2.UNLIMIT_STAGE_WIDTH * 0.5, var_0_2.UNLIMIT_STAGE_HEIGHT * 0.5 - 50)
	else
		var_17_0:pos(var_0_2.STAGE_WIDTH * 0.5, var_0_2.STAGE_HEIGHT * 0.5)
	end

	var_17_0:playOnce(function()
		arg_17_0.skinShowEffect_:hide()
	end)

	arg_17_0.skinShowEffect_ = var_17_0
end

function var_0_3.playSkinSkillEffect(arg_19_0)
	local var_19_0 = var_0_1.ctx.battle.getSpine(var_0_21, "unit", 1)

	var_19_0:addTo(var_0_1.ctx.battle.unitBottomLayer)

	local var_19_1 = arg_19_0:getTeamType() == var_0_2.TeamType.A and {
		x = 0,
		y = 330
	} or {
		x = 1280,
		y = 330
	}
	local var_19_2 = arg_19_0:getTeamType() == var_0_2.TeamType.B and {
		x = 0,
		y = 330
	} or {
		x = 1280,
		y = 330
	}
	local var_19_3 = arg_19_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_19_4 = var_0_4:speed(var_0_21) * var_19_3
	local var_19_5 = math.ceil(math.abs((var_19_2.x - var_19_1.x) / var_19_4))
	local var_19_6 = {
		0,
		0,
		0,
		0
	}
	local var_19_7 = {
		initPos = var_19_1,
		totalTime = var_19_5,
		time = var_19_5,
		effect = var_19_0,
		speed = var_19_4,
		notAttack = var_19_6
	}

	var_19_0:pos(var_19_1.x, var_19_1.y)
	var_19_0:playRepeat()
	var_19_0:flipX(arg_19_0:getTeamType() == var_0_2.TeamType.B)
	table.insert(arg_19_0.energySkillRegion, var_19_7)
end

function var_0_3.setSummonMonsters(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4, arg_20_5)
	local var_20_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_20_0 = arg_20_0:getSummonMonster()
	else
		local var_20_1 = var_0_6.new()

		var_20_1:populateWithTableID(arg_20_1)

		var_20_1.level_ = arg_20_2 or var_20_1.level_
		var_20_1.color_ = arg_20_3 or var_20_1.color_

		for iter_20_0, iter_20_1 in pairs(var_20_1.skillLev_) do
			var_20_1.skillLev_[iter_20_0] = arg_20_0.hero_.skillLev_[iter_20_0]
		end

		local var_20_2 = var_20_1:className()

		var_20_0 = var_0_1.ctx.battle.requireFighter(var_20_2).new({
			is_arena = arg_20_0.isInArena_
		})

		var_20_0:populateWithHero(var_20_1)
		var_20_0:initModels()
		var_20_0.fighterModel:initHeaderView(arg_20_0:getTeamType() - 1)

		var_20_0.fighterIndex = arg_20_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_20_0:setFormationDelay(0, 100)
	end

	var_20_0:setTeamType(arg_20_0:getTeamType())

	var_20_0.summoner = arg_20_0

	var_20_0.fighterModel:pos(arg_20_4.x, arg_20_4.y)
	var_20_0:updateHp(var_20_0:getHpLimit())
	var_20_0:getFighterModel():flipX(arg_20_0:getTeamType() == var_0_2.TeamType.B)
	var_20_0:born()
	var_20_0:setGlobalBuffs()

	local var_20_3 = var_20_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_20_3, var_20_0)

	if not arg_20_5 then
		var_20_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
		table.insert(var_0_1.ctx.battle.yOrder, var_20_0)
		var_0_1.ctx.battle.updateZorder()
	else
		var_20_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer, 100)
	end

	table.insert(arg_20_0.summonMonsters_, var_20_0)
end

function var_0_3.newBuff(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = {}

	for iter_21_0, iter_21_1 in ipairs(arg_21_1) do
		local var_21_1 = var_0_5.new({
			tableID = iter_21_1,
			start = var_0_1.ctx.battle.count,
			level = arg_21_0:getSkillLevelByID(arg_21_3),
			skillID = arg_21_3,
			fighter = arg_21_0,
			target = arg_21_2
		})

		var_21_1:setYongJiu()
		var_21_1:setIsHit(true)
		var_21_1:setDirection(arg_21_0:getFighterModel():getFlipX())
		table.insert(var_21_0, var_21_1)
	end

	return var_21_0
end

function var_0_3.isInEnergyCircle(arg_22_0, arg_22_1)
	for iter_22_0, iter_22_1 in ipairs(arg_22_0.energyEffects_) do
		if math.abs(arg_22_1:getX() - iter_22_1.posX) <= var_0_7 * 0.5 then
			return true
		end
	end

	return false
end

function var_0_3.createUnits(arg_23_0, arg_23_1)
	var_0_3.super.createUnits(arg_23_0, arg_23_1)

	if arg_23_1.rootID_ == arg_23_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_23_0.blueTargetsNum_ = #var_0_1.ctx.battle.getFighters(arg_23_1.reportData_[1].targets)
	end
end

function var_0_3.selectTargetByTypeD1(arg_24_0, arg_24_1)
	local var_24_0 = {}
	local var_24_1 = var_0_4:scope(var_0_24) / 2

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.sideTeam_) do
		local var_24_2, var_24_3 = iter_24_1.fighterModel:getPosition()

		if not iter_24_1:isDeath() and not iter_24_1:isAffected() and var_24_1 >= math.abs(arg_24_1 - var_24_2) then
			table.insert(var_24_0, iter_24_1)
		end
	end

	return var_24_0
end

return var_0_3
