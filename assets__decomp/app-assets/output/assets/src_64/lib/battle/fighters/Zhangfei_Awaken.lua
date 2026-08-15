local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangfei", var_0_1.ctx.battle.requireFighter("Zhangfei"))
local var_0_4 = 0
local var_0_5 = 2
local var_0_6 = 0
local var_0_7 = 10
local var_0_8 = 0.5
local var_0_9 = 8
local var_0_10 = 60
local var_0_11 = 20010047
local var_0_12 = 20010068

function var_0_3.getAD(arg_1_0)
	return var_0_3.super.getAD(arg_1_0) + math.floor(arg_1_0:getDamageBlood() / 8) * (var_0_5 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) + var_0_4)
end

function var_0_3.getDamageBlood(arg_2_0)
	return (arg_2_0:getHpLimit() - arg_2_0:getHp()) / arg_2_0:getHpLimit() * 100
end

function var_0_3.getCurrentAckSpeed(arg_3_0)
	return var_0_3.super.getCurrentAckSpeed(arg_3_0) + math.floor(arg_3_0:getDamageBlood() / 8) * (var_0_7 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) + var_0_6) / var_0_2.DECIMAL_BASE
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	local var_4_1 = arg_4_1.target

	if var_4_0 > 0 and arg_4_1.basicHarm > 0 and var_4_1:getTeamType() ~= arg_4_0:getTeamType() then
		local var_4_2 = var_4_1:getBuffByID(var_0_11)
		local var_4_3 = var_4_1:getBuffByID(var_0_12)

		if var_4_2 and var_4_3 then
			var_4_2.leftCount_ = var_4_2.leftCount_ + var_0_10
			var_4_3.leftCount_ = var_4_3.leftCount_ + var_0_10

			arg_4_1:setExtraHarm(arg_4_0:getAD() * var_0_8 + var_4_0 * var_0_9)
		end
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

return var_0_3
