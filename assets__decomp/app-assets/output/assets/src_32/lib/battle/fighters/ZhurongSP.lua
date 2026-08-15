local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhurongSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40012237
local var_0_7 = 0.25
local var_0_8 = 10002093
local var_0_9 = 10002106
local var_0_10 = 350
local var_0_11 = 0.4
local var_0_12 = 0.1
local var_0_13 = 0.003
local var_0_14 = 10002094
local var_0_15 = 10002095

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7 = var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)

	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_1.target:isHasBuffByID(var_0_6) then
		arg_2_4 = arg_2_4 * (1 + var_0_7)
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	local var_3_0 = arg_3_1.fighter

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_3_4 > 0 and var_3_0:getTeamType() ~= arg_3_0:getTeamType() then
		if var_3_0:isHasBuffByID(var_0_6) then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_1 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_15)

				for iter_3_0, iter_3_1 in ipairs(var_3_1) do
					iter_3_1.basicHarm = arg_3_4 * (var_0_12 + var_0_13 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end
			end

			arg_3_4 = arg_3_4 * (1 - var_0_12 + var_0_13 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
		end

		local var_3_2 = var_0_11

		if var_0_2.weightedChoise({
			var_3_2,
			1 - var_3_2
		}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_3 = arg_3_0:createAttackUnits({
				var_3_0
			}, var_0_14)

			for iter_3_2, iter_3_3 in ipairs(var_3_3) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_4_1.target:isHasBuffByID(var_0_6) then
			local var_4_0 = var_0_5:attackIndex(var_0_8)

			arg_4_0:createSkillByID(var_0_8, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_4_0)
		end
	elseif arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_4_0:blueSkill(arg_4_1)
	end
end

function var_0_3.blueSkill(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.target
	local var_5_1 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if iter_5_1 ~= var_5_0 and not iter_5_1:isDeath() and not iter_5_1:isAffected() and math.abs(iter_5_1:getX() - var_5_0:getX()) <= var_0_10 / 2 then
			table.insert(var_5_1, iter_5_1)

			local var_5_2 = arg_5_0:createNewBuffs({
				var_0_6
			}, iter_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			iter_5_1:addBuffs(var_5_2)
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_3 = arg_5_0:createAttackUnits(var_5_1, var_0_9)

		for iter_5_2, iter_5_3 in ipairs(var_5_3) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	end
end

return var_0_3
