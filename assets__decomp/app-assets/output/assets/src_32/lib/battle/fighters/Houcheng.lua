local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Houcheng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 5
local var_0_9 = 15
local var_0_10 = 10000547
local var_0_11 = 40010382
local var_0_12 = 300
local var_0_13 = 45
local var_0_14 = 51
local var_0_15 = 0.15

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.passionNum_ = 0
	arg_2_0.energyTimes_ = 0
	arg_2_0.energyBeginCount_ = 0
	arg_2_0.energyContinueCount_ = 0
	arg_2_0.energyEndCount_ = 0
	arg_2_0.blueCount_ = 0
	arg_2_0.isEnergying_ = false
	arg_2_0.isGreenBuff_ = false
	arg_2_0.bluePassionReady_ = false
	arg_2_0.energyTransBuff_ = {}
	arg_2_0.records_.skin_passion = {}
	arg_2_0.records_.get_random_target = {}

	arg_2_0:updateStateNumber(arg_2_0.passionNum_)
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0.blueCount_ = var_0_7:pretime(arg_3_1.rootID_) - 2
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0.isGreenBuff_ = true
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0.blueCount_ > 0 then
		arg_5_0.blueCount_ = arg_5_0.blueCount_ - 1

		if arg_5_0.blueCount_ == 0 then
			arg_5_0:addPassionNum(1)
		end

		if not arg_5_0.unitSkills_ or arg_5_0.unitSkills_.rootID_ ~= arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			arg_5_0.blueCount_ = 0
		end
	end

	if arg_5_0.energyBeginCount_ > 0 then
		arg_5_0.energyBeginCount_ = arg_5_0.energyBeginCount_ - 1

		if arg_5_0.energyBeginCount_ == 0 then
			arg_5_0.energyContinueCount_ = var_0_12

			arg_5_0:getFighterModel():playAnimation_("gongji05", true)
		end
	end

	if arg_5_0.energyContinueCount_ > 0 then
		arg_5_0.energyContinueCount_ = arg_5_0.energyContinueCount_ - 1

		if arg_5_0.energyContinueCount_ == 0 then
			arg_5_0:playAttack(6)

			arg_5_0.energyEndCount_ = var_0_14
		end
	end

	if arg_5_0.energyEndCount_ > 0 then
		arg_5_0.energyEndCount_ = arg_5_0.energyEndCount_ - 1

		if arg_5_0.energyEndCount_ == 0 then
			arg_5_0.isEnergying_ = false
			arg_5_0.energyTransBuff_ = {}
		end
	end

	if arg_5_0.isGreenBuff_ and not arg_5_0:isHasBuffByID(var_0_11) then
		arg_5_0.isGreenBuff_ = false
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
		local var_5_0 = iter_5_1.target

		if var_5_0:getTeamType() ~= arg_5_0:getTeamType() and iter_5_1:getBuffForm() == var_0_2.BuffForm.GAIN then
			if not arg_5_0.isEnergying_ then
				local var_5_1 = 1

				if arg_5_0.isGreenBuff_ then
					var_5_1 = 2
				end

				arg_5_0:addPassionNum(var_5_1)
			else
				arg_5_0:enemyTransBuff(var_5_0, iter_5_1)
			end
		end

		if (arg_5_0.isEnergying_ or arg_5_0.isGreenBuff_) and var_5_0:getTeamType() == arg_5_0:getTeamType() and iter_5_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and (iter_5_1:getTime() < 10000 or not iter_5_1:isYongJiu()) then
			if arg_5_0.isEnergying_ then
				arg_5_0:selfTeamTransBuff(var_5_0, iter_5_1)
			elseif arg_5_0.isGreenBuff_ then
				arg_5_0:addPassionNum(1)
			end
		end
	end
end

