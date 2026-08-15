local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 10001638
local var_0_6 = 10001643
local var_0_7 = 4
local var_0_8 = 0.3
local var_0_9 = 40011731
local var_0_10 = 10001640
local var_0_11 = 10001642
local var_0_12 = 10001641
local var_0_13 = 0.015
local var_0_14 = 0.3
local var_0_15 = 40011728
local var_0_16 = 0.5

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")

	arg_1_0.x0 = 0
	arg_1_0.y0 = 0
	arg_1_0.greenTarget = nil
	arg_1_0.blueTarget = nil
	arg_1_0.blueTargets = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	if arg_2_1.skillID == var_0_5 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_1.target:getBuffs()) do
			if iter_2_1:dBuffType() > 0 or iter_2_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				arg_2_1.target:removeBuffs(iter_2_1)
			end
		end
	end

	if arg_2_1.skillID == var_0_6 and arg_2_0.isStarEnergy_ then
		arg_2_1:setExtraHarm(var_0_7 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_2_0.greenTarget = arg_2_1.target
		arg_2_0.x0 = arg_2_0:getX()
		arg_2_0.y0 = arg_2_0:getY()

		arg_2_0:x(arg_2_0.greenTarget:getX())
		arg_2_0:y(arg_2_0.greenTarget:getY())
		arg_2_0:createSkillByID(var_0_10, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_0_4:attackIndex(var_0_10))
	end

	if arg_2_1.skillID == var_0_10 then
		arg_2_0.greenTarget = nil
		arg_2_0.blueTarget = arg_2_0

		arg_2_0:createSkillByID(var_0_12, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_4:attackIndex(var_0_12))
	end

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_2_0.blueTarget = arg_2_1.target
		arg_2_0.x0 = arg_2_0:getX()
		arg_2_0.y0 = arg_2_0:getY()

		arg_2_0:createSkillByID(var_0_11, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_4:attackIndex(var_0_11))
	end

	if arg_2_1.skillID == var_0_11 then
		arg_2_0.blueTarget = nil
		arg_2_0.blueTarget = arg_2_0:selectTargetByTypeD3(var_0_12, arg_2_1)[1]

		arg_2_0:x(arg_2_1.target:getX())
		arg_2_0:y(arg_2_1.target:getY())

		if arg_2_0.blueTarget then
			arg_2_0:createSkillByID(var_0_12, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_4:attackIndex(var_0_12))
		else
			arg_2_0.blueTargets = {}
			arg_2_0.blueTarget = arg_2_0

			arg_2_0:createSkillByID(var_0_12, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_4:attackIndex(var_0_12))
		end
	end

	if arg_2_1.skillID == var_0_12 then
		arg_2_0.blueTarget = arg_2_1.target

		if arg_2_0.blueTarget ~= arg_2_0 then
			arg_2_0:createSkillByID(var_0_11, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_4:attackIndex(var_0_11))
			arg_2_0:x(arg_2_0.blueTarget:getX())
			arg_2_0:y(arg_2_0.blueTarget:getY())
		else
			arg_2_0.blueTarget = nil

			arg_2_0:x(arg_2_0.x0)
			arg_2_0:y(arg_2_0.y0)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.skillID == var_0_11 then
		arg_3_7 = arg_3_7 - arg_3_1.target:getAP() * var_0_13

		if arg_3_0.isStarBlue_ then
			arg_3_7 = arg_3_7 + arg_3_7 * var_0_14
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.toDoPerFrames(arg_4_0)
	for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
		if iter_4_1.target:isHasBuffByID(var_0_9) and iter_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and (iter_4_1:isFear() or iter_4_1:isApUnable() or iter_4_1:isAdUnable() or iter_4_1:isExcuteAdCircle() or iter_4_1:isAttackFriend() or iter_4_1:isPugongOnly()) then
			iter_4_1.leftCount_ = iter_4_1.leftCount_ + iter_4_1.leftCount_ * var_0_8
		end
	end
end

function var_0_3.selectTargetByTypeD2(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_0.greenTarget then
		return {
			arg_5_0.greenTarget
		}
	end

	local var_5_0 = {}
	local var_5_1 = {}
	local var_5_2 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.targetTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			if iter_5_1.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI then
				table.insert(var_5_0, iter_5_1)
			elseif iter_5_1.hero_:getDistanceType() == var_0_2.DistanceType.ZHONGPAI then
				table.insert(var_5_1, iter_5_1)
			elseif iter_5_1.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI then
				table.insert(var_5_2, iter_5_1)
			end
		end
	end

	local var_5_3 = math.random(tonumber(os.time()))

	math.randomseed(var_5_3)

	if next(var_5_1) then
		return {
			var_5_1[math.random(#var_5_1)]
		}
	elseif next(var_5_2) then
		return {
			var_5_2[math.random(#var_5_2)]
		}
	elseif next(var_5_0) then
		return {
			var_5_0[math.random(#var_5_0)]
		}
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD3(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_0.blueTarget then
		return {
			arg_6_0.blueTarget
		}
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and not arg_6_0.blueTargets[iter_6_1] then
			arg_6_0.blueTargets[iter_6_1] = true

			return {
				iter_6_1
			}
		end
	end

	return {}
end

function var_0_3.setGlobalBuffs(arg_7_0)
	var_0_3.super.setGlobalBuffs(arg_7_0)

	if arg_7_0.isStarPurple_ then
		for iter_7_0, iter_7_1 in ipairs(var_0_1.ctx.battle.globalBuffs) do
			if iter_7_1.fighter == arg_7_0 and iter_7_1:getTableID() == var_0_15 then
				iter_7_1.manualRevise = var_0_16 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

				var_0_1.ctx.battle.clearAttrCache(arg_7_0.selfTeam_, iter_7_1:getAttrType())
			end
		end
	end
end

return var_0_3
