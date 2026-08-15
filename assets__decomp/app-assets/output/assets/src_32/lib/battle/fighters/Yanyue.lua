local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yanyue", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = 10000397
local var_0_8 = 10000398
local var_0_9 = 10000399
local var_0_10 = 10000400
local var_0_11 = 10000403
local var_0_12 = 0
local var_0_13 = 25
local var_0_14 = 40010793
local var_0_15 = 40010794

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueSkillTarget_ = nil
	arg_1_0.blueSkillNum_ = 0
	arg_1_0.awakeSkillNum_ = 0
	arg_1_0.isAddSkinBuff_ = false
	arg_1_0.jumpToX_ = {}
	arg_1_0.jumpToY_ = {}
	arg_1_0.jumpToCount_ = {}
	arg_1_0.isJumpFlip_ = {}
end

function var_0_3.beginAttack(arg_2_0)
	arg_2_0:jumpTo()
	var_0_3.super.beginAttack(arg_2_0)
end

function var_0_3.skillIsBreak(arg_3_0, arg_3_1)
	var_0_3.super.skillIsBreak(arg_3_0, arg_3_1)

	arg_3_0.jumpToX_ = {}
	arg_3_0.jumpToY_ = {}
	arg_3_0.jumpToCount_ = {}
	arg_3_0.isJumpFlip_ = {}
end

function var_0_3.popSkillByType(arg_4_0)
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

function var_0_3.initJump(arg_5_0)
	arg_5_0.jumpToX_ = {}
	arg_5_0.jumpToY_ = {}
	arg_5_0.jumpToCount_ = {}
	arg_5_0.isJumpFlip_ = {}
end

