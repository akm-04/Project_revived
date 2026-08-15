local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Simazhao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.model
local var_0_7 = 30010042
local var_0_8 = 20010252
local var_0_9 = 20010253
local var_0_10 = 10000361
local var_0_11 = 10000362
local var_0_12 = 10001850
local var_0_13 = 10000363
local var_0_14 = 10001851
local var_0_15 = 0
local var_0_16 = 1.5
local var_0_17 = {
	4,
	5,
	6
}
local var_0_18 = 80010092
local var_0_19 = 1.8
local var_0_20 = 10001849

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyBall_ = 0
	arg_2_0.targetSkillCount_ = {}
	arg_2_0.extraUnits_ = {}
	arg_2_0.greenTarget_ = nil

	arg_2_0:updateStateNumber()
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("attack_info")) do
		if iter_3_1.rootID_ ~= iter_3_1.fighter_:getPugongID() and iter_3_1.rootID_ ~= var_0_11 and iter_3_1.rootID_ ~= var_0_12 then
			if iter_3_1.fighter_:getTeamType() == arg_3_0:getTeamType() then
				arg_3_0.targetSkillCount_[iter_3_1.fighter_] = (arg_3_0.targetSkillCount_[iter_3_1.fighter_] or 0) + 1
			end

			if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_18 then
				if arg_3_0.energyBall_ < 40 then
					arg_3_0.energyBall_ = math.min(arg_3_0.energyBall_ + 2, 40)

					arg_3_0:updateStateNumber(arg_3_0.energyBall_)
				end
			elseif arg_3_0.energyBall_ < 20 then
				arg_3_0.energyBall_ = math.min(arg_3_0.energyBall_ + 1, 20)

				arg_3_0:updateStateNumber(arg_3_0.energyBall_)
			end
		end

		if iter_3_1.fighter_:getTeamType() == arg_3_0:getTeamType() and iter_3_1.rootID_ ~= iter_3_1.fighter_:getPugongID() and iter_3_1.rootID_ ~= var_0_11 and iter_3_1.rootID_ ~= var_0_12 then
			arg_3_0:updatePurpleSkill()
		end
	end

	if arg_3_0:acttionInBlack() then
		for iter_3_2, iter_3_3 in ipairs(arg_3_0.extraUnits_) do
			arg_3_0.extraUnits_[iter_3_2] = arg_3_0.extraUnits_[iter_3_2] - 1
		end

		if arg_3_0.extraUnits_[1] and arg_3_0.extraUnits_[1] < 1 and not arg_3_0.specialSkills_ then
			arg_3_0:createSpecialSkill()
			table.remove(arg_3_0.extraUnits_, 1)
		end
	end
end

