local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuejin", var_0_1.ctx.battle.requireFighter("Yuejin"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = 0.8
local var_0_6 = 40011606
local var_0_7 = 60020047
local var_0_8 = 10002184

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakenCureHarm = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_0:isHasBuffByID(var_0_6) and arg_2_1.basicHarm > 0 then
		arg_2_1:setExtraHarm(arg_2_0.awakenCureHarm * var_0_5)

		arg_2_0.awakenCureHarm = 0

		arg_2_0:removeBuffByID(var_0_6)
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)
end

function var_0_3.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByTarget(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.fighter:getTeamType() ~= arg_3_0:getTeamType() and arg_3_2 then
		local var_3_0 = arg_3_0:createAttackUnits({
			arg_3_0
		}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		arg_3_0.awakenCureHarm = arg_3_0.awakenCureHarm + arg_3_5
	end

	if arg_3_0.hero_:isAwakeTwice() and arg_3_1.fighter:getTeamType() ~= arg_3_0:getTeamType() and arg_3_1.target == arg_3_0 and arg_3_4 > 0 and not arg_3_2 then
		local var_3_1 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_0_7)

		for iter_3_2, iter_3_3 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.forceDie(arg_4_0)
	if arg_4_0:getSummonType() == var_0_2.summonMonsterType.None and arg_4_0.hero_:isAwakeTwice() then
		arg_4_0:specialAttack()
	end

	var_0_3.super.forceDie(arg_4_0)
end

function var_0_3.specialAttack(arg_5_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_5_0 = false

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() or iter_5_1:canReborn() then
			var_5_0 = true
		end
	end

	if not var_5_0 then
		return
	end

	local var_5_1 = var_0_8
	local var_5_2 = var_0_4.A2(arg_5_0, var_5_1)

	if next(var_5_2) then
		local var_5_3 = arg_5_0:createAttackUnits(var_5_2, var_5_1)

		for iter_5_2, iter_5_3 in ipairs(var_5_3) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	end
end

return var_0_3
