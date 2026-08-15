local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahouxuan", var_0_1.ctx.battle.requireFighter("Xiahouxuan"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10001868
local var_0_8 = 10001869
local var_0_9 = 0.17
local var_0_10 = 90

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("harm_info")

	arg_1_0.bearHarm = 0
	arg_1_0.awakeDuration = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		if arg_2_0.awakeDuration > 0 then
			arg_2_0.awakeDuration = arg_2_0.awakeDuration - 1
		else
			for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("harm_info")) do
				local var_2_0 = iter_2_1.harm

				if iter_2_1.target == arg_2_0 then
					arg_2_0.bearHarm = arg_2_0.bearHarm + var_2_0
				end

				if arg_2_0:getHpLimit() * var_0_9 < arg_2_0.bearHarm then
					arg_2_0.awakeDuration = var_0_10
					arg_2_0.bearHarm = 0

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_2_1 = var_0_7
						local var_2_2 = var_0_6:selectType(var_2_1)
						local var_2_3 = var_0_4[var_2_2](arg_2_0, var_2_1)
						local var_2_4 = arg_2_0:createAttackUnits(var_2_3, var_2_1)

						for iter_2_2, iter_2_3 in ipairs(var_2_4) do
							table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
							table.insert(arg_2_0.records_.special_units, iter_2_3)
						end

						local var_2_5 = var_0_8
						local var_2_6 = var_0_6:selectType(var_2_5)
						local var_2_7 = var_0_4[var_2_6](arg_2_0, var_2_5)
						local var_2_8 = arg_2_0:createAttackUnits(var_2_7, var_2_5)

						for iter_2_4, iter_2_5 in ipairs(var_2_8) do
							table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
							table.insert(arg_2_0.records_.special_units, iter_2_5)
						end
					end

					break
				end
			end
		end
	end
end

return var_0_3
