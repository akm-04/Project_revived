local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhanghong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 10000463
local var_0_7 = 10000462
local var_0_8 = 300
local var_0_9 = {
	40010220,
	40010221,
	40010222
}
local var_0_10 = 80010110
local var_0_11 = 0.15
local var_0_12 = 81010110
local var_0_13 = 300
local var_0_14 = {
	30010050
}
local var_0_15 = 10001112
local var_0_16 = 80010112
local var_0_17 = {
	160,
	480,
	800,
	1120
}
local var_0_18 = 30
local var_0_19 = 10001100
local var_0_20 = 10001099
local var_0_21 = 10001096
local var_0_22 = 80020110
local var_0_23 = 10001095
local var_0_24 = 80021110
local var_0_25 = 10001098

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillRegion_ = {}
	arg_1_0.negetiveTarget_ = nil
	arg_1_0.positiveTarget_ = nil
	arg_1_0.isBlueEffect_ = false
	arg_1_0.energyEffects_ = {}
	arg_1_0.isEnergyEffect_ = false
	arg_1_0.skinZhanghongJudgeDelay_ = 2
	arg_1_0.skinZhanghongJudge_ = false
	arg_1_0.skinPartner_ = nil
	arg_1_0.skinShowEffect_ = nil
	arg_1_0.energySkillRegion = {}
	arg_1_0.bombSkillRegion = {}
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:updateEnergyEffect()
	arg_2_0:updateBombEffect()
end

function var_0_3.updateEnergyEffect(arg_3_0)
	if not arg_3_0:acttionInBlack() then
		return
	end

	if next(arg_3_0.energySkillRegion) ~= nil then
		for iter_3_0 = #arg_3_0.energySkillRegion, 1, -1 do
			local var_3_0 = arg_3_0.energySkillRegion[iter_3_0]

			var_3_0.time = var_3_0.time - 1

			var_3_0.effect:pos(var_3_0.initPos.x + (var_3_0.totalTime - var_3_0.time) * var_3_0.speed, var_3_0.initPos.y)

			for iter_3_1, iter_3_2 in ipairs(var_0_17) do
				if var_3_0.speed > 0 then
					if iter_3_2 <= var_3_0.effect:getX() and var_3_0.notAttack[iter_3_1] == 0 then
						var_3_0.notAttack[iter_3_1] = 1

						arg_3_0:bombSkill(var_3_0.effect:getX(), var_3_0.effect:getY() - iter_3_1 % 2 * 80)
					end
				elseif iter_3_2 >= var_3_0.effect:getX() and var_3_0.notAttack[iter_3_1] == 0 then
					var_3_0.notAttack[iter_3_1] = 1

					arg_3_0:bombSkill(var_3_0.effect:getX(), var_3_0.effect:getY() - iter_3_1 % 2 * 80)
				end
			end

			if var_3_0.time <= 0 then
				var_3_0.effect:removeSelf()

				var_3_0.effect = nil

				table.remove(arg_3_0.energySkillRegion, iter_3_0)
			end
		end
	end
end

function var_0_3.updateBombEffect(arg_4_0)
	if not arg_4_0:acttionInBlack() then
		return
	end

	if next(arg_4_0.bombSkillRegion) ~= nil then
		for iter_4_0 = #arg_4_0.bombSkillRegion, 1, -1 do
			local var_4_0 = arg_4_0.bombSkillRegion[iter_4_0]

			var_4_0.time = var_4_0.time - 1

			if var_4_0.time == 0 then
				if arg_4_0.skinPartner_ and not arg_4_0.skinPartner_:isDeath() then
					arg_4_0.isEnergyEffect_ = true

					local var_4_1 = {
						x = var_4_0.effect:getX(),
						y = var_4_0.effect:getY()
					}
					local var_4_2 = var_0_1.ctx.battle.getSpine(arg_4_0.skinPartner_:getEnergySkillID(), "area", 1)

					var_4_2:addTo(var_0_1.ctx.battle.unitBottomLayer)
					var_4_2:pos(var_4_1.x, var_4_1.y)
					var_4_2:setScale(0.5)
					var_4_2:playRepeat()

					local var_4_3 = {
						posX = var_4_1.x,
						posY = var_4_1.y,
						effect = var_4_2
					}

					table.insert(arg_4_0.energyEffects_, var_4_3)
				end

				var_4_0.effect:removeSelf()

				var_4_0.effect = nil

				table.remove(arg_4_0.bombSkillRegion, iter_4_0)
			end
		end
	end