function var_0_3.removeBuffAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_7 then
		arg_4_1.target:removeBuffByID(var_0_9)
		arg_4_1.target:removeBuffByID(var_0_8)
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_1.target:getTeamType() ~= arg_5_0:getTeamType() then
		if arg_5_1.target.hero_:getHeroType() == var_0_2.HeroType.WISE or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			return
		end

		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_1.target
		}, var_0_10)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.updatePurpleSkill(arg_6_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType or arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return
	end

	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			table.insert(var_6_0, iter_6_1)
		end
	end

	local var_6_1 = {}

	for iter_6_2 = 1, 3 do
		if #var_6_0 < 1 then
			break
		end

		local var_6_2 = math.random(#var_6_0)

		table.insert(var_6_1, var_6_0[var_6_2])
		table.remove(var_6_0, var_6_2)
	end

	if not next(var_6_1) then
		return
	end

	local var_6_3 = arg_6_0:createAttackUnits(var_6_1, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	for iter_6_3, iter_6_4 in ipairs(var_6_3) do
		table.insert(arg_6_0.moveAttackUnits_, iter_6_4)
		table.insert(arg_6_0.records_.special_units, iter_6_4)
	end
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	if not arg_7_0.greenTarget_ then
		arg_7_0.greenTarget_ = arg_7_0

		return {
			arg_7_0
		}
	end

	arg_7_0.greenTarget_ = arg_7_0

	local var_7_0
	local var_7_1

	for iter_7_0, iter_7_1 in pairs(arg_7_0.targetSkillCount_) do
		if not iter_7_0:isDeath() and not iter_7_0:isAffected() and (not var_7_0 or var_7_1 < iter_7_1) then
			var_7_0 = iter_7_0
			var_7_1 = iter_7_1
		end
	end

	if not var_7_0 then
		return {
			arg_7_0
		}
	end

	return {
		var_7_0
	}
end

function var_0_3.beginAttackEnd(arg_8_0, arg_8_1)
	var_0_3.super.beginAttackEnd(arg_8_0, arg_8_1)

	if arg_8_1.rootID_ == arg_8_0:getEnergySkillID() or arg_8_1.rootID_ == var_0_20 then
		local var_8_0 = var_0_5:attackIndex(arg_8_1.rootID_)
		local var_8_1 = var_0_6:duration(arg_8_0:getModelID(), var_0_17[2])
		local var_8_2 = var_0_5:pretime(arg_8_1.rootID_)
		local var_8_3 = var_8_1 * math.ceil(arg_8_0.energyBall_ / 2) / (arg_8_0.energyBall_ + 1)

		arg_8_0.extraUnits_ = {}

		for iter_8_0 = 1, arg_8_0.energyBall_ do
			table.insert(arg_8_0.extraUnits_, var_8_2 + var_8_3 * iter_8_0)
		end

		arg_8_0.energyBall_ = 0

		arg_8_0:updateStateNumber(arg_8_0.energyBall_)
	end
end

function var_0_3.getAPBaoJiHarm(arg_9_0)
	if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_18 then
		return var_0_3.super.getAPBaoJiHarm(arg_9_0) * var_0_19
	else
		return var_0_3.super.getAPBaoJiHarm(arg_9_0)
	end
end

function var_0_3.playAttack(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if not arg_10_1 then
		return
	end

	arg_10_0.skillRoll_ = var_0_6:duration(arg_10_0:getModelID(), arg_10_1) + 5

	arg_10_0:getFighterModel():attack(arg_10_1, nil, nil, function()
		if arg_10_2 then
			arg_10_2()
		end

		if arg_10_0.fighterModel:getScale() ~= 1 then
			arg_10_0.fighterModel:scale(1)
		end

		if arg_10_1 == var_0_17[1] and next(arg_10_0.extraUnits_) then
			arg_10_0:playAttack(var_0_17[2], nil, false)
		elseif arg_10_1 == var_0_17[2] and next(arg_10_0.extraUnits_) then
			arg_10_0:playAttack(var_0_17[2], nil, false)
		elseif arg_10_1 == var_0_17[2] and not next(arg_10_0.extraUnits_) then
			arg_10_0:playAttack(var_0_17[3], nil, false)
		elseif arg_10_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_10_1) then
			arg_10_0:resumeIdle()
		end
	end, arg_10_3)
end

function var_0_3.createSpecialSkill(arg_12_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_12_0 = var_0_11

	if arg_12_0.isSkinSkillOn_ and arg_12_0.skinSkillID_ == var_0_18 then
		var_12_0 = var_0_12
	end

	local var_12_1 = var_0_5:sound(var_12_0)

	var_0_1.ctx.battle.pushSoundQueue(var_12_1)

	arg_12_0.specialSkills_ = var_0_4.new({
		fighter = arg_12_0,
		skillID = var_12_0
	})

	arg_12_0:beginAttackEnd(arg_12_0.specialSkills_)
end

function var_0_3.isBreakImmortal(arg_13_0)
	return var_0_3.super.isBreakImmortal(arg_13_0) or next(arg_13_0.extraUnits_)
end

function var_0_3.canAttack(arg_14_0)
	if next(arg_14_0.extraUnits_) then
		return false
	end

	return var_0_3.super.canAttack(arg_14_0)
end

function var_0_3.getAP(arg_15_0)
	local var_15_0 = var_0_15 + arg_15_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_16

	return var_0_3.super.getAP(arg_15_0) + var_15_0
end

function var_0_3.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
	local var_16_0, var_16_1, var_16_2, var_16_3, var_16_4, var_16_5 = var_0_3.super.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)

	if arg_16_1.skillID == var_0_13 then
		if arg_16_0.isSkinSkillOn_ and arg_16_0.skinSkillID_ == var_0_18 then
			var_16_2 = var_16_2 * math.max(0.2, arg_16_0.energyBall_ / 40)
		else
			var_16_2 = var_16_2 * math.max(0.2, arg_16_0.energyBall_ / 20)
		end
	end

	return var_16_0, var_16_1, var_16_2, var_16_3, var_16_4, var_16_5
end

function var_0_3.die(arg_17_0)
	arg_17_0:specialAttack()
	var_0_3.super.die(arg_17_0)
end

function var_0_3.specialAttack(arg_18_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_18_0 = false

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.selfTeam_) do
		if not iter_18_1:isDeath() or iter_18_1:canReborn() then
			var_18_0 = true
		end
	end

	if not var_18_0 then
		return
	end

	local var_18_1 = var_0_13

	if arg_18_0.isSkinSkillOn_ and arg_18_0.skinSkillID_ == var_0_18 then
		var_18_1 = var_0_14
	end

	local var_18_2 = {}

	for iter_18_2, iter_18_3 in ipairs(arg_18_0.sideTeam_) do
		if not iter_18_3:isDeath() and not iter_18_3:isAffected() then
			table.insert(var_18_2, iter_18_3)
		end
	end

	if next(var_18_2) then
		local var_18_3 = arg_18_0:createAttackUnits(var_18_2, var_18_1)

		for iter_18_4, iter_18_5 in ipairs(var_18_3) do
			iter_18_5.arrived = false

			table.insert(arg_18_0.moveAttackUnits_, iter_18_5)
			table.insert(arg_18_0.records_.special_units, iter_18_5)
		end
	end
end

return var_0_3
