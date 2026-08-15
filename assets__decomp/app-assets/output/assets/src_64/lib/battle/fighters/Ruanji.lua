local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ruanji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = {
	40010530
}
local var_0_7 = 0.2
local var_0_8 = 0.0015
local var_0_9 = 90
local var_0_10 = 0.3
local var_0_11 = 0.004
local var_0_12 = 180
local var_0_13 = 1
local var_0_14 = 30
local var_0_15 = 0.1
local var_0_16 = 0.005
local var_0_17 = 10000608
local var_0_18 = 10000609
local var_0_19 = 0.1
local var_0_20 = 80010139
local var_0_21 = {
	40011739
}
local var_0_22 = 0.5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyBuff_ = false
	arg_1_0.energyBeginCount_ = 0
	arg_1_0.energyContinueCount_ = 0
	arg_1_0.energyEndCount_ = 0
	arg_1_0.energyCureToHarm_ = {}
	arg_1_0.energyHarmToCure_ = {}
	arg_1_0.blueTarget_ = nil
	arg_1_0.blueCount_ = 0
	arg_1_0.blueShiledHarm_ = 0
	arg_1_0.greenExtraHarmCount_ = 0
	arg_1_0.records_.blue_shiled_num = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() then
		arg_2_0.isEnergyBuff_ = true
		arg_2_0.energyBeginCount_ = var_0_13

		arg_2_0:skinBuffAction(nil)
	elseif var_0_5:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_2_0.blueTarget_ = arg_2_1.target
		arg_2_0.blueCount_ = var_0_9
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0.blueCount_ > 0 then
		arg_3_0.blueCount_ = arg_3_0.blueCount_ - 1

		if arg_3_0.blueCount_ <= 0 then
			arg_3_0.blueTarget_ = nil
		end
	end

	if arg_3_0.energyBeginCount_ > 0 then
		arg_3_0.energyBeginCount_ = arg_3_0.energyBeginCount_ - 1

		if arg_3_0.energyBeginCount_ <= 0 then
			arg_3_0.energyContinueCount_ = var_0_12

			arg_3_0:getFighterModel():playAnimation_("gongji05", true)
		end
	end

	if arg_3_0.energyContinueCount_ > 0 then
		arg_3_0.energyContinueCount_ = arg_3_0.energyContinueCount_ - 1

		if arg_3_0.energyContinueCount_ == 0 then
			arg_3_0:playAttack(6)

			arg_3_0.energyEndCount_ = var_0_14
		end
	end

	if arg_3_0.energyEndCount_ > 0 then
		arg_3_0.energyEndCount_ = arg_3_0.energyEndCount_ - 1

		if arg_3_0.energyEndCount_ == 0 then
			arg_3_0.isEnergyBuff_ = false
		end
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_3_0.blueShiledNum_[tostring(var_0_1.ctx.battle.count)] and arg_3_0.blueTarget_ then
		local var_3_0 = arg_3_0:newBuff(var_0_6, arg_3_0.blueTarget_, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_3_0.blueShiledHarm_ = arg_3_0.blueShiledNum_[tostring(var_0_1.ctx.battle.count)]

		arg_3_0.blueTarget_:addBuffs(var_3_0)
		arg_3_0:skinBuffAction(var_3_0)
	end
end

function var_0_3.skinBuffAction(arg_4_0, arg_4_1)
	if arg_4_0.skinSkillID_ == var_0_20 then
		local var_4_0 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1 ~= arg_4_0.blueTarget_ then
				table.insert(var_4_0, iter_4_1)
			end
		end

		if #var_4_0 > 0 then
			local var_4_1 = math.random(tonumber(os.time()))

			math.randomseed(var_4_1)

			local var_4_2 = var_4_0[math.random(#var_4_0)]

			arg_4_0.blueShiledHarm_ = 0

			local var_4_3 = arg_4_0:newBuff(var_0_21, var_4_2, var_0_20)

			if arg_4_1 and arg_4_1[1] and var_4_3 and var_4_3[1] then
				var_4_3[1].manualDharm = arg_4_1[1]:totalDHarm() * var_0_22
			end

			var_4_2:addBuffs(var_4_3)
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == unpack(var_0_6) then
		arg_5_1.manualDharm = arg_5_0.blueShiledHarm_
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) == var_0_5:father(arg_6_1.rootID_) then
		arg_6_0.greenExtraHarmCount_ = 0
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	if arg_7_1.skillID == var_0_18 then
		arg_7_4 = arg_7_0.energyCureToHarm_[arg_7_1.target]
	elseif arg_7_1.skillID == var_0_17 then
		arg_7_5 = arg_7_0.energyHarmToCure_[arg_7_1.target]
	elseif var_0_5:father(arg_7_1.skillID) == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		for iter_7_0 = 1, arg_7_0.greenExtraHarmCount_ do
			arg_7_4 = arg_7_4 * (1 + var_0_19)
		end

		arg_7_0.greenExtraHarmCount_ = arg_7_0.greenExtraHarmCount_ + 1
	end

	return var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
end

function var_0_3.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if arg_8_0.isEnergyBuff_ and arg_8_1.skillID ~= var_0_17 and arg_8_1.skillID ~= var_0_18 then
		if arg_8_1.target:getTeamType() ~= arg_8_0:getTeamType() then
			if arg_8_1.attackType == var_0_2.AttackType.CURE and arg_8_5 > 0 then
				local var_8_0 = arg_8_5 * (var_0_15 + var_0_16 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

				arg_8_0.energyCureToHarm_[arg_8_1.target] = var_8_0
				arg_8_5 = math.max(0, arg_8_5 - var_8_0)

				local var_8_1 = {
					arg_8_1.target
				}
				local var_8_2 = arg_8_0:createAttackUnits(var_8_1, var_0_18)

				for iter_8_0, iter_8_1 in ipairs(var_8_2) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
					table.insert(arg_8_0.records_.special_units, iter_8_1)
				end
			end
		elseif arg_8_1.attackType ~= var_0_2.AttackType.CURE and arg_8_4 > 0 and not var_0_5:isReflect(arg_8_1.skillID) then
			local var_8_3 = arg_8_4 * (var_0_15 + var_0_16 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

			arg_8_0.energyHarmToCure_[arg_8_1.target] = var_8_3
			arg_8_4 = math.max(0, arg_8_4 - var_8_3)

			local var_8_4 = {
				arg_8_1.target
			}
			local var_8_5 = arg_8_0:createAttackUnits(var_8_4, var_0_17)

			for iter_8_2, iter_8_3 in ipairs(var_8_5) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end
		end
	end

	if arg_8_0.blueTarget_ == arg_8_1.target and arg_8_1.attackType ~= var_0_2.AttackType.CURE and arg_8_4 > 0 and not arg_8_1.target:isHasBuffByID(unpack(var_0_6)) then
		local var_8_6 = arg_8_0:newBuff(var_0_6, arg_8_1.target, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))
		local var_8_7 = arg_8_4 * (var_0_10 + var_0_11 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))

		arg_8_0.blueShiledHarm_ = var_8_7
		arg_8_4 = math.max(0, arg_8_4 - var_8_7)
		arg_8_0.records_.blue_shiled_num[tostring(var_0_1.ctx.battle.count)] = math.floor(var_8_7)

		arg_8_0.blueTarget_:addBuffs(var_8_6)
		arg_8_0:skinBuffAction(var_8_6)
	end

	return var_0_3.super.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
end

function var_0_3.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	local var_9_0 = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if arg_9_1.attackType ~= var_0_2.AttackType.CURE and arg_9_4 > 0 and var_9_0 > 0 then
		local var_9_1 = var_0_7 + var_0_8 * var_9_0

		if var_0_2.weightedChoise({
			var_9_1,
			1 - var_9_1
		}) == 1 then
			local var_9_2 = {
				arg_9_0
			}
			local var_9_3 = arg_9_0:createAttackUnits(var_9_2, arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_9_0, iter_9_1 in ipairs(var_9_3) do
				table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
				table.insert(arg_9_0.records_.special_units, iter_9_1)
			end

			arg_9_4 = 0
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

function var_0_3.newBuff(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		local var_10_1 = var_0_4.new({
			tableID = iter_10_1,
			start = var_0_1.ctx.battle.count,
			level = arg_10_0:getSkillLevelByID(arg_10_3) > 0 and arg_10_0:getSkillLevelByID(arg_10_3) or arg_10_0:getLevel(),
			skillID = arg_10_3,
			fighter = arg_10_0,
			target = arg_10_2
		})

		var_10_1:setIsHit(true)
		var_10_1:setDirection(arg_10_0:getFighterModel():getFlipX())
		table.insert(var_10_0, var_10_1)
	end

	return var_10_0
end

function var_0_3.canAttack(arg_11_0)
	if arg_11_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.canAttack(arg_11_0)
	end
end

function var_0_3.isMoveUnable(arg_12_0)
	if arg_12_0.isEnergyBuff_ then
		return true
	else
		return var_0_3.super.isMoveUnable(arg_12_0)
	end
end

function var_0_3.isBreakImmortal(arg_13_0)
	if arg_13_0.isEnergyBuff_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_13_0)
	end
end

function var_0_3.setupReport(arg_14_0, arg_14_1)
	var_0_3.super.setupReport(arg_14_0, arg_14_1)

	arg_14_0.blueShiledNum_ = arg_14_1.blue_shiled_num
end

function var_0_3.writeReport(arg_15_0)
	local var_15_0 = var_0_3.super.writeReport(arg_15_0)

	var_15_0.blue_shiled_num = arg_15_0.records_.blue_shiled_num

	return var_15_0
end

return var_0_3
