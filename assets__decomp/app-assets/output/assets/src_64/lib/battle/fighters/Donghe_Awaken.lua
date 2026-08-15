local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Donghe", var_0_1.ctx.battle.requireFighter("Donghe"))
local var_0_4 = 0.2
local var_0_5 = 0.002

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("unit_cure_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("unit_cure_info")) do
		local var_2_0 = var_0_4 + var_0_5 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
		local var_2_1 = iter_2_1.cure * var_2_0

		arg_2_0:updateHp(var_2_1 + arg_2_0:getHp())
	end
end

return var_0_3
