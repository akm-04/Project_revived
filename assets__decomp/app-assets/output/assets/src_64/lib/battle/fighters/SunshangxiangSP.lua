local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SunshangxiangSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10002374
local var_0_8 = 10002375
local var_0_9 = 10002407
local var_0_10 = 10002364
local var_0_11 = 0.004
local var_0_12 = 5
local var_0_13 = 0.15
local var_0_14 = 10002377
local var_0_15 = 10002366
local var_0_16 = 10002367
local var_0_17 = 10002365
local var_0_18 = 15
local var_0_19 = 40012576

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.EnergyChildSkillNum = 0
	arg_2_0.EnergyChildExtraSkillNum = 0
	arg_2_0.EnergySkillHarm = 0
	arg_2_0.EnergyTarget = {}
	arg_2_0.GreenTarget = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
		local var_3_0 = iter_3_1.harm
		local var_3_1 = iter_3_1.fighter
		local var_3_2 = iter_3_1.skillID

		if var_3_1 == arg_3_0 and (var_3_2 == var_0_15 or var_3_2 == var_0_14) then
			arg_3_0.EnergySkillHarm = var_3_0 + arg_3_0.EnergySkillHarm
			arg_3_0.EnergyChildSkillNum = arg_3_0.EnergyChildSkillNum + 1
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_1.target

		if (arg_4_1.skillID == var_0_14 or arg_4_1.skillID == var_0_15) and not var_4_0:isDeath() and arg_4_0.EnergyChildSkillNum < 3 then
			arg_4_0.EnergyTarget = {
				var_4_0
			}

			arg_4_0:createSkillByID(var_0_15, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), var_0_6:attackIndex(var_0_15))
		elseif arg_4_1.skillID == var_0_15 and not var_4_0:isDeath() and arg_4_0.EnergyChildSkillNum >= 3 then
			local var_4_1 = arg_4_0:createAttackUnits({
				var_4_0
			}, var_0_16)

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		elseif arg_4_1.skillID == var_0_16 and not var_4_0:isDeath() and arg_4_0.EnergyChildSkillNum >= 3 then
			arg_4_0.EnergyChildSkillNum = 0

			local var_4_2 = arg_4_0.EnergySkillHarm / var_4_0:getHpLimit()

			if var_4_2 > var_0_13 then
				arg_4_0.EnergyChildExtraSkillNum = math.min(math.floor(var_4_2 / var_0_13), 3)
			end

			if arg_4_0.EnergyChildExtraSkillNum > 0 then
				arg_4_0.EnergyChildExtraSkillNum = arg_4_0.EnergyChildExtraSkillNum - 1

				arg_4_0:createSkillByID(var_0_17, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), var_0_6:attackIndex(var_0_17))
				arg_4_0:resumeIdle()
			end
		elseif arg_4_1.skillID == var_0_17 and not var_4_0:isDeath() and arg_4_0.EnergyChildExtraSkillNum > 0 then
			arg_4_0.EnergyChildExtraSkillNum = arg_4_0.EnergyChildExtraSkillNum - 1

			arg_4_0:createSkillByID(var_0_17, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), var_0_6:attackIndex(var_0_17))
		elseif arg_4_1.skillID == var_0_7 then
			table.insert(arg_4_0.GreenTarget, arg_4_1.target)
		elseif arg_4_1.skillID == var_0_9 and #arg_4_0.GreenTarget > 0 then
			local var_4_3 = arg_4_0:createAttackUnits(arg_4_0.GreenTarget, var_0_8)

			for iter_4_2, iter_4_3 in ipairs(var_4_3) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)
			end

			arg_4_0.GreenTarget = {}
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0)
	return arg_5_0.EnergyTarget
end

function var_0_3.selectTargetByTypeD2(arg_6_0)
	local var_6_0
	local var_6_1

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_6_0 or var_6_1 > iter_6_1:getHp() / iter_6_1:getHpLimit() or var_6_1 == iter_6_1:getHp() / iter_6_1:getHpLimit() and var_6_0:getHp() > iter_6_1:getHp()) then
			var_6_0 = iter_6_1
			var_6_1 = var_6_0:getHp() / var_6_0:getHpLimit()
		end
	end

	if var_6_0 then
		return {
			var_6_0
		}
	else
		return {}
	end
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_4 > 0 and not arg_7_2 and arg_7_0:isHasBuffByID(var_0_19) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_0
		}, var_0_10)

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	local var_8_0 = arg_8_1.target

	if arg_8_4 > 0 and var_8_0:getTeamType() ~= arg_8_0:getTeamType() and arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_8_4 = arg_8_4 + arg_8_4 * (1 - var_8_0:getHp() / var_8_0:getHpLimit()) * var_0_11 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.getADBaoJi(arg_9_0)
	local var_9_0 = var_0_3.super.getADBaoJi(arg_9_0)
	local var_9_1 = 0

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		var_9_1 = (1 - arg_9_0:getHp() / arg_9_0:getHpLimit()) * var_0_12 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return var_9_0 + var_9_1
end

return var_0_3
