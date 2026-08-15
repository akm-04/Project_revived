local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhuhuan", var_0_1.ctx.battle.requireFighter("Zhuhuan"))
local var_0_4 = 40012049

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.basicHarm > 0 then
		local var_1_0 = arg_1_0:createNewBuffs({
			var_0_4
		}, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_0)
	end
end

return var_0_3