function var_0_3.selfTeamTransBuff(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_2:getTableID()

	if arg_6_0.energyTransBuff_[var_6_0] then
		return
	else
		arg_6_0.energyTransBuff_[var_6_0] = true
	end

	arg_6_1:removeBuffByID(var_6_0)

	local var_6_1 = arg_6_0:getTransBuffTarget(2, var_6_0)

	if var_6_1 then
		local var_6_2 = arg_6_0:newBuff({
			var_6_0
		}, var_6_1, arg_6_0:getEnergySkillID())

		var_6_1:addBuffs(var_6_2)
	end
end

function var_0_3.getTransBuffTarget(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_7_0.getRandomTarget_[tostring(var_0_1.ctx.battle.count)] then
			local var_7_1 = arg_7_0.getRandomTarget_[tostring(var_0_1.ctx.battle.count)]

			for iter_7_0 = 1, #var_7_1 do
				if var_7_1[iter_7_0].index == arg_7_1 and var_7_1[iter_7_0].buffID == arg_7_2 then
					if var_7_1[iter_7_0].target_id then
						var_7_0 = arg_7_0:getRandomTarget(arg_7_1, var_7_1[iter_7_0].target_id)
					end

					table.remove(arg_7_0.getRandomTarget_[tostring(var_0_1.ctx.battle.count)], iter_7_0)

					break
				end
			end
		end
	else
		var_7_0 = arg_7_0:getRandomTarget(arg_7_1)

		if not arg_7_0.records_.get_random_target[tostring(var_0_1.ctx.battle.count)] then
			arg_7_0.records_.get_random_target[tostring(var_0_1.ctx.battle.count)] = {}
		end

		local var_7_2 = {
			index = arg_7_1,
			buffID = arg_7_2
		}

		if var_7_0 then
			var_7_2.target_id = var_7_0:getTableID()
		end

		table.insert(arg_7_0.records_.get_random_target[tostring(var_0_1.ctx.battle.count)], var_7_2)
	end

	return var_7_0
end

function var_0_3.enemyTransBuff(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_2:getTableID()

	if arg_8_0.energyTransBuff_[var_8_0] then
		return
	else
		arg_8_0.energyTransBuff_[var_8_0] = true
	end

	arg_8_1:removeBuffByID(var_8_0)

	local var_8_1 = arg_8_0:getTransBuffTarget(1, var_8_0)

	if var_8_1 then
		local var_8_2 = arg_8_0:newBuff({
			var_8_0
		}, var_8_1, arg_8_0:getEnergySkillID())

		var_8_1:addBuffs(var_8_2)
	end
end

function var_0_3.checkPassion(arg_9_0, arg_9_1)
	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_9_0 = 1, arg_9_1 do
			local var_9_0 = arg_9_0:createAttackUnits({
				arg_9_0
			}, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_9_1, iter_9_2 in ipairs(var_9_0) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_2)
				table.insert(arg_9_0.records_.special_units, iter_9_2)
			end
		end
	end

	if arg_9_0.passionNum_ >= var_0_9 then
		arg_9_0.passionNum_ = 0
		arg_9_0.energyTimes_ = arg_9_0.energyTimes_ + 1

		arg_9_0:doEnergyAction()
	end

	arg_9_0:updateStateNumber(arg_9_0.passionNum_)
end

function var_0_3.addPassionNum(arg_10_0, arg_10_1)
	arg_10_0.passionNum_ = arg_10_0.passionNum_ + arg_10_1

	if arg_10_0.isSkinSkillOn_ then
		local var_10_0 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_10_0.skinAddPassion[tostring(var_0_1.ctx.battle.count)] then
				var_10_0 = true
			end
		else
			local var_10_1 = var_0_15

			var_10_0 = var_0_2.weightedChoise({
				var_10_1,
				1 - var_10_1
			}) == 1

			if var_10_0 then
				arg_10_0.records_.skin_passion[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_10_0 then
			arg_10_0.passionNum_ = arg_10_0.passionNum_ + 1
		end
	end

	arg_10_0:checkPassion(arg_10_1)
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.skinAddPassion = arg_11_1.skin_passion
	arg_11_0.getRandomTarget_ = arg_11_1.get_random_target
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.skin_passion = arg_12_0.records_.skin_passion
	var_12_0.get_random_target = arg_12_0.records_.get_random_target

	return var_12_0
end

function var_0_3.getRandomTarget(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}
	local var_13_1
	local var_13_2

	if arg_13_1 == 1 then
		var_13_2 = arg_13_0.selfTeam_
	elseif arg_13_1 == 2 then
		var_13_2 = arg_13_0.sideTeam_
	else
		return
	end

	if arg_13_2 then
		for iter_13_0, iter_13_1 in ipairs(var_13_2) do
			if iter_13_1:getTableID() == arg_13_2 then
				return iter_13_1
			end
		end

		return
	end

	for iter_13_2, iter_13_3 in ipairs(var_13_2) do
		if not iter_13_3:isDeath() and not iter_13_3:isAffected() then
			table.insert(var_13_0, iter_13_3)
		end
	end

	if #var_13_0 >= 1 then
		var_13_1 = var_13_0[math.random(#var_13_0)]
	end

	return var_13_1
end

function var_0_3.newBuff(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		local var_14_1 = {
			tableID = iter_14_1,
			start = var_0_1.ctx.battle.count,
			skillID = arg_14_3,
			fighter = arg_14_0,
			target = arg_14_2
		}

		if arg_14_3 == arg_14_0:getEnergySkillID() then
			var_14_1.level = arg_14_0:getSkillLevelByID(arg_14_3) + math.max(0, arg_14_0.energyTimes_ - 1) * var_0_8
		else
			var_14_1.level = arg_14_0:getSkillLevelByID(arg_14_3)
		end

		local var_14_2 = var_0_4.new(var_14_1)

		var_14_2:setIsHit(true)
		var_14_2:setDirection(arg_14_0:getFighterModel():getFlipX())
		table.insert(var_14_0, var_14_2)
	end

	return var_14_0
end

function var_0_3.doEnergyAction(arg_15_0)
	arg_15_0.isEnergying_ = true

	arg_15_0:playAttack(4)

	arg_15_0.energyBeginCount_ = var_0_13

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_15_0 = {}

		for iter_15_0, iter_15_1 in ipairs(arg_15_0.selfTeam_) do
			if not iter_15_1:isDeath() and not iter_15_1:isAffected() then
				table.insert(var_15_0, iter_15_1)
			end
		end

		local var_15_1 = arg_15_0:createAttackUnits(var_15_0, var_0_10)

		for iter_15_2, iter_15_3 in ipairs(var_15_1) do
			table.insert(arg_15_0.moveAttackUnits_, iter_15_3)
			table.insert(arg_15_0.records_.special_units, iter_15_3)
		end
	end
end

function var_0_3.canAttack(arg_16_0)
	if arg_16_0.isEnergying_ then
		return false
	else
		return var_0_3.super.canAttack(arg_16_0)
	end
end

function var_0_3.isBreakImmortal(arg_17_0)
	if arg_17_0.isEnergying_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_17_0)
	end
end

function var_0_3.checkEnergySkill(arg_18_0)
	return false
end

function var_0_3.selectTargetByTypeD1(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = {}

	for iter_19_0, iter_19_1 in ipairs(arg_19_0.targetTeam_) do
		if var_0_6:distanceType(iter_19_1:getTableID()) == var_0_2.DistanceType.QIANPAI then
			table.insert(var_19_0, iter_19_1)
		end
	end

	return var_19_0
end

function var_0_3.updateEnergyTo(arg_20_0, arg_20_1)
	return
end

function var_0_3.updateEnergyBy(arg_21_0, arg_21_1, arg_21_2)
	return
end

function var_0_3.updateEnergyByHarm(arg_22_0, arg_22_1)
	return
end

function var_0_3.updateEnergyByCount(arg_23_0)
	return
end

return var_0_3
