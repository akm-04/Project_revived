local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementXuhuang", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40010500

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_1_0 = arg_1_0:newBuff({
			var_0_5
		}, arg_1_1.target, arg_1_1.skillID)

		arg_1_1.target:addBuffs(var_1_0)
	end
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_1.target:isHasBuffByID(var_0_5) then
		arg_2_4 = arg_2_1.target:getHpLimit() * 0.2 * arg_2_1.target:getAPJianShang() + arg_2_4
	end

	return var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getSkillID() == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and not arg_3_1.target:isHasBuffByID(var_0_5) then
		local var_3_0 = arg_3_1:getTime()

		arg_3_1:setExtraTime(var_3_0)
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

return var_0_3
