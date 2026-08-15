local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementZhangliao", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = {
	40010496,
	40010497,
	40010498,
	40010499,
	40010508
}
local var_0_7 = 80022022

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == var_0_7 then
		local var_1_0 = var_0_6[math.random(1, #var_0_6)]
		local var_1_1 = arg_1_0:newBuff({
			var_1_0
		}, arg_1_1.target, arg_1_1.skillID)

		arg_1_1.target:addBuffs(var_1_1)
	end
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_0:isCannotMove(arg_2_1.target) then
		arg_2_4 = arg_2_4 + arg_2_1.target:getHpLimit() * 0.5
	end

	return var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
end

function var_0_3.newBuff(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		local var_3_1 = var_0_4.new({
			tableID = iter_3_1,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_3),
			skillID = arg_3_3,
			fighter = arg_3_0,
			target = arg_3_2
		})

		var_3_1:setIsHit(true)
		var_3_1:setDirection(arg_3_0:getFighterModel():getFlipX())
		table.insert(var_3_0, var_3_1)
	end

	return var_3_0
end

function var_0_3.isCannotMove(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1:getBuffs()

	for iter_4_0, iter_4_1 in ipairs(var_4_0) do
		if var_0_5:pause(iter_4_1:getTableID()) then
			return true
		end
	end

	return false
end

return var_0_3
