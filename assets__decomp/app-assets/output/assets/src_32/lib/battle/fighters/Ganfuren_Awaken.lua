local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ganfuren", var_0_1.ctx.battle.requireFighter("Ganfuren"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000801
local var_0_7 = 0.2
local var_0_8 = 0.1
local var_0_9 = 0.6
local var_0_10 = 200
local var_0_11 = 300
local var_0_12 = 500
local var_0_13 = 40010867

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.awake_eat_hp = {}
	arg_1_0.awakenEatTargets_ = {}
	arg_1_0.awakeEatAp_ = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID ~= var_0_6 and var_0_5:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_2_1.target:getSummonType() == var_0_2.summonMonsterType.None and (not arg_2_0.awakenEatTargets_[arg_2_1.target] or var_0_1.ctx.battle.count - arg_2_0.awakenEatTargets_[arg_2_1.target] > var_0_11) then
		local var_2_0 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_2_0.awakeEatHpLimit[tostring(var_0_1.ctx.battle.count)] then
				var_2_0 = true
			end
		else
			var_2_0 = var_0_2.weightedChoise({
				var_0_7,
				1 - var_0_7
			}) == 1

			if var_2_0 then
				arg_2_0.records_.awake_eat_hp[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_2_0 then
			arg_2_0:useAwakeSkillToHero(arg_2_1.target)

			arg_2_0.awakenEatTargets_[arg_2_1.target] = var_0_1.ctx.battle.count
		end
	end
end

function var_0_3.useAwakeSkillToHero(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	local var_3_1 = var_0_10 * var_3_0
	local var_3_2 = var_0_12 * var_3_0
	local var_3_3 = 0
	local var_3_4 = arg_3_1:getTempHpLimit()

	if var_3_4 < var_3_1 then
		local var_3_5 = var_0_8 * arg_3_1:getHpLimit()

		if var_3_1 < var_3_4 + var_3_5 then
			var_3_3 = var_3_1 - var_3_4
			var_3_4 = var_3_1
		else
			var_3_3 = var_3_5
			var_3_4 = var_3_4 + var_3_5
		end

		arg_3_1:setTempHpLimit(var_3_4)

		local var_3_6 = arg_3_0:getTempHpLimit()

		if var_3_6 > -var_3_2 then
			local var_3_7 = var_0_9 * var_3_3

			if -var_3_7 + var_3_6 < -var_3_2 then
				var_3_6 = -var_3_2
			else
				var_3_6 = var_3_6 - var_3_7
			end

			arg_3_0:setTempHpLimit(var_3_6)
		end
	end

	local var_3_8 = arg_3_1:getAP() * var_0_8

	arg_3_0.awakeEatAp_ = arg_3_0.awakeEatAp_ + var_3_8 * var_0_9
end

function var_0_3.setupReport(arg_4_0, arg_4_1)
	var_0_3.super.setupReport(arg_4_0, arg_4_1)

	arg_4_0.awakeEatHpLimit = arg_4_1.awake_eat_hp
end

function var_0_3.writeReport(arg_5_0)
	local var_5_0 = var_0_3.super.writeReport(arg_5_0)

	var_5_0.awake_eat_hp = arg_5_0.records_.awake_eat_hp

	return var_5_0
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.getAP(arg_7_0)
	return var_0_3.super.getAP(arg_7_0) + arg_7_0.awakeEatAp_
end

return var_0_3