end

function var_0_3.bombSkill(arg_5_0, arg_5_1, arg_5_2)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:selectTargetByTypeD3(arg_5_1)

		if arg_5_0.skinPartner_ and not arg_5_0.skinPartner_:isDeath() then
			local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_25)

			for iter_5_0, iter_5_1 in ipairs(var_5_1) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		else
			local var_5_2 = arg_5_0:createAttackUnits(var_5_0, var_0_23)

			for iter_5_2, iter_5_3 in ipairs(var_5_2) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
				table.insert(arg_5_0.records_.special_units, iter_5_3)
			end
		end
	end

	local var_5_3 = {
		x = arg_5_1,
		y = arg_5_2
	}
	local var_5_4 = var_0_18
	local var_5_5 = var_0_1.ctx.battle.getSpine(var_0_19, "area", 1)

	var_5_5:addTo(var_0_1.ctx.battle.unitBottomLayer)
	var_5_5:pos(var_5_3.x, var_5_3.y)
	var_5_5:playRepeat()
	var_5_5:flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)

	local var_5_6 = {
		pos = var_5_3,
		time = var_5_4,
		effect = var_5_5
	}

	table.insert(arg_5_0.bombSkillRegion, var_5_6)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if not arg_6_0.positiveTarget_ then
			arg_6_0.positiveTarget_ = arg_6_1.target
		elseif arg_6_0.positiveTarget_ ~= arg_6_1.target then
			arg_6_0.isBlueEffect_ = true
			arg_6_0.negetiveTarget_ = arg_6_1.target
		else
			arg_6_0.positiveTarget_ = nil
		end
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_6_0 = {
			x = arg_6_1.target:getX(),
			y = arg_6_1.target:getY()
		}
		local var_6_1 = var_0_8
		local var_6_2 = var_0_1.ctx.battle.getSpine(arg_6_1.skillID, "area", 1)

		var_6_2:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_6_2:pos(var_6_0.x, var_6_0.y)
		var_6_2:playRepeat()

		local var_6_3 = {
			posX = var_6_0.x,
			posY = var_6_0.y,
			time = var_6_1,
			effect = var_6_2
		}

		table.insert(arg_6_0.purpleSkillRegion_, var_6_3)
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_6_4

		if arg_6_1.target:getTeamType() ~= var_0_2.TeamType.A then
			if var_0_1.ctx.battle.isUnlimitBattle then
				var_6_4 = var_0_2.UNLIMIT_STAGE_WIDTH
			else
				var_6_4 = var_0_2.STAGE_WIDTH
			end
		else
			var_6_4 = 0
		end

		arg_6_1.target:x(var_6_4)
	elseif arg_6_1.skillID == var_0_10 then
		arg_6_0:checkAddSkinBuff(arg_6_1)
	elseif arg_6_1.skillID == var_0_24 then
		arg_6_0:playSkinSkillEffect()
		arg_6_0:setImmuneControl(false)
		arg_6_0.skinPartner_:setImmuneControl(false)
	elseif arg_6_1.skillID == var_0_22 then
		arg_6_0:playSkinSkillEffect()
	end
end

