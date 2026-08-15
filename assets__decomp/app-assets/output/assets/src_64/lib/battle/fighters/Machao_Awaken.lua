local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Machao", var_0_1.ctx.battle.requireFighter("Machao"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40011557
local var_0_6 = {
	40011558,
	40011559
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.twiceAwakenSkillUsed = false
end

function var_0_3.newBuffs(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
	local var_2_0 = {}

	for iter_2_0, iter_2_1 in ipairs(arg_2_1) do
		local var_2_1 = var_0_4.new({
			tableID = iter_2_1,
			start = var_0_1.ctx.battle.count,
			level = arg_2_3,
			skillID = arg_2_2,
			fighter = arg_2_0,
			target = arg_2_4
		})

		table.insert(var_2_0, var_2_1)
	end

	return var_2_0
end

function var_0_3.transformIntoWolf(arg_3_0)
	var_0_3.super.transformIntoWolf(arg_3_0)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_3_0 = 0
		local var_3_1 = arg_3_0:getBuffByID(var_0_5)

		if var_3_1 then
			var_3_0 = var_3_1:getDHarm() / var_3_1:totalDHarm()
		else
			var_3_0 = 0
		end

		local var_3_2 = arg_3_0:newBuffs(var_0_6, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice), arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice), arg_3_0)

		for iter_3_0, iter_3_1 in ipairs(var_3_2) do
			iter_3_1.manualRevise = -var_3_0 * iter_3_1:getAttr()
		end

		arg_3_0:addBuffs(var_3_2)
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	var_0_3.super.toDoPerFrames(arg_4_0)

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and not arg_4_0.twiceAwakenSkillUsed then
		arg_4_0.twiceAwakenSkillUsed = true

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_0
			}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	end
end

return var_0_3
