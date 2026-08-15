local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuchu", var_0_1.ctx.battle.requireFighter("Xuchu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 60010011
local var_0_7 = 10001456
local var_0_8 = 0.5
local var_0_9 = 0.3
local var_0_10 = 0.01

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.nAwakenCounts = 0
	arg_1_0.records_.debuff_immute = {}
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:dBuffType() == var_0_2.DBuffType.XUAN_YUN then
		arg_2_0.nAwakenCounts = arg_2_0.nAwakenCounts + 1

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_0 = arg_2_0:getTargets(var_0_6)
			local var_2_1 = arg_2_0:createAttackUnits(var_2_0, var_0_6)

			for iter_2_0, iter_2_1 in ipairs(var_2_1) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end

			if arg_2_0.nAwakenCounts >= 10 then
				local var_2_2 = arg_2_0:createAttackUnits({
					arg_2_0
				}, var_0_7)

				for iter_2_2, iter_2_3 in ipairs(var_2_2) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end
		end
	end
end

function var_0_3.addBuffs(arg_3_0, arg_3_1)
	local var_3_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_3_0 = arg_3_0.debuffImmute[tostring(var_0_1.ctx.battle.count)]
	else
		local var_3_1 = var_0_8

		var_3_0 = var_0_2.weightedChoise({
			var_3_1,
			1 - var_3_1
		}) == 1 and arg_3_0.nAwakenCounts >= 10

		if var_3_0 then
			arg_3_0.records_.debuff_immute[tostring(var_0_1.ctx.battle.count)] = 1
		end
	end

	if var_3_0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
			if iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				table.remove(arg_3_1, iter_3_0)
			end
		end
	end

	var_0_3.super.addBuffs(arg_3_0, arg_3_1)
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.debuffImmute = arg_4_1.debuff_immute
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.debuff_immute = arg_5_0.records_.debuff_immute

	return var_5_0
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	local var_6_0 = arg_6_0:getAttrByType(var_0_2.AttributeType.STRENGTH) - arg_6_1.target:getAttrByType(var_0_2.AttributeType.STRENGTH)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_6_0 > 0 and arg_6_4 > 0 then
		arg_6_4 = arg_6_4 + var_6_0 * (var_0_9 + var_0_10 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

return var_0_3
