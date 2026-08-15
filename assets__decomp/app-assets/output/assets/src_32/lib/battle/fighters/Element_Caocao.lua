local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementCaocao", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = var_0_2.tables.dbuff
local var_0_11 = 3.5
local var_0_12 = 20010043
local var_0_13 = 20010042
local var_0_14 = 80022010
local var_0_15 = 80022011
local var_0_16 = 80022012
local var_0_17 = {
	200,
	300,
	400,
	500,
	600
}
local var_0_18 = {
	8,
	4,
	2,
	1,
	0.5,
	0.25
}
local var_0_19 = {
	40010460
}
local var_0_20 = {
	40010461
}
local var_0_21 = {
	40010462
}
local var_0_22 = 80022013
local var_0_23 = {
	40010469,
	40010470,
	40010471,
	40010472
}
local var_0_24 = {
	40010473,
	40010474
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceTargets_ = {}
	arg_1_0.awakeTwiceExtraRate_ = 0
	arg_1_0.energyExtraTarget_ = 0
	arg_1_0.count_ = false
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getEnergySkillID() then
		if arg_2_0.energyExtraTarget_ == 1 then
			arg_2_0.isEnergyFullTarget_ = true
		else
			arg_2_0.isEnergyFullTarget_ = false
		end

		local var_2_0

		if arg_2_0.isEnergyFullTarget_ then
			var_2_0 = var_0_24[1]
		else
			var_2_0 = var_0_24[2]
		end

		if var_2_0 then
			local var_2_1 = arg_2_0:newBuff({
				var_2_0
			}, arg_2_0, arg_2_0:getEnergySkillID())

			arg_2_0:addBuffs(var_2_1)
		end

		arg_2_0.energyExtraTarget_ = 0
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if not arg_3_0:isCreatingUnits() and arg_3_0.energyExtraTarget_ == 0 then
		arg_3_0.energyExtraTarget_ = math.random(1, 2)
	end

	if not arg_3_0.count_ and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_3_0.count_ = true

		local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		arg_3_0.awakeTwiceExtraRate_ = var_0_7:descNumInit(var_3_0)[1] * 0.01 + var_0_7:descNumStep(var_3_0)[1] * 0.01 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	if arg_5_1.skillID == var_0_15 and arg_5_1.target:isHasBuffByID(unpack(var_0_21)) then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_0 = {}
			local var_5_1 = var_0_7:scope(var_0_22)

			for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
				if not iter_5_1:isDeath() and not iter_5_1:isAffected() and math.abs(iter_5_1:getX() - arg_5_1.target:getX()) <= var_5_1 * 0.5 then
					table.insert(var_5_0, iter_5_1)
				end
			end

			local var_5_2 = arg_5_0:createAttackUnits(var_5_0, var_0_22)

			for iter_5_2, iter_5_3 in ipairs(var_5_2) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
				table.insert(arg_5_0.records_.special_units, iter_5_3)
			end
		end

		arg_5_1.target:removeBuffByID(unpack(var_0_21))
	end

	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if (arg_5_1.skillID == arg_5_0:getEnergySkillID() or arg_5_1.skillID == DIE_SKILL) and not arg_5_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_3 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_5_4, iter_5_5 in ipairs(var_5_3) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
			table.insert(arg_5_0.records_.special_units, iter_5_5)
		end
	end

	if var_0_7:father(arg_5_1.skillID) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if not arg_5_0.awakeTwiceTargets_[arg_5_1.target] then
			arg_5_0.awakeTwiceTargets_[arg_5_1.target] = 1
		else
			local var_5_4 = arg_5_0:createAttackUnits({
				arg_5_1.target
			}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_5_6, iter_5_7 in ipairs(var_5_4) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_7)
				table.insert(arg_5_0.records_.special_units, iter_5_7)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		local var_6_6 = math.abs(arg_6_1.target:getX() - arg_6_0:getX())

		for iter_6_0, iter_6_1 in ipairs(var_0_17) do
			if var_6_6 <= iter_6_1 then
				var_6_2 = var_6_2 * var_0_18[iter_6_0]

				break
			end

			if iter_6_0 == #var_0_17 then
				var_6_2 = var_6_2 * 0.25
			end
		end
	elseif arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		local var_6_7 = arg_6_1.target:getEnergy() == var_0_2.ENERGY_DECIMAL_BASE and true or false

		if arg_6_0.isEnergyFullTarget_ then
			if arg_6_0.isEnergyFullTarget_ == var_6_7 then
				var_6_2 = var_6_2 * 2
			else
				var_6_2 = var_6_2 * 0.5
			end
		elseif arg_6_0.isEnergyFullTarget_ == var_6_7 then
			local var_6_8 = var_0_23[math.random(1, #var_0_23)]
			local var_6_9 = arg_6_0:getEnergySkillID()
			local var_6_10 = arg_6_0:newBuff({
				var_6_8
			}, arg_6_1.target, arg_6_0:getEnergySkillID())

			arg_6_1.target:addBuffs(var_6_10)
		else
			var_6_2 = var_6_2 * 0.5
		end
	end

	if var_0_7:father(arg_6_1.skillID) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_6_0.awakeTwiceTargets_[arg_6_1.target] then
		var_6_2 = var_6_2 * (1 + arg_6_0.awakeTwiceExtraRate_)
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.getAD(arg_7_0)
	local var_7_0 = var_0_3.super.getAD(arg_7_0)
	local var_7_1 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

	if var_7_1 < 1 then
		return var_7_0
	end

	local var_7_2 = 0
	local var_7_3 = 0

	for iter_7_0, iter_7_1 in ipairs(var_0_1.ctx.battle.teamA) do
		if iter_7_1:isDeath() and iter_7_1.summonType_ == var_0_2.summonMonsterType.None then
			var_7_2 = var_7_2 + 1
		elseif iter_7_1:isDeath() then
			var_7_3 = var_7_3 + 1
		end
	end

	for iter_7_2, iter_7_3 in ipairs(var_0_1.ctx.battle.teamB) do
		if iter_7_3:isDeath() and iter_7_3.summonType_ == var_0_2.summonMonsterType.None then
			var_7_2 = var_7_2 + 1
		elseif iter_7_3:isDeath() then
			var_7_3 = var_7_3 + 1
		end
	end

	local var_7_4 = var_0_10:init(var_0_12)
	local var_7_5 = var_0_10:step(var_0_12)
	local var_7_6 = var_0_10:init(var_0_13)
	local var_7_7 = var_0_10:step(var_0_13)
	local var_7_8 = var_7_0 + (var_7_4 + var_7_1 * var_7_5) * var_7_2 + (var_7_6 + var_7_1 * var_7_7) * var_7_3

	return math.min(var_0_11 * var_7_0, var_7_8)
end

return var_0_3
