local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Liubei", var_0_1.ctx.battle.requireFighter("Liubei"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = 0.6
local var_0_6 = 10001555
local var_0_7 = 10001556

function var_0_3.beginAttackEnd(arg_1_0, arg_1_1)
	var_0_3.super.beginAttackEnd(arg_1_0, arg_1_1)

	if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_0 = arg_1_0:createAttackUnits(var_0_4.A2(arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)), arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		local var_2_0 = arg_2_1.target

		if var_2_0:getHp() / var_2_0:getHpLimit() >= var_0_5 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_1 = arg_2_0:createAttackUnits({
					var_2_0
				}, var_0_6)

				for iter_2_0, iter_2_1 in ipairs(var_2_1) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_2 = arg_2_0:createAttackUnits({
				var_2_0
			}, var_0_7)

			for iter_2_2, iter_2_3 in ipairs(var_2_2) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
				table.insert(arg_2_0.records_.special_units, iter_2_3)
			end
		end
	end
end

return var_0_3
