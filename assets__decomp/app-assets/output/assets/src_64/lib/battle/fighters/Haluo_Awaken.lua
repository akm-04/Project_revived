local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Haluo"))
local var_0_4 = 40010129

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("magic_crit_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("magic_crit_info")) do
			local var_2_0 = iter_2_1[1].target

			if var_2_0:getTeamType() == arg_2_0:getTeamType() and var_2_0:isHasBuffByID(var_0_4) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_1 = arg_2_0:createAttackUnits({
					var_2_0
				}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				for iter_2_2, iter_2_3 in ipairs(var_2_1) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end
		end
	end
end

return var_0_3
