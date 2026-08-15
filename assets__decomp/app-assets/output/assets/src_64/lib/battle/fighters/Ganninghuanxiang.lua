local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ganninghuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 1
local var_0_5 = 20
local var_0_6 = 0.5
local var_0_7 = 10

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.leftCount_ = 10 * var_0_1.ctx.battleConst.frames
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	arg_2_0.leftCount_ = arg_2_0.leftCount_ - 1

	if arg_2_0.leftCount_ < 1 and not arg_2_0:isDeath() then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end
end

return var_0_3
