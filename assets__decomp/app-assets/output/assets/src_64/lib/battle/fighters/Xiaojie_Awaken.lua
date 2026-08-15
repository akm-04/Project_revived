local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Xiaojie"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0.2
local var_0_6 = 0.005
local var_0_7 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.is_hit = {}
	arg_1_0.BuffAddCoolingTime = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	for iter_2_0, iter_2_1 in pairs(arg_2_0.BuffAddCoolingTime) do
		arg_2_0.BuffAddCoolingTime[iter_2_0] = arg_2_0.BuffAddCoolingTime[iter_2_0] - 1
	end
end

function var_0_3.addBuffBySpecialHero(arg_3_0, arg_3_1)
	var_0_3.super.addBuffBySpecialHero(arg_3_0, arg_3_1)

	if arg_3_1 and next(arg_3_1) then
		for iter_3_0 = #arg_3_1, 1, -1 do
			local var_3_0 = arg_3_1[iter_3_0]

			if (var_3_0:dBuffType() ~= var_0_2.DBuffType.NONE or var_3_0:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE or var_3_0:getBuffForm() == var_0_2.BuffForm.DEBUFF) and var_3_0:canRemove() and var_3_0.target:getTeamType() == arg_3_0:getTeamType() and (not arg_3_0.BuffAddCoolingTime[var_3_0.target] or arg_3_0.BuffAddCoolingTime[var_3_0.target] <= 0) then
				local var_3_1 = math.min(var_0_5 + var_0_6 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), 1)
				local var_3_2 = true

				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					var_3_2 = arg_3_0.isHit_[tostring(var_0_1.ctx.battle.count)] or true
				else
					var_3_2 = var_0_2.weightedChoise({
						var_3_1,
						1 - var_3_1
					}) == 1
					arg_3_0.records_.is_hit[tostring(var_0_1.ctx.battle.count)] = var_3_2
				end

				if var_3_2 then
					table.remove(arg_3_1, iter_3_0)

					arg_3_0.BuffAddCoolingTime[var_3_0.target] = var_0_7
				end
			end
		end
	end
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.isHit_ = arg_4_1.is_hit or {}
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.is_hit = arg_5_0.records_.is_hit

	return var_5_0
end

return var_0_3
