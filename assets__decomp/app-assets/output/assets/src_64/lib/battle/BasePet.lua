local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("BasePet", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("MoveUnit")
local var_0_7 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_8 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_9 = var_0_1.ctx.battle.getRequire("FighterModel")
local var_0_10 = var_0_1.ctx.battle.getRequire("SpineEffect")
local var_0_11 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_12 = var_0_2.tables.skill
local var_0_13 = var_0_2.tables.hero
local var_0_14 = var_0_2.tables.model
local var_0_15 = var_0_2.tables.dbuff
local var_0_16 = var_0_2.tables.battleConfig
local var_0_17 = var_0_3.super
local var_0_18 = math.min
local var_0_19 = math.max
local var_0_20 = math.abs
local var_0_21 = math.floor
local var_0_22 = math.ceil
local var_0_23 = math.sqrt
local var_0_24 = 450

function var_0_3.init(arg_1_0)
	var_0_17.init(arg_1_0)

	arg_1_0.idleCount_ = 0
	arg_1_0.isCheckStar_ = false
	arg_1_0.isStarPurple_ = false
	arg_1_0.isStarBlue_ = false
	arg_1_0.isStarGreen_ = false
	arg_1_0.isStarEnergy_ = false
	arg_1_0.beginJudgeDie = true
end

function var_0_3.checkStarLevel(arg_2_0)
	local var_2_0 = arg_2_0.hero_:getStar()

	if var_2_0 >= 5 then
		arg_2_0.isStarPurple_ = true
	end

	if var_2_0 >= 4 then
		arg_2_0.isStarBlue_ = true
	end

	if var_2_0 >= 3 then
		arg_2_0.isStarGreen_ = true
	end

	if var_2_0 >= 2 then
		arg_2_0.isStarEnergy_ = true
	end
end

function var_0_3.updateBaseInfo(arg_3_0)
	var_0_17.updateBaseInfo(arg_3_0)

	arg_3_0.idleCount_ = arg_3_0.idleCount_ + 1

	arg_3_0:restIdle()
end

function var_0_3.checkMove(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.walk2Position_ then
		if arg_4_0:isWalked2Position() then
			arg_4_0.walk2Position_ = false
			arg_4_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk
		else
			arg_4_0.isWalking_ = 1

			if not arg_4_0:isWalking() then
				arg_4_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_4_0:isWalking() == 2 then
				local var_4_0 = arg_4_0:getFlipX() and -1 or 1

				arg_4_0:moveByX(arg_4_0:getCurrentSpeed() * var_4_0)
			end

			if arg_4_0:getCurrentAnimation() ~= "run" then
				arg_4_0:modelWalk()
			end
		end

		arg_4_0:writeWalkState()
	elseif var_0_1.ctx.battle.walk2NextBattle_ and arg_4_0:getTeamType() == var_0_2.TeamType.A then
		arg_4_0.isWalking_ = 1
		arg_4_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		arg_4_0:flipX(false)

		if not arg_4_0:isWalking() then
			arg_4_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_4_0:isWalking() == 2 then
			arg_4_0:moveByX(arg_4_0:getCurrentSpeed() * var_0_2.tables.battleConfig.speedAccelerate)
		end

		if arg_4_0:getCurrentAnimation() ~= "run" then
			arg_4_0:modelWalk()
		end
	elseif arg_4_0:isWalking() ~= 3 then
		arg_4_0.preWalk_ = false
		arg_4_0.isWalking_ = false
		arg_4_0.behindWalk_ = false

		if arg_4_0:getCurrentAnimation() == "run" then
			arg_4_0:getFighterModel():idle()
		end
	end
end

function var_0_3.isAffected(arg_5_0)
	return true
end

function var_0_3.getSummonType(arg_6_0)
	return var_0_2.summonMonsterType.Pet
end

function var_0_3.deathFeedback(arg_7_0, arg_7_1)
	if arg_7_1:getTeamType() == arg_7_0:getTeamType() then
		arg_7_0:judgeDie()
	end
end

function var_0_3.judgeDie(arg_8_0)
	local var_8_0 = false

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
		if iter_8_1 ~= arg_8_0 and (not iter_8_1:isDeath() or iter_8_1:canReborn()) then
			var_8_0 = true
		end
	end

	if not var_8_0 then
		arg_8_0:updateHp(0)
		arg_8_0:die()
	end
end

function var_0_3.updateEnergyBar(arg_9_0)
	if arg_9_0.mpBar_ then
		arg_9_0.bottomWnd:setPetMPProgress(arg_9_0.energy_ / var_0_2.ENERGY_DECIMAL_BASE, false)
	end
end

function var_0_3.singleLoop(arg_10_0)
	if not arg_10_0.isCheckStar_ then
		arg_10_0:checkStarLevel()

		arg_10_0.isCheckStar_ = true
	end

	var_0_17.singleLoop(arg_10_0)

	if not arg_10_0:isDeath() and var_0_1.ctx.battle.count % 30 < 1 and var_0_1.ctx.battle.count > 0 and not var_0_1.ctx.battle.teamAEnd and not var_0_1.ctx.battle.teamBEnd then
		arg_10_0:updateEnergyBy(arg_10_0:getEnergyPerSecond())
	end

	if arg_10_0.beginJudgeDie then
		arg_10_0.beginJudgeDie = nil

		arg_10_0:judgeDie()
	end
end

function var_0_3.getEnergyPerSecond(arg_11_0)
	return 40
end

function var_0_3.resumeIdle(arg_12_0)
	if not arg_12_0:isDeath() and arg_12_0:getFighterModel() then
		arg_12_0:getFighterModel():idle()

		arg_12_0.idleCount_ = 0
	end
end

function var_0_3.restIdle(arg_13_0)
	local function var_13_0()
		if not arg_13_0:getFighterModel():hasAnimation("rest") then
			return
		end

		arg_13_0:getFighterModel():rest(false, function()
			if arg_13_0:getFighterModel().currentAnimation_ == "rest" then
				arg_13_0:resumeIdle()
			end
		end)
	end

	local function var_13_1()
		arg_13_0:getFighterModel():win(false, function()
			if arg_13_0:getFighterModel().currentAnimation_ == "win" then
				arg_13_0:resumeIdle()
			end
		end)
	end

	if arg_13_0.idleCount_ < 90 or arg_13_0:getFighterModel().currentAnimation_ ~= "idle" then
		return
	end

	if var_0_1.ctx.battle.count % 2 > 0 then
		var_13_0()
	else
		var_13_1()
	end
end

function var_0_3.getCurrentAckSpeed(arg_18_0)
	return var_0_17.getCurrentAckSpeed(arg_18_0) + arg_18_0:getAttrByType(var_0_2.HeroType.AGILE) * var_0_2.AGILE_GONGSU_RATE / var_0_2.DECIMAL_BASE
end

function var_0_3.checkEnergySkill(arg_19_0)
	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return false
	end

	if arg_19_0:isDeath() then
		return false
	end

	if arg_19_0.energy_ < arg_19_0:energyDecimalBase() then
		return false
	end

	if arg_19_0:getDelaySkill() > var_0_1.ctx.battle.count then
		return false
	end

	if arg_19_0.walk2Position_ then
		return false
	end

	if arg_19_0:isBattleUnable() then
		return false
	end

	if arg_19_0:isApUnable() and (var_0_12:type(arg_19_0:getEnergySkillID()) == var_0_2.AttackType.AP or var_0_12:type(arg_19_0:getEnergySkillID()) == var_0_2.AttackType.CURE) then
		return false
	end

	if arg_19_0:isAdUnable() and var_0_12:type(arg_19_0:getEnergySkillID()) == var_0_2.AttackType.AD then
		return false
	end

	if arg_19_0.isEnergySkill_ and arg_19_0:isCreatingUnits() then
		return false
	end

	if arg_19_0:isAutoFighter() and arg_19_0:isInSkillRoll() then
		return false
	end

	if arg_19_0:isPugongOnly() then
		return false
	end

	if arg_19_0:isInvalidEnergySkill() then
		return false
	end

	if not arg_19_0:getNearestTarget() then
		return false
	end

	local var_19_0 = var_0_12:distance(arg_19_0:getEnergySkillID())

	if var_19_0 > 0 and var_19_0 < var_0_20(arg_19_0:getNearestTarget():getX() - arg_19_0:getX()) then
		return false
	end

	return true
end

return var_0_3
