local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hudieyu", var_0_0.import("lib.fight_fish.FightFish"))
local var_0_4 = 100
local var_0_5 = 140

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.speed = {}
	arg_1_0.speed = 10
end

function var_0_3.updateLeftInterval(arg_2_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_2_0.speed = arg_2_0.recordSpeed_[tostring(var_0_1.ctx.battle.count)]
	else
		arg_2_0.speed = math.random(var_0_4, var_0_5)
		arg_2_0.records_.speed[tostring(var_0_1.ctx.battle.count)] = arg_2_0.speed
	end

	arg_2_0.leftInterval_ = arg_2_0.leftInterval_ - arg_2_0:getAttrByType(var_0_2.FishAttributeType.SPEED)
end

function var_0_3.getAttrByType(arg_3_0, arg_3_1)
	if arg_3_1 == var_0_2.FishAttributeType.SPEED then
		return arg_3_0.speed
	else
		return var_0_3.super.getAttrByType(arg_3_0, arg_3_1)
	end
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.recordSpeed_ = arg_4_1.speed
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.speed = arg_5_0.records_.speed

	return var_5_0
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6)
	if arg_6_0:getAttrByType(var_0_2.FishAttributeType.SPEED) > arg_6_0.target:getAttrByType(var_0_2.FishAttributeType.SPEED) then
		arg_6_4 = math.ceil(arg_6_4 * 1.5)
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6
end

return var_0_3
