local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SimazhaoSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.model
local var_0_8 = 40012374
local var_0_9 = 10
local var_0_10 = 0.24
local var_0_11 = 0.04
local var_0_12 = 10002226
local var_0_13 = {
	2,
	3,
	4
}
local var_0_14 = 10
local var_0_15 = 22
local var_0_16 = 0.1

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")

	arg_1_0.energyBall_ = 0
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isCreatingGreenChildSkill = false
	arg_2_0.extraUnits_ = {}

	arg_2_0:updateStateNumber()
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count == 1 then
		arg_3_0:updateStateNumber(arg_3_0.energyBall_)
	end

	if arg_3_0:isHasBuffByID(var_0_8) then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("attack_info")) do
			if iter_3_1.fighter_:getTeamType() == arg_3_0:getTeamType() and iter_3_1.rootID_ ~= iter_3_1.fighter_:getPugongID() and iter_3_1.rootID_ ~= arg_3_0:getEnergySkillID() and iter_3_1.rootID_ ~= arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and iter_3_1.rootID_ ~= var_0_12 and arg_3_0.energyBall_ < var_0_9 and not arg_3_0.isCreatingGreenChildSkill then
				arg_3_0.energyBall_ = arg_3_0.energyBall_ + 1

				arg_3_0:updateStateNumber(arg_3_0.energyBall_)
			end
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

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0.energyBall_ = arg_4_0.energyBall_ + 1
		arg_4_0.extraTargets = var_0_4.C30(arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		local var_4_0 = var_0_6:attackIndex(arg_4_1.rootID_)
		local var_4_1 = var_0_7:duration(arg_4_0:getModelID(), var_0_13[2])
		local var_4_2 = var_0_6:pretime(arg_4_1.rootID_)
		local var_4_3 = var_4_1 * arg_4_0.energyBall_ / (arg_4_0.energyBall_ + 1)

		arg_4_0.extraUnits_ = {}

		for iter_4_0 = 1, arg_4_0.energyBall_ do
			table.insert(arg_4_0.extraUnits_, var_4_2 + var_4_3 * iter_4_0)
		end

		arg_4_0:updateStateNumber(arg_4_0.energyBall_)
	elseif arg_4_1.rootID_ == var_0_12 then
		arg_4_0.energyBall_ = math.max(#arg_4_0.extraUnits_ - 1, 0)

		arg_4_0:updateStateNumber(arg_4_0.energyBall_)
	end
end

function var_0_3.playAttack(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if not arg_5_1 then
		return
	end

	local var_5_0 = var_0_7:duration(arg_5_0:getModelID(), arg_5_1)

	arg_5_0:getFighterModel():attack(arg_5_1, nil, nil, function()
		if arg_5_2 then
			arg_5_2()
		end

		if arg_5_0.fighterModel:getScale() ~= 1 then
			arg_5_0.fighterModel:scale(1)
		end

		if arg_5_1 == var_0_13[1] and next(arg_5_0.extraUnits_) then
			arg_5_0:playAttack(var_0_13[2], nil, false)
		elseif arg_5_1 == var_0_13[2] and next(arg_5_0.extraUnits_) then
			arg_5_0:playAttack(var_0_13[2], nil, false)
		elseif arg_5_1 == var_0_13[2] and not next(arg_5_0.extraUnits_) then
			arg_5_0:playAttack(var_0_13[3], nil, false)
		elseif arg_5_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_5_1) then
			arg_5_0:resumeIdle()

			arg_5_0.isCreatingGreenChildSkill = false
		end
	end, arg_5_3)
end

function var_0_3.createSpecialSkill(arg_7_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_7_0 = var_0_12
	local var_7_1 = var_0_6:sound(var_7_0)

	var_0_1.ctx.battle.pushSoundQueue(var_7_1)

	arg_7_0.specialSkills_ = var_0_5.new({
		fighter = arg_7_0,
		skillID = var_7_0
	})

	arg_7_0:beginAttackEnd(arg_7_0.specialSkills_)
end

function var_0_3.isBreakImmortal(arg_8_0)
	return var_0_3.super.isBreakImmortal(arg_8_0) or next(arg_8_0.extraUnits_)
end

function var_0_3.canAttack(arg_9_0)
	if next(arg_9_0.extraUnits_) then
		arg_9_0.isCreatingGreenChildSkill = true

		return false
	end

	return var_0_3.super.canAttack(arg_9_0)
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	if arg_10_1.skillID == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_10_0.energyBall_ < var_0_9 then
		arg_10_0.energyBall_ = arg_10_0.energyBall_ + 1
	end
end

function var_0_3.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)
	local var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5 = var_0_3.super.updateUnitDataByFighter(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6, arg_11_7)

	if arg_11_1.skillID == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_11_3 > 0 then
		var_11_3 = var_11_3 + var_0_16 * arg_11_0.energyBall_ * arg_11_0:getAP()
	end

	return var_11_0, var_11_1, var_11_2, var_11_3, var_11_4, var_11_5
end

function var_0_3.getDamageRate(arg_12_0)
	local var_12_0 = arg_12_0:getHp()
	local var_12_1 = arg_12_0:getHpLimit()

	return (math.floor((var_12_1 - var_12_0) / var_12_1 * 100))
end

function var_0_3.getAP(arg_13_0)
	local var_13_0 = var_0_3.super.getAP(arg_13_0)

	if arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		var_13_0 = var_13_0 + var_0_10 * arg_13_0:getDamageRate() * arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return var_13_0
end

function var_0_3.getAPBaoJi(arg_14_0)
	local var_14_0 = var_0_3.super.getAP(arg_14_0)

	if arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		var_14_0 = var_14_0 + var_0_11 * arg_14_0:getDamageRate() * arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return var_14_0
end

return var_0_3
