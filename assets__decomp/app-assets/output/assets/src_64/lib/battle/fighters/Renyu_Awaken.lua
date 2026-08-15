local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Renyu", var_0_1.ctx.battle.requireFighter("Renyu"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = 40011052
local var_0_6 = 0.001
local var_0_7 = 0.1
local var_0_8 = 0.001
local var_0_9 = 0.1
local var_0_10 = 0.0015
local var_0_11 = 0
local var_0_12 = 0.2
local var_0_13 = 0.2

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("crit_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("crit_info")) do
			local var_2_1 = iter_2_1.unit.fighter
			local var_2_2 = false

			if var_2_1 == arg_2_0 then
				local var_2_3 = var_2_0 * var_0_6 + var_0_7

				var_2_2 = var_0_2.weightedChoise({
					var_2_3,
					1 - var_2_3
				}) == 1
			elseif var_2_1:getTeamType() == arg_2_0:getTeamType() then
				local var_2_4 = var_2_0 * var_0_8 + var_0_9
				local var_2_5

				var_2_5 = var_0_2.weightedChoise({
					var_2_4,
					1 - var_2_4
				}) == 1
			end

			if var_2_2 then
				local var_2_6 = arg_2_0:createAttackUnits({
					var_2_1
				}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				for iter_2_2, iter_2_3 in ipairs(var_2_6) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_0.skinSkillIndex_ == 1 and arg_3_1.target:getTeamType() == arg_3_0:getTeamType() and arg_3_1.target:isHasBuffByID(var_0_5) then
		arg_3_4 = arg_3_4 - var_0_12 * arg_3_4
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_5 then
		local var_4_0 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_10 + var_0_11

		arg_4_1.manualDharm = arg_4_1.manualDharm + var_4_0 * arg_4_1.target:getHpLimit()
	end

	if arg_4_0.skinSkillIndex_ == 1 and arg_4_1:getTableID() == var_0_5 then
		local var_4_1 = var_0_4:time(arg_4_1:getTableID()) * var_0_13

		arg_4_1:setExtraTime(var_4_1)
	end
end

return var_0_3
