local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunyu", var_0_1.ctx.battle.requireFighter("HideBoss"))
local var_0_4 = 10000136
local var_0_5 = 80010036
local var_0_6 = 0.3
local var_0_7 = 50110036

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	if arg_1_1.skillID == arg_1_0:getEnergySkillID() then
		-- block empty
	end

	local var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5 = var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if var_1_2 > 0 and arg_1_1.skillID == var_0_7 and arg_1_0:getAP() > arg_1_1.target:getAP() and arg_1_0.isSkinSkillOn_ and arg_1_0.skinSkillID_ == var_0_5 then
		var_1_2 = var_1_2 * (1 + var_0_6)
	end

	return var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.skillID == arg_2_0:getEnergySkillID() and arg_2_0:isDeath() then
		return
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.skillRehp_ = 0
end

function var_0_3.checkReHpMp(arg_4_0)
	var_0_3.super.checkReHpMp(arg_4_0)
end

return var_0_3
