local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caoxing", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 30010044
local var_0_6 = 0.1
local var_0_7 = 0.2
local var_0_8 = 270
local var_0_9 = 90
local var_0_10 = 10000372
local var_0_11 = 0
local var_0_12 = 1
local var_0_13 = 30010045
local var_0_14 = 3
local var_0_15 = 5
local var_0_16 = 0.1
local var_0_17 = 10000
local var_0_18 = 30010046
local var_0_19 = 80010096
local var_0_20 = 0.15
local var_0_21 = 0.2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.hasCount = false
	arg_1_0.greenTarget = {}
	arg_1_0.speedUp = 1
	arg_1_0.purpleSkillExsist = false
	arg_1_0.currentTarget = nil
	arg_1_0.purpleCount = 0
end

function var_0_3.updateUnitDataByTarget(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	if arg_2_0.skinSkillID_ == var_0_19 and arg_2_4 > 0 and (arg_2_1.fighter:isHasBuffByID(var_0_18) or arg_2_1.fighter:isHasBuffByID(var_0_13)) then
		arg_2_4 = arg_2_4 - arg_2_4 * var_0_21
	end

	return arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_0.skinSkillID_ == var_0_19 and arg_3_1.basicHarm > 0 and (arg_3_1.target:isHasBuffByID(var_0_18) or arg_3_1.target:isHasBuffByID(var_0_13)) and var_0_2.weightedChoise({
		var_0_20,
		1 - var_0_20
	}) == 1 then
		arg_3_1.mustBaoji = true
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_0 = {
			hero = arg_3_1.target,
			count = var_0_8
		}

		table.insert(arg_3_0.greenTarget, var_3_0)
	end
end

function var_0_3.checkUnitBuffs(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4 = var_0_3.super.checkUnitBuffs(arg_4_0, arg_4_1, arg_4_2)

	if next(var_4_0) then
		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			if iter_4_1:getTableID() == var_0_5 then
				local var_4_5 = iter_4_1.target
				local var_4_6 = iter_4_1:getTime()
				local var_4_7 = math.ceil((1 - var_4_5:getHp() / var_4_5:getHpLimit()) / var_0_6) * var_0_7

				iter_4_1:setExtraTime(var_4_6 * var_4_7)
			end
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4
end

function var_0_3.die(arg_5_0)
	if arg_5_0.currentTarget then
		arg_5_0.currentTarget:removeBuffByID(var_0_13)

		arg_5_0.currentTarget = nil
	end

	var_0_3.super.die(arg_5_0)
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = var_0_4.new({
		tableID = arg_6_1,
		start = var_0_1.ctx.battle.count,
		level = arg_6_0:getSkillLevelByID(arg_6_3),
		skillID = arg_6_3,
		fighter = arg_6_0,
		target = arg_6_2
	})

	var_6_0:setIsHit(true)
	var_6_0:setDirection(arg_6_0:getFighterModel():getFlipX())

	return {
		var_6_0
	}
end

function var_0_3.calculateUnitData(arg_7_0, arg_7_1)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.calculateUnitData(arg_7_0, arg_7_1)

	if arg_7_0.purpleSkillExsist and var_7_2 > 0 then
		if arg_7_0.currentTarget and arg_7_0.currentTarget == arg_7_1.target then
			arg_7_0.purpleCount = arg_7_0.purpleCount + 1

			if arg_7_0.purpleCount >= var_0_14 then
				local var_7_6 = (arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_16 + var_0_15) / 100
				local var_7_7 = arg_7_1.target:getHpLimit() * var_7_6

				if var_7_7 > var_0_17 then
					var_7_7 = var_0_17
				end

				var_7_2 = var_7_2 + var_7_7
				arg_7_0.purpleCount = 0
			end
		else
			if arg_7_0.currentTarget then
				arg_7_0.currentTarget:removeBuffByID(var_0_13)
			end

			arg_7_0.currentTarget = arg_7_1.target
			arg_7_0.purpleCount = 1

			arg_7_0.currentTarget:addBuffs(arg_7_0:newBuff(var_0_13, arg_7_1.target, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
		end
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.updateBaseInfo(arg_8_0)
	var_0_3.super.updateBaseInfo(arg_8_0)

	if not arg_8_0.hasCount then
		if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
			arg_8_0.speedUp = (arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_12 + var_0_11) / 100 + arg_8_0.speedUp
		end

		if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_8_0.purpleSkillExsist = true
		end

		arg_8_0.hasCount = true
	end

	if next(arg_8_0.greenTarget) ~= nil and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_8_0 = #arg_8_0.greenTarget, 1, -1 do
			local var_8_0 = arg_8_0.greenTarget[iter_8_0]

			var_8_0.count = var_8_0.count - 1

			if var_8_0.hero and var_8_0.hero:isDeath() then
				table.remove(arg_8_0.greenTarget, iter_8_0)
			else
				if var_8_0.count % var_0_9 == 0 then
					local var_8_1 = var_8_0.hero
					local var_8_2 = arg_8_0:createAttackUnits({
						var_8_1
					}, var_0_10)

					for iter_8_1, iter_8_2 in ipairs(var_8_2) do
						table.insert(arg_8_0.moveAttackUnits_, iter_8_2)
						table.insert(arg_8_0.records_.special_units, iter_8_2)
					end
				end

				if var_8_0.count <= 0 then
					table.remove(arg_8_0.greenTarget, iter_8_0)
				end
			end
		end
	end
end

function var_0_3.isTeamWeaker(arg_9_0)
	local var_9_0 = 0
	local var_9_1 = 0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_9_0 = var_9_0 + 1
		end
	end

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_3:isDeath() and iter_9_3:getSummonType() == var_0_2.summonMonsterType.None then
			var_9_1 = var_9_1 + 1
		end
	end

	if var_9_0 < var_9_1 then
		return true
	else
		return false
	end
end

function var_0_3.getCurrentAckSpeed(arg_10_0)
	if arg_10_0:isTeamWeaker() then
		return var_0_3.super.getCurrentAckSpeed(arg_10_0) * arg_10_0.speedUp
	else
		return var_0_3.super.getCurrentAckSpeed(arg_10_0)
	end
end

return var_0_3
