local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangxiu", var_0_1.ctx.battle.requireFighter("Yangxiu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40010328
local var_0_7 = 5

function var_0_3.lightChess(arg_1_0)
	var_0_3.super.lightChess(arg_1_0)

	if arg_1_0.lightedChess_ >= var_0_7 then
		return
	end

	local var_1_0 = arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
	local var_1_1 = var_0_4.new({
		tableID = var_0_6,
		start = var_0_1.ctx.battle.count,
		level = arg_1_0:getSkillLevelByID(var_1_0),
		skillID = var_1_0,
		fighter = arg_1_0,
		target = arg_1_0
	})

	arg_1_0:addBuffs({
		var_1_1
	})
end

function var_0_3.dHarmBuffBreakFeedback(arg_2_0, arg_2_1, arg_2_2)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_0 = {}
		local var_2_1 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
		local var_2_2 = var_0_5:scope(var_2_1)

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and (not iter_2_1:isAffected() or not not iter_2_1:isInvisible()) and math.abs(iter_2_1:getX() - arg_2_0:getX()) <= var_2_2 * 0.5 then
				table.insert(var_2_0, iter_2_1)
			end
		end

		local var_2_3 = arg_2_0:createAttackUnits(var_2_0, var_2_1)

		for iter_2_2, iter_2_3 in ipairs(var_2_3) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
			table.insert(arg_2_0.records_.special_units, iter_2_3)
		end
	end
end

return var_0_3
