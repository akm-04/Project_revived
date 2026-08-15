local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Bangni"))

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isAwakeReady_ = false
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	arg_2_0.isAwakeReady_ = true
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and arg_3_0.isAwakeReady_ then
		arg_3_0.isAwakeReady_ = false

		local var_3_0 = {
			arg_3_1.target
		}
		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

return var_0_3
