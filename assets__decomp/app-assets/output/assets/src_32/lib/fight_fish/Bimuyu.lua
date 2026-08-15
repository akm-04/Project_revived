local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Bimuyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 30

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6)
	local var_1_0 = math.random() - 0.5

	arg_1_4 = math.max(arg_1_4 + math.floor(var_1_0 * var_0_4), 0)

	return arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6
end

return var_0_3
