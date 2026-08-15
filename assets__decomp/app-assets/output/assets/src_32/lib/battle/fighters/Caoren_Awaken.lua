local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caoren", var_0_1.ctx.battle.requireFighter("Caoren"))
local var_0_4 = {
	20010278
}
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 900
local var_0_7 = 0.3
local var_0_8 = 0.04
local var_0_9 = 300
local var_0_10 = {
	40010155
}
local var_0_11 = 550
local var_0_12 = 0.03
local var_0_13 = 0.2
local var_0_14 = 40011716

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeSkillCD = 0
	arg_1_0.awakeBuffTime = 0
	arg_1_0.awakeHalo_ = nil
	arg_1_0.twiceAwakeLossHp = 0
end

function var_0_3.updateHp(arg_2_0, arg_2_1, arg_2_2)
	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_2_0 = arg_2_0:getHp() - arg_2_1

		if var_2_0 > 0 then
			arg_2_0.twiceAwakeLossHp = arg_2_0.twiceAwakeLossHp + var_2_0

			if arg_2_0.twiceAwakeLossHp > arg_2_0:getHpLimit() * var_0_13 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_1 = arg_2_0:createAttackUnits({
					arg_2_0
				}, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				for iter_2_0, iter_2_1 in ipairs(var_2_1) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
					table.insert(arg_2_0.records_.special_units, iter_2_1)
				end

				arg_2_0.twiceAwakeLossHp = 0
			end
		end
	end

	var_0_3.super.updateHp(arg_2_0, arg_2_1, arg_2_2)
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getBuffs()) do
			if iter_3_1:isFear() or iter_3_1:isApUnable() or iter_3_1:isAdUnable() or iter_3_1:isExcuteAdCircle() or iter_3_1:isAttackFriend() or iter_3_1:isPugongOnly() then
				arg_3_0:removeBuffs(iter_3_1)
			end
		end
	end
end

function var_0_3.isBreakImmortal(arg_4_0)
	if arg_4_0:isHasBuffByID(var_0_14) then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_4_0)
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	var_0_3.super.toDoPerFrames(arg_5_0)

	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0.awakeSkillCD <= 0 and arg_5_0:getHp() < arg_5_0:getHpLimit() * var_0_7 then
		local var_5_0 = arg_5_0:newBuff(var_0_4, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_5_0:addBuffs(var_5_0)

		arg_5_0.awakeSkillCD = var_0_6
		arg_5_0.awakeBuffTime = var_0_9

		arg_5_0:addHarmHalo()
	elseif arg_5_0.awakeSkillCD > 0 then
		arg_5_0.awakeSkillCD = arg_5_0.awakeSkillCD - 1
	end

	if arg_5_0.awakeBuffTime > 0 then
		if arg_5_0.awakeBuffTime % 30 == 0 then
			local var_5_1 = arg_5_0:getHpLimit() * var_0_8 * arg_5_0:getDCureRate()

			arg_5_0:updateHp(arg_5_0:getHp() + var_5_1)
		end

		arg_5_0.awakeBuffTime = arg_5_0.awakeBuffTime - 1

		local var_5_2 = unpack(var_0_4)

		if not arg_5_0:isHasBuffByID(var_5_2) then
			arg_5_0.awakeBuffTime = 0
		end

		if arg_5_0.awakeBuffTime == 0 then
			arg_5_0:removeBuffHalo(arg_5_0.awakeHalo_)

			arg_5_0.awakeHalo_ = nil
		end
	end
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_5.new({
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

function var_0_3.deathFeedback(arg_7_0, arg_7_1)
	if arg_7_0:isDeath() then
		return
	end

	if arg_7_1:getTeamType() ~= arg_7_0:getTeamType() and arg_7_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_7_0.awakeSkillCD = 0
	end
end

function var_0_3.die(arg_8_0)
	var_0_3.super.die(arg_8_0)

	if arg_8_0.awakeHalo_ then
		arg_8_0:removeBuffHalo(arg_8_0.awakeHalo_)

		arg_8_0.awakeHalo_ = nil
	end
end

function var_0_3.addHarmHalo(arg_9_0)
	if arg_9_0.awakeHalo_ then
		return
	end

	local var_9_0 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
	local var_9_1 = {
		fighter = arg_9_0,
		effect_area = function(arg_10_0)
			local var_10_0 = var_0_11

			if math.abs(arg_10_0:getX() - arg_9_0:getX()) <= var_10_0 / 2 then
				return true
			else
				return false
			end
		end,
		manualHarm = function()
			return (arg_9_0:getHpLimit() - arg_9_0:getHp()) * var_0_12
		end,
		target_type = var_0_2.HaloEffect.sideTeam,
		buffs = var_0_10,
		level = arg_9_0:getSkillLevelByID(var_9_0),
		skillID = var_9_0
	}

	arg_9_0.awakeHalo_ = var_9_1

	arg_9_0:addBuffHalo(var_9_1)
end

return var_0_3
