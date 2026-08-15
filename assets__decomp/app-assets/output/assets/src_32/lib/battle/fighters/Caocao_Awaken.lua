local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caocao", var_0_1.ctx.battle.requireFighter("Caocao"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = {
	200,
	300,
	400,
	500,
	600
}
local var_0_6 = {
	8,
	4,
	2,
	1,
	0.5,
	0.25
}
local var_0_7 = 10000062

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceTargets_ = {}
	arg_1_0.awakeTwiceExtraRate_ = 0
	arg_1_0.count_ = false
end

function var_0_3.toDoPerFrames(arg_2_0, ...)
	if not arg_2_0.count_ and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_2_0.count_ = true

		local var_2_0 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		arg_2_0.awakeTwiceExtraRate_ = var_0_4:descNumInit(var_2_0)[1] * 0.01 + var_0_4:descNumStep(var_2_0)[1] * 0.01 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if (arg_3_1.skillID == arg_3_0:getEnergySkillID() or arg_3_1.skillID == var_0_7) and not arg_3_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:createAttackUnits({
			arg_3_1.target
		}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end

	if var_0_4:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if not arg_3_0.awakeTwiceTargets_[arg_3_1.target] then
			arg_3_0.awakeTwiceTargets_[arg_3_1.target] = 1
		else
			local var_3_1 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_3_2, iter_3_3 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		local var_4_6 = math.abs(arg_4_1.target:getX() - arg_4_0:getX())

		for iter_4_0, iter_4_1 in ipairs(var_0_5) do
			if var_4_6 <= iter_4_1 then
				var_4_2 = var_4_2 * var_0_6[iter_4_0]

				break
			end

			if iter_4_0 == #var_0_5 then
				var_4_2 = var_4_2 * 0.25
			end
		end
	end

	if var_0_4:father(arg_4_1.skillID) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_4_0.awakeTwiceTargets_[arg_4_1.target] then
		var_4_2 = var_4_2 * (1 + arg_4_0.awakeTwiceExtraRate_)
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

return var_0_3
