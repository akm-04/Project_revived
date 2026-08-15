local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangwan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 10001142
local var_0_8 = 10001146
local var_0_9 = 10001144
local var_0_10 = 240
local var_0_11 = 24
local var_0_12 = 3
local var_0_13 = 19
local var_0_14 = {
	0,
	10,
	400
}
local var_0_15 = {
	1,
	1.2,
	1.5
}
local var_0_16 = 80010192
local var_0_17 = 40011683
local var_0_18 = 40011684
local var_0_19 = 40011681
local var_0_20 = 40011682
local var_0_21 = 20070004
local var_0_22 = 40011950
local var_0_23 = 40011951
local var_0_24 = 8
local var_0_25 = 8
local var_0_26 = 80020192
local var_0_27 = {
	40012538,
	40012539,
	40012540,
	40012541
}
local var_0_28 = 4

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.init(arg_2_0)
	arg_2_0.super.init(arg_2_0)

	arg_2_0.energyTimeCount = 0
	arg_2_0.energyHarmCount = 0
	arg_2_0.energyJumpToCount = 0
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
	arg_2_0.extraHujiaManualRevise = 0
	arg_2_0.extraMingzhongManualRevise = 0
	arg_2_0.skinSkillCount = 0
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillID_ == var_0_26 then
		arg_3_0.energyEffectSkill = 10002340
	else
		arg_3_0.energyEffectSkill = 10001145
	end
end

function var_0_3.popSkillByType(arg_4_0, ...)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0.reportSkills_[1]

		if not var_4_0 then
			return 0
		end

		return var_4_0.rootID_
	end

	if arg_4_0.isEnergySkill_ then
		return arg_4_0:getOrbOfFrontSkill()
	end

	if arg_4_0:isApUnable() or arg_4_0:isAttackFriend() and not arg_4_0:isPossessed() then
		return arg_4_0:popAdSkill()
	elseif arg_4_0:isAdUnable() and not arg_4_0:isExcuteAdCircle() then
		return arg_4_0:popApSkill()
	end

	return arg_4_0:popColorSkill()
end

