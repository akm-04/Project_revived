local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yujin", var_0_1.ctx.battle.requireFighter("Yujin"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000125
local var_0_6 = 10001240
local var_0_7 = {
	40010455
}
local var_0_8 = 0.5
local var_0_9 = {
	40010453,
	40010454
}
local var_0_10 = {
	40010480,
	40010481
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.records_.pugong_stun = {}
	arg_1_0.isAwakeBuffAdded_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() or arg_2_0.isAwakeBuffAdded_ or arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) <= 0 then
		return
	end

	if arg_2_0:getHp() <= arg_2_0:getHpLimit() * 0.3 then
		local var_2_0 = arg_2_0:newBuff(var_0_10, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_2_0:addBuffs(var_2_0)

		arg_2_0.isAwakeBuffAdded_ = true
	end
end

function var_0_3.attackModeJudge(arg_3_0)
	var_0_3.super.attackModeJudge(arg_3_0)

	if arg_3_0.isSaber_ and not arg_3_0:isHasBuffByID(unpack(var_0_9)) then
		arg_3_0:addBuffs(arg_3_0:newBuff(var_0_9, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
	elseif not arg_3_0.isSaber_ and arg_3_0:isHasBuffByID(unpack(var_0_9)) then
		for iter_3_0, iter_3_1 in ipairs(var_0_9) do
			arg_3_0:removeBuffByID(iter_3_1)
		end
	end
end

function var_0_3.getCurrentSpeed(arg_4_0)
	local var_4_0 = 0

	if arg_4_0.isSaber_ then
		var_4_0 = 2
	end

	return var_0_3.super.getCurrentSpeed(arg_4_0) + var_4_0
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == var_0_5 or arg_5_1.skillID == var_0_6 then
		local var_5_0 = var_0_2.split(arg_5_1.target.fighterIndex, "|")
		local var_5_1 = tostring(var_5_0[2])
		local var_5_2 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_5_0.pugongStun_[var_5_1] and arg_5_0.pugongStun_[var_5_1][tostring(var_0_1.ctx.battle.count)] then
				var_5_2 = true
			end
		elseif var_0_2.weightedChoise({
			var_0_8,
			1 - var_0_8
		}) == 1 then
			if not arg_5_0.records_.pugong_stun[var_5_1] then
				arg_5_0.records_.pugong_stun[var_5_1] = {}
			end

			arg_5_0.records_.pugong_stun[var_5_1][tostring(var_0_1.ctx.battle.count)] = true
			var_5_2 = true
		end

		if var_5_2 then
			arg_5_1.target:addBuffs(arg_5_0:newBuff(var_0_7, arg_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)))
			arg_5_1.target:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_5_1)
		end
	end
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.pugongStun_ = arg_6_1.pugong_stun
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.pugong_stun = arg_7_0.records_.pugong_stun

	return var_7_0
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

return var_0_3