function var_0_3.jumpTo(arg_6_0)
	if not arg_6_0:canAttack() or not arg_6_0:getNearestTarget() then
		return
	end

	local var_6_0 = arg_6_0:popSkillByType()

	arg_6_0:initJump()

	if var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_6_1 = arg_6_0:selectTargetByTypeD1(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		if next(var_6_1) then
			local var_6_2 = var_6_1[1]
			local var_6_3 = var_6_2:getFlipX() == true and 1 or -1

			if var_6_2:avoidHeroMoveBehind() then
				table.insert(arg_6_0.isJumpFlip_, not var_6_2:getFlipX())
				table.insert(arg_6_0.jumpToX_, var_6_2:getX() - var_6_3 * 50)
			else
				table.insert(arg_6_0.isJumpFlip_, var_6_2:getFlipX())
				table.insert(arg_6_0.jumpToX_, var_6_2:getX() + var_6_3 * 50)
			end

			table.insert(arg_6_0.jumpToCount_, var_0_5:pretime(var_6_0) + 3)
			table.insert(arg_6_0.jumpToY_, var_6_2:getY())
		end
	elseif var_6_0 == arg_6_0:getEnergySkillID() then
		table.insert(arg_6_0.jumpToCount_, var_0_5:pretime(var_0_7))
		table.insert(arg_6_0.jumpToCount_, var_0_5:pretime(var_0_9) - var_0_5:pretime(var_0_7))
		table.insert(arg_6_0.jumpToY_, arg_6_0:getY())
		table.insert(arg_6_0.jumpToY_, arg_6_0:getY())

		local var_6_4 = arg_6_0:getNearestTarget()

		if arg_6_0:getX() >= var_6_4:getX() then
			table.insert(arg_6_0.jumpToX_, var_6_4:getX() - 100)
			table.insert(arg_6_0.isJumpFlip_, false)
		else
			table.insert(arg_6_0.jumpToX_, var_6_4:getX() + 100)
			table.insert(arg_6_0.isJumpFlip_, true)
		end

		local var_6_5 = unpack(var_0_4.B4(arg_6_0, var_6_0))

		if var_6_5 and var_6_5:avoidHeroMoveBehind() then
			table.insert(arg_6_0.jumpToX_, arg_6_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH)

			if arg_6_0:getTeamType() == var_0_2.TeamType.A then
				table.insert(arg_6_0.isJumpFlip_, false)
			else
				table.insert(arg_6_0.isJumpFlip_, true)
			end
		else
			if arg_6_0:getTeamType() == var_0_2.TeamType.A then
				if var_0_1.ctx.battle.isUnlimitBattle then
					table.insert(arg_6_0.jumpToX_, var_0_2.UNLIMIT_STAGE_WIDTH)
				else
					table.insert(arg_6_0.jumpToX_, var_0_2.STAGE_WIDTH)
				end
			else
				table.insert(arg_6_0.jumpToX_, 0)
			end

			table.insert(arg_6_0.isJumpFlip_, arg_6_0:getTeamType() == var_0_2.TeamType.A and true or false)
		end
	end
end

function var_0_3.toDoPerFrames(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if next(arg_7_0.jumpToCount_) then
		arg_7_0.jumpToCount_[1] = arg_7_0.jumpToCount_[1] - 1

		if arg_7_0.jumpToCount_[1] <= 0 then
			table.remove(arg_7_0.jumpToCount_, 1)
			arg_7_0:jumpToPosition()
		end

		if not arg_7_0.unitSkills_ and arg_7_0.jumpToCount_[1] and arg_7_0.jumpToCount_[1] > 3 then
			table.remove(arg_7_0.jumpToCount_, 1)
		end
	end

	if arg_7_0.isSkinSkillOn_ and not arg_7_0.isAddSkinBuff_ then
		arg_7_0.isAddSkinBuff_ = true

		local var_7_0 = arg_7_0:newBuff({
			var_0_14,
			var_0_15
		}, arg_7_0, arg_7_0:getEnergySkillID())

		arg_7_0:addBuffs(var_7_0)
	end
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_6.new({
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

function var_0_3.jumpToPosition(arg_9_0)
	arg_9_0:x(arg_9_0.jumpToX_[1])
	arg_9_0:y(arg_9_0.jumpToY_[1])
	arg_9_0:flipX(arg_9_0.isJumpFlip_[1])
	table.remove(arg_9_0.jumpToX_, 1)
	table.remove(arg_9_0.jumpToY_, 1)
	table.remove(arg_9_0.isJumpFlip_, 1)
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0
	local var_10_1 = 0
	local var_10_2 = var_0_5:distance(arg_10_1)

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_10_3 = math.abs(arg_10_0:getX() - iter_10_1:getX())

			if var_10_3 <= var_10_2 and var_10_1 < var_10_3 then
				var_10_0 = iter_10_1
				var_10_1 = var_10_3
			end
		end
	end

	return {
		var_10_0
	}
end

function var_0_3.calculateUnitData(arg_11_0, arg_11_1)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.calculateUnitData(arg_11_0, arg_11_1)
	local var_11_6 = arg_11_1.target

	if not var_11_0 and var_11_2 > 0 and arg_11_1.skillID ~= var_0_11 and var_11_6:getTeamType() ~= arg_11_0:getTeamType() and arg_11_0:getFlipX() == var_11_6:getFlipX() and arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		var_11_2 = var_11_2 + (var_0_12 + var_0_13 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))
		arg_11_0.blueSkillNum_ = arg_11_0.blueSkillNum_ + 1

		if arg_11_0.blueSkillNum_ >= 2 then
			arg_11_0.blueSkillNum_ = arg_11_0.blueSkillNum_ - 2
			arg_11_0.awakeSkillNum_ = arg_11_0.awakeSkillNum_ + 1

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_11_7 = arg_11_0:createAttackUnits({
					var_11_6
				}, var_0_11)

				for iter_11_0, iter_11_1 in ipairs(var_11_7) do
					table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
					table.insert(arg_11_0.records_.special_units, iter_11_1)
				end
			end
		end
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

return var_0_3
