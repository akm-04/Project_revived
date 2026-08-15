local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuan", var_0_1.ctx.battle.requireFighter("SingleBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 0.5
local var_0_8 = 150
local var_0_9 = 10000223
local var_0_10 = 10000224
local var_0_11 = 40010034
local var_0_12 = 240
local var_0_13 = 2
local var_0_14 = -50

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.coldTime = 0
	arg_1_0.buriedCount_ = nil
	arg_1_0.isBuried = false
end

function var_0_3.applyHurtFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5)
	if arg_2_0.isBuried then
		arg_2_2 = arg_2_2 * var_0_13
	end

	if arg_2_1 and arg_2_1.fighter and not arg_2_1.fighter:isDeath() then
		arg_2_1.fighter:updateEnergyBy(var_0_14)
	end

	return var_0_3.super.applyHurtFighter(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5)
end

function var_0_3.playAttack(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = var_0_9

	if arg_3_1 == var_0_5:attackIndex(var_3_0) then
		var_0_3.super.playAttack(arg_3_0, arg_3_1, function()
			arg_3_0:getFighterModel():playAnimation_("gongji05", true, nil, nil, nil, false)

			if arg_3_2 then
				arg_3_2()
			end
		end)
	else
		var_0_3.super.playAttack(arg_3_0, arg_3_1, arg_3_2)
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0.buriedCount_ and arg_5_0.isBuried then
		arg_5_0.buriedCount_ = arg_5_0.buriedCount_ - 1

		if arg_5_0.buriedCount_ <= 0 then
			arg_5_0.buriedCount_ = nil
			arg_5_0.isBuried = false

			arg_5_0:GetOut()
		end
	end
end

function var_0_3.canAttack(arg_6_0)
	if arg_6_0.isBuried then
		return false
	end

	return var_0_3.super.canAttack(arg_6_0)
end

function var_0_3.updateHp(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0.isBuried and arg_7_1 > arg_7_0:getHp() then
		return
	end

	var_0_3.super.updateHp(arg_7_0, arg_7_1, arg_7_2)
end

function var_0_3.Buried(arg_8_0)
	local var_8_0 = var_0_9
	local var_8_1 = var_0_5:sound(var_8_0)

	var_0_1.ctx.battle.pushSoundQueue(var_8_1)

	local var_8_2 = var_0_5:attackIndex(var_8_0)

	arg_8_0:playAttack(var_8_2)

	arg_8_0.unitSkills_ = var_0_4.new({
		fighter = arg_8_0,
		skillID = var_8_0
	})

	arg_8_0:beginAttackEnd(arg_8_0.unitSkills_)

	arg_8_0.isBuried = true
end

function var_0_3.GetOut(arg_9_0)
	arg_9_0:removeBuffByID(var_0_11)
	arg_9_0:getFighterModel():resume()

	if arg_9_0.coldTime < 1 then
		arg_9_0.coldTime = var_0_8
		arg_9_0.startSkillQueue_ = {}
		arg_9_0.skillQueue_ = arg_9_0.hero_:getCircle()
	end

	local var_9_0 = var_0_10
	local var_9_1 = var_0_5:sound(var_9_0)

	var_0_1.ctx.battle.pushSoundQueue(var_9_1)

	local var_9_2 = var_0_5:attackIndex(var_9_0)

	arg_9_0:playAttack(var_9_2)

	arg_9_0.unitSkills_ = var_0_4.new({
		fighter = arg_9_0,
		skillID = var_9_0
	})

	arg_9_0:beginAttackEnd(arg_9_0.unitSkills_)

	arg_9_0.isBuried = false
end

function var_0_3.applyBuffHarm(arg_10_0)
	local var_10_0 = 0
	local var_10_1 = 0
	local var_10_2 = 0
	local var_10_3

	for iter_10_0 = #arg_10_0.buffs_, 1, -1 do
		local var_10_4 = arg_10_0.buffs_[iter_10_0]

		if var_10_4:getType() == var_0_2.BuffType.CONTINUE_HARM then
			var_10_0 = var_10_0 + var_10_4:getHarm()
			var_10_3 = var_10_4.fighter

			if var_10_4:getHarm() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				var_10_3.harms = var_10_3.harms + var_10_4:getHarm()
			end

			var_10_2 = var_10_2 + var_10_4:getMana()
		elseif var_10_4:getType() == var_0_2.BuffType.GAIN then
			var_10_1 = var_10_1 + var_10_4:getHarm()
		end
	end

	if var_10_1 == 0 and var_10_0 == 0 and var_10_2 == 0 then
		return
	end

	local var_10_5 = math.max(0, arg_10_0:getHp() - var_10_0 + var_10_1)

	if not arg_10_0.isBuried then
		if var_10_1 - var_10_0 > 0 then
			var_10_5 = math.min(arg_10_0:getHp() - var_10_0 + var_10_1, arg_10_0:getHpLimit())
		end
	else
		var_10_5 = math.min(arg_10_0:getHp() + var_10_1, arg_10_0:getHpLimit())
	end

	if var_10_1 ~= 0 then
		arg_10_0.cureHp = arg_10_0.cureHp + var_10_1
	end

	local var_10_6 = -var_10_2

	arg_10_0:updateHp(var_10_5)
	arg_10_0:updateEnergyBy(var_10_6)
	arg_10_0:setOriHurt(var_10_0)

	return var_10_3
end

function var_0_3.checkMove(arg_11_0)
	if arg_11_0.isBuried then
		return
	end

	var_0_3.super.checkMove(arg_11_0)
end

function var_0_3.addBuffs(arg_12_0, arg_12_1)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
		if var_0_6:attr(iter_12_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_6:attr(iter_12_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_12_1:isFear() and not iter_12_1:isApUnable() and not iter_12_1:isAdUnable() and not iter_12_1:isExcuteAdCircle() and not iter_12_1:isAttackFriend() then
			table.insert(var_12_0, iter_12_1)
		end
	end

	var_0_3.super.addBuffs(arg_12_0, var_12_0)
end

function var_0_3.applyUnitBuffs(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6)
	var_0_3.super.applyUnitBuffs(arg_13_0, arg_13_1, arg_13_2)
end

function var_0_3.checkSkillBreak(arg_14_0, arg_14_1)
	return
end

function var_0_3.beginAttackEnd(arg_15_0, arg_15_1)
	var_0_3.super.beginAttackEnd(arg_15_0, arg_15_1)

	if arg_15_1.rootID_ == var_0_9 then
		arg_15_0.isBuried = true
		arg_15_0.buriedCount_ = var_0_12
	end
end

function var_0_3.isAdBreakImmortal(arg_16_0)
	return true
end

function var_0_3.applyBuffHarms(arg_17_0)
	if arg_17_0:isDeath() then
		return
	end

	local var_17_0 = var_0_2.tables.battleConfig.buffHarmBaseDuration

	if var_0_1.ctx.battle.count % var_17_0 > 0 then
		return
	end

	local var_17_1 = arg_17_0:applyBuffHarm()

	if arg_17_0:isDeath() then
		if var_17_1 and not var_17_1:isDeath() and arg_17_0:getSummonType() == var_0_2.summonMonsterType.None then
			var_17_1:updateEnergyBy(var_17_1:getKillingMp())
			var_17_1.fighterModel:playFloatText({
				var_0_2.BattleFloatType.KILLING
			}, var_17_1:getTeamType())
		end

		arg_17_0:die()
	end
end

function var_0_3.popSkillByType(arg_18_0)
	if arg_18_0:getOrbOfFrontSkill() == var_0_9 and (arg_18_0:getHp() > 0.98 * arg_18_0:getHpLimit() or arg_18_0.coldTime == 0) then
		arg_18_0:popFrontSkill()
	end

	return var_0_3.super.popSkillByType(arg_18_0)
end

return var_0_3
