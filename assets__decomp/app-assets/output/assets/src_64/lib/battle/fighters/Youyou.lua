local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 1
local var_0_7 = 0.02
local var_0_8 = 0
local var_0_9 = 0.003
local var_0_10 = 0.25
local var_0_11 = 60
local var_0_12 = 40010682
local var_0_13 = 10000673
local var_0_14 = 10002363
local var_0_15 = 3
local var_0_16 = 40010683
local var_0_17 = 0
local var_0_18 = 0.05
local var_0_19 = 2000
local var_0_20 = 80
local var_0_21 = 0.4
local var_0_22 = 40010681
local var_0_23 = 40010680

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.records_.purple_buff_rebound = {}
	arg_2_0.purpleSkillCounts_ = {}
	arg_2_0.blueTimeCount_ = {}
	arg_2_0.energyAdHarmCount_ = 0
	arg_2_0.energyApHarmCount_ = 0
	arg_2_0.energyBaseHarm_ = 0
	arg_2_0.addEnergyBuff = 0
	arg_2_0.reboundTotalHarm_ = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	local var_3_0 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)
	local var_3_1 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_3_0 > 0 then
		local var_3_2 = (var_0_6 + var_0_7 * var_3_0) * 30

		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_1.target:getTeamType() == arg_3_0:getTeamType() then
				if iter_3_1:getBuffForm() == var_0_2.BuffForm.GAIN then
					iter_3_1:setExtraTime(var_3_2)
				elseif arg_3_0:checkBuffCanRebound(iter_3_1) and iter_3_1.target:getBuffByID(var_0_16) then
					arg_3_0:updateBuffByPurple(iter_3_1)
				end

				if var_3_1 > 0 and iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
					if arg_3_0.purpleSkillCounts_[iter_3_1.target] then
						arg_3_0.purpleSkillCounts_[iter_3_1.target] = arg_3_0.purpleSkillCounts_[iter_3_1.target] + 1
					else
						arg_3_0.purpleSkillCounts_[iter_3_1.target] = 1
					end
				end
			end
		end

		if var_3_1 > 0 then
			local var_3_3 = {}

			for iter_3_2, iter_3_3 in pairs(arg_3_0.purpleSkillCounts_) do
				if iter_3_3 >= var_0_15 then
					table.insert(var_3_3, iter_3_2)

					arg_3_0.purpleSkillCounts_[iter_3_2] = 0
				end
			end

			if var_3_3 and next(var_3_3) then
				arg_3_0:usePurpleSkill(var_3_3)
			end
		end
	end

	local var_3_4 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

	for iter_3_4, iter_3_5 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
		local var_3_5 = iter_3_5.harm
		local var_3_6 = arg_3_0:getTeamType()
		local var_3_7 = iter_3_5.fighter
		local var_3_8 = iter_3_5.target

		if var_3_4 > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_3_5 > 0 and var_3_8:getTeamType() == var_3_6 and var_3_8:getBuffByID(var_0_12) and arg_3_0:checkCanRebound(var_3_7) then
			local var_3_9 = arg_3_0:getChance(var_3_4)
			local var_3_10 = math.min(1, var_3_9)

			if var_0_2.weightedChoise({
				var_3_10,
				1 - var_3_10
			}) == 1 then
				local var_3_11 = {
					var_3_7
				}
				local var_3_12 = var_3_5

				if not arg_3_0.reboundTotalHarm_[var_3_8] then
					arg_3_0.reboundTotalHarm_[var_3_8] = var_3_8:getHpLimit() * var_0_10
				end

				if var_3_12 >= arg_3_0.reboundTotalHarm_[var_3_8] then
					var_3_12 = arg_3_0.reboundTotalHarm_[var_3_8]

					local var_3_13 = arg_3_0:createAttackUnits({
						var_3_8
					}, var_0_14)

					for iter_3_6, iter_3_7 in ipairs(var_3_13) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
						table.insert(arg_3_0.records_.special_units, iter_3_7)
					end

					arg_3_0.reboundTotalHarm_[var_3_8] = 0
				else
					arg_3_0.reboundTotalHarm_[var_3_8] = arg_3_0.reboundTotalHarm_[var_3_8] - var_3_12
				end

				arg_3_0.blueTimeCount_[var_3_7] = var_0_1.ctx.battle.count

				if var_3_11 and next(var_3_11) then
					local var_3_14 = arg_3_0:createAttackUnits(var_3_11, var_0_13)

					for iter_3_8, iter_3_9 in ipairs(var_3_14) do
						iter_3_9.rebound_harm = var_3_12

						table.insert(arg_3_0.moveAttackUnits_, iter_3_9)
						table.insert(arg_3_0.records_.special_units, iter_3_9)
					end
				end
			end
		end

		if var_3_5 > 0 then
			if iter_3_5.type == var_0_2.AttackType.AP then
				arg_3_0.energyApHarmCount_ = arg_3_0.energyApHarmCount_ + var_3_5
			elseif iter_3_5.type == var_0_2.AttackType.AD then
				arg_3_0.energyAdHarmCount_ = arg_3_0.energyAdHarmCount_ + var_3_5
			end
		end
	end
