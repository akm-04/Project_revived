local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hanxiandi", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 40010261
local var_0_8 = 40010262
local var_0_9 = 30010031
local var_0_10 = 10
local var_0_11 = 30010030
local var_0_12 = 0.15

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("move_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.count = false
	arg_2_0.energyCount_ = nil
	arg_2_0.sortedHero = {}
	arg_2_0.energyMoveHeros = {}
end

function var_0_3.setProgress(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	var_0_3.super.setProgress(arg_3_0, arg_3_1, arg_3_2, arg_3_3)

	local var_3_0 = arg_3_0.hpIndex_ - 1

	if var_3_0 > 0 then
		if var_3_0 % 2 == 0 then
			arg_3_0:addBuffs(arg_3_0:newBuff(var_0_8, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
			arg_3_0:removeBuffByID(var_0_7)
		else
			arg_3_0:addBuffs(arg_3_0:newBuff(var_0_7, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)))
			arg_3_0:removeBuffByID(var_0_8)
		end
	end
end

function var_0_3.isHurtBreak(arg_4_0, arg_4_1, arg_4_2)
	return false
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0.energyCount_ then
		arg_5_0.energyCount_ = arg_5_0.energyCount_ - 1

		if arg_5_0.energyCount_ == 0 then
			arg_5_0.energyCount_ = nil
		end

		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("move_info")) do
			table.insert(arg_5_0.energyMoveHeros, iter_5_1.fighter)
		end
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	if arg_6_1.skillID == arg_6_0:getEnergySkillID() then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.energyMoveHeros) do
			if iter_6_1 == arg_6_1.target then
				table.remove(arg_6_0.energyMoveHeros, iter_6_0)

				return
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)
end

function var_0_3.newBuff(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = var_0_6.new({
		tableID = arg_7_1,
		start = var_0_1.ctx.battle.count,
		level = arg_7_0:getSkillLevelByID(arg_7_3),
		skillID = arg_7_3,
		fighter = arg_7_0,
		target = arg_7_2
	})

	var_7_0:setIsHit(true)

	return {
		var_7_0
	}
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1
	local var_8_2 = arg_8_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_8_3 = arg_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_8_0, iter_8_1 in ipairs(var_8_3) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_8_4 = iter_8_1:getX() * var_8_2

			if not var_8_1 then
				var_8_0 = {
					iter_8_1
				}
				var_8_1 = var_8_4
			elseif var_8_1 <= var_8_4 then
				if var_8_4 == var_8_1 then
					table.insert(var_8_0, iter_8_1)
				else
					var_8_0 = {
						iter_8_1
					}
					var_8_1 = var_8_4
				end
			end
		end
	end

	local var_8_5

	if #var_8_0 > 1 then
		var_8_5 = var_8_0[math.random(1, #var_8_0)]
	else
		var_8_5 = var_8_0[1]
	end

	return {
		var_8_5
	}
end

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0:selectTargetByTypeD1(arg_9_1, arg_9_2)
	local var_9_1 = {}

	if not next(var_9_0) then
		return {}
	end

	local var_9_2 = var_0_4:scope(arg_9_1)
	local var_9_3 = arg_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_9_0, iter_9_1 in ipairs(var_9_3) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and math.abs(iter_9_1:getX() - var_9_0[1]:getX()) <= var_9_2 / 2 then
			table.insert(var_9_1, iter_9_1)
		end
	end

	return var_9_1
end

function var_0_3.beginAttackEnd(arg_10_0, arg_10_1)
	var_0_3.super.beginAttackEnd(arg_10_0, arg_10_1)

	if arg_10_1.rootID_ == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_10_0:getPositionNum()
	elseif arg_10_1.rootID_ == arg_10_0:getEnergySkillID() then
		arg_10_0.energyCount_ = var_0_4:pretime(arg_10_1.rootID_)
	end
end

function var_0_3.isStunBuff(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1:getTableID()

	if var_0_5:adUnable(var_11_0) and var_0_5:apUnable(var_11_0) and var_0_5:type(var_11_0) == var_0_2.BuffType.MOVE_SKILL_LIMIT and not arg_11_1:isFear() and not var_0_5:pause(var_11_0) and not var_0_5:sleep(var_11_0) then
		return true
	end

	return false
end

function var_0_3.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	if arg_12_1.skillID == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_12_0, iter_12_1 in ipairs(arg_12_0.sortedHero) do
			if not iter_12_1:isDeath() and iter_12_1 == arg_12_1.target then
				arg_12_4 = (1 + (iter_12_0 - 1) * var_0_12) * arg_12_4

				break
			end
		end
	end

	return arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7
end

function var_0_3.getPositionNum(arg_13_0)
	local var_13_0 = arg_13_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_13_1 = {}

	local function var_13_2(arg_14_0, arg_14_1)
		if arg_14_0:getX() * var_13_0 < arg_14_1:getX() * var_13_0 then
			return true
		else
			return false
		end
	end

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() then
			table.insert(var_13_1, iter_13_1)
		end
	end

	table.sort(var_13_1, var_13_2)

	arg_13_0.sortedHero = var_13_1
end

return var_0_3
