local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Agan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isBerserker_ = false
end

function var_0_3.updateHp(arg_2_0, arg_2_1, arg_2_2)
	var_0_3.super.updateHp(arg_2_0, arg_2_1, arg_2_2)

	if arg_2_0:getHp() <= arg_2_0:getHpLimit() * 0.5 then
		arg_2_0.isBerserker_ = true
	end
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)
	local var_3_1 = var_0_4:buffOrb(var_3_0)

	if var_3_1 and arg_3_0.isBerserker_ then
		return var_3_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_3_0)
end

function var_0_3.resetLeftInterval(arg_4_0)
	if arg_4_0.isBerserker_ then
		arg_4_0.leftInterval_ = 0
	else
		arg_4_0.leftInterval_ = arg_4_0:getInterval()
	end
end

return var_0_3
