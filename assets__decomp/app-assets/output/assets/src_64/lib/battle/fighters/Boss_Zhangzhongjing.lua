local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangzhongjing", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0.8
local var_0_8 = 1
local var_0_9 = 40010753
local var_0_10 = 3
local var_0_11 = 40010755
local var_0_12 = 1.2
local var_0_13 = 10000706
local var_0_14 = 10000708
local var_0_15 = 40010752

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueBuffTargets_ = {}
	arg_1_0.purpleShanbiCount_ = 0
	arg_1_0.energyTarget_ = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.target:isDeath() and var_0_6:father(arg_2_1.skillID) == arg_2_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_2_1:recordData(false, false, 0, 0, 0, 0)
	end

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_2_0 = arg_2_1.target

		if var_2_0:isDeath() then
			return
		end

		local var_2_1 = arg_2_0:getX()
		local var_2_2 = arg_2_0:getY()
		local var_2_3 = var_2_0:getX()
		local var_2_4 = var_2_0:getY()
		local var_2_5 = var_2_3 - var_2_1 > 0 and 120 or -120
		local var_2_6 = var_0_1.ctx.battle.adjustX(var_2_3 + var_2_5, arg_2_0)

		if var_2_0:avoidHeroMoveBehind() then
			local var_2_7 = var_2_0:getX() - var_2_5

			var_2_6 = var_0_1.ctx.battle.adjustX(var_2_7, arg_2_0)
			var_2_5 = 0
		end

		arg_2_0:pos(var_2_6, var_2_4 + 0.1)
		arg_2_0:flipX(var_2_5 > 0)
	elseif arg_2_1.skillID == var_0_13 then
		if arg_2_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_8 = arg_2_0:getTargets(var_0_14)
			local var_2_9 = arg_2_0:createAttackUnits(var_2_8, var_0_14)

			for iter_2_0, iter_2_1 in ipairs(var_2_9) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end

		arg_2_1.target:removeBuffByID(var_0_15)
		arg_2_0:removeBuffByID(var_0_15)

		arg_2_0.energyTarget_ = {}
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if var_3_2 > 0 and var_0_6:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() then
		local var_3_6 = arg_3_0:getAttrByType(var_0_2.AttributeType.AGILE) - arg_3_1.target:getAttrByType(var_0_2.AttributeType.AGILE)
		local var_3_7 = 0

		if var_3_6 > 0 then
			var_3_7 = var_3_6 * var_0_12
		end

		var_3_2 = var_3_2 + var_3_7
	end

	if var_3_2 > 0 and arg_3_1.target:isHasBuffByID(var_0_9) then
		var_3_2 = var_3_2 + var_3_2 * var_0_7
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	if arg_4_1:getTableID() == var_0_9 and arg_4_1.target:getAttrByType(var_0_2.AttributeType.AGILE) < arg_4_0:getAttrByType(var_0_2.AttributeType.AGILE) then
		local var_4_0 = arg_4_1:getTime()

		arg_4_1:setExtraTime(var_4_0 * var_0_8)
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1.hero_:getHeroType() == var_0_2.HeroType.AGILE then
			table.insert(var_5_0, iter_5_1)
		end
	end

	return var_5_0
end

function var_0_3.checkKilling(arg_6_0, arg_6_1)
	var_0_3.super.checkKilling(arg_6_0, arg_6_1)

	if arg_6_0:isCreatingUnits() or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_6_1 = var_0_6:sound(var_6_0)

	var_0_1.ctx.battle.pushSoundQueue(var_6_1)

	local var_6_2 = var_0_6:attackIndex(var_6_0)

	arg_6_0:playAttack(var_6_2)

	arg_6_0.unitSkills_ = var_0_5.new({
		fighter = arg_6_0,
		skillID = var_6_0
	})

	arg_6_0:beginAttackEnd(arg_6_0.unitSkills_)
end

function var_0_3.playShanbi(arg_7_0, arg_7_1)
	var_0_3.super.playShanbi(arg_7_0, arg_7_1)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_7_0.purpleShanbiCount_ = arg_7_0.purpleShanbiCount_ + 1

		if arg_7_0.purpleShanbiCount_ >= var_0_10 then
			arg_7_0.purpleShanbiCount_ = 0

			local var_7_0 = arg_7_0:newBuff({
				var_0_11
			}, arg_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			arg_7_0:addBuffs(var_7_0)
		end
	end
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

function var_0_3.selectTargetByTypeD2(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0

	if next(arg_9_0.energyTarget_) then
		return arg_9_0.energyTarget_
	else
		local var_9_1 = 2

		for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_9_2 = iter_9_1:getHp() / iter_9_1:getHpLimit()

				if var_9_2 < var_9_1 then
					var_9_1 = var_9_2
					var_9_0 = iter_9_1
				end
			end
		end

		arg_9_0.energyTarget_ = {
			var_9_0
		}
	end

	return {
		var_9_0
	}
end

function var_0_3.checkMove(arg_10_0)
	if arg_10_0.isEnterSkill_ then
		if var_0_1.ctx.battle.count < arg_10_0.hero_:enterDuration() then
			arg_10_0.isWalking_ = 1

			if not arg_10_0:isWalking() then
				arg_10_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_10_0:isWalking() == 2 then
				local var_10_0 = arg_10_0:getFlipX() and -1 or 1

				arg_10_0:moveByX(arg_10_0.hero_:enterSpeed() * var_10_0)
			end

			if arg_10_0:getCurrentAnimation() ~= "run" then
				arg_10_0:modelWalk()
			end
		elseif not arg_10_0.playedEnterSkill_ then
			if arg_10_0:isWalking() ~= 3 then
				arg_10_0.preWalk_ = false
				arg_10_0.isWalking_ = false
				arg_10_0.behindWalk_ = false
				arg_10_0.playedEnterSkill_ = true
				arg_10_0.walk2Position_ = false

				if arg_10_0:getCurrentAnimation() == "run" then
					arg_10_0:getFighterModel():idle()
				end
			end
		elseif var_0_1.ctx.battle.count > arg_10_0.hero_:enterDelayDuration() then
			arg_10_0.isEnterSkill_ = nil
			arg_10_0.walk2Position_ = false
			arg_10_0.playedEnterSkill_ = false
		end

		return
	end

	var_0_3.super.checkMove(arg_10_0)
end

function var_0_3.setFormation(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	arg_11_0.isEnterSkill_ = arg_11_0:enterSkill() > 0 and arg_11_0:getSkillLevelByID(arg_11_0:enterSkill()) > 0

	if arg_11_0.isEnterSkill_ then
		arg_11_0.playedEnterSkill_ = false

		local var_11_0 = arg_11_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH

		arg_11_0:x(var_11_0)
		arg_11_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_11_3 - 90 * (arg_11_2 % 2))

		return arg_11_2 + 1
	end

	return var_0_3.super.setFormation(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
end

function var_0_3.enterSkill(arg_12_0)
	return arg_12_0.hero_:enterSkill()
end

return var_0_3