function var_0_3.toDoPerFrames(arg_7_0)
	if arg_7_0.isBlueEffect_ then
		if not arg_7_0.negetiveTarget_ or arg_7_0.negetiveTarget_:isDeath() or not arg_7_0.positiveTarget_ or arg_7_0.positiveTarget_:isDeath() then
			arg_7_0.negetiveTarget_ = nil
			arg_7_0.positiveTarget_ = nil
			arg_7_0.isBlueEffect_ = false
		else
			if arg_7_0.negetiveTarget_:getX() > arg_7_0.positiveTarget_:getX() then
				arg_7_0.negetiveTarget_:moveByX(-10)
				arg_7_0.positiveTarget_:moveByX(10)
			else
				arg_7_0.negetiveTarget_:moveByX(10)
				arg_7_0.positiveTarget_:moveByX(-10)
			end

			if math.abs(arg_7_0.negetiveTarget_:getX() - arg_7_0.positiveTarget_:getX()) <= 50 then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_7_0 = {
						arg_7_0.negetiveTarget_,
						arg_7_0.positiveTarget_
					}
					local var_7_1 = arg_7_0:createAttackUnits(var_7_0, var_0_7)

					for iter_7_0, iter_7_1 in ipairs(var_7_1) do
						table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
						table.insert(arg_7_0.records_.special_units, iter_7_1)
					end
				end

				arg_7_0.negetiveTarget_ = nil
				arg_7_0.positiveTarget_ = nil
				arg_7_0.isBlueEffect_ = false
			end
		end
	end

	for iter_7_2 = #arg_7_0.purpleSkillRegion_, 1, -1 do
		local var_7_2 = arg_7_0.purpleSkillRegion_[iter_7_2]

		var_7_2.time = var_7_2.time - 1

		if var_7_2.time <= 0 then
			for iter_7_3, iter_7_4 in ipairs(arg_7_0.sideTeam_) do
				if not iter_7_4:isDeath() and not iter_7_4:isAffected() and iter_7_4:isHasBuffByID(var_0_9[1]) and arg_7_0:isInPurpleCircle(iter_7_4, var_7_2) then
					for iter_7_5, iter_7_6 in ipairs(var_0_9) do
						iter_7_4:removeBuffByID(iter_7_6)
					end
				end
			end

			var_7_2.effect:removeSelf()
			table.remove(arg_7_0.purpleSkillRegion_, iter_7_2)
		end
	end

	if next(arg_7_0.purpleSkillRegion_) and var_0_1.ctx.battle.count % 10 == 0 then
		for iter_7_7, iter_7_8 in ipairs(arg_7_0.purpleSkillRegion_) do
			arg_7_0:removePurpleBuff(iter_7_8)
			arg_7_0:addPurpleBuff(iter_7_8)
		end
	end

	if var_0_1.ctx.battle.count % 10 == 0 and next(arg_7_0.energyEffects_) then
		for iter_7_9, iter_7_10 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_10:isDeath() and not iter_7_10:isAffected() then
				if iter_7_10:isHasBuffByID(var_0_14[1]) and not arg_7_0:isInEnergyCircle(iter_7_10) then
					for iter_7_11, iter_7_12 in ipairs(var_0_14) do
						iter_7_10:removeBuffByID(iter_7_12)
					end
				elseif not iter_7_10:isHasBuffByID(var_0_14[1]) and arg_7_0:isInEnergyCircle(iter_7_10) then
					iter_7_10:addBuffs(arg_7_0:newBuff(var_0_14, iter_7_10, arg_7_0:getEnergySkillID()))
				end
			end
		end
	end

	if not arg_7_0.skinZhanghongJudge_ and arg_7_0.isSkinSkillOn_ and arg_7_0.skinSkillID_ == var_0_22 then
		if arg_7_0.skinZhanghongJudgeDelay_ > 0 then
			arg_7_0.skinZhanghongJudgeDelay_ = arg_7_0.skinZhanghongJudgeDelay_ - 1
		else
			arg_7_0.skinZhanghongJudge_ = true

			for iter_7_13, iter_7_14 in ipairs(arg_7_0.selfTeam_) do
				if iter_7_14.hero_:getTableID() == var_0_15 or iter_7_14.hero_:beforeAwakenID() == var_0_15 then
					if iter_7_14.isSkinSkillOn_ and iter_7_14.skinSkillID_ == var_0_16 then
						arg_7_0.skinPartner_ = iter_7_14
						iter_7_14.skinPartner_ = arg_7_0
					end

					break
				end
			end
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_8_0)
	local var_8_0 = var_0_3.super.getOrbOfFrontSkill(arg_8_0)

	if var_8_0 == arg_8_0:getEnergySkillID() and arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_22 then
		if arg_8_0.skinPartner_ and not arg_8_0.skinPartner_:isDeath() then
			return var_0_24
		else
			return var_0_22
		end
	end

	return var_8_0
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == var_0_22 then
		-- block empty
	elseif arg_9_1.rootID_ == var_0_24 then
		arg_9_0.isEnergyEffect_ = false

		arg_9_0:playPartnerSkinSkillEffect()
		arg_9_0:setImmuneControl(true)
		arg_9_0.skinPartner_:setImmuneControl(true)
	end
