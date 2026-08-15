local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 0.2
local var_0_9 = 0.005
local var_0_10 = 0.2
local var_0_11 = 40012546
local var_0_12 = 10002341
local var_0_13 = 0.002
local var_0_14 = 0.1
local var_0_15 = 40012547
local var_0_16 = -0.1
local var_0_17 = 40012548
local var_0_18 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyAddEnergy = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.purpleAddBuffSkill and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_1.ctx.battle.count % 10 == 1 then
		local var_2_0 = var_0_7.B2(arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))
		local var_2_1 = arg_2_0:createAttackUnits(var_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end

		arg_2_0.purpleAddBuffSkill = true
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_0 = arg_3_0:createNewBuffs({
			var_0_11
		}, arg_3_1.target, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		if arg_3_0.isStarBlue_ then
			for iter_3_0, iter_3_1 in ipairs(var_3_0) do
				iter_3_1.manualSpGiveRate = var_0_13 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) + var_0_14
			end
		else
			for iter_3_2, iter_3_3 in ipairs(var_3_0) do
				iter_3_3.manualSpGiveRate = var_0_13 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
			end
		end

		arg_3_1.target:addBuffs(var_3_0)
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	local var_4_0 = arg_4_1.target

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_4_1 = arg_4_0:getLeastMpTarget(false)
		local var_4_2 = 0

		if #var_4_1 >= 1 then
			var_4_2 = var_4_1[1]:getEnergy() - var_4_0:getEnergy()
		end

		local var_4_3 = var_0_8 + var_0_8 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

		if arg_4_0.isStarGreen_ then
			var_4_3 = var_4_3 + var_0_10
		end

		arg_4_7 = arg_4_7 + var_4_2 * var_4_3
	elseif arg_4_1.skillID == var_0_12 then
		arg_4_7 = arg_4_7 + arg_4_0.energyAddEnergy
		arg_4_0.energyAddEnergy = 0
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.getLeastMpTarget(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	if not arg_5_1 then
		var_5_0 = arg_5_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	end

	local var_5_1
	local var_5_2 = {}
	local var_5_3 = {}

	for iter_5_0, iter_5_1 in ipairs(var_5_0) do
		if not iter_5_1:isDeath() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_5_3, iter_5_1)
		end
	end

	for iter_5_2, iter_5_3 in ipairs(var_5_3) do
		if not var_5_1 then
			var_5_1 = iter_5_3:getEnergy()
			var_5_2 = {
				iter_5_3
			}
		elseif var_5_1 > iter_5_3:getEnergy() then
			var_5_2 = {
				iter_5_3
			}
			var_5_1 = iter_5_3:getEnergy()
		elseif iter_5_3:getEnergy() == var_5_1 then
			table.insert(var_5_2, iter_5_3)
		end
	end

	local var_5_4

	if #var_5_2 > 1 then
		var_5_4 = var_5_2[math.random(1, #var_5_2)]
	else
		var_5_4 = var_5_2[1]
	end

	return {
		var_5_4
	}
end

function var_0_3.spGiveIsSelf(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_1:getTableID() == var_0_11 then
		return false
	end

	return true
end

function var_0_3.spGiveValue(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_1:getTableID() == var_0_11 then
		arg_7_0.energyAddEnergy = arg_7_0.energyAddEnergy + arg_7_2
	end
end

function var_0_3.buffRemoveAction(arg_8_0, arg_8_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_8_1:getTableID() == var_0_11 then
		local var_8_0 = arg_8_0:getLeastMpTarget(true)
		local var_8_1 = arg_8_0:createAttackUnits(var_8_0, var_0_12)

		for iter_8_0, iter_8_1 in ipairs(var_8_1) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	var_0_3.super.buffAddAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == var_0_17 and arg_9_0.isStarEnergy_ then
		local var_9_0 = var_0_18

		arg_9_1:setExtraTime(arg_9_1.extraTime_ + var_9_0)
	elseif arg_9_1:getTableID() == var_0_15 and arg_9_0.isStarPurple_ then
		arg_9_1.manualRevise = var_0_16
	end
end

return var_0_3
