local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangchengyan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000
local var_0_7 = 0
local var_0_8 = 1
local var_0_9 = 40011028
local var_0_10 = 10000971
local var_0_11 = 40011029
local var_0_12 = 40011030
local var_0_13 = 10000922
local var_0_14 = 80010174
local var_0_15 = {
	40011592
}
local var_0_16 = {
	40011590,
	40011591
}
local var_0_17 = var_0_2.tables.elementEquip
local var_0_18 = 20001498
local var_0_19 = 10002429
local var_0_20 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.greenCureNum_ = 0
	arg_1_0.elementCount = 0
	arg_1_0.records_.blue_buff_remove = {}
	arg_1_0.records_.purple_buff_remove = {}
end

function var_0_3.createUnits(arg_2_0, arg_2_1)
	var_0_3.super.createUnits(arg_2_0, arg_2_1)

	if (arg_2_1 or arg_2_0.unitSkills_).rootID_ == arg_2_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:getTargets(var_0_13)

		if next(var_2_0) then
			local var_2_1 = arg_2_0:createAttackUnits(var_2_0, var_0_13)

			for iter_2_0, iter_2_1 in ipairs(var_2_1) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_4 > 0 and arg_3_1.skillID == arg_3_0:getPugongID() and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		local var_3_0 = var_0_8 + var_0_7 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

		arg_3_0.greenCureNum_ = arg_3_0.greenCureNum_ + var_3_0 * arg_3_4
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_1 = arg_3_0.greenCureNum_

		if var_3_1 > var_0_6 then
			var_3_1 = var_0_6
		end

		arg_3_5 = arg_3_5 + var_3_1
		arg_3_0.greenCureNum_ = 0
	elseif arg_3_1.skillID == var_0_19 and arg_3_1.cureHp then
		arg_3_5 = arg_3_1.cureHp + arg_3_5
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	var_0_3.super.buffRemoveAction(arg_4_0, arg_4_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_4_1:getTableID() == var_0_9 then
		arg_4_0:blueSkill(arg_4_1.target)
	end
end

function var_0_3.blueSkill(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1:getX()
	local var_5_1 = var_0_5:scope(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) / 2
	local var_5_2 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
	local var_5_3 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and var_5_1 >= math.abs(iter_5_1:getX() - var_5_0) then
			table.insert(var_5_3, iter_5_1)
		end
	end

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_3:isDeath() and not iter_5_3:isAffected() and var_5_1 >= math.abs(iter_5_3:getX() - var_5_0) then
			table.insert(var_5_3, iter_5_3)
		end
	end

	if next(var_5_3) then
		local var_5_4 = arg_5_0:createAttackUnits(var_5_3, var_0_10)

		for iter_5_4, iter_5_5 in ipairs(var_5_4) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
			table.insert(arg_5_0.records_.special_units, iter_5_5)
		end
	end
end

function var_0_3.blueClearBuff(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1:getTeamType() ~= arg_6_0:getTeamType() and true or false
	local var_6_1
	local var_6_2 = 0

	for iter_6_0, iter_6_1 in ipairs(arg_6_1:getBuffs()) do
		if var_6_0 and iter_6_1:getTableID() ~= var_0_9 and iter_6_1:getBuffForm() == var_0_2.BuffForm.GAIN and iter_6_1.leftCount_ < 10000 and var_6_2 < iter_6_1.leftCount_ and iter_6_1:canRemove() then
			var_6_1 = iter_6_1
			var_6_2 = iter_6_1.leftCount_
		elseif not var_6_0 and iter_6_1:getTableID() ~= var_0_9 and iter_6_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and iter_6_1.leftCount_ < 10000 and var_6_2 < iter_6_1.leftCount_ and iter_6_1:canRemove() then
			var_6_1 = iter_6_1
			var_6_2 = iter_6_1.leftCount_
		end
	end

	if var_6_1 then
		local var_6_3 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_6_0.blueBuffRemove and arg_6_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)] and arg_6_0.blueBuffRemove[tostring(var_0_1.ctx.battle.count)][arg_6_1.fighterIndex] then
				var_6_3 = true
			end
		else
			local var_6_4 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
			local var_6_5 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(arg_6_1:getLevel() - var_6_4, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)

			var_6_3 = var_0_2.weightedChoise({
				var_6_5,
				1 - var_6_5
			}) == 1

			if var_6_3 then
				if not arg_6_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)] then
					arg_6_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)] = {}
				end

				arg_6_0.records_.blue_buff_remove[tostring(var_0_1.ctx.battle.count)][arg_6_1.fighterIndex] = 1
			end
		end

		if var_6_3 then
			arg_6_1:removeBuffs(var_6_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.target:getTeamType() == arg_7_0:getTeamType() and arg_7_1.attackType == var_0_2.AttackType.CURE and arg_7_0.skinSkillID_ == var_0_14 then
		arg_7_1.target:addBuffs(arg_7_0:newBuff(var_0_15, arg_7_1.target, var_0_14, arg_7_0:getLevel()))
	end

	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and not arg_7_1.target:isDeath() then
		local var_7_0 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_7_1 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(arg_7_1.target:getLevel() - var_7_0, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)

		arg_7_0:purpleClearBuff(var_7_1, arg_7_1.target)
	elseif arg_7_1.skillID == var_0_10 then
		arg_7_0:blueClearBuff(arg_7_1.target)
	end
end

function var_0_3.purpleClearBuff(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = false

	if arg_8_2:getTeamType() ~= arg_8_0:getTeamType() then
		var_8_0 = true
	end

	local var_8_1 = false

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_8_0.purpleBuffRemove and arg_8_0.purpleBuffRemove[tostring(var_0_1.ctx.battle.count)] then
			var_8_1 = true
		end
	else
		var_8_1 = var_0_2.weightedChoise({
			arg_8_1,
			1 - arg_8_1
		}) == 1

		if var_8_1 then
			arg_8_0.records_.purple_buff_remove[tostring(var_0_1.ctx.battle.count)] = 1
		end
	end

	if var_8_1 then
		local var_8_2 = arg_8_2:getBuffs()

		for iter_8_0 = #var_8_2, 1, -1 do
			local var_8_3 = var_8_2[iter_8_0]

			if var_8_0 and var_8_3 and var_8_3:getBuffForm() == var_0_2.BuffForm.GAIN and var_8_3.leftCount_ < 3000 and var_8_3:canRemove() then
				arg_8_2:removeBuffs(var_8_3)

				if arg_8_0.skinSkillID_ == var_0_14 then
					arg_8_2:addBuffs(arg_8_0:newBuff(var_0_16, arg_8_2, var_0_14, arg_8_0:getLevel()))
				end
			elseif not var_8_0 and var_8_3 and var_8_3:getBuffForm() == var_0_2.BuffForm.DEBUFF and var_8_3.leftCount_ < 3000 and var_8_3:canRemove() then
				arg_8_2:removeBuffs(var_8_3)
			end
		end

		if arg_8_0:hasElementEquipByID(var_0_18) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and (arg_8_0.elementCount == 0 or var_0_1.ctx.battle.count - arg_8_0.elementCount > var_0_20) then
			local var_8_4 = arg_8_0:getTargets(var_0_19)
			local var_8_5 = arg_8_0:createAttackUnits(var_8_4, var_0_19)
			local var_8_6 = var_0_18
			local var_8_7 = var_0_17:battleAttr(var_8_6, arg_8_0:getElementEquipLevelByID(var_8_6))
			local var_8_8 = arg_8_0.hero_:getElementEquipActiveRate(var_8_6)

			for iter_8_1, iter_8_2 in ipairs(var_8_5) do
				iter_8_2.cureHp = var_8_7 * var_8_8

				table.insert(arg_8_0.moveAttackUnits_, iter_8_2)
				table.insert(arg_8_0.records_.special_units, iter_8_2)
			end

			arg_8_0.elementCount = var_0_20
		end
	end

	local var_8_9 = var_0_11

	if var_8_0 then
		var_8_9 = var_0_12
	end

	local var_8_10 = arg_8_0:newBuff({
		var_8_9
	}, arg_8_2, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	arg_8_2:addBuffs(var_8_10)
end

function var_0_3.setupReport(arg_9_0, arg_9_1)
	var_0_3.super.setupReport(arg_9_0, arg_9_1)

	arg_9_0.blueBuffRemove = arg_9_1.blue_buff_remove
	arg_9_0.purpleBuffRemove = arg_9_1.purple_buff_remove
end

function var_0_3.writeReport(arg_10_0)
	local var_10_0 = var_0_3.super.writeReport(arg_10_0)

	var_10_0.blue_buff_remove = arg_10_0.records_.blue_buff_remove
	var_10_0.purple_buff_remove = arg_10_0.records_.purple_buff_remove

	return var_10_0
end

function var_0_3.newBuff(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_1) do
		local var_11_1 = var_0_4.new({
			tableID = iter_11_1,
			start = var_0_1.ctx.battle.count,
			level = arg_11_4 or arg_11_0:getSkillLevelByID(arg_11_3),
			skillID = arg_11_3,
			fighter = arg_11_0,
			target = arg_11_2
		})

		var_11_1:setIsHit(true)
		var_11_1:setDirection(arg_11_0:getFighterModel():getFlipX())
		table.insert(var_11_0, var_11_1)
	end

	return var_11_0
end

function var_0_3.selectTargetByTypeD1(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.selfTeam_) do
		if not iter_12_1:isAffected() and not iter_12_1:isDeath() and iter_12_1 ~= arg_12_0 then
			table.insert(var_12_0, iter_12_1)
		end
	end

	for iter_12_2, iter_12_3 in ipairs(arg_12_0.sideTeam_) do
		if not iter_12_3:isAffected() and not iter_12_3:isDeath() then
			table.insert(var_12_0, iter_12_3)
		end
	end

	if not next(var_12_0) then
		return {}
	end

	local var_12_1 = var_12_0[math.random(1, #var_12_0)]

	return {
		var_12_1
	}
end

return var_0_3
