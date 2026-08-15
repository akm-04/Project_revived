local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhuling", var_0_1.ctx.battle.requireFighter("Zhuling"))
local var_0_4 = 0.18

function var_0_3.updateMagicBy(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_0.magic

	var_0_3.super.updateMagicBy(arg_1_0, arg_1_1)

	local var_1_1 = arg_1_0.magic

	if var_1_1 < var_1_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_1_2 = arg_1_0:createAttackUnits({
			arg_1_0
		}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_1_0, iter_1_1 in ipairs(var_1_2) do
			iter_1_1:setExtraHarm((var_1_0 - var_1_1) * var_0_4 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
			table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
			table.insert(arg_1_0.records_.special_units, iter_1_1)
		end
	end
end

return var_0_3
