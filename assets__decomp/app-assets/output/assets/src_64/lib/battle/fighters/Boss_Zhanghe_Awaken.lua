local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhanghe", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = {
	10010068,
	10010069,
	10010070,
	10010071
}
local var_0_9 = 90020011
local var_0_10 = 90020012

function var_0_3.getOrbOfFrontSkill(arg_1_0)
	local var_1_0 = var_0_3.super.getFrontSkill(arg_1_0)

	if var_1_0 == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_1_1 = var_0_5:randomOrb(var_1_0)

		if next(var_1_1) then
			local var_1_2 = {}

			for iter_1_0, iter_1_1 in ipairs(var_1_1) do
				table.insert(var_1_2, 1)
			end

			return var_1_1[var_0_2.weightedChoise(var_1_2)]
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_1_0)
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not var_0_0.table.indexof(var_0_8, arg_2_1:getTableID()) then
		return
	end

	local var_2_0 = arg_2_1.target

	if var_2_0:isHasBuffByID(arg_2_1:getTableID()) then
		arg_2_0:createSpecialUnits(var_0_9, var_2_0)
	end

	for iter_2_0, iter_2_1 in ipairs(var_0_8) do
		if iter_2_1 ~= arg_2_1:getTableID() and var_2_0:isHasBuffByID(iter_2_1) then
			arg_2_0:createSpecialUnits(var_0_10, var_2_0)

			break
		end
	end
end

function var_0_3.createSpecialUnits(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = {
		arg_3_2
	}
	local var_3_1 = arg_3_0:createAttackUnits(var_3_0, arg_3_1)

	for iter_3_0, iter_3_1 in ipairs(var_3_1) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
		table.insert(arg_3_0.records_.special_units, iter_3_1)
	end
end

return var_0_3
