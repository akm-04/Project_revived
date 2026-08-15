local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("GongsunzanBird", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = 10000965
local var_0_7 = 0.002
local var_0_8 = 0
local var_0_9 = 10000963
local var_0_10 = 40011054

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.forceTarget_ = nil
	arg_1_0.specialAttack_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	arg_2_0.fighterModel:hideHeaderView()
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)

	if arg_3_0.specialAttack_ and var_3_0 == arg_3_0:getPugongID() then
		var_3_0 = var_0_6
	end

	return var_3_0
end

function var_0_3.getForceTarget(arg_4_0)
	return arg_4_0.forceTarget_
end

function var_0_3.setForceTarget(arg_5_0, arg_5_1)
	arg_5_0.forceTarget_ = arg_5_1
end

function var_0_3.isAffected(arg_6_0)
	return true
end

function var_0_3.setSpecialAttack(arg_7_0, arg_7_1)
	arg_7_0.specialAttack_ = arg_7_1
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_4 > 0 and arg_8_0.forceTarget_ and arg_8_0.forceTarget_ == arg_8_1.target then
		arg_8_4 = arg_8_4 * (1 + (var_0_8 + var_0_7 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)))
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.useSkill(arg_9_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_9_0 = var_0_9
	local var_9_1 = var_0_4:sound(var_9_0)

	var_0_1.ctx.battle.pushSoundQueue(var_9_1)

	local var_9_2 = var_0_4:attackIndex(var_9_0)

	arg_9_0:playAttack(var_9_2)

	arg_9_0.unitSkills_ = var_0_5.new({
		fighter = arg_9_0,
		skillID = var_9_0
	})

	arg_9_0:beginAttackEnd(arg_9_0.unitSkills_)
end

function var_0_3.selectTargetByTypeD2(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1:isHasBuffByID(var_0_10) then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

function var_0_3.canAttack(arg_11_0)
	if not arg_11_0.forceTarget_ or arg_11_0.forceTarget_:isDeath() or arg_11_0.forceTarget_:isAffected() then
		return false
	end

	return var_0_3.super.canAttack(arg_11_0)
end

function var_0_3.checkMove(arg_12_0)
	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport and not var_0_1.ctx.battle.walk2NextBattle_ and arg_12_0.summoner and (not arg_12_0.forceTarget_ or arg_12_0.forceTarget_:isDeath()) and math.abs(arg_12_0:getX() - arg_12_0.summoner:getX()) > 50 then
		arg_12_0.isWalking_ = 1
		arg_12_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		local var_12_0 = arg_12_0.summoner:getX() > arg_12_0:getX() and 1 or -1

		arg_12_0:flipX(var_12_0 < 0)

		if not arg_12_0:isWalking() then
			arg_12_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_12_0:isWalking() == 2 then
			arg_12_0:moveByX(arg_12_0:getCurrentSpeed() * var_12_0)
		end

		if not arg_12_0:isWalkAnimation() then
			arg_12_0:modelWalk()
		end

		arg_12_0:writeWalkState()

		return
	end

	return var_0_3.super.checkMove(arg_12_0)
end

function var_0_3.isTargetBeyondReach(arg_13_0)
	if not arg_13_0.forceTarget_ or arg_13_0.forceTarget_:isDeath() then
		return false
	end

	return var_0_3.super.isTargetBeyondReach(arg_13_0)
end

return var_0_3
