local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Nvheguan", var_0_1.ctx.battle.requireFighter("Nvheguan"))
local var_0_4 = 6500
local var_0_5 = 480
local var_0_6 = 210
local var_0_7 = 150

function var_0_3.toDoPerFrames(arg_1_0)
	var_0_3.super.toDoPerFrames(arg_1_0)

	if var_0_1.ctx.battle.count % var_0_6 < 1 and arg_1_0.chipNums_ < 7 then
		arg_1_0:updateChip(1)
	end

	if var_0_1.ctx.battle.count % var_0_7 < 1 and arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if var_0_2.weightedChoise({
			0.5,
			0.5
		}) == 1 and arg_1_0.chipNums_ < 7 then
			arg_1_0:updateChip(2)
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_1_0 = arg_1_0:createAttackUnits({
				arg_1_0
			}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_1_0, iter_1_1 in ipairs(var_1_0) do
				table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
				table.insert(arg_1_0.records_.special_units, iter_1_1)
			end
		end
	end
end

function var_0_3.getDamageRate(arg_2_0)
	local var_2_0 = arg_2_0:getHp()
	local var_2_1 = arg_2_0:getHpLimit()

	return (var_2_1 - var_2_0) / var_2_1
end

function var_0_3.getAP(arg_3_0)
	return var_0_3.super.getAP(arg_3_0) + var_0_4 * arg_3_0:getDamageRate()
end

function var_0_3.getDMoKang(arg_4_0)
	return var_0_3.super.getDMoKang(arg_4_0) + var_0_5 * arg_4_0:getDamageRate()
end

return var_0_3
