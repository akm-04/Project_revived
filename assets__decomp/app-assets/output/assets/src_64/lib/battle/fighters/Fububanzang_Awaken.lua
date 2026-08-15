local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fububanzang", var_0_1.ctx.battle.requireFighter("Fububanzang"))
local var_0_4 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 8

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakePugongBuffCount = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	var_0_3.super.MarkBuff = 20020184
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)

	if var_0_1.ctx.battle.count % 30 == 0 then
		arg_3_0.awakePugongBuffCount = arg_3_0.awakePugongBuffCount + 1
	end
end

function var_0_3.updateUnitBaseByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if arg_4_1.skillID == arg_4_0:getPugongID() then
		local var_4_0 = arg_4_0:getAD() + arg_4_0.awakePugongBuffCount * var_0_8 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		arg_4_0.awakePugongBuffCount = 0

		return arg_4_2 * var_4_0 / var_0_2.DECIMAL_BASE + arg_4_3 * arg_4_0:getAP() / var_0_2.DECIMAL_BASE
	else
		return var_0_3.super.updateUnitBaseByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	end
end

return var_0_3
