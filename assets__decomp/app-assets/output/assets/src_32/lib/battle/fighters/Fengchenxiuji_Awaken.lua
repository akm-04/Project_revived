local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fengchenxiuji", var_0_1.ctx.battle.requireFighter("Fengchenxiuji"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = {
	40010777,
	40010778
}
local var_0_6 = {
	40010779,
	40010780
}
local var_0_7 = 15

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if #arg_1_0:getBuffsByID(var_0_6[1]) < var_0_7 and arg_1_1.target ~= arg_1_0 and arg_1_1.target:getTeamType() ~= arg_1_0:getTeamType() and not arg_1_1.target:isDeath() then
		local var_1_0 = arg_1_0:newBuff(var_0_5, arg_1_1.target, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_1.target:addBuffs(var_1_0)

		local var_1_1 = arg_1_0:newBuff(var_0_6, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_1)
	end
end

function var_0_3.newBuff(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	local var_2_0 = {}

	for iter_2_0, iter_2_1 in ipairs(arg_2_1) do
		local var_2_1 = var_0_4.new({
			tableID = iter_2_1,
			start = var_0_1.ctx.battle.count,
			level = arg_2_0:getSkillLevelByID(arg_2_3),
			skillID = arg_2_3,
			fighter = arg_2_0,
			target = arg_2_2
		})

		var_2_1:setIsHit(true)
		var_2_1:setDirection(arg_2_0:getFighterModel():getFlipX())
		table.insert(var_2_0, var_2_1)
	end

	return var_2_0
end

return var_0_3
