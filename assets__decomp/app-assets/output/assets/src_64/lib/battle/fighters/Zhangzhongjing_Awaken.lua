local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Zhangzhongjing", var_0_1.ctx.battle.requireFighter("Zhangzhongjing"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 40012306
local var_0_8 = 0.1
local var_0_9 = 0.003
local var_0_10 = 40010752
local var_0_11 = 40010755

function var_0_4.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)
	local var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5 = var_0_4.super.updateUnitDataByFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6, arg_1_7)

	if arg_1_0:isHasBuffByID(var_0_7) and var_1_2 > 0 then
		if not var_1_1 and not var_1_0 then
			var_1_1 = true
			var_1_2 = var_1_2 * (arg_1_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_1_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
			var_1_2 = var_1_2 * math.max(0.01, arg_1_1.target:getADBaoJiJianShang())
		end

		arg_1_0:removeBuffByID(var_0_7)

		var_1_2 = var_1_2 + var_1_2 * (var_0_8 + var_0_9 * arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	return var_0_4.super.updateUnitDataByFighter(arg_1_0, arg_1_1, var_1_0, var_1_1, var_1_2, var_1_3, var_1_4, var_1_5)
end

function var_0_4.addBuffs(arg_2_0, arg_2_1)
	for iter_2_0, iter_2_1 in ipairs(arg_2_1) do
		if iter_2_1:getTableID() == var_0_10 or iter_2_1:getTableID() == var_0_11 then
			local var_2_0 = arg_2_0:createNewBuffs({
				var_0_7
			}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			arg_2_0:addBuffs(var_2_0)
		end
	end

	var_0_4.super.addBuffs(arg_2_0, arg_2_1)
end

return var_0_4
