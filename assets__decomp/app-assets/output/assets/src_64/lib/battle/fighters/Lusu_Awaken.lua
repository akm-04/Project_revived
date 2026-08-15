local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Lusu", var_0_1.ctx.battle.requireFighter("Lusu"))
local var_0_4 = 60010080
local var_0_5 = 10001587
local var_0_6 = 15

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeMPSkillCount = 0
	arg_1_0.awakeCureSkillCount = 0
end

function var_0_3.removeTargetBuff(arg_2_0, arg_2_1, arg_2_2)
	var_0_3.super.removeTargetBuff(arg_2_0, arg_2_1, arg_2_2)

	if (arg_2_2:dBuffType() > 0 or arg_2_2:getBuffForm() == var_0_2.BuffForm.GAIN or arg_2_2:getBuffForm() == var_0_2.BuffForm.DEBUFF) and arg_2_2:canRemove() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and (not arg_2_0.awakeMPSkillCD_ or var_0_1.ctx.battle.count - arg_2_0.awakeMPSkillCD_ >= var_0_6 or arg_2_0.awakeMPSkillCD_ and var_0_1.ctx.battle.count == arg_2_0.awakeMPSkillCD_ and arg_2_0.awakeMPSkillCount < 3) then
		if arg_2_0.awakeMPSkillCD_ and var_0_1.ctx.battle.count > arg_2_0.awakeMPSkillCD_ then
			arg_2_0.awakeMPSkillCount = 0
		end

		arg_2_0.awakeMPSkillCount = arg_2_0.awakeMPSkillCount + 1

		local var_2_0 = arg_2_0:createAttackUnits({
			arg_2_0
		}, var_0_5)

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end

		arg_2_0.awakeMPSkillCD_ = var_0_1.ctx.battle.count
	end

	if (arg_2_2:isMoveUnable() or arg_2_2:isApUnable() and arg_2_2:isAdUnable() or arg_2_2:isPossessed() or arg_2_2:isAttackFriend()) and arg_2_2:canRemove() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and (not arg_2_0.awakeCureSkillCD_ or var_0_1.ctx.battle.count - arg_2_0.awakeCureSkillCD_ >= var_0_6 or arg_2_0.awakeCureSkillCD_ and var_0_1.ctx.battle.count == arg_2_0.awakeCureSkillCD_ and arg_2_0.awakeCureSkillCount < 3) then
		if arg_2_0.awakeCureSkillCD_ and var_0_1.ctx.battle.count > arg_2_0.awakeCureSkillCD_ then
			arg_2_0.awakeCureSkillCount = 0
		end

		arg_2_0.awakeCureSkillCount = arg_2_0.awakeCureSkillCount + 1

		local var_2_1 = arg_2_0:createAttackUnits({
			arg_2_0
		}, var_0_4)

		for iter_2_2, iter_2_3 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
			table.insert(arg_2_0.records_.special_units, iter_2_3)
		end

		arg_2_0.awakeCureSkillCD_ = var_0_1.ctx.battle.count
	end
end

return var_0_3
