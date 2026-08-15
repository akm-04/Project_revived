local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caochong", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = 5
local var_0_8 = 45
local var_0_9 = 1.5

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("death_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyDharm_ = 0
	arg_2_0.deadCount_ = 0
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)

	if arg_3_0.deadCount_ < 10 and next(arg_3_0:getInfoByKey("death_info")) then
		arg_3_0.deadCount_ = arg_3_0.deadCount_ + #arg_3_0:getInfoByKey("death_info")
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and var_4_2 > 0 then
		if arg_4_1.target:getSummonType() ~= var_0_2.summonMonsterType.None then
			var_4_2 = 2 * var_4_2
		end

		if var_0_4:father(arg_4_1.skillID) == arg_4_0:getEnergySkillID() then
			arg_4_0.energyDharm_ = arg_4_0.energyDharm_ + var_4_2
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.getUnitData(arg_5_0, arg_5_1)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.getUnitData(arg_5_0, arg_5_1)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_5_1.target:getTeamType() ~= arg_5_0:getTeamType() and var_5_2 > 0 and var_0_4:father(arg_5_1.skillID) == arg_5_0:getEnergySkillID() then
		arg_5_0.energyDharm_ = arg_5_0.energyDharm_ + var_5_2
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_1.target == arg_6_0 and var_0_4:father(arg_6_1.skillID_) == arg_6_0:getEnergySkillID() and arg_6_1:getDHarm() > 0 then
		arg_6_1.dHarm_ = math.max(arg_6_0.energyDharm_, arg_6_1.dHarm_)
		arg_6_0.energyDharm_ = 0
	end

	if arg_6_1.skillID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_6_1.target:getSummonType() ~= var_0_2.summonMonsterType.None then
		arg_6_1.leftCount_ = arg_6_1.leftCount_ * 2
	end
end

function var_0_3.getAP(arg_7_0)
	return var_0_3.super.getAP(arg_7_0) + (var_0_8 + arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_9) * arg_7_0.deadCount_
end

return var_0_3
