local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SunwukongMirrow", var_0_1.ctx.battle.requireFighter("Sunwukong"))
local var_0_4 = 0.05
local var_0_5 = 0.005

function var_0_3.getAwakenLevel(arg_1_0)
	if not arg_1_0.awakenLevel_ then
		arg_1_0.awakenLevel_ = arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	end

	return arg_1_0.awakenLevel_
end

function var_0_3.getADJianShang(arg_2_0)
	return var_0_3.super.getADJianShang(arg_2_0) * 2
end

function var_0_3.getAPJianShang(arg_3_0)
	return var_0_3.super.getAPJianShang(arg_3_0) * 2
end

function var_0_3.getAD(arg_4_0)
	return var_0_3.super.getAD(arg_4_0) * (var_0_4 + var_0_5 * arg_4_0:getAwakenLevel())
end

function var_0_3.die(arg_5_0)
	var_0_3.super.die(arg_5_0)
end

return var_0_3
