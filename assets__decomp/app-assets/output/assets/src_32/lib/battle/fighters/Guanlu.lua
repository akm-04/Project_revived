local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guanlu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 90
local var_0_9 = 270
local var_0_10 = 10000572
local var_0_11 = 40010409
local var_0_12 = 40010411
local var_0_13 = 40010410
local var_0_14 = 10000569
local var_0_15 = 10000571
local var_0_16 = 10000570
local var_0_17 = 10000566
local var_0_18 = 10000568
local var_0_19 = 10000567
local var_0_20 = 50
local var_0_21 = 30

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenTarget_ = nil
	arg_1_0.purpleMove_ = false
	arg_1_0.isPurpleMoving_ = false
	arg_1_0.specialAttackCount_ = 0
	arg_1_0.currentComb_ = 0
	arg_1_0.isSpecialExtra_ = {
		0,
		0,
		0
	}
	arg_1_0.purpleHurtCount_ = 0
	arg_1_0.selfSignBuffCount_ = 270
	arg_1_0.records_.out_posx = {}
	arg_1_0.records_.self_energy_sign = {}
	arg_1_0.records_.blue_enemy_sign = {}
	arg_1_0.records_.pugong_sign = {}
	arg_1_0.records_.green_sign = {}
	arg_1_0.greenCount_ = 0
	arg_1_0.greenHarmCount_ = 0
	arg_1_0.energyCount_ = 0
	arg_1_0.energyHarmCount_ = 0
	arg_1_0.energySkillRegion_ = nil
	arg_1_0.purpleMoveCount_ = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_2_0 = arg_2_1.rootID_

		arg_2_0.greenTarget_ = unpack(var_0_4.B4(arg_2_0, var_2_0))

		if arg_2_0.greenTarget_ then
			arg_2_0.greenCount_ = var_0_6:pretime(var_2_0)

			local var_2_1

			if arg_2_0.greenTarget_:getX() > arg_2_0:getX() then
				arg_2_0:flipX(false)

				var_2_1 = -1
			else
				arg_2_0:flipX(true)

				var_2_1 = 1
			end

			arg_2_0.xPre_ = (arg_2_0.greenTarget_:getX() + var_2_1 * 30 - arg_2_0:getX()) / 10
			arg_2_0.yPre_ = (arg_2_0.greenTarget_:getY() + 100 - arg_2_0:getY()) / 10
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = {
		var_0_11,
		var_0_12,
		var_0_13
	}

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_1 = {
			100,
			500,
			800,
			1200
		}

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			arg_3_1.target:x(var_3_1[arg_3_0.outPosX_[tostring(var_0_1.ctx.battle.count)]])

			local var_3_2 = arg_3_0.blueEnemySign_[tostring(var_0_1.ctx.battle.count)]
			local var_3_3 = arg_3_0:randomSignBuff(var_3_2, arg_3_1.target, arg_3_1.skillID)

			if var_3_3 then
				arg_3_1.target:addBuffs({
					var_3_3
				})
			end
		else
			local var_3_4 = math.random(1, 4)

			arg_3_0.records_.out_posx[tostring(var_0_1.ctx.battle.count)] = var_3_4

			arg_3_1.target:x(var_3_1[var_3_4])

			local var_3_5 = math.random(1, 3)

			arg_3_0.records_.blue_enemy_sign[tostring(var_0_1.ctx.battle.count)] = var_3_5

			local var_3_6 = arg_3_0:randomSignBuff(var_3_5, arg_3_1.target, arg_3_1.skillID)

			if var_3_6 then
				arg_3_1.target:addBuffs({
					var_3_6
				})
			end
		end
	elseif arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.energyCount_ = var_0_20
		arg_3_0.energyHarmCount_ = 0

		local var_3_7 = {
			x = arg_3_1.target:getX(),
			y = arg_3_1.target:getY()
		}
		local var_3_8 = var_0_20
		local var_3_9 = var_0_1.ctx.battle.getSpine(arg_3_1.skillID, "area", 1)

		var_3_9:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_3_9:pos(var_3_7.x, var_3_7.y)
		var_3_9:scale(1.5)
		var_3_9:playRepeat()

		arg_3_0.energySkillRegion_ = {
			posX = var_3_7.x,
			posY = var_3_7.y,
			time = var_3_8,
			effect = var_3_9
		}
	elseif arg_3_1.skillID == arg_3_0:getPugongID() then
		local var_3_10

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_3_10 = arg_3_0.pugongSign_[tostring(var_0_1.ctx.battle.count)]
		else
			var_3_10 = math.random(1, 3)
			arg_3_0.records_.pugong_sign[tostring(var_0_1.ctx.battle.count)] = var_3_10
		end

		local var_3_11 = arg_3_0:randomSignBuff(var_3_10, arg_3_0, arg_3_0:getPugongID())

		if var_3_11 then
			arg_3_1.target:addBuffs({
				var_3_11
			})
		end
	elseif arg_3_1.skillID == var_0_10 then
		local var_3_12

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_3_12 = arg_3_0.greenSign_[tostring(var_0_1.ctx.battle.count)]
		else
			var_3_12 = math.random(1, 3)
			arg_3_0.records_.green_sign[tostring(var_0_1.ctx.battle.count)] = var_3_12
		end

		local var_3_13 = arg_3_0:randomSignBuff(var_3_12, arg_3_0, arg_3_1.skillID)

		if var_3_13 then
			arg_3_1.target:addBuffs({
				var_3_13
			})
		end
	end
