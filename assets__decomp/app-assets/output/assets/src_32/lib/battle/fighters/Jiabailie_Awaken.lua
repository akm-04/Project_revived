local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiabailie", var_0_1.ctx.battle.requireFighter("Jiabailie"))
local var_0_4 = 40010719
local var_0_5 = 40010718

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isAddAwakenBuff_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if not arg_2_0.isEnergyType_ and arg_2_0.isAddAwakenBuff_ then
		arg_2_0.isAddAwakenBuff_ = false

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				iter_2_1:removeBuffByID(var_0_4)
				iter_2_1:removeBuffByID(var_0_5)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if not arg_3_0.isAddAwakenBuff_ and arg_3_0.isEnergyType_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_3_0:createAwakenSkill()
	end
end

function var_0_3.createAwakenSkill(arg_4_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_4_0, iter_4_1)
		end
	end

	if #var_4_0 == 0 or not next(var_4_0) then
		return
	end

	local var_4_1 = arg_4_0:createAttackUnits(var_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

	for iter_4_2, iter_4_3 in ipairs(var_4_1) do
		table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
		table.insert(arg_4_0.records_.special_units, iter_4_3)
	end

	arg_4_0.isAddAwakenBuff_ = true
end

return var_0_3
