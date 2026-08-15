local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = 10001514
local var_0_8 = 10001515
local var_0_9 = 10001516

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillUsed = false
end

function var_0_3.getFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getFrontSkill(arg_2_0)

	if arg_2_0.isStarEnergy_ and var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		var_2_0 = var_0_7
	elseif arg_2_0.isStarBlue_ and var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		var_2_0 = var_0_8
	end

	return var_2_0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if not arg_3_0.purpleSkillUsed then
		if arg_3_0.isStarPurple_ then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_0 = arg_3_0:createAttackUnits(var_0_6.A2(arg_3_0), var_0_9)

				for iter_3_0, iter_3_1 in ipairs(var_3_0) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end
			end
		elseif var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_1 = arg_3_0:createAttackUnits(var_0_6.A2(arg_3_0), arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			for iter_3_2, iter_3_3 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end

		arg_3_0.purpleSkillUsed = true
	end
end

return var_0_3
