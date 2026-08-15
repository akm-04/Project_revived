local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mirage", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10010056
local var_0_6 = 60010056

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.manaBreakNum = 125
	arg_1_0.manaBreakTimes = 3
end

function var_0_3.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_1.skillID == var_0_5 and arg_2_4 > 0 and arg_2_0.manaBreakTimes > 0 then
		arg_2_7 = arg_2_7 - arg_2_0.manaBreakNum
		arg_2_0.manaBreakTimes = arg_2_0.manaBreakTimes - 1
	end

	return var_0_3.super.updateUnitDataByFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
end

return var_0_3
