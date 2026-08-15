local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Quanshen", var_0_1.ctx.battle.requireFighter("Quanshen"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40011589
local var_0_7 = 90
local var_0_8 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.AwakeBuffTimeCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	arg_2_0.AwakeBuffTimeCount = arg_2_0.AwakeBuffTimeCount - 1
end

function var_0_3.removeBuffBySpecialHero(arg_3_0, arg_3_1)
	var_0_3.super.removeBuffBySpecialHero(arg_3_0, arg_3_1)

	if arg_3_1:getTime() >= var_0_7 and arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and (arg_3_1:dBuffType() > 0 or arg_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF) and arg_3_1:getTableID() ~= var_0_6 and var_0_1.ctx.battle.count - arg_3_1:getStartTime() >= var_0_7 and (arg_3_1.fighter == arg_3_0 or arg_3_0.AwakeBuffTimeCount < 0) then
		if arg_3_1.fighter ~= arg_3_0 then
			arg_3_0.AwakeBuffTimeCount = var_0_8
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_0 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_3_0, iter_3_1 in ipairs(var_3_0) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end
end

return var_0_3