function var_0_3.beginAttack(arg_5_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not arg_5_0:canAttack() then
		return
	else
		arg_5_0.blueSecondSkillTargets = nil

		arg_5_0.super.beginAttack(arg_5_0)
	end

	if arg_5_0:popSkillByType() == arg_5_0:getEnergySkillID() then
		arg_5_0.energyJumpToCount = var_0_13
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if not arg_6_0.extraSkillJudge then
		arg_6_0.extraSkillJudge = true
		arg_6_0.extraSkillLevel = arg_6_0.hero_:skillBook()[tostring(var_0_21)] or 0
		arg_6_0.extraHujiaManualRevise = arg_6_0.extraSkillLevel * var_0_24
		arg_6_0.extraMingzhongManualRevise = arg_6_0.extraSkillLevel * var_0_25
	end

	if arg_6_0.energyTimeCount > 0 then
		arg_6_0.energyTimeCount = arg_6_0.energyTimeCount - 1

		if arg_6_0.energyTimeCount == 0 then
			arg_6_0:energyOver()
		end

		arg_6_0.energyHarmCount = arg_6_0.energyHarmCount + 1

		if arg_6_0.energyHarmCount >= var_0_11 then
			arg_6_0:energySpecialAttack()

			arg_6_0.energyHarmCount = 0
		end

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() then
				local var_6_0 = arg_6_0.energyPos_ < iter_6_1:getX() and -1 or 1

				if math.abs(arg_6_0.energyPos_ - iter_6_1:getX()) > 10 then
					iter_6_1:moveByX(var_6_0 * var_0_12)
				end
			end
		end
	end

	if arg_6_0.energyJumpToCount > 0 then
		arg_6_0.energyJumpToCount = arg_6_0.energyJumpToCount - 1

		if arg_6_0.energyJumpToCount == 0 and arg_6_0:getNearestTarget() then
			arg_6_0:x(arg_6_0:getNearestTarget():getX())
		end
	end
end

function var_0_3.energySpecialAttack(arg_7_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
			local var_7_0 = arg_7_0:createAttackUnits({
				iter_7_1
			}, var_0_9)

			for iter_7_2, iter_7_3 in pairs(var_7_0) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end
end

function var_0_3.energyOver(arg_8_0)
	if arg_8_0.energyEffect_ then
		arg_8_0.energyEffect_:stop()

		arg_8_0.energyEffect_ = nil
	end

	arg_8_0.energyEffectOn_ = false
	arg_8_0.energyHarmCount = 0
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)

	if arg_9_1.rootID_ == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_9_0.extraSkillLevel > 0 then
		local var_9_0 = var_0_6.new({
			tableID = var_0_22,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0.extraSkillLevel,
			fighter = arg_9_0,
			target = arg_9_0,
			manualRevise = arg_9_0.extraHujiaManualRevise
		})

		arg_9_0:addBuffs({
			var_9_0
		})

		local var_9_1 = var_0_6.new({
			tableID = var_0_23,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0.extraSkillLevel,
			fighter = arg_9_0,
			target = arg_9_0,
			manualRevise = arg_9_0.extraMingzhongManualRevise
		})

		arg_9_0:addBuffs({
			var_9_1
		})
	end

	if arg_9_0.skinSkillID_ == var_0_26 and not arg_9_0:isHasBuffByID(var_0_27[1]) then
		arg_9_0.skinSkillCount = arg_9_0.skinSkillCount + 1

		if arg_9_0.skinSkillCount == var_0_28 then
			local var_9_2 = arg_9_0:createNewBuffs(var_0_27, arg_9_0, var_0_26)

			arg_9_0:addBuffs(var_9_2)

			arg_9_0.skinSkillCount = 0
		end
	end
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
		arg_10_0.energyTimeCount = var_0_10
		arg_10_0.energyHarmCount = 0
		arg_10_0.energyPos_ = arg_10_1.target:getX()

		local var_10_0, var_10_1 = var_0_4:areaResource(arg_10_0.energyEffectSkill)

		if var_10_0 and var_10_0 ~= "" and var_10_1 and var_10_1 ~= "" then
			arg_10_0.energyEffect_ = var_0_1.ctx.battle.getSpine(arg_10_0.energyEffectSkill, "area", arg_10_0:getScale())

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

	if arg_10_1.basicHarm > 0 and arg_10_0.skinSkillID_ == var_0_16 then
		arg_10_0:addBuffs({
			var_0_6.new({
				tableID = var_0_17,
				start = var_0_1.ctx.battle.count,
				level = arg_10_0:getLevel(),
				skillID = var_0_16,
				fighter = arg_10_0,
				target = arg_10_0
			}),
			var_0_6.new({
				tableID = var_0_18,
				start = var_0_1.ctx.battle.count,
				level = arg_10_0:getLevel(),
				skillID = var_0_16,
				fighter = arg_10_0,
				target = arg_10_0
			})
		})
		arg_10_1.target:addBuffs({
			var_0_6.new({
				tableID = var_0_19,
				start = var_0_1.ctx.battle.count,
				level = arg_10_0:getLevel(),
				skillID = var_0_16,
				fighter = arg_10_0,
				target = arg_10_1.target
			}),
			var_0_6.new({
				tableID = var_0_20,
				start = var_0_1.ctx.battle.count,
				level = arg_10_0:getLevel(),
				skillID = var_0_16,
				fighter = arg_10_0,
				target = arg_10_1.target
			})
		})
	end
end

function var_0_3.getEnergyHarmRateByTarget(arg_11_0, arg_11_1)
	local var_11_0 = math.abs(arg_11_1:getX() - arg_11_0.energyPos_)
	local var_11_1 = var_0_15[3]

	for iter_11_0 = 3, 1, -1 do
		if var_11_0 < var_0_14[iter_11_0] then
			var_11_1 = var_0_15[iter_11_0 - 1]
		end
	end

	return var_11_1
end

function var_0_3.calculateUnitData(arg_12_0, arg_12_1)
	local var_12_0, var_12_1, var_12_2, var_12_3, var_12_4, var_12_5 = arg_12_0.super.calculateUnitData(arg_12_0, arg_12_1)

	if arg_12_1.skillID == var_0_9 then
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

function var_0_3.die(arg_15_0)
	var_0_3.super.die(arg_15_0)
	arg_15_0:energyOver()
end

return var_0_3
