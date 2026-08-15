local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shengdanjingling", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = var_0_2.tables.cabinetSkillTable
local var_0_9 = var_0_2.tables.skill
local var_0_10 = 300
local var_0_11 = 15000
local var_0_12 = 10010054
local var_0_13 = 20010105
local var_0_14 = 10010089
local var_0_15 = {
	40010027,
	20010106,
	{
		20010107,
		20010108
	}
}
local var_0_16 = {
	10010087,
	40010026,
	10010088
}
local var_0_17 = 10000172
local var_0_18 = 10000173
local var_0_19 = 10000174
local var_0_20 = 10390008

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.getGiftHeros = {}
	arg_1_0.count = false
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.currentSkillID_ = nil
	arg_1_0.records_.random_buff_count1 = {}
	arg_1_0.records_.random_buff_count2 = {}
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if not arg_2_0.count and not arg_2_0:isDeath() then
		local var_2_0 = arg_2_0:selectTargetByTypeD1()

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			iter_2_1:addBuffs(arg_2_0:newBuffs({
				var_0_14
			}, var_0_17, arg_2_0:getLevel(), iter_2_1))
		end

		arg_2_0.count = true
	end

	if arg_2_0:acttionInBlack() and not arg_2_0:isDeath() and next(arg_2_0.getGiftHeros) ~= nil then
		for iter_2_2 = #arg_2_0.getGiftHeros, 1, -1 do
			local var_2_1 = arg_2_0.getGiftHeros[iter_2_2]

			var_2_1[2] = var_2_1[2] - 1

			if var_2_1[2] == 0 then
				var_2_1[1]:addBuffs(arg_2_0:newBuffs({
					var_0_14
				}, var_0_17, arg_2_0:getLevel(), var_2_1[1]))
				table.remove(arg_2_0.getGiftHeros, iter_2_2)
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.extraSkillJudge then
		arg_3_0.extraSkillJudge = true
		arg_3_0.extraSkillLevel = arg_3_0.hero_:skillBook()[tostring(var_0_20)] or 0
		arg_3_0.extraSkillAddMp = arg_3_0.extraSkillLevel * var_0_8:attrValues(var_0_20)
	end
end

function var_0_3.getOrbOfFrontSkill(arg_4_0)
	local var_4_0 = arg_4_0:getFrontSkill()

	if var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_0:noHopeBuff() then
		var_4_0 = var_0_12
	end

	local var_4_1 = var_0_9:orb(var_4_0)

	if var_4_1 > 0 and arg_4_0:getSkillLevelByID(var_4_1) > 0 then
		return var_4_1
	end

	return var_4_0
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	if arg_5_0.unitSkills_.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_0 = arg_5_0:getRandomSkill(arg_5_0.unitSkills_.idQueue_[1])
		local var_5_1 = arg_5_0:getRandomSkill(arg_5_0.unitSkills_.idQueue_[2])

		arg_5_0.unitSkills_.idQueue_ = {
			var_5_0,
			var_5_1
		}
	end

	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)
end

function var_0_3.noHopeBuff(arg_6_0)
	for iter_6_0, iter_6_1 in ipairs(var_0_1.ctx.battle.teamA) do
		if not iter_6_1:isDeath() and iter_6_1:getSummonType() == 0 and iter_6_1:isHasBuffByID(var_0_14) then
			return false
		end
	end

	for iter_6_2, iter_6_3 in ipairs(var_0_1.ctx.battle.teamB) do
		if not iter_6_3:isDeath() and iter_6_3:getSummonType() == 0 and iter_6_3:isHasBuffByID(var_0_14) then
			return false
		end
	end

	return true
end

function var_0_3.getRandomSkill(arg_7_0, arg_7_1)
	local var_7_0 = var_0_9:randomOrb(arg_7_1)

	if next(var_7_0) then
		local var_7_1 = {}

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			table.insert(var_7_1, 1)
		end

		return var_7_0[var_0_2.weightedChoise(var_7_1)]
	end
end

function var_0_3.newBuffs(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_6.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_3,
			skillID = arg_8_2,
			fighter = arg_8_0,
			target = arg_8_4
		})

		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

