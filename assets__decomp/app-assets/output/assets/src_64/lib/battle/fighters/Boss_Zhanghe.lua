local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhanghe", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model

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

return var_0_3