end

function var_0_3.energyAction(arg_10_0, arg_10_1)
	if arg_10_1 == var_0_24 then
		arg_10_0:getFighterModel():playEnergyEffect_()
		arg_10_0:updateEnergyTo(arg_10_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		arg_10_0.skinPartner_:getFighterModel():playEnergyEffect_()
		arg_10_0.skinPartner_:updateEnergyTo(arg_10_0.skinPartner_:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		local var_10_0 = var_0_4:attackIndex(var_0_16)

		arg_10_0.skinPartner_:playAttack(var_10_0)
		arg_10_0:addBlackLayer(arg_10_1)
	elseif arg_10_1 == var_0_22 then
		arg_10_0:getFighterModel():playEnergyEffect_()
		arg_10_0:updateEnergyTo(arg_10_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)
		arg_10_0:addBlackLayer(arg_10_1)
	else
		var_0_3.super.energyAction(arg_10_0, arg_10_1)
	end
end

function var_0_3.addBlackLayer(arg_11_0, arg_11_1)
	if arg_11_1 == var_0_24 then
		if var_0_1.ctx.battle.isUnlimitBattle then
			if not arg_11_0.isNotFirstEnergySkill_ then
				arg_11_0.isNotFirstEnergySkill_ = true
			else
				return
			end
		end

		if var_0_1.ctx.battle.isEnergySkilling then
			var_0_1.ctx.battle.isEnergySkilling = math.max(var_0_1.ctx.battle.isEnergySkilling, 46)

			arg_11_0:unsetMaskColor()
			arg_11_0:resume()
			arg_11_0.skinPartner_:unsetMaskColor()
			arg_11_0.skinPartner_:resume()

			if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
				transition.scaleTo(arg_11_0.fighterModel, {
					time = 0.2,
					scale = 1.1
				})
				transition.scaleTo(arg_11_0.skinPartner_.fighterModel, {
					time = 0.2,
					scale = 1.1
				})
			end

			arg_11_0.acttionInBlack_ = true
			arg_11_0.skinPartner_.acttionInBlack_ = true

			return
		end

		arg_11_0.acttionInBlack_ = true
		arg_11_0.skinPartner_.acttionInBlack_ = true

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			transition.scaleTo(arg_11_0.fighterModel, {
				time = 0.2,
				scale = 1.1
			})
			transition.scaleTo(arg_11_0.skinPartner_.fighterModel, {
				time = 0.2,
				scale = 1.1
			})
		end

		var_0_1.ctx.battle.stopAllFighter()
		var_0_1.ctx.battle.blackLayer:show()

		var_0_1.ctx.battle.isEnergySkilling = 46
	else
		var_0_3.super.addBlackLayer(arg_11_0)
	end
end

function var_0_3.playPartnerSkinSkillEffect(arg_12_0)
	if not arg_12_0.skinPartner_ or var_0_1.ctx.battle.isSpecialSkill or var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_12_0.skinShowEffect_ then
		arg_12_0.skinShowEffect_:removeSelf()

		arg_12_0.skinShowEffect_ = nil
	end

	local var_12_0 = var_0_1.ctx.battle.getSpine(var_0_21, "area", 1)

	var_12_0:addTo(var_0_1.ctx.battle.unitLayer)

	if var_0_1.ctx.battle.isUnlimitBattle then
		var_12_0:pos(var_0_2.UNLIMIT_STAGE_WIDTH * 0.5, var_0_2.UNLIMIT_STAGE_HEIGHT * 0.5 - 50)
	else
		var_12_0:pos(var_0_2.STAGE_WIDTH * 0.5, var_0_2.STAGE_HEIGHT * 0.5)
	end

	var_12_0:playOnce(function()
		arg_12_0.skinShowEffect_:hide()
	end)

	arg_12_0.skinShowEffect_ = var_12_0
end

function var_0_3.playSkinSkillEffect(arg_14_0)
	local var_14_0 = var_0_1.ctx.battle.getSpine(var_0_20, "unit", 1)

	var_14_0:addTo(var_0_1.ctx.battle.unitBottomLayer)

	local var_14_1 = arg_14_0:getTeamType() == var_0_2.TeamType.A and {
		x = 0,
		y = 330
	} or {
		x = 1280,
		y = 330
	}
	local var_14_2 = arg_14_0:getTeamType() == var_0_2.TeamType.B and {
		x = 0,
		y = 330
	} or {
		x = 1280,
		y = 330
	}
	local var_14_3 = arg_14_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_14_4 = var_0_4:speed(var_0_20) * var_14_3
	local var_14_5 = math.ceil(math.abs((var_14_2.x - var_14_1.x) / var_14_4))
	local var_14_6 = {
		0,
		0,
		0,
		0
	}
	local var_14_7 = {
		initPos = var_14_1,
		totalTime = var_14_5,
		time = var_14_5,
		effect = var_14_0,
		speed = var_14_4,
		notAttack = var_14_6
	}

	var_14_0:pos(var_14_1.x, var_14_1.y)
	var_14_0:playRepeat()
	var_14_0:flipX(arg_14_0:getTeamType() == var_0_2.TeamType.B)
	table.insert(arg_14_0.energySkillRegion, var_14_7)
end

function var_0_3.isInEnergyCircle(arg_15_0, arg_15_1)
	for iter_15_0, iter_15_1 in ipairs(arg_15_0.energyEffects_) do
		if math.abs(arg_15_1:getX() - iter_15_1.posX) <= var_0_13 * 0.5 then
			return true
		end
	end

	return false
end

function var_0_3.selectTargetByTypeD3(arg_16_0, arg_16_1)
	local var_16_0 = {}
	local var_16_1 = var_0_4:scope(var_0_23) / 2

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		local var_16_2, var_16_3 = iter_16_1.fighterModel:getPosition()

		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and var_16_1 >= math.abs(arg_16_1 - var_16_2) then
			table.insert(var_16_0, iter_16_1)
		end
	end

	return var_16_0
end

function var_0_3.selectTargetByTypeD1(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = {}

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.sideTeam_) do
		if not iter_17_1:isDeath() and not iter_17_1:isAffected() then
			table.insert(var_17_0, iter_17_1)
		end
	end

	if #var_17_0 > 1 then
		table.sort(var_17_0, function(arg_18_0, arg_18_1)
			return arg_18_0:getDamage() > arg_18_1:getDamage()
		end)

		return {
			var_17_0[1],
			var_17_0[2]
		}
	else
		local var_17_1 = unpack(var_17_0)

		return {
			var_17_1,
			var_17_1
		}
	end
end

function var_0_3.selectTargetByTypeD2(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = -1
	local var_19_1
	local var_19_2 = {}
	local var_19_3 = var_0_4:scope(arg_19_1)

	for iter_19_0, iter_19_1 in ipairs(arg_19_0.sideTeam_) do
		if not iter_19_1:isDeath() and not iter_19_1:isAffected() and iter_19_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_19_4 = iter_19_1.hero_:getMainAttr(var_0_2.AttributeType.STRENGTH)

			if var_19_0 < var_19_4 then
				var_19_0 = var_19_4
				var_19_1 = iter_19_1
			end
		end
	end

	if var_19_1 then
		table.insert(var_19_2, var_19_1)

		for iter_19_2, iter_19_3 in ipairs(arg_19_0.sideTeam_) do
			if not iter_19_3:isDeath() and not iter_19_3:isAffected() and iter_19_3 ~= var_19_1 and var_19_3 >= math.abs(var_19_1:getX() - iter_19_3:getX()) * 2 then
				table.insert(var_19_2, iter_19_3)
			end
		end
	end

	return var_19_2
end

function var_0_3.checkAddSkinBuff(arg_20_0, arg_20_1)
	if arg_20_1.target:isDeath() or arg_20_1.target:isAffected() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if var_0_2.weightedChoise({
		var_0_11,
		1 - var_0_11
	}) == 1 then
		local var_20_0 = arg_20_0:createAttackUnits({
			arg_20_1.target
		}, var_0_12)

		for iter_20_0, iter_20_1 in ipairs(var_20_0) do
			table.insert(arg_20_0.moveAttackUnits_, iter_20_1)
			table.insert(arg_20_0.records_.special_units, iter_20_1)
		end
	end
end

function var_0_3.isInPurpleCircle(arg_21_0, arg_21_1, arg_21_2)
	if var_0_4:scope(arg_21_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) * 0.5 >= math.abs(arg_21_1:getX() - arg_21_2.posX) then
		return true
	else
		return false
	end
end

function var_0_3.removePurpleBuff(arg_22_0, arg_22_1)
	for iter_22_0, iter_22_1 in ipairs(arg_22_0.sideTeam_) do
		if not iter_22_1:isDeath() and not iter_22_1:isAffected() and iter_22_1:isHasBuffByID(var_0_9[1]) and not arg_22_0:isInPurpleCircle(iter_22_1, arg_22_1) then
			for iter_22_2, iter_22_3 in ipairs(var_0_9) do
				iter_22_1:removeBuffByID(iter_22_3)
			end
		end
	end
end

function var_0_3.addPurpleBuff(arg_23_0, arg_23_1)
	for iter_23_0, iter_23_1 in ipairs(arg_23_0.sideTeam_) do
		if not iter_23_1:isDeath() and not iter_23_1:isAffected() and not iter_23_1:isHasBuffByID(var_0_9[1]) and arg_23_0:isInPurpleCircle(iter_23_1, arg_23_1) then
			iter_23_1:addBuffs(arg_23_0:newBuff(var_0_9, iter_23_1, arg_23_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
		end
	end
end

function var_0_3.newBuff(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	local var_24_0 = {}

	for iter_24_0, iter_24_1 in ipairs(arg_24_1) do
		local var_24_1 = var_0_5.new({
			tableID = iter_24_1,
			start = var_0_1.ctx.battle.count,
			level = arg_24_0:getSkillLevelByID(arg_24_3),
			skillID = arg_24_3,
			fighter = arg_24_0,
			target = arg_24_2
		})

		var_24_1:setYongJiu()
		var_24_1:setIsHit(true)
		var_24_1:setDirection(arg_24_0:getFighterModel():getFlipX())
		table.insert(var_24_0, var_24_1)
	end

	return var_24_0
end

return var_0_3