function var_0_3.createAttacks(arg_9_0)
	local var_9_0 = arg_9_0.unitSkills_

	if not var_9_0 then
		return
	end

	if var_9_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_9_0.reportSkills_, 1)
		end

		arg_9_0.unitSkills_ = nil

		return
	end

	local var_9_1, var_9_2 = var_9_0:getFront()

	while var_9_1 and var_9_1 < 1 do
		arg_9_0:createUnits(var_9_0)
		var_9_0:popQueue()

		local var_9_3

		var_9_1, var_9_3 = var_9_0:getFront()

		if not arg_9_0:isCreatingUnits() then
			arg_9_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_9_0.reportSkills_, 1)
			end

			local var_9_4 = 0

			if arg_9_0.extraSkillLevel > 0 and (var_9_0.rootID_ == arg_9_0:getPugongID() or var_9_0.rootID_ == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) then
				var_9_4 = arg_9_0.extraSkillAddMp
			end

			arg_9_0:updateEnergyBy(var_9_0:getRemp() + var_9_4)
			arg_9_0:popFrontSkill()
		end
	end
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1.skillID
	local var_10_1 = arg_10_1.target
	local var_10_2 = {
		var_10_1,
		var_0_10
	}

	if var_0_0.table.indexof(var_0_9:randomOrb(var_0_18), var_10_0) or var_0_0.table.indexof(var_0_9:randomOrb(var_0_19), var_10_0) then
		var_10_1:removeBuffByID(var_0_14)
		table.insert(arg_10_0.getGiftHeros, var_10_2)
		arg_10_0:addSpeedBuff()
	elseif var_10_0 == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		if var_10_1:getTeamType() == arg_10_0:getTeamType() then
			local var_10_3 = 1

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				var_10_3 = arg_10_0.randomBuffCount1_[tostring(var_0_1.ctx.battle.count)] or 1
			else
				var_10_3 = math.random(#var_0_15)
				arg_10_0.records_.random_buff_count1[tostring(var_0_1.ctx.battle.count)] = var_10_3
			end

			local var_10_4 = var_0_15[var_10_3]

			if type(var_10_4) == "table" then
				arg_10_1.buffIDs = {
					var_10_4[1],
					var_10_4[2]
				}
			else
				arg_10_1.buffIDs = {
					var_10_4
				}
			end
		else
			local var_10_5 = 1

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				var_10_5 = arg_10_0.randomBuffCount2_[tostring(var_0_1.ctx.battle.count)] or 1
			else
				var_10_5 = math.random(#var_0_16)
				arg_10_0.records_.random_buff_count2[tostring(var_0_1.ctx.battle.count)] = var_10_5
			end

			local var_10_6 = var_0_16[var_10_5]

			arg_10_1.buffIDs = {
				var_10_6
			}
		end

		var_10_1:removeBuffByID(var_0_14)
		table.insert(arg_10_0.getGiftHeros, var_10_2)
		arg_10_0:addSpeedBuff()
	end

	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)
end

function var_0_3.addSpeedBuff(arg_11_0)
	if arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_11_0:addBuffs(arg_11_0:newBuffs({
			var_0_13
		}, arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple), arg_11_0))
	end
end

