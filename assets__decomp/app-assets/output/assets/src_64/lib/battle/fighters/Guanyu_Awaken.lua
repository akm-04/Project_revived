local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guanyu", var_0_1.ctx.battle.requireFighter("Guanyu"))
local var_0_4 = {
	30010048
}
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceSkillHarm_ = 0
	arg_1_0.awakeTwiceRate_ = 0
	arg_1_0.count_ = false
end

function var_0_3.toDoPerFrames(arg_2_0, ...)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if not arg_2_0.count_ and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_2_0.count_ = true

		local var_2_0 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
		local var_2_1 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		arg_2_0.awakeTwiceRate_ = (var_0_6:descNumInit(var_2_0)[1] + var_0_6:descNumStep(var_2_0)[1] * var_2_1) * 0.01
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if var_0_6:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and arg_3_1.target ~= arg_3_0 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_3_0.awakeSkillHarm_ = arg_3_4

		local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
		local var_3_1 = var_0_6:scope(var_3_0)
		local var_3_2 = {}
		local var_3_3 = arg_3_1.target:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

		for iter_3_0, iter_3_1 in ipairs(var_3_3) do
			if iter_3_1 ~= arg_3_1.target and not iter_3_1:isDeath() and not iter_3_1:isAffected() and math.abs(iter_3_1:getX() - arg_3_1.target:getX()) <= var_3_1 * 0.5 then
				table.insert(var_3_2, iter_3_1)
			end
		end

		local var_3_4 = arg_3_0:createAttackUnits(var_3_2, var_3_0)

		for iter_3_2, iter_3_3 in ipairs(var_3_4) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		arg_3_4 = arg_3_0.awakeSkillHarm_ * arg_3_0.awakeTwiceRate_
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.getUnitData(arg_4_0, arg_4_1)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.getUnitData(arg_4_0, arg_4_1)

	if var_4_1 then
		arg_4_1.target:addBuffs(arg_4_0:newBuff(var_0_4, arg_4_1.target, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		local var_5_1 = var_0_5.new({
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(arg_5_3),
			skillID = arg_5_3,
			fighter = arg_5_0,
			target = arg_5_2
		})

		var_5_1:setIsHit(true)
		var_5_1:setDirection(arg_5_0:getFighterModel():getFlipX())
		table.insert(var_5_0, var_5_1)
	end

	return var_5_0
end

return var_0_3
