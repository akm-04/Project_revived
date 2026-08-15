local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhugeliangWater", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 0.05

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isSmall_ = false
end

function var_0_3.setSmallType(arg_2_0, arg_2_1)
	arg_2_0.isSmall_ = arg_2_1 or false
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if var_3_2 > 0 then
		local var_3_6 = arg_3_1.target:getHp() * var_0_4 * arg_3_1.target:getADJianShang()

		if arg_3_0.isSmall_ then
			var_3_6 = var_3_6 / 2
		end

		if var_3_6 > 100 * arg_3_0:getLevel() then
			var_3_6 = 100 * arg_3_0:getLevel()
		end

		var_3_2 = var_3_2 + var_3_6
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

return var_0_3