function var_0_3.selectTargetByTypeD1(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {}
	local var_12_1 = arg_12_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_12_2 = arg_12_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_12_0, iter_12_1 in ipairs(var_12_1) do
		if not iter_12_1:isDeath() and not iter_12_1:isHasBuffByID(var_0_14) and iter_12_1:getTableID() ~= arg_12_0:getTableID() and iter_12_1:getSummonType() == 0 then
			table.insert(var_12_0, iter_12_1)
		end
	end

	for iter_12_2, iter_12_3 in ipairs(var_12_2) do
		if not iter_12_3:isDeath() and not iter_12_3:isHasBuffByID(var_0_14) and iter_12_3:getTableID() ~= arg_12_0:getTableID() and iter_12_3:getSummonType() == 0 then
			table.insert(var_12_0, iter_12_3)
		end
	end

	return var_12_0
end

function var_0_3.selectTargetByTypeD2(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0:getNearestTarget()
	local var_13_1 = {}
	local var_13_2 = arg_13_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_13_0, iter_13_1 in ipairs(var_13_2) do
		if iter_13_1 ~= var_13_0 and not iter_13_1:isDeath() and not iter_13_1:isHasBuffByID(var_0_14) and iter_13_1 ~= arg_13_0 and not iter_13_1:isAffected() then
			table.insert(var_13_1, iter_13_1)
		end
	end

	table.insert(var_13_1, var_13_0)

	return var_13_1
end

function var_0_3.selectTargetByTypeD3(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {}
	local var_14_1 = arg_14_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_14_2 = arg_14_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	if arg_14_0.unitSkills_ and arg_14_0.unitSkills_.rootID_ == arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_14_3 = {}
		local var_14_4 = {}

		for iter_14_0, iter_14_1 in ipairs(var_14_1) do
			if iter_14_1:getTableID() ~= arg_14_0:getTableID() and iter_14_1:getSummonType() == 0 and not iter_14_1:isDeath() and iter_14_1:isHasBuffByID(var_0_14) and not iter_14_1:isAffected() then
				table.insert(var_14_3, iter_14_1)
			end
		end

		for iter_14_2, iter_14_3 in ipairs(var_14_3) do
			table.insert(var_14_0, iter_14_3)
		end

		for iter_14_4, iter_14_5 in ipairs(var_14_2) do
			if iter_14_5:getTableID() ~= arg_14_0:getTableID() and iter_14_5:getSummonType() == 0 and not iter_14_5:isDeath() and iter_14_5:isHasBuffByID(var_0_14) and not iter_14_5:isAffected() then
				table.insert(var_14_4, iter_14_5)
			end
		end

		for iter_14_6, iter_14_7 in ipairs(var_14_4) do
			table.insert(var_14_0, iter_14_7)
		end
	elseif var_0_0.table.indexof(var_0_9:randomOrb(var_0_18), arg_14_1) then
		local var_14_5 = {}

		for iter_14_8, iter_14_9 in ipairs(var_14_1) do
			if iter_14_9:getTableID() ~= arg_14_0:getTableID() and iter_14_9:getSummonType() == 0 and not iter_14_9:isDeath() and iter_14_9:isHasBuffByID(var_0_14) and not iter_14_9:isAffected() then
				table.insert(var_14_5, iter_14_9)
			end
		end

		if next(var_14_5) ~= nil then
			local var_14_6 = var_14_5[math.random(#var_14_5)]

			table.insert(var_14_0, var_14_6)
		end
	elseif var_0_0.table.indexof(var_0_9:randomOrb(var_0_19), arg_14_1) then
		local var_14_7 = {}

		for iter_14_10, iter_14_11 in ipairs(var_14_2) do
			if iter_14_11:getTableID() ~= arg_14_0:getTableID() and iter_14_11:getSummonType() == 0 and not iter_14_11:isDeath() and iter_14_11:isHasBuffByID(var_0_14) and not iter_14_11:isAffected() then
				table.insert(var_14_7, iter_14_11)
			end
		end

		if next(var_14_7) ~= nil then
			local var_14_8 = var_14_7[math.random(#var_14_7)]

			table.insert(var_14_0, var_14_8)
		end
	end

	return var_14_0
end

function var_0_3.die(arg_15_0)
	var_0_3.super.die(arg_15_0)

	local var_15_0 = arg_15_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_15_1 = arg_15_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_15_0, iter_15_1 in ipairs(var_15_1) do
		if not iter_15_1:isDeath() and iter_15_1:getTableID() == arg_15_0:getTableID() then
			return
		end
	end

	for iter_15_2, iter_15_3 in ipairs(var_15_0) do
		if not iter_15_3:isDeath() and iter_15_3:isHasBuffByID(var_0_14) then
			iter_15_3:removeBuffByID(var_0_14)
		end
	end

	for iter_15_4, iter_15_5 in ipairs(var_15_1) do
		if not iter_15_5:isDeath() and iter_15_5:isHasBuffByID(var_0_14) then
			iter_15_5:removeBuffByID(var_0_14)
		end
	end

	arg_15_0.getGiftHeros = {}
end

function var_0_3.setupReport(arg_16_0, arg_16_1)
	var_0_3.super.setupReport(arg_16_0, arg_16_1)

	arg_16_0.randomBuffCount1_ = arg_16_1.random_buff_count1 or {}
	arg_16_0.randomBuffCount2_ = arg_16_1.random_buff_count2 or {}
end

function var_0_3.writeReport(arg_17_0)
	local var_17_0 = var_0_3.super.writeReport(arg_17_0)

	var_17_0.random_buff_count1 = arg_17_0.records_.random_buff_count1
	var_17_0.random_buff_count2 = arg_17_0.records_.random_buff_count2

	return var_17_0
end

return var_0_3
