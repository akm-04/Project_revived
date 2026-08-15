local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementTaishici", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = {
	40010168,
	40010169,
	40010170,
	40010171,
	40010172,
	40010173,
	40010174,
	40010175
}

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getEnergySkillID() then
		for iter_1_0, iter_1_1 in ipairs(arg_1_0.sideTeam_) do
			if not iter_1_1:isDeath() and not iter_1_1:isAffected() then
				local var_1_0 = var_0_5[math.random(1, #var_0_5)]

				iter_1_1:addBuffs(arg_1_0:newBuff({
					var_1_0
				}, iter_1_1, arg_1_1.skillID))
			end
		end
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
