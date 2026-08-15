local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caocao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 3.5
local var_0_11 = 20010043
local var_0_12 = 20010042
local var_0_13 = 10000062
local var_0_14 = 80010033
local var_0_15 = 0.5
local var_0_16 = 80030033
local var_0_17 = 2
local var_0_18 = 0.5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCount = 0
end

function var_0_3.getAD(arg_2_0)
	local var_2_0 = var_0_3.super.getAD(arg_2_0)
	local var_2_1 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

	if var_2_1 < 1 then
		return var_2_0
	end

	local var_2_2 = 0
	local var_2_3 = 0

	for iter_2_0, iter_2_1 in ipairs(var_0_1.ctx.battle.teamA) do
		if iter_2_1:isDeath() and iter_2_1.summonType_ == var_0_2.summonMonsterType.None then
			var_2_2 = var_2_2 + 1
		elseif iter_2_1:isDeath() then
			var_2_3 = var_2_3 + 1
		end
	end

	for iter_2_2, iter_2_3 in ipairs(var_0_1.ctx.battle.teamB) do
		if iter_2_3:isDeath() and iter_2_3.summonType_ == var_0_2.summonMonsterType.None then
			var_2_2 = var_2_2 + 1
		elseif iter_2_3:isDeath() then
			var_2_3 = var_2_3 + 1
		end
	end

	local var_2_4 = var_0_9:init(var_0_11)
	local var_2_5 = var_0_9:step(var_0_11)
	local var_2_6 = var_0_9:init(var_0_12)
	local var_2_7 = var_0_9:step(var_0_12)
	local var_2_8 = var_2_0 + (var_2_4 + var_2_1 * var_2_5) * var_2_2 + (var_2_6 + var_2_1 * var_2_7) * var_2_3

	return math.min(var_0_10 * var_2_0, var_2_8)
end

function var_0_3.forceDie(arg_3_0)
	if arg_3_0:getSummonType() == var_0_2.summonMonsterType.None then
		arg_3_0:specialAttack()
	end

	var_0_3.super.forceDie(arg_3_0)
end

function var_0_3.specialAttack(arg_4_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_4_0 = false

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() or iter_4_1:canReborn() then
			var_4_0 = true
		end
	end

	if not var_4_0 then
		return
	end

	local var_4_1 = var_0_13
	local var_4_2 = var_0_5.B2(arg_4_0, var_4_1)

	if next(var_4_2) then
		local var_4_3 = arg_4_0:createAttackUnits(var_4_2, var_4_1)

		for iter_4_2, iter_4_3 in ipairs(var_4_3) do
			iter_4_3.arrived = false

			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end
	end
end

function var_0_3.getCountReMp(arg_5_0)
	local var_5_0 = var_0_3.super.getCountReMp(arg_5_0)
	local var_5_1 = 0

	if arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_16 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_1:isDeath() then
				if iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
					var_5_1 = var_5_1 + var_0_17
				else
					var_5_1 = var_5_1 + var_0_17 / 2
				end
			end
		end
	end

	return var_5_0 + var_5_1
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if var_0_6:father(arg_6_1.rootID_) == arg_6_0:getEnergySkillID() and arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_16 then
		arg_6_0.energyCount = arg_6_0.energyCount + 1
	end
end

function var_0_3.getAliveEnemy(arg_7_0)
	local var_7_0 = 0

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() then
			var_7_0 = var_7_0 + 1
		end
	end

	return var_7_0
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if var_8_2 > 0 and arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_14 and (arg_8_1.skillID == arg_8_0:getEnergySkillID() or arg_8_1.skillID == var_0_13) then
		var_8_2 = var_8_2 + var_0_15 * arg_8_0:getAliveEnemy() * var_8_2
	end

	if var_8_2 > 0 and var_0_6:father(arg_8_1.skillID) == arg_8_0:getEnergySkillID() and arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_16 then
		var_8_2 = var_8_2 * (1 + math.min(arg_8_0.energyCount * var_0_18, 3))
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

return var_0_3
