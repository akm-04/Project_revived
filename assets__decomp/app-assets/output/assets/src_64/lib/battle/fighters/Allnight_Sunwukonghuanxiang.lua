local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunwukonghuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 1
local var_0_5 = 20
local var_0_6 = 0.5
local var_0_7 = 10
local var_0_8 = {
	81200002,
	81200007,
	81200008,
	81200003,
	81200004,
	81200005,
	81200009,
	81200006
}
local var_0_9 = 10
local var_0_10 = {
	40012208,
	40012209,
	40012210
}
local var_0_11 = 0.01
local var_0_12 = 40012211
local var_0_13 = 0.5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftCount_ = 15 * var_0_1.ctx.battleConst.frames
	arg_1_0.extraHp_ = 0
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	arg_2_0.leftCount_ = arg_2_0.leftCount_ - 1

	if arg_2_0.leftCount_ < 1 and not arg_2_0:isDeath() then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

function var_0_3.getShanBi(arg_3_0)
	return var_0_5 + var_0_4 * arg_3_0:getSkillLevelByID(var_0_8[1])
end

function var_0_3.getAD(arg_4_0)
	if arg_4_0.summoner then
		return arg_4_0.summoner:getAD() * var_0_6
	end

	return var_0_3.super.getAD(arg_4_0)
end

function var_0_3.setExtraSkillHp(arg_5_0, arg_5_1)
	arg_5_0.extraHp_ = arg_5_0.extraHp_ + arg_5_1
end

function var_0_3.die(arg_6_0)
	var_0_3.super.die(arg_6_0)

	if arg_6_0:isDeath() and arg_6_0.summoner:isHasSkill(var_0_8[3]) then
		local var_6_0 = arg_6_0:createNewBuffs(var_0_10, arg_6_0.summoner, var_0_8[3])

		arg_6_0.summoner:addBuffs(var_6_0)
		arg_6_0.summoner:updateHp(arg_6_0.summoner:getHp() * (1 - var_0_11))
	end
end

function var_0_3.afterDamageHarm(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_1 > 0 and arg_7_0.summoner and arg_7_0.summoner:isHasSkill(var_0_8[2]) then
		arg_7_0.summoner:updateHp(arg_7_0.summoner:getHp() + arg_7_1 * var_0_9)
	end
end

function var_0_3.updateUnitDataByTarget(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.fighter:isHasBuffByID(var_0_12) and arg_8_4 > 0 then
		arg_8_4 = arg_8_4 * (1 - var_0_13)
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.isForverNeverDie(arg_9_0)
	return next(arg_9_0.forverNeverDieBuffs_) ~= nil
end

return var_0_3
