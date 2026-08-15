local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hanlingdi", var_0_1.ctx.battle.requireFighter("Hanlingdi"))
local var_0_4 = 400
local var_0_5 = 10
local var_0_6 = 0.2
local var_0_7 = 0.001
local var_0_8 = 0.1
local var_0_9 = 1.5

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	local var_1_0 = arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

	arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_4 > 0 and arg_1_3 and arg_1_1.skillID ~= arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		if var_0_2.weightedChoise({
			var_0_6,
			1 - var_0_6
		}) == 1 then
			local var_1_1 = arg_1_0:createAttackUnits({
				arg_1_1.target
			}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_1_0, iter_1_1 in ipairs(var_1_1) do
				table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
				table.insert(arg_1_0.records_.special_units, iter_1_1)
			end
		end
	elseif arg_1_4 > 0 and arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		local var_1_2 = arg_1_1.target:getHpLimit() * (var_0_7 * var_1_0 + var_0_8)
		local var_1_3 = var_0_4 * var_1_0 + var_0_5

		var_1_2 = var_1_3 < var_1_2 and var_1_3 or var_1_2
		arg_1_4 = arg_1_4 + var_1_2
		arg_1_4 = math.min(arg_1_0:getHpLimit() * var_0_9, arg_1_4)
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

return var_0_3
