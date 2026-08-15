local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_4 = var_0_0.class("Caopi", var_0_1.ctx.battle.requireFighter("Hide_Caopi"))
local var_0_5 = 10000767
local var_0_6 = 10010135
local var_0_7 = 10000303
local var_0_8 = 0.05
local var_0_9 = 40010842
local var_0_10 = 10000
local var_0_11 = 10

function var_0_4.init(arg_1_0)
	var_0_4.super.init(arg_1_0)
end

function var_0_4.calculateUnitData(arg_2_0, arg_2_1)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_4.super.calculateUnitData(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_5 then
		local var_2_6 = arg_2_1.target

		var_2_2 = math.min(var_2_6:getHp() * var_0_8, var_0_10)
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_4.applySingleUnit(arg_3_0, arg_3_1)
	arg_3_0.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == var_0_7 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_3_0 = 0

		for iter_3_0, iter_3_1 in pairs(arg_3_0.sideTeam_) do
			if iter_3_1:getBuffByID(var_0_6) then
				var_3_0 = var_3_0 + 1
			end
		end

		for iter_3_2, iter_3_3 in pairs(arg_3_0.selfTeam_) do
			if iter_3_3:getBuffByID(var_0_6) then
				var_3_0 = var_3_0 + 1
			end
		end

		if #arg_3_0:getBuffsByID(var_0_9) <= var_0_11 then
			local var_3_1 = var_0_3.new({
				tableID = var_0_9,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				fighter = arg_3_0,
				target = arg_3_0
			})

			arg_3_0:addBuffs({
				var_3_1
			})
		end
	elseif arg_3_1.skillID ~= var_0_5 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_1.target:getBuffByID(var_0_6) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_2 = arg_3_0:createAttackUnits({
			arg_3_1.target
		}, var_0_5)

		table.insert(arg_3_0.moveAttackUnits_, var_3_2[1])
		arg_3_0:unitAfterCreate(nil, var_3_2)
	end
end

return var_0_4
