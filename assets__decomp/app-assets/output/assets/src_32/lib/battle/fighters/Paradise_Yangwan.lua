local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangwan", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 10001142
local var_0_8 = 10001146
local var_0_9 = 10001145
local var_0_10 = 10001144
local var_0_11 = 240
local var_0_12 = 60
local var_0_13 = 3
local var_0_14 = 19
local var_0_15 = {
	0,
	10,
	400
}
local var_0_16 = {
	1,
	1.1,
	1.2
}
local var_0_17 = 0.6
local var_0_18 = 0.3
local var_0_19 = {
	10020053,
	10020054,
	10020055,
	10020056
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.init(arg_2_0)
	arg_2_0.super.init(arg_2_0)

	arg_2_0.energyTimeCount = 0
	arg_2_0.energyHarmCount = 0
	arg_2_0.energyJumpToCount = 0
	arg_2_0.firstMode = false
	arg_2_0.secondMode = false
end

function var_0_3.popSkillByType(arg_3_0, ...)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0.reportSkills_[1]

		if not var_3_0 then
			return 0
		end

		return var_3_0.rootID_
	end

	if arg_3_0.isEnergySkill_ then
		return arg_3_0:getOrbOfFrontSkill()
	end

	if arg_3_0:isApUnable() or arg_3_0:isAttackFriend() and not arg_3_0:isPossessed() then
		return arg_3_0:popAdSkill()
	elseif arg_3_0:isAdUnable() and not arg_3_0:isExcuteAdCircle() then
		return arg_3_0:popApSkill()
	end

	return arg_3_0:popColorSkill()
end

function var_0_3.beginAttack(arg_4_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not arg_4_0:canAttack() then
		return
	else
		arg_4_0.blueSecondSkillTargets = nil

		arg_4_0.super.beginAttack(arg_4_0)
	end

	if arg_4_0:popSkillByType() == arg_4_0:getEnergySkillID() then
		arg_4_0.energyJumpToCount = var_0_14
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0.energyTimeCount > 0 then
		arg_5_0.energyTimeCount = arg_5_0.energyTimeCount - 1

		if arg_5_0.energyTimeCount == 0 then
			arg_5_0:energyOver()
		end

		arg_5_0.energyHarmCount = arg_5_0.energyHarmCount + 1

		if arg_5_0.energyHarmCount >= var_0_12 then
			arg_5_0:energySpecialAttack()

			arg_5_0.energyHarmCount = 0
		end

		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_1:isDeath() then
				local var_5_0 = arg_5_0.energyPos_ < iter_5_1:getX() and -1 or 1

				if math.abs(arg_5_0.energyPos_ - iter_5_1:getX()) > 10 then
					iter_5_1:moveByX(var_5_0 * var_0_13)
				end
			end
		end
	end

	if arg_5_0.energyJumpToCount > 0 then
		arg_5_0.energyJumpToCount = arg_5_0.energyJumpToCount - 1

		if arg_5_0.energyJumpToCount == 0 and arg_5_0:getNearestTarget() then
			arg_5_0:x(arg_5_0:getNearestTarget():getX())
		end
	end

	if arg_5_0:getHp() / arg_5_0:getHpLimit() <= var_0_17 and not arg_5_0.firstMode then
		arg_5_0.firstMode = true

		for iter_5_2, iter_5_3 in ipairs(arg_5_0:getBuffs()) do
			if (iter_5_3:dBuffType() > 0 or iter_5_3:getType() == var_0_2.BuffType.CONTINUE_HARM) and iter_5_3:canRemove() then
				arg_5_0:removeBuffs(iter_5_3)
			end
		end
	end

	local function var_5_1(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
		local var_6_0 = {}

		for iter_6_0, iter_6_1 in ipairs(arg_6_0) do
			local var_6_1 = {
				tableID = iter_6_1,
				start = var_0_1.ctx.battle.count,
				level = arg_6_3,
				skillID = arg_6_2,
				fighter = arg_5_0,
				target = arg_6_1
			}
			local var_6_2 = var_0_6.new(var_6_1)

			table.insert(var_6_0, var_6_2)
		end

		return var_6_0
	end

	if arg_5_0:getHp() / arg_5_0:getHpLimit() <= var_0_18 and not arg_5_0.secondMode then
		arg_5_0.secondMode = true

		for iter_5_4, iter_5_5 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_5:isDeath() then
				for iter_5_6, iter_5_7 in pairs(var_0_19) do
					local var_5_2 = var_0_6.new({
						tableID = iter_5_7,
						start = var_0_1.ctx.battle.count,
						skillID = arg_5_0:getPugongID(),
						level = arg_5_0:getLevel(),
						fighter = arg_5_0,
						target = iter_5_5
					})

					iter_5_5:addBuffs({
						var_5_2
					})
				end
			end
		end
	end
end

function var_0_3.addBuffBySpecialHero(arg_7_0, arg_7_1)
	var_0_3.super.addBuffBySpecialHero(arg_7_0, arg_7_1)

	if arg_7_0.firstMode then
		for iter_7_0 = #arg_7_1, 1, -1 do
			local var_7_0 = arg_7_1[iter_7_0]

			if var_7_0.target == arg_7_0 and var_7_0.fighter:getTeamType() ~= arg_7_0:getTeamType() and var_7_0:canRemove() and (var_7_0:dBuffType() > 0 or var_7_0:getType() == var_0_2.BuffType.CONTINUE_HARM) then
				table.remove(arg_7_1, iter_7_0)
			end
		end
	end
end

function var_0_3.energySpecialAttack(arg_8_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() then
			local var_8_0 = arg_8_0:createAttackUnits({
				iter_8_1
			}, var_0_10)

			for iter_8_2, iter_8_3 in pairs(var_8_0) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
				table.insert(arg_8_0.records_.special_units, iter_8_3)
			end
		end
	end
end

function var_0_3.energyOver(arg_9_0)
	if arg_9_0.energyEffect_ then
		arg_9_0.energyEffect_:stop()

		arg_9_0.energyEffect_ = nil
	end

	arg_9_0.energyEffectOn_ = false
	arg_9_0.energyHarmCount = 0
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	arg_10_0.super.applySingleUnit(arg_10_0, arg_10_1)

	if arg_10_1.skillID == var_0_8 then
		arg_10_0:x(arg_10_1.target:getX() - 50 * (arg_10_0:getX() > arg_10_1.target:getX() and -1 or 1))
	end

	if arg_10_1.skillID == arg_10_0:getEnergySkillID() then
		if arg_10_0.energyEffectOn_ then
			arg_10_0:energyOver()
		end

		arg_10_0.energyEffectOn_ = true
		arg_10_0.energyTimeCount = var_0_11
		arg_10_0.energyHarmCount = 0
		arg_10_0.energyPos_ = arg_10_1.target:getX()

		local var_10_0, var_10_1 = var_0_4:areaResource(var_0_9)

		if var_10_0 and var_10_0 ~= "" and var_10_1 and var_10_1 ~= "" then
			arg_10_0.energyEffect_ = var_0_1.ctx.battle.getSpine(var_0_9, "area", arg_10_0:getScale())

			arg_10_0.energyEffect_:addTo(var_0_1.ctx.battle.unitBottomLayer)
		end

		if arg_10_0.energyEffect_ then
			arg_10_0.energyEffect_:pos(arg_10_0.energyPos_, 300)
			arg_10_0.energyEffect_:playRepeat()
		end
	end

	if arg_10_1.skillID == var_0_7 and not arg_10_0.blueJump then
		local var_10_2 = arg_10_1.target

		arg_10_0:x(var_10_2:getX() + 100 * (arg_10_0:getX() > var_10_2:getX() and -1 or 1))
		arg_10_0:flipX(arg_10_0:getX() > var_10_2:getX())

		arg_10_0.blueJump = true
	end
end

function var_0_3.getEnergyHarmRateByTarget(arg_11_0, arg_11_1)
	local var_11_0 = math.abs(arg_11_1:getX() - arg_11_0.energyPos_)
	local var_11_1 = var_0_16[3]

	for iter_11_0 = 3, 1, -1 do
		if var_11_0 < var_0_15[iter_11_0] then
			var_11_1 = var_0_16[iter_11_0 - 1]
		end
	end

	return var_11_1
end

function var_0_3.calculateUnitData(arg_12_0, arg_12_1)
	local var_12_0, var_12_1, var_12_2, var_12_3, var_12_4, var_12_5 = arg_12_0.super.calculateUnitData(arg_12_0, arg_12_1)

	if arg_12_1.skillID == var_0_10 then
		var_12_2 = var_12_2 * arg_12_0:getEnergyHarmRateByTarget(arg_12_1.target)
	end

	return var_12_0, var_12_1, var_12_2, var_12_3, var_12_4, var_12_5
end

function var_0_3.getTargets(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0.super.getTargets(arg_13_0, arg_13_1, arg_13_2)

	if arg_13_1 == var_0_7 then
		if arg_13_0.blueSecondSkillTargets then
			var_13_0 = arg_13_0.blueSecondSkillTargets
		else
			arg_13_0.blueJump = false
			arg_13_0.blueSecondSkillTargets = var_13_0
		end
	end

	return var_13_0
end

function var_0_3.selectTargetByTypeB11(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {}
	local var_14_1 = arg_14_0:getX()
	local var_14_2
	local var_14_3

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and (not var_14_2 or var_14_2 < math.abs(iter_14_1:getX() - var_14_1)) then
			var_14_3 = iter_14_1
			var_14_2 = math.abs(iter_14_1:getX() - var_14_1)
		end
	end

	if not var_14_3 then
		return {}
	else
		for iter_14_2, iter_14_3 in ipairs(arg_14_0.sideTeam_) do
			if (iter_14_3:getX() - arg_14_0:getX()) * (iter_14_3:getX() - var_14_3:getX()) < 0 then
				table.insert(var_14_0, iter_14_3)
			end
		end
	end

	return var_14_0
end

return var_0_3