end

function var_0_3.checkBuffCanRebound(arg_4_0, arg_4_1)
	if arg_4_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and not arg_4_1:isYongJiu() and arg_4_1:getTime() < 10000 and arg_4_1:canRemove() then
		return true
	end

	return false
end

function var_0_3.updateBuffByPurple(arg_5_0, arg_5_1)
	if not arg_5_1.fighter:isDeath() and not arg_5_1.fighter:isAffected() then
		local var_5_0 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_5_0.purpleBuffRebound[tostring(var_0_1.ctx.battle.count)] then
				var_5_0 = true
			end
		else
			local var_5_1 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

			var_5_0 = arg_5_0:getPurpleChance(arg_5_1.fighter, var_5_1)

			if var_5_0 then
				arg_5_0.records_.purple_buff_rebound[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_5_0 then
			local var_5_2 = arg_5_0:newBuff({
				arg_5_1:getTableID()
			}, arg_5_1.fighter, arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

			arg_5_1.fighter:addBuffs(var_5_2)
		end
	end

	arg_5_1.target:removeBuffs(arg_5_1)
	arg_5_1.target:removeBuffByID(var_0_16)
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.purpleBuffRebound = arg_6_1.purple_buff_rebound
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.purple_buff_rebound = arg_7_0.records_.purple_buff_rebound

	return var_7_0
end

function var_0_3.applySingleUnit(arg_8_0, arg_8_1)
	var_0_3.super.applySingleUnit(arg_8_0, arg_8_1)

	if arg_8_0.addEnergyBuff ~= 0 then
		local var_8_0 = arg_8_0:newBuff({
			arg_8_0.addEnergyBuff
		}, arg_8_1.target, arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

		arg_8_1.target:addBuffs(var_8_0)
	end

	if arg_8_1.skillID == var_0_14 then
		arg_8_1.target:removeBuffByID(var_0_12)
	end
end

function var_0_3.calculateUnitData(arg_9_0, arg_9_1)
	local var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = var_0_3.super.calculateUnitData(arg_9_0, arg_9_1)

	if arg_9_1.skillID == var_0_13 and arg_9_1.rebound_harm and arg_9_1.rebound_harm > 0 then
		var_9_2 = arg_9_1.rebound_harm * arg_9_1.target:getADJianShang()
		arg_9_1.rebound_harm = 0
	elseif arg_9_1.skillID == arg_9_0:getEnergySkillID() then
		var_9_2 = arg_9_0.energyBaseHarm_ * arg_9_1.target:getADJianShang()
	end

	return var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5
end

function var_0_3.usePurpleSkill(arg_10_0, arg_10_1)
	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
			local var_10_0 = iter_10_1:getBuffs()

			for iter_10_2 = #var_10_0, 1, -1 do
				if var_10_0[iter_10_2] and var_10_0[iter_10_2]:getBuffForm() == var_0_2.BuffForm.DEBUFF and var_10_0[iter_10_2]:canRemove() then
					iter_10_1:removeBuffs(var_10_0[iter_10_2])
				end
			end

			local var_10_1 = arg_10_0:newBuff({
				var_0_16
			}, iter_10_1, arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

			iter_10_1:addBuffs(var_10_1)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.teamType_ == var_0_2.TeamType.A and true or false
	local var_11_1 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_11_2 = 0
			local var_11_3, var_11_4 = iter_11_1:getPos()

			if var_11_0 then
				var_11_2 = var_11_3
			else
				var_11_2 = -var_11_3
			end

			table.insert(var_11_1, {
				target = iter_11_1,
				distance = var_11_2
			})
		end
	end

	if #var_11_1 == 0 then
		return {}
	end

	table.sort(var_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0.distance ~= arg_12_1.distance then
			return arg_12_0.distance > arg_12_1.distance
		end
	end)

	local var_11_5 = 1

	for iter_11_2 = 1, #var_11_1 do
		if not var_11_1[iter_11_2].target:getBuffByID(var_0_12) then
			var_11_5 = iter_11_2

			break
		end
	end

	return {
		var_11_1[var_11_5].target
	}
end

function var_0_3.selectTargetByTypeD2(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_13_0, iter_13_1)
		end
	end

	if #var_13_0 == 0 then
		return {}
	end

	arg_13_0.addEnergyBuff = 0

	local var_13_1 = 0
	local var_13_2 = arg_13_0:getEnergyHarmLimit()

	if arg_13_0.energyAdHarmCount_ > 0 and arg_13_0.energyAdHarmCount_ >= arg_13_0.energyApHarmCount_ then
		if (arg_13_0.energyAdHarmCount_ - arg_13_0.energyApHarmCount_) / arg_13_0.energyAdHarmCount_ > var_0_21 then
			arg_13_0.addEnergyBuff = var_0_23
		end

		var_13_1 = arg_13_0.energyAdHarmCount_ - arg_13_0.energyApHarmCount_
	elseif arg_13_0.energyApHarmCount_ > 0 then
		if (arg_13_0.energyApHarmCount_ - arg_13_0.energyAdHarmCount_) / arg_13_0.energyApHarmCount_ > var_0_21 then
			arg_13_0.addEnergyBuff = var_0_22
		end

		var_13_1 = arg_13_0.energyApHarmCount_ - arg_13_0.energyAdHarmCount_
	end

	arg_13_0.energyApHarmCount_ = 0
	arg_13_0.energyAdHarmCount_ = 0
	arg_13_0.energyBaseHarm_ = var_13_1 / #var_13_0

	if var_13_2 < arg_13_0.energyBaseHarm_ then
		arg_13_0.energyBaseHarm_ = var_13_2
	end

	return var_13_0
end

function var_0_3.getEnergyHarmLimit(arg_14_0)
	local var_14_0 = arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_20 + var_0_19

	if arg_14_0.isStarEnergy_ then
		local var_14_1 = arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)

		var_14_0 = var_14_0 + var_0_5:desc4NumStep(var_14_1)[2]
	end

	return var_14_0
end

function var_0_3.newBuff(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		local var_15_1 = var_0_4.new({
			tableID = iter_15_1,
			start = var_0_1.ctx.battle.count,
			level = arg_15_0:getSkillLevelByID(arg_15_3),
			skillID = arg_15_3,
			fighter = arg_15_0,
			target = arg_15_2
		})

		var_15_1:setIsHit(true)
		var_15_1:setDirection(arg_15_0:getFighterModel():getFlipX())
		table.insert(var_15_0, var_15_1)
	end

	return var_15_0
end

function var_0_3.checkCanRebound(arg_16_0, arg_16_1)
	local var_16_0 = var_0_1.ctx.battle.count

	if arg_16_1:isDeath() or arg_16_1:isAffected() then
		return false
	elseif arg_16_0.blueTimeCount_[arg_16_1] and var_16_0 - arg_16_0.blueTimeCount_[arg_16_1] < var_0_11 then
		return false
	end

	return true
end

function var_0_3.getChance(arg_17_0, arg_17_1)
	local var_17_0 = var_0_9 * arg_17_1 + var_0_8

	if arg_17_0.isStarBlue_ then
		local var_17_1 = arg_17_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_17_2 = var_0_5:desc4NumStep(var_17_1)[2]
		local var_17_3 = arg_17_1

		var_17_0 = var_17_2 / 100 + var_17_0
	end

	return var_17_0
end

function var_0_3.getPurpleChance(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_2

	if arg_18_0.isStarPurple_ then
		local var_18_1 = arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

		var_18_0 = var_18_0 + var_0_5:desc4NumStep(var_18_1)[2]
	end

	local var_18_2 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(arg_18_1:getLevel() - var_18_0, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)

	return var_0_2.weightedChoise({
		var_18_2,
		1 - var_18_2
	}) == 1
end

return var_0_3
