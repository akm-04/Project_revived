local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Diaochan", var_0_1.ctx.battle.requireFighter("Diaochan"))
local var_0_4 = var_0_2.tables.dbuff
local var_0_5 = 0
local var_0_6 = 0.9

function var_0_3.isInDebuff(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_1:getBuffs()

	for iter_1_0, iter_1_1 in ipairs(var_1_0) do
		local var_1_1 = iter_1_1:getTableID()

		if var_0_4:buffForm(var_1_1) == var_0_2.BuffForm.DEBUFF then
			return true
		end
	end

	return false
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_2_1.target:getTeamType() ~= arg_2_0:getTeamType() and arg_2_0:isInDebuff(arg_2_1.target) then
		local var_2_0 = var_0_5 + var_0_6 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		arg_2_0:updateEnergyBy(var_2_0)
	end
end

return var_0_3
