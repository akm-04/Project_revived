local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuan", var_0_1.ctx.battle.requireFighter("ProphesyBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 0.5
local var_0_8 = 150
local var_0_9 = 10000223
local var_0_10 = 10000224
local var_0_11 = 40010034

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.coldTime = 0
	arg_1_0.isBuried = false
end

function var_0_3.playAttack(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = var_0_9

	if arg_2_1 == var_0_5:attackIndex(var_2_0) then
		var_0_3.super.playAttack(arg_2_0, arg_2_1, function()
			arg_2_0:getFighterModel():playAnimation_("gongji05", true, nil, nil, nil, false)

			if arg_2_2 then
				arg_2_2()
			end
		end)
	else
		var_0_3.super.playAttack(arg_2_0, arg_2_1, arg_2_2)
	end
end

function var_0_3.canAttack(arg_4_0)
	if arg_4_0.isBuried then
		return false
	end

	return var_0_3.super.canAttack(arg_4_0)
end

function var_0_3.updateHp(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_0.isBuried and arg_5_1 < arg_5_0:getHp() then
		return
	end

	var_0_3.super.updateHp(arg_5_0, arg_5_1, arg_5_2)

	if not arg_5_0.isBuried and arg_5_1 > 0 and arg_5_1 <= arg_5_0:getHpLimit() * var_0_7 and arg_5_0.coldTime == 0 then
		arg_5_0:Buried()
	end

	if arg_5_0.isBuried and arg_5_1 >= arg_5_0:getHpLimit() then
		arg_5_0:GetOut()
	end
end

function var_0_3.Buried(arg_6_0)
	local var_6_0 = var_0_9
	local var_6_1 = var_0_5:sound(var_6_0)

	var_0_1.ctx.battle.pushSoundQueue(var_6_1)

	local var_6_2 = var_0_5:attackIndex(var_6_0)

	arg_6_0:playAttack(var_6_2)

	arg_6_0.unitSkills_ = var_0_4.new({
		fighter = arg_6_0,
		skillID = var_6_0
	})

	arg_6_0:beginAttackEnd(arg_6_0.unitSkills_)

	arg_6_0.isBuried = true
end

function var_0_3.GetOut(arg_7_0)
	arg_7_0:removeBuffByID(var_0_11)
	arg_7_0:getFighterModel():resume()

	if arg_7_0.coldTime < 1 then
		arg_7_0.coldTime = var_0_8
		arg_7_0.startSkillQueue_ = {}
		arg_7_0.skillQueue_ = arg_7_0.hero_:getCircle()
	end

	local var_7_0 = var_0_10
	local var_7_1 = var_0_5:sound(var_7_0)

	var_0_1.ctx.battle.pushSoundQueue(var_7_1)

	local var_7_2 = var_0_5:attackIndex(var_7_0)

	arg_7_0:playAttack(var_7_2)

	arg_7_0.unitSkills_ = var_0_4.new({
		fighter = arg_7_0,
		skillID = var_7_0
	})

	arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)

	arg_7_0.isBuried = false
end

function var_0_3.applyBuffHarm(arg_8_0)
	local var_8_0 = 0
	local var_8_1 = 0
	local var_8_2 = 0
	local var_8_3

	for iter_8_0 = #arg_8_0.buffs_, 1, -1 do
		local var_8_4 = arg_8_0.buffs_[iter_8_0]

		if var_8_4:getType() == var_0_2.BuffType.CONTINUE_HARM then
			var_8_0 = var_8_0 + var_8_4:getHarm()
			var_8_3 = var_8_4.fighter

			if var_8_4:getHarm() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				var_8_3.harms = var_8_3.harms + var_8_4:getHarm()
			end

			var_8_2 = var_8_2 + var_8_4:getMana()
		elseif var_8_4:getType() == var_0_2.BuffType.GAIN then
			var_8_1 = var_8_1 + var_8_4:getHarm()
		end
	end

	if var_8_1 == 0 and var_8_0 == 0 and var_8_2 == 0 then
		return
	end

	local var_8_5 = math.max(0, arg_8_0:getHp() - var_8_0 + var_8_1)

	if not arg_8_0.isBuried then
		if var_8_1 - var_8_0 > 0 then
			var_8_5 = math.min(arg_8_0:getHp() - var_8_0 + var_8_1, arg_8_0:getHpLimit())
		end
	else
		var_8_5 = math.min(arg_8_0:getHp() + var_8_1, arg_8_0:getHpLimit())
	end

	if var_8_1 ~= 0 then
		arg_8_0.cureHp = arg_8_0.cureHp + var_8_1
	end

	local var_8_6 = -var_8_2

	arg_8_0:updateHp(var_8_5)
	arg_8_0:updateEnergyBy(var_8_6)
	arg_8_0:setOriHurt(var_8_0)

	return var_8_3
end

function var_0_3.checkMove(arg_9_0)
	if arg_9_0.isBuried then
		return
	end

	var_0_3.super.checkMove(arg_9_0)
end

function var_0_3.addBuffs(arg_10_0, arg_10_1)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		if var_0_6:attr(iter_10_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_6:attr(iter_10_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_10_1:isFear() and not iter_10_1:isApUnable() and not iter_10_1:isAdUnable() and not iter_10_1:isExcuteAdCircle() and not iter_10_1:isAttackFriend() then
			table.insert(var_10_0, iter_10_1)
		end
	end

	var_0_3.super.addBuffs(arg_10_0, var_10_0)
end

function var_0_3.applyUnitBuffs(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5, arg_11_6)
	var_0_3.super.applyUnitBuffs(arg_11_0, arg_11_1, arg_11_2)
end

function var_0_3.checkSkillBreak(arg_12_0, arg_12_1)
	return
end

function var_0_3.beginAttackEnd(arg_13_0, arg_13_1)
	var_0_3.super.beginAttackEnd(arg_13_0, arg_13_1)

	if arg_13_1.rootID_ == var_0_9 then
		arg_13_0.isBuried = true
	end
end

function var_0_3.isAdBreakImmortal(arg_14_0)
	return true
end

function var_0_3.applyBuffHarms(arg_15_0)
	if arg_15_0:isDeath() then
		return
	end

	local var_15_0 = var_0_2.tables.battleConfig.buffHarmBaseDuration

	if var_0_1.ctx.battle.count % var_15_0 > 0 then
		return
	end

	local var_15_1 = arg_15_0:applyBuffHarm()

	if arg_15_0:isDeath() then
		if var_15_1 and not var_15_1:isDeath() and arg_15_0:getSummonType() == var_0_2.summonMonsterType.None then
			var_15_1:updateEnergyBy(var_15_1:getKillingMp())
			var_15_1.fighterModel:playFloatText({
				var_0_2.BattleFloatType.KILLING
			}, var_15_1:getTeamType())
		end

		arg_15_0:die()
	end
end

function var_0_3.popSkillByType(arg_16_0)
	if arg_16_0:getOrbOfFrontSkill() == var_0_9 and (arg_16_0:getHp() > 0.98 * arg_16_0:getHpLimit() or arg_16_0.coldTime == 0) then
		arg_16_0:popFrontSkill()
	end

	return var_0_3.super.popSkillByType(arg_16_0)
end

return var_0_3
