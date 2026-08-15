local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Panghui", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.cabinetSkillTable
local var_0_7 = 10000916
local var_0_8 = 10000914
local var_0_9 = 40011020
local var_0_10 = 450
local var_0_11 = 0.004
local var_0_12 = 10000915
local var_0_13 = 0
local var_0_14 = 0.007
local var_0_15 = 0
local var_0_16 = 0.006
local var_0_17 = 20030007
local var_0_18 = 0.03

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueTimeCount_ = var_0_10
	arg_1_0.energyTargets_ = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_17)] or 0
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		if arg_2_0.blueTimeCount_ > 0 then
			arg_2_0.blueTimeCount_ = arg_2_0.blueTimeCount_ - 1
		end

		if arg_2_0.blueTimeCount_ <= 0 then
			local var_2_0 = arg_2_0:newBuff({
				var_0_9
			}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_2_0:addBuffs(var_2_0)

			arg_2_0.blueTimeCount_ = var_0_10
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_0, var_3_1 = arg_3_1.target:getPos()
		local var_3_2 = arg_3_1.target:getFlipX() and 1 or -1
		local var_3_3 = var_0_1.ctx.battle.adjustX(var_3_0 + var_3_2 * 100, arg_3_0)

		if arg_3_1.target:avoidHeroMoveBehind() then
			var_3_3 = var_3_0 - 100

			arg_3_0:flipX(not arg_3_1.target:getFlipX())
		else
			arg_3_0:flipX(arg_3_1.target:getFlipX())
		end

		arg_3_0:pos(var_3_3, var_3_1)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_4 = arg_3_0:getGreenTargets(arg_3_1.target)
			local var_3_5 = arg_3_0:createAttackUnits(var_3_4, var_0_8)

			for iter_3_0, iter_3_1 in ipairs(var_3_5) do
				arg_3_1.changeHarm = changeHarm

				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	end
end

function var_0_3.getGreenTargets(arg_4_0, arg_4_1)
	if not arg_4_1 then
		return {}
	end

	local var_4_0 = {}
	local var_4_1 = var_0_5:scope(var_0_8) / 2
	local var_4_2, var_4_3 = arg_4_1:getPos()

	table.insert(var_4_0, arg_4_1)

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		local var_4_4, var_4_5 = iter_4_1:getPos()

		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and var_4_1 >= math.abs(var_4_2 - var_4_4) and iter_4_1 ~= arg_4_1 then
			table.insert(var_4_0, iter_4_1)
		end
	end

	return var_4_0
end

function var_0_3.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_4 > 0 and arg_5_0:isHasBuffByID(var_0_9) then
		local var_5_0 = var_0_11 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		local var_5_1 = math.min(1, var_5_0)

		if var_0_2.weightedChoise({
			var_5_1,
			1 - var_5_1
		}) == 1 then
			arg_5_4 = 0

			if not arg_5_1.fighter:isDeath() and not arg_5_1.fighter:isAffected() then
				local var_5_2 = arg_5_0:createAttackUnits({
					arg_5_1.fighter
				}, var_0_12)

				for iter_5_0, iter_5_1 in ipairs(var_5_2) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
					table.insert(arg_5_0.records_.special_units, iter_5_1)
				end
			end
		end
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_4 > 0 and arg_6_1.skillID == arg_6_0:getPugongID() and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_6_0 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_1 = arg_6_0:getEnergy() * (var_0_13 + var_0_14 * var_6_0)
		local var_6_2 = var_6_1 * (var_0_16 * var_6_0 + var_0_15)

		arg_6_4 = arg_6_4 + var_6_1
		arg_6_6 = arg_6_6 + var_6_2
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.newBuff(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		local var_7_1 = var_0_4.new({
			tableID = iter_7_1,
			start = var_0_1.ctx.battle.count,
			level = arg_7_0:getSkillLevelByID(arg_7_3),
			skillID = arg_7_3,
			fighter = arg_7_0,
			target = arg_7_2
		})

		var_7_1:setIsHit(true)
		var_7_1:setDirection(arg_7_0:getFighterModel():getFlipX())
		table.insert(var_7_0, var_7_1)
	end

	return var_7_0
end

function var_0_3.getTargets(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = var_0_3.super.getTargets(arg_8_0, arg_8_1, arg_8_2)

	if arg_8_1 == var_0_7 then
		arg_8_0.energyTargets_ = var_8_0
	end

	return var_8_0
end

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	if not arg_9_0.energyTargets_ or not next(arg_9_0.energyTargets_) then
		return {}
	end

	local var_9_0 = 1
	local var_9_1

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.energyTargets_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and var_9_0 >= iter_9_1:getHp() / iter_9_1:getHpLimit() then
			var_9_1 = iter_9_1
			var_9_0 = iter_9_1:getHp() / iter_9_1:getHpLimit()
		end
	end

	if not var_9_1 then
		return {}
	end

	local var_9_2 = {}
	local var_9_3 = var_0_5:scope(arg_9_1) / 2
	local var_9_4, var_9_5 = var_9_1:getPos()

	table.insert(var_9_2, var_9_1)

	for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
		local var_9_6, var_9_7 = iter_9_3:getPos()

		if not iter_9_3:isDeath() and not iter_9_3:isAffected() and var_9_3 >= math.abs(var_9_4 - var_9_6) and iter_9_3 ~= var_9_1 then
			table.insert(var_9_2, iter_9_3)
		end
	end

	return var_9_2
end

function var_0_3.getAPBaoJiHarm(arg_10_0)
	local var_10_0 = var_0_3.super.getAPBaoJiHarm(arg_10_0)

	if arg_10_0.extraSkillLevel > 0 then
		var_10_0 = var_10_0 * (arg_10_0.extraSkillLevel * var_0_6:attrValues(var_0_17) / var_0_2.PERCENT_BASE * ((arg_10_0:getHpLimit() - arg_10_0:getHp()) / arg_10_0:getHpLimit() / var_0_18) + 1)
	end

	return var_10_0
end

return var_0_3
