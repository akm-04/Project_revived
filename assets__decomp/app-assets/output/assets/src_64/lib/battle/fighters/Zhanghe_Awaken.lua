local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhanghe", var_0_1.ctx.battle.requireFighter("Zhanghe"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = {
	10010068,
	10010069,
	10010070,
	10010071,
	40011264
}
local var_0_6 = 10000262
local var_0_7 = 5
local var_0_8 = 10001756
local var_0_9 = 10000045

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.energyCount = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if arg_2_1.skillID == var_0_8 and not arg_2_1.hasAddCollision then
			for iter_2_0 = 1, arg_2_0.energyCount do
				arg_2_1:addCollisionNum()
			end

			arg_2_1.hasAddCollision = true
		elseif arg_2_1.skillID == var_0_9 then
			arg_2_0.energyCount = math.min(arg_2_0.energyCount + 1, var_0_7)
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.super.getOrbOfFrontSkill(arg_3_0)
	local var_3_1 = var_0_4:randomOrb(var_3_0)

	if next(var_3_1) and var_3_1[1] > 0 then
		local var_3_2 = {}

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(var_3_2, 1)
		end

		return var_3_1[var_0_2.weightedChoise(var_3_2)]
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		return var_0_8
	end

	return var_3_0
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not var_0_0.table.indexof(var_0_5, arg_4_1:getTableID()) then
		return
	end

	local var_4_0 = arg_4_1.target

	if next(var_4_0:getBuffsByID(arg_4_1:getTableID())) then
		arg_4_0:createSpecialUnits({
			var_4_0
		}, var_0_6)
		var_4_0:removeBuffByID(arg_4_1:getTableID())
	end

	local var_4_1 = arg_4_1.target

	for iter_4_0, iter_4_1 in ipairs(var_0_5) do
		if iter_4_1 ~= arg_4_1:getTableID() and var_4_1:isHasBuffByID(iter_4_1) then
			var_4_1:removeBuffByID(iter_4_1)
		end
	end
end

function var_0_3.createSpecialUnits(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_0:createAttackUnits(arg_5_1, arg_5_2)

	for iter_5_0, iter_5_1 in ipairs(var_5_0) do
		table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
		table.insert(arg_5_0.records_.special_units, iter_5_1)
	end
end

return var_0_3
