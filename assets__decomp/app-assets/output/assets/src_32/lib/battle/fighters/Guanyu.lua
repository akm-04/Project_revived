local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guanyu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 40010008
local var_0_9 = 80010032
local var_0_10 = 0.1
local var_0_11 = 1
local var_0_12 = 0.3
local var_0_13 = 10001300
local var_0_14 = math.min
local var_0_15 = math.max
local var_0_16 = math.abs
local var_0_17 = math.floor
local var_0_18 = math.ceil
local var_0_19 = math.sqrt

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinAngerCount = 0
	arg_1_0.awakeCollectHp_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_9 and arg_2_0.skinAngerCount >= var_0_11 and not arg_2_0:isInSkillRoll() and not arg_2_0:isDeath() and arg_2_0:acttionInBlack() and arg_2_0:isCreatingUnits() ~= true and not arg_2_0:isBattleUnable() then
		-- block empty
	end
end

function var_0_3.popSkillByType(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return arg_3_0.reportSkills_[1].rootID_
	end

	if arg_3_0.isEnergySkill_ then
		return arg_3_0:getOrbOfFrontSkill()
	end

	if arg_3_0.skinAngerCount >= var_0_11 then
		arg_3_0.skinAngerCount = 0

		return arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	end

	if arg_3_0:isApUnable() or arg_3_0:isAttackFriend() and not arg_3_0:isPossessed() then
		return arg_3_0:popAdSkill()
	elseif arg_3_0:isAdUnable() and not arg_3_0:isExcuteAdCircle() then
		return arg_3_0:popApSkill()
	end

	return arg_3_0:popColorSkill()
end

function var_0_3.updateHp(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_0:getHp()

	var_0_3.super.updateHp(arg_4_0, arg_4_1, arg_4_2)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_4_0:isDeath() and arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_9 then
		local var_4_1 = arg_4_0:getHp()

		if var_4_1 < var_4_0 then
			arg_4_0.awakeCollectHp_ = arg_4_0.awakeCollectHp_ + var_4_0 - var_4_1

			if arg_4_0.awakeCollectHp_ >= arg_4_0:getHpLimit() * var_0_12 then
				arg_4_0.skinAngerCount = arg_4_0.skinAngerCount + var_0_17(arg_4_0.awakeCollectHp_ / (arg_4_0:getHpLimit() * var_0_12))
				arg_4_0.awakeCollectHp_ = arg_4_0.awakeCollectHp_ % (arg_4_0:getHpLimit() * var_0_12)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD2(arg_5_0, arg_5_1)
	local var_5_0 = {}

	arg_5_0.greenSkill_ = arg_5_0.greenSkill_ or {}
	arg_5_0.greenSkill_[tostring(arg_5_1)] = arg_5_0.greenSkill_[tostring(arg_5_1)] or {}

	local var_5_1
	local var_5_2
	local var_5_3
	local var_5_4 = arg_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_5_5 = arg_5_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_5_6 = arg_5_0:isAttackFriend() and var_5_4 or var_5_5
	local var_5_7 = var_0_5:scope(arg_5_1)
	local var_5_8 = arg_5_0:getX()

	for iter_5_0, iter_5_1 in ipairs(var_5_6) do
		local var_5_9 = iter_5_1:getX()

		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and var_5_7 >= math.abs(var_5_9 - var_5_8) and not var_0_0.table.keyof(arg_5_0.greenSkill_[tostring(arg_5_1)], iter_5_1) then
			table.insert(var_5_0, iter_5_1)
			table.insert(arg_5_0.greenSkill_[tostring(arg_5_1)], iter_5_1)
		end
	end

	return var_5_0
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if var_0_5:father(arg_6_1.skillID) == arg_6_0:getEnergySkillID() and arg_6_1.target:getTeamType() ~= arg_6_0:getTeamType() and arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_9 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_0 = arg_6_0:createAttackUnits({
				arg_6_0
			}, var_0_9)

			for iter_6_0, iter_6_1 in ipairs(var_6_0) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	elseif arg_6_1.skillID == var_0_13 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0:acttionInBlack() and arg_6_0:isCreatingUnits() ~= true and not arg_6_0:isBattleUnable() then
		local var_6_1 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
		local var_6_2 = var_0_5:sound(var_6_1)

		var_0_1.ctx.battle.pushSoundQueue(var_6_2)

		local var_6_3 = var_0_5:attackIndex(var_6_1)

		arg_6_0:playAttack(var_6_3)

		arg_6_0.unitSkills_ = var_0_4.new({
			fighter = arg_6_0,
			skillID = var_6_1
		})

		arg_6_0:beginAttackEnd(arg_6_0.unitSkills_)
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_5 > 0 and arg_7_1.skillID == var_0_9 then
		arg_7_5 = arg_7_0:getHpLimit() * var_0_10
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.beginAttack(arg_8_0)
	if arg_8_0:isDeath() then
		return
	end

	if not arg_8_0:canAttack() then
		return
	end

	if arg_8_0:getLeftInterval() > 0 then
		return
	end

	arg_8_0.greenSkill_ = nil

	var_0_3.super.beginAttack(arg_8_0)
end

function var_0_3.applyBuffMoves(arg_9_0)
	if var_0_1.ctx.battle.isEnergySkilling and arg_9_0.acttionInBlack_ ~= true and arg_9_0:isHasBuffByID(var_0_8) then
		return
	end

	var_0_3.super.applyBuffMoves(arg_9_0)
end

return var_0_3
