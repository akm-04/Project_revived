local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guiyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 0.25

function var_0_3.getAttrByType(arg_1_0, arg_1_1)
	if arg_1_1 == var_0_2.FishAttributeType.BAOJI then
		return var_0_3.super.getAttrByType(arg_1_0, arg_1_1) + (1 - arg_1_0:getHp() / arg_1_0:getHpLimit()) * var_0_4
	else
		return var_0_3.super.getAttrByType(arg_1_0, arg_1_1)
	end
end

return var_0_3
