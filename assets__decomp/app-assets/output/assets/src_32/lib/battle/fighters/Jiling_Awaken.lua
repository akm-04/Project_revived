local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiling", var_0_1.ctx.battle.requireFighter("Jiling"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 40012196
local var_0_6 = 0.001
local var_0_7 = 0.001

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getEnergySkillID() then
		local var_1_0 = var_0_4:scope(arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
			if not iter_1_1:isDeath() and not iter_1_1:isAffected() and var_1_0 >= math.abs(arg_1_0:getX() - iter_1_1:getX()) then
				local var_1_1 = arg_1_0:createNewBuffs({
					var_0_5
				}, iter_1_1, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				iter_1_1:addBuffs(var_1_1)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	var_0_3.super.buffAddAction(arg_2_0, arg_2_1)

	if arg_2_1:getTableID() == var_0_5 then
		arg_2_1:setForceTarget(arg_2_0)
	end
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	local var_3_0 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

	if var_3_0 > 0 then
		local var_3_1 = arg_3_1.fighter
		local var_3_2 = var_0_6 + math.abs(var_3_1:getX() - arg_3_0:getX()) / 100 * var_0_7

		arg_3_4 = arg_3_4 * (1 - math.min(1, var_3_2 * var_3_0))
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
