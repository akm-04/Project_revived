local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhurong", var_0_1.ctx.battle.requireFighter("Zhurong"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 0.1
local var_0_9 = 0.003
local var_0_10 = 10000042
local var_0_11 = 80110002
local var_0_12 = 10

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.twice_awake_skill = {}
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getOrbOfFrontSkill(arg_2_0)
	local var_2_1 = var_0_4:orb(var_2_0)

	if var_2_1 > 0 and arg_2_0:getSkillLevelByID(var_2_1) > 0 then
		return var_2_1
	end

	return var_2_0
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if arg_3_1.rootID_ == var_0_11 then
			arg_3_1.idQueue_ = {}
			arg_3_1.pretimeQueue_ = {}

			local var_3_0 = var_0_4:children(arg_3_1.rootID_)

			if var_3_0 and #var_3_0 > 1 then
				local var_3_1 = 1

				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					if arg_3_0.skinChildCount and arg_3_0.skinChildCount[tostring(var_0_1.ctx.battle.count)] then
						var_3_1 = tonumber(arg_3_0.skinChildCount[tostring(var_0_1.ctx.battle.count)])
					end
				else
					local var_3_2 = #arg_3_0:selectTargetByTypeD2(var_0_11)

					if var_3_2 >= 2 and var_3_2 <= 3 then
						var_3_1 = 2
					elseif var_3_2 > 3 then
						var_3_1 = 3
					end

					arg_3_0.records_.skin_child_count[tostring(var_0_1.ctx.battle.count)] = var_3_1
				end

				local var_3_3 = 0

				for iter_3_0 = 1, var_3_1 do
					for iter_3_1, iter_3_2 in ipairs(var_3_0) do
						local var_3_4 = var_0_4:pretime(iter_3_2) + var_3_3 * var_0_12

						table.insert(arg_3_1.pretimeQueue_, var_3_4)
						table.insert(arg_3_1.idQueue_, iter_3_2)
					end

					var_3_3 = var_3_3 + 1
				end
			end
		end

		if arg_3_1.rootID_ ~= arg_3_0:getPugongID() and arg_3_1.rootID_ ~= 40010002 and arg_3_1.rootID_ ~= 60010002 then
			local var_3_5 = 0

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				if arg_3_0.twiceAwakeSkill and arg_3_0.twiceAwakeSkill[tostring(var_0_1.ctx.battle.count)] and arg_3_0.twiceAwakeSkill[tostring(var_0_1.ctx.battle.count)][tostring(arg_3_1.rootID_)] then
					var_3_5 = tonumber(arg_3_0.twiceAwakeSkill[tostring(var_0_1.ctx.battle.count)][tostring(arg_3_1.rootID_)])
				end
			else
				local var_3_6 = var_0_8 + arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * var_0_9

				if var_0_2.weightedChoise({
					var_3_6,
					1 - var_3_6
				}) == 1 then
					arg_3_0.records_.twice_awake_skill[tostring(var_0_1.ctx.battle.count)] = {}
					arg_3_0.records_.twice_awake_skill[tostring(var_0_1.ctx.battle.count)][tostring(arg_3_1.rootID_)] = 1
					var_3_5 = 1
				end
			end

			if var_3_5 > 0 then
				local var_3_7 = var_0_0.clone(arg_3_1.pretimeQueue_)
				local var_3_8 = 5

				for iter_3_3, iter_3_4 in ipairs(var_3_7) do
					var_3_8 = iter_3_4 + var_3_8
				end

				for iter_3_5, iter_3_6 in ipairs(var_3_7) do
					table.insert(arg_3_1.pretimeQueue_, iter_3_6 + var_3_8)
				end

				local var_3_9 = var_0_0.clone(arg_3_1.idQueue_)

				for iter_3_7, iter_3_8 in ipairs(var_3_9) do
					table.insert(arg_3_1.idQueue_, iter_3_8)
				end
			end
		end
	end

	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.twiceAwakeSkill = arg_4_1.twice_awake_skill
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.twice_awake_skill = arg_5_0.records_.twice_awake_skill

	return var_5_0
end

return var_0_3
