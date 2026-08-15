local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangdaoling", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.hero
local var_0_5 = 0
local var_0_6 = 11

function var_0_3.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_1_0 = arg_1_1.target

		if var_0_4:speed(var_1_0:getTableID()) > var_1_0:getCurrentSpeed() then
			arg_1_4 = arg_1_4 + (var_0_5 + var_0_6 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * arg_1_1.target:getAPJianShang()
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
end

return var_0_3
