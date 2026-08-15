local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wood", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 300

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	arg_1_0.leftCount_ = var_0_4
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	arg_2_0.leftCount_ = arg_2_0.leftCount_ - 1

	if not arg_2_0:isDeath() and (arg_2_0.leftCount_ < 1 or var_0_1.ctx.battle.walk2NextBattle_) then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

function var_0_3.canAttack(arg_3_0)
	return false
end

function var_0_3.checkMove(arg_4_0)
	return
end

function var_0_3.die(arg_5_0)
	var_0_3.super.die(arg_5_0)
end

return var_0_3
