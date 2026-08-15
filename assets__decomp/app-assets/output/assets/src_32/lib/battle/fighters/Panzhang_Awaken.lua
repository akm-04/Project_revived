local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Panzhang", var_0_1.ctx.battle.requireFighter("Panzhang"))
local var_0_4 = 0
local var_0_5 = 0.0015
local var_0_6 = 10002264
local var_0_7 = 0

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.canReEnergy = true
	arg_1_0.reEnergyCDCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	arg_2_0.reEnergyCDCount = arg_2_0.reEnergyCDCount + 1

	if arg_2_0.reEnergyCDCount > var_0_7 and arg_2_0.canReEnergy == false then
		arg_2_0.canReEnergy = true
		arg_2_0.reEnergyCDCount = 0
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if var_3_1 and arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() then
		var_3_2 = var_3_2 * (1 + var_0_4 + var_0_5 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

		if arg_3_0.canReEnergy == true then
			local var_3_6 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_6)

			for iter_3_0, iter_3_1 in ipairs(var_3_6) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end

			arg_3_0.canReEnergy = false
		end
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

return var_0_3