end

function var_0_3.energyAttack(arg_4_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = {}
		local var_4_1 = arg_4_0.energySkillRegion_.posX
		local var_4_2 = var_0_6:scope(arg_4_0:getEnergySkillID())

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and math.abs(iter_4_1:getX() - var_4_1) < 0.5 * var_4_2 then
				table.insert(var_4_0, iter_4_1)
			end
		end

		local var_4_3 = math.random(1, 3)
		local var_4_4 = {
			var_0_17,
			var_0_18,
			var_0_19
		}
		local var_4_5 = arg_4_0:createAttackUnits(var_4_0, var_4_4[var_4_3])

		for iter_4_2, iter_4_3 in ipairs(var_4_5) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end
	end
end

function var_0_3.randomSignBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if type(arg_5_1) ~= "number" or not arg_5_2 then
		return
	end

	local var_5_0 = {
		var_0_11,
		var_0_12,
		var_0_13
	}
	local var_5_1 = var_0_5.new({
		tableID = var_5_0[arg_5_1],
		start = var_0_1.ctx.battle.count,
		level = arg_5_0:getSkillLevelByID(arg_5_3),
		skillID = arg_5_3,
		fighter = arg_5_0,
		target = arg_5_2
	})

	var_5_1:setIsHit(true)
	var_5_1:setDirection(arg_5_0:getFighterModel():getFlipX())

	return var_5_1
end

function var_0_3.toDoPerFrames(arg_6_0)
	if var_0_1.ctx.battle.count % 15 == 0 then
		local var_6_0 = {}
		local var_6_1 = {}
		local var_6_2 = {}

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
				if iter_6_1:isHasBuffByID(var_0_11) then
					table.insert(var_6_0, iter_6_1)
				end

				if iter_6_1:isHasBuffByID(var_0_12) then
					table.insert(var_6_1, iter_6_1)
				end

				if iter_6_1:isHasBuffByID(var_0_13) then
					table.insert(var_6_2, iter_6_1)
				end
			end
		end

		if arg_6_0:isHasBuffByID(var_0_11) then
			table.insert(var_6_0, arg_6_0)
		end

		if arg_6_0:isHasBuffByID(var_0_12) then
			table.insert(var_6_1, arg_6_0)
		end

		if arg_6_0:isHasBuffByID(var_0_13) then
			table.insert(var_6_2, arg_6_0)
		end

		arg_6_0:checkSignBuff(var_6_0, 1)
		arg_6_0:checkSignBuff(var_6_1, 2)
		arg_6_0:checkSignBuff(var_6_2, 3)
	end

	if arg_6_0.specialAttackCount_ > 0 then
		arg_6_0.specialAttackCount_ = arg_6_0.specialAttackCount_ - 1
		arg_6_0.currentComb_ = 0
		arg_6_0.isSpecialExtra_ = {
			0,
			0,
			0
		}
	end

	if arg_6_0.greenCount_ > 0 then
		local var_6_3 = 60 - arg_6_0.greenCount_

		if var_6_3 >= 25 and var_6_3 <= 35 then
			if arg_6_0.unitSkills_ and arg_6_0.unitSkills_.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
				arg_6_0:moveByX(arg_6_0.xPre_)
			end
		elseif var_6_3 == 37 then
			arg_6_0.greenHarmCount_ = 5
		end

		arg_6_0.greenCount_ = arg_6_0.greenCount_ - 1
	end

	if arg_6_0.greenHarmCount_ > 0 then
		arg_6_0.greenHarmCount_ = arg_6_0.greenHarmCount_ - 1

		if arg_6_0.greenHarmCount_ <= 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_4 = {}

			if arg_6_0.greenTarget_ then
				local var_6_5 = var_0_6:scope(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

				if not arg_6_0.greenTarget_:isDeath() and not arg_6_0.greenTarget_:isAffected() and math.abs(arg_6_0.greenTarget_:getX() - arg_6_0:getX()) <= var_6_5 * 0.5 then
					table.insert(var_6_4, arg_6_0.greenTarget_)
				end
			end

			local var_6_6 = arg_6_0:createAttackUnits(var_6_4, var_0_10)

			for iter_6_2, iter_6_3 in ipairs(var_6_6) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end
		end
	end

	if arg_6_0.energySkillRegion_ and (arg_6_0.energyCount_ == 0 or arg_6_0:isDeath()) then
		arg_6_0.energySkillRegion_.effect:removeSelf()

		arg_6_0.energySkillRegion_ = nil
	end

	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.energyCount_ > 0 then
		arg_6_0.energyCount_ = arg_6_0.energyCount_ - 1
		arg_6_0.energyHarmCount_ = arg_6_0.energyHarmCount_ + 1

		if arg_6_0:getFighterModel().currentAnimation_ ~= "gongji05" then
			arg_6_0:playAttack(5)
		end

		if arg_6_0.energyHarmCount_ == 12 then
			arg_6_0.energyHarmCount_ = 0

			arg_6_0:energyAttack()
		end

		if arg_6_0:isAdUnable() or arg_6_0:isApUnable() then
			arg_6_0.energyCount_ = 0
			arg_6_0.energyHarmCount_ = 0

			arg_6_0:resumeIdle()
		end
	end

	if arg_6_0.selfSignBuffCount_ > 0 then
		arg_6_0.selfSignBuffCount_ = arg_6_0.selfSignBuffCount_ - 1

		if arg_6_0.selfSignBuffCount_ == 0 then
			local var_6_7

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				var_6_7 = arg_6_0.selfEnergySign_[tostring(var_0_1.ctx.battle.count)]
			else
				var_6_7 = math.random(1, 3)
				arg_6_0.records_.self_energy_sign[tostring(var_0_1.ctx.battle.count)] = var_6_7
			end

			local var_6_8 = arg_6_0:randomSignBuff(var_6_7, arg_6_0, arg_6_0:getEnergySkillID())

			if var_6_8 then
				arg_6_0:addBuffs({
					var_6_8
				})
			end

			arg_6_0.selfSignBuffCount_ = var_0_9
		end
	end

	if arg_6_0.purpleMove_ and not arg_6_0:isMoveUnable() and not arg_6_0:isCreatingUnits() and arg_6_0.energyCount_ == 0 and arg_6_0:getNearestTarget() then
		arg_6_0.isPurpleMoving_ = true
		arg_6_0.purpleMoveCount_ = var_0_21

		local var_6_9 = 30

		if arg_6_0:getFighterModel().currentAnimation_ ~= "gongji04" then
			arg_6_0:playAttack(4)
		end

		if arg_6_0:getTeamType() ~= var_0_2.TeamType.A then
			if arg_6_0:getX() < var_0_2.STAGE_WIDTH - 60 then
				arg_6_0:flipX(true)

				local var_6_10 = math.min(var_6_9, var_0_2.STAGE_WIDTH - 50 - arg_6_0:getX())

				arg_6_0:moveByX(var_6_10)
			else
				arg_6_0.purpleMove_ = false
			end
		elseif arg_6_0:getX() <= 60 then
			arg_6_0.purpleMove_ = false
		else
			arg_6_0:flipX(false)

			local var_6_11 = math.max(-var_6_9, 50 - arg_6_0:getX())

			arg_6_0:moveByX(var_6_11)
		end
	end

	if arg_6_0.purpleMoveCount_ > 0 then
		arg_6_0.purpleMoveCount_ = arg_6_0.purpleMoveCount_ - 1

		if arg_6_0.purpleMoveCount_ <= 0 then
			arg_6_0.isPurpleMoving_ = false
		end
	end
end

function var_0_3.checkSignBuff(arg_7_0, arg_7_1, arg_7_2)
	if #arg_7_1 < 1 then
		return
	end

	local var_7_0 = 100
	local var_7_1 = {}
	local var_7_2 = ({
		var_0_11,
		var_0_12,
		var_0_13
	})[arg_7_2]

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		if not var_7_1[iter_7_1] then
			if #iter_7_1:getBuffsByID(var_7_2) > 1 then
				var_7_1[iter_7_1] = 1
			else
				for iter_7_2, iter_7_3 in ipairs(arg_7_1) do
					if iter_7_3 ~= iter_7_1 and var_7_0 >= math.abs(iter_7_3:getX() - iter_7_1:getX()) then
						var_7_1[iter_7_3] = 1
						var_7_1[iter_7_1] = 1

						break
					end
				end
			end
		end
	end

	if next(var_7_1) then
		local var_7_3 = {}

		for iter_7_4, iter_7_5 in pairs(var_7_1) do
			table.insert(var_7_3, iter_7_4)
		end

		arg_7_0:energyEffect(var_7_3, arg_7_2)
	end
end

function var_0_3.energyEffect(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {
		var_0_11,
		var_0_12,
		var_0_13
	}
	local var_8_1 = {
		var_0_14,
		var_0_15,
		var_0_16
	}

	if arg_8_0.specialAttackCount_ > 0 then
		arg_8_0.isSpecialExtra_[arg_8_2] = arg_8_0.currentComb_
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_2 = {}

		for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
			if iter_8_1.hero_:getFirstTableID() ~= arg_8_0.hero_:getFirstTableID() then
				table.insert(var_8_2, iter_8_1)
			end
		end

		local var_8_3 = arg_8_0:createAttackUnits(var_8_2, var_8_1[arg_8_2])

		for iter_8_2, iter_8_3 in ipairs(var_8_3) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
			table.insert(arg_8_0.records_.special_units, iter_8_3)
		end
	end

	for iter_8_4, iter_8_5 in ipairs(arg_8_1) do
		iter_8_5:removeBuffByID(var_8_0[arg_8_2])
	end

	arg_8_0.currentComb_ = math.min(arg_8_0.currentComb_ + 1, 9)
	arg_8_0.specialAttackCount_ = var_0_8
end

function var_0_3.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5 = var_0_3.super.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_9_2 >= arg_9_0:getHpLimit() * 0.1 then
			arg_9_0.purpleMove_ = true
		else
			arg_9_0.purpleHurtCount_ = arg_9_0.purpleHurtCount_ + 1

			if arg_9_0.purpleHurtCount_ >= 5 then
				arg_9_0.purpleHurtCount_ = 0
				arg_9_0.purpleMove_ = true
			end
		end
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5
end

function var_0_3.isAffected(arg_10_0)
	if arg_10_0.isPurpleMoving_ or arg_10_0.greenCount_ > 0 then
		return true
	else
		return var_0_3.super.isAffected(arg_10_0)
	end
end

function var_0_3.canAttack(arg_11_0)
	if arg_11_0.isPurpleMoving_ or arg_11_0.energyCount_ > 0 then
		return false
	else
		return var_0_3.super.canAttack(arg_11_0)
	end
end

function var_0_3.isMoveUnable(arg_12_0)
	if arg_12_0.energyCount_ > 0 then
		return true
	else
		return var_0_3.super.isMoveUnable(arg_12_0)
	end
end

function var_0_3.setupReport(arg_13_0, arg_13_1)
	var_0_3.super.setupReport(arg_13_0, arg_13_1)

	arg_13_0.outPosX_ = arg_13_1.out_posx
	arg_13_0.selfEnergySign_ = arg_13_1.self_energy_sign
	arg_13_0.blueEnemySign_ = arg_13_1.blue_enemy_sign
	arg_13_0.pugongSign_ = arg_13_1.pugong_sign
	arg_13_0.greenSign_ = arg_13_1.green_sign
end

function var_0_3.writeReport(arg_14_0)
	local var_14_0 = var_0_3.super.writeReport(arg_14_0)

	var_14_0.out_posx = arg_14_0.records_.out_posx
	var_14_0.self_energy_sign = arg_14_0.records_.self_energy_sign
	var_14_0.blue_enemy_sign = arg_14_0.records_.blue_enemy_sign
	var_14_0.pugong_sign = arg_14_0.records_.pugong_sign
	var_14_0.green_sign = arg_14_0.records_.green_sign

	return var_14_0
end

function var_0_3.buffAddAction(arg_15_0, arg_15_1)
	if arg_15_1.skillID_ == var_0_16 then
		local var_15_0 = arg_15_1:getTableID()
		local var_15_1 = var_0_7:time(var_15_0) * (arg_15_0.isSpecialExtra_[3] * 0.1)

		arg_15_1:setExtraTime(var_15_1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
	if arg_16_1.skillID == var_0_15 then
		arg_16_4 = arg_16_4 * (1 + arg_16_0.isSpecialExtra_[2] * 0.1)
	elseif arg_16_1.skillID == var_0_14 then
		arg_16_7 = arg_16_7 * (1 + arg_16_0.isSpecialExtra_[1] * 0.1)
	end

	return var_0_3.super.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
end

function var_0_3.selectTargetByTypeD1(arg_17_0, arg_17_1, arg_17_2)
	local function var_17_0(arg_18_0, arg_18_1)
		local var_18_0 = {}

		table.insert(var_18_0, arg_18_0)

		for iter_18_0, iter_18_1 in ipairs(arg_18_0.selfTeam_) do
			if not iter_18_1:isDeath() and not iter_18_1:isAffected() and iter_18_1 ~= arg_18_0 and arg_18_1 >= math.abs(iter_18_1:getX() - arg_18_0:getX()) then
				table.insert(var_18_0, iter_18_1)
			end
		end

		return var_18_0
	end

	local var_17_1
	local var_17_2 = -1
	local var_17_3 = var_0_6:scope(arg_17_1) * 0.5

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.targetTeam_) do
		if not iter_17_1:isDeath() and not iter_17_1:isAffected() then
			local var_17_4 = var_17_0(iter_17_1, var_17_3)

			if var_17_2 < #var_17_4 then
				var_17_1 = iter_17_1
				var_17_2 = #var_17_4
			end
		end
	end

	return {
		var_17_1
	}
end

return var_0_3
