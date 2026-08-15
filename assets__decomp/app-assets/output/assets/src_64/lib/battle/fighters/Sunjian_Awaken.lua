local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunjian", var_0_1.ctx.battle.requireFighter("Sunjian"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill

function var_0_3.selectTargetByTypeD2(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = {}

	for iter_1_0 = #arg_1_0.eatSummonMonsters_, 1, -1 do
		if arg_1_0.eatSummonMonsters_[iter_1_0]:isDeath() then
			table.remove(arg_1_0.eatSummonMonsters_, iter_1_0)
		end
	end

	table.sort(arg_1_0.eatSummonMonsters_, function(arg_2_0, arg_2_1)
		return arg_2_0.bornCount_ > arg_2_1.bornCount_
	end)

	local var_1_1

	for iter_1_1 = #arg_1_0.eatSummonMonsters_, 1, -1 do
		local var_1_2 = arg_1_0.eatSummonMonsters_[iter_1_1]

		if not var_1_2:isDeath() and not var_1_2:isAffected() and (not var_1_1 or var_1_2.bornCount_ == var_1_1) then
			var_1_1 = var_1_2.bornCount_

			table.insert(var_1_0, var_1_2)
		end
	end

	return var_1_0
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.target
	local var_3_1 = var_0_6:father(arg_3_1.skillID)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_3_0.eatSummonMonsterInterval_ = arg_3_0.eatSummonMonsterInterval_ - 30
	end
end

function var_0_3.deathFeedback(arg_4_0, arg_4_1)
	if arg_4_1:getSummonType() == var_0_2.summonMonsterType.Copy and arg_4_1.summoner and arg_4_1.summoner:getTeamType() ~= arg_4_0:getTeamType() and not arg_4_1.summoner:isDeath() and not arg_4_1.summoner:isAffected() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_1.summoner
		}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

return var_0_3
