local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangliang", var_0_1.ctx.battle.requireFighter("Zhangliang"))
local var_0_4 = 3
local var_0_5 = 0.3
local var_0_6 = 0.005
local var_0_7 = 10000827
local var_0_8 = 60010164
local var_0_9 = 150

function var_0_3.toDoPerFrames(arg_1_0)
	var_0_3.super.toDoPerFrames(arg_1_0)

	if arg_1_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 30 == 0 then
		arg_1_0:updateChargeNum(var_0_4)
	end
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_7 then
		local var_2_0 = arg_2_1.target

		if var_2_0:getTeamType() ~= arg_2_0:getTeamType() then
			local var_2_1 = {}

			for iter_2_0, iter_2_1 in ipairs(arg_2_0.targetTeam_) do
				if iter_2_1 ~= var_2_0 and math.abs(iter_2_1:getX() - var_2_0:getX()) <= var_0_9 then
					table.insert(var_2_1, iter_2_1)
				end
			end

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_2 = arg_2_0:createAttackUnits(var_2_1, var_0_8)

				for iter_2_2, iter_2_3 in ipairs(var_2_2) do
					local var_2_3 = arg_2_1.harm * (var_0_5 + arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_6)

					iter_2_3:setExtraHarm(var_2_3)
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end
		end
	end
end

return var_0_3
