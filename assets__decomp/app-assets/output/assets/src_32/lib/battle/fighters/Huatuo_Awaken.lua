local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huatuo", var_0_1.ctx.battle.requireFighter("Huatuo"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 60010024
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 0.4
local var_0_8 = 0.005

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_1_0:awakenSkill(arg_1_1)
	end
end

function var_0_3.awakenSkill(arg_2_0, arg_2_1)
	local var_2_0 = var_0_7 + var_0_8 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

	if var_0_2.weightedChoise({
		var_2_0,
		1 - var_2_0
	}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_1
		local var_2_2

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if iter_2_1 ~= arg_2_1.target and not iter_2_1:isDeath() and (not var_2_1 or var_2_2 > iter_2_1:getHp() / iter_2_1:getHpLimit() or var_2_2 == iter_2_1:getHp() / iter_2_1:getHpLimit() and var_2_1:getHp() > iter_2_1:getHp()) then
				var_2_1 = iter_2_1
				var_2_2 = var_2_1:getHp() / var_2_1:getHpLimit()
			end
		end

		local var_2_3 = arg_2_0:createAttackUnits({
			var_2_1
		}, var_0_5)

		for iter_2_2, iter_2_3 in ipairs(var_2_3) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
			table.insert(arg_2_0.records_.special_units, iter_2_3)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == var_0_5 or arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_3_5 = arg_3_1.target:getHpLimit() * 0.1
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
