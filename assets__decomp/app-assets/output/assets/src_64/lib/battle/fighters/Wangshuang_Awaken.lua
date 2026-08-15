local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wangshuang", var_0_1.ctx.battle.requireFighter("Wangshuang"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = 40010159
local var_0_9 = 40010160
local var_0_10 = 40010164
local var_0_11 = 40012159
local var_0_12 = 40012160
local var_0_13 = 40012161

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_1_1.target:addBuffs(arg_1_0:createNewBuffs({
			var_0_11,
			var_0_12,
			var_0_13
		}, arg_1_1.target, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
	end
end

return var_0_3
