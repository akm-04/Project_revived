local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Zhanghong", var_0_1.ctx.battle.requireFighter("Zhanghong"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = {
	40012302,
	40012303,
	40012304
}

function var_0_4.applySingleUnit(arg_1_0, arg_1_1)
	var_0_4.super.applySingleUnit(arg_1_0, arg_1_1)

	if var_0_5:father(arg_1_1.skillID) == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) or var_0_5:father(arg_1_1.skillID) == arg_1_0:getEnergySkillID() then
		local var_1_0 = arg_1_0:createNewBuffs(var_0_6, arg_1_1.target, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_1.target:addBuffs(var_1_0)
	end
end

return var_0_4
