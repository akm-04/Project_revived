local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chunhong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = var_0_2.tables.cabinetSkillTable
local var_0_9
local var_0_10 = 20010065
local var_0_11 = 10000222
local var_0_12 = 30010036
local var_0_13 = 20010161
local var_0_14 = 30010031
local var_0_15 = 10390001
local var_0_16 = 10010106

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.count = false
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.currentSkillID_ = nil
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if not arg_2_0.count and not arg_2_0:isDeath() then
		arg_2_0.count = true

		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_2_0:addOpeningBuff()
		end
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.extraSkillJudge then
		arg_3_0.extraSkillJudge = true
		arg_3_0.extraSkillLevel = arg_3_0.hero_:skillBook()[tostring(var_0_15)] or 0
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)
end

function var_0_3.getTargets(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {}
	local var_5_1 = var_0_4:selectType(arg_5_1)

	if arg_5_0["selectTargetByType" .. var_5_1] then
		var_5_0 = arg_5_0["selectTargetByType" .. var_5_1](arg_5_0, arg_5_1, arg_5_2)
	elseif arg_5_1 == var_0_10 then
		var_5_0 = var_0_7[var_5_1](arg_5_0, arg_5_1, arg_5_2)
		var_0_9 = var_5_0
	elseif arg_5_1 == var_0_11 then
		if var_0_9 then
			local var_5_2 = var_0_9[1]

			if not var_5_2 then
				return {}
			end

			local var_5_3 = var_0_4:scope(arg_5_1) / 2
			local var_5_4, var_5_5 = var_5_2:getPos()
			local var_5_6, var_5_7 = var_0_7.getTeam(arg_5_0)

			table.insert(var_5_0, var_5_2)

			for iter_5_0, iter_5_1 in ipairs(var_5_7) do
				local var_5_8, var_5_9 = iter_5_1:getPos()

				if not iter_5_1:isDeath() and not iter_5_1:isAffected() and var_5_3 >= math.abs(var_5_4 - var_5_8) and iter_5_1 ~= var_5_2 then
					table.insert(var_5_0, iter_5_1)
				end
			end

			var_0_9 = nil
		else
			return
		end
	else
		var_5_0 = var_0_7[var_5_1](arg_5_0, arg_5_1, arg_5_2)
	end

	return var_5_0
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_6_0 = arg_6_1:getRemoveSkill()
	local var_6_1 = arg_6_0:getTargets(var_6_0)
	local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

	for iter_6_0, iter_6_1 in ipairs(var_6_2) do
		table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
		table.insert(arg_6_0.records_.special_units, iter_6_1)
	end
end

function var_0_3.specialBuffExecute(arg_7_0, arg_7_1)
	if arg_7_0:isDotBuff(arg_7_1) then
		local var_7_0 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

		arg_7_1.target:addBuffs(arg_7_0:newBuff(var_0_13, var_7_0, arg_7_0:getSkillLevelByID(var_7_0), arg_7_1.target))
	end
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = var_0_6.new({
		tableID = arg_8_1,
		start = var_0_1.ctx.battle.count,
		level = arg_8_3,
		skillID = arg_8_2,
		fighter = arg_8_0,
		target = arg_8_4
	})

	return {
		var_8_0
	}
end

function var_0_3.addOpeningBuff(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_9_0, iter_9_1 in ipairs(var_9_0) do
		if not iter_9_1:isDeath() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_9_1 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

			iter_9_1:addBuffs(arg_9_0:newBuff(var_0_12, var_9_1, arg_9_0:getSkillLevelByID(var_9_1), iter_9_1))
		end
	end
end

function var_0_3.isDotBuff(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1:getTableID()

	if var_0_5:type(var_10_0) == var_0_2.BuffType.CONTINUE_HARM and arg_10_1:getTableID() ~= var_0_13 and arg_10_1:getTableID() ~= var_0_14 then
		return true
	end

	return false
end

function var_0_3.die(arg_11_0)
	var_0_3.super.die(arg_11_0)

	local var_11_0 = arg_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_11_0, iter_11_1 in ipairs(var_11_0) do
		if not iter_11_1:isDeath() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None and iter_11_1:getBuffByID(var_0_12) then
			iter_11_1:removeBuffByID(var_0_12)
		end
	end
end

function var_0_3.buffAddAction(arg_12_0, arg_12_1)
	if arg_12_0.extraSkillLevel > 0 and arg_12_1:getTableID() == var_0_16 then
		local var_12_0 = arg_12_0.extraSkillLevel * var_0_8:attrValues(var_0_15) * 30

		arg_12_1:setExtraTime(var_12_0)
	end
end

return var_0_3
