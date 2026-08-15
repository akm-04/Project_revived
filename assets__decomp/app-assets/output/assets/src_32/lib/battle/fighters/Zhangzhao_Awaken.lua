local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Zhangzhao", var_0_1.ctx.battle.requireFighter("Zhangzhao"))
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 40012306
local var_0_8 = 60010112

function var_0_4.beginAttackEnd(arg_1_0, arg_1_1)
	var_0_4.super.beginAttackEnd(arg_1_0, arg_1_1)

	if var_0_5:father(arg_1_1.rootID_) ~= arg_1_0:getPugongID() then
		local var_1_0 = arg_1_0:createNewBuffs({
			var_0_7
		}, arg_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_1_0:addBuffs(var_1_0)
	end
end

function var_0_4.dHarmBuffBreakFeedback(arg_2_0, arg_2_1, arg_2_2)
	var_0_4.super.dHarmBuffBreakFeedback(arg_2_0, arg_2_1, arg_2_2)

	if arg_2_2:getTableID() ~= var_0_7 then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = var_0_8
		local var_2_1 = var_0_5:selectType(var_2_0)
		local var_2_2 = var_0_6[var_2_1](arg_2_0, var_2_0)
		local var_2_3 = arg_2_0:createAttackUnits(var_2_2, var_2_0)

		for iter_2_0, iter_2_1 in ipairs(var_2_3) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

return var_0_4
