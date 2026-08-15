local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Luzhi", var_0_1.ctx.battle.requireFighter("Luzhi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.03
local var_0_7 = 0.002

function var_0_3.updateEnergyBy(arg_1_0, arg_1_1, arg_1_2)
	if arg_1_1 > 0 then
		arg_1_1 = arg_1_1 + arg_1_1 * (var_0_6 + var_0_7 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	var_0_3.super.updateEnergyBy(arg_1_0, arg_1_1, arg_1_2)
end

return var_0_3
