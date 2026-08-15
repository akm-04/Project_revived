local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiaoqiao", var_0_1.ctx.battle.requireFighter("Xiaoqiao"))
local var_0_4 = 0.2
local var_0_5 = 0
local var_0_6 = 40011607
local var_0_7 = 0
local var_0_8 = 0
local var_0_9 = 0.03

function var_0_3.updateUnitDataBySpecialHero(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	local var_1_0 = arg_1_1.target

	if arg_1_4 > 0 and arg_1_0:getTeamType() == var_1_0:getTeamType() then
		local var_1_1 = var_0_4 + var_0_5 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		if var_0_2.weightedChoise({
			var_1_1,
			1 - var_1_1
		}) == 1 then
			local var_1_2 = arg_1_0:createAttackUnits({
				var_1_0
			}, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_1_0, iter_1_1 in ipairs(var_1_2) do
				table.insert(arg_1_0.moveAttackUnits_, iter_1_1)
				table.insert(arg_1_0.records_.special_units, iter_1_1)
			end
		end
	end

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.target

	if arg_2_1:getTableID() == var_0_6 then
		arg_2_1.manualHarmRevise = var_0_7 + var_0_8 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) + (var_2_0:getHpLimit() - var_2_0:getHp()) * var_0_9

		if arg_2_1.target:isHasBuffByID(arg_2_0.purpleBuffID) then
			arg_2_1.manualHarmRevise = arg_2_1.manualHarmRevise * 2
		end
	end
end

return var_0_3
