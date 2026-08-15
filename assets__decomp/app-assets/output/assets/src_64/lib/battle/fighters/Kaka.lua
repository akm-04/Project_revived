local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = math
local var_0_8 = 10100101
local var_0_9 = 0.5
local var_0_10 = 0.01

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount_ = 0
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1:getLevel()
	local var_2_1 = var_0_4:desc4NumStep(arg_2_1:getSkillID())[2]

	if arg_2_1:getSkillID() == arg_2_0:getEnergySkillID() and arg_2_0.isStarEnergy_ then
		arg_2_1.manualRevise = var_2_1 * var_2_0 * -1
	elseif arg_2_1:getSkillID() == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_2_0.isStarBlue_ then
		arg_2_1.manualRevise = var_2_1 * var_2_0
	elseif arg_2_1:getSkillID() == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_2_0.isStarPurple_ then
		arg_2_1:setExtraTime(45)
	end
end

function var_0_3.deathFeedback(arg_3_0, arg_3_1)
	var_0_3.super.deathFeedback(arg_3_0, arg_3_1)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or arg_3_0.purpleCount_ > 1 or arg_3_1:getTeamType() ~= arg_3_0:getTeamType() or arg_3_1:getSummonType() ~= var_0_2.summonMonsterType.None then
		return
	end

	arg_3_0.purpleCount_ = arg_3_0.purpleCount_ + 1

	local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_3_1 = var_0_6.B2(arg_3_0, var_3_0)
	local var_3_2 = arg_3_0:createAttackUnits(var_3_1, var_3_0)

	for iter_3_0, iter_3_1 in ipairs(var_3_2) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
		table.insert(arg_3_0.records_.special_units, iter_3_1)
	end
end

return var_0_3
