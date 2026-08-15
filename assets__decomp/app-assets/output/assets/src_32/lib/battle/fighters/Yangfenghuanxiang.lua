local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangfenghuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 90
local var_0_5 = 10
local var_0_6 = 6

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftCount_ = var_0_4
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	arg_2_0.leftCount_ = arg_2_0.leftCount_ - 1

	if arg_2_0.leftCount_ < 1 and not arg_2_0:isDeath() then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_6 = 0

	return var_3_0, var_3_1, var_3_6, var_3_3, var_3_4, var_3_5
end

function var_0_3.applyBuffHarms(arg_4_0)
	return
end

function var_0_3.checkSkillBreak(arg_5_0, arg_5_1)
	return
end

function var_0_3.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	arg_6_2 = 0

	return var_0_3.super.updateUnitDataByTarget(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if var_7_2 > 0 and arg_7_0.summoner and arg_7_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		var_7_2 = var_7_2 + arg_7_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_6 + var_0_5
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

return var_0_3
