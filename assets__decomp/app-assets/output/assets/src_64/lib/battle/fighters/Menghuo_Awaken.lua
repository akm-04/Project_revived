local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Menghuo", var_0_1.ctx.battle.requireFighter("Menghuo"))
local var_0_4 = 30010021
local var_0_5 = 40011031
local var_0_6 = 45

function var_0_3.buffAddAction(arg_1_0, arg_1_1)
	if arg_1_1:getTableID() == var_0_5 or arg_1_1:getTableID() == var_0_4 then
		local var_1_0 = var_0_6 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		arg_1_1.manualDharm = arg_1_1.manualDharm + var_1_0
		arg_1_1.dHarm_ = arg_1_1:totalDHarm()
	end

	var_0_3.super.buffAddAction(arg_1_0, arg_1_1)
end

return var_0_3
