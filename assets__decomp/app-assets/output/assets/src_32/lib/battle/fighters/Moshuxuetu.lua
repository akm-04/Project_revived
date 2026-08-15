local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Moshuxuetu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.3
local var_0_7 = 150
local var_0_8 = 10000177
local var_0_9 = 10000178
local var_0_10 = 40010030

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.coldTime = 0
	arg_1_0.isBuried = false
	arg_1_0.BuriedActionCount = true
end

function var_0_3.canAttack(arg_2_0)
	if arg_2_0.isBuried then
		return false
	end

	return var_0_3.super.canAttack(arg_2_0)
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)

	if arg_3_0:acttionInBlack() then
		if arg_3_0.coldTime > 0 then
			arg_3_0.coldTime = arg_3_0.coldTime - 1
		end

		if arg_3_0:isHasBuffByID(var_0_10) and arg_3_0.BuriedActionCount then
			arg_3_0:getFighterModel():playAnimation_("gongji03", true)

			arg_3_0.BuriedActionCount = false
		end
	end
end

function var_0_3.checkMove(arg_4_0)
	if arg_4_0.isBuried then
		return
	end

	var_0_3.super.checkMove(arg_4_0)
end

function var_0_3.getTargets(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_1 == var_0_8 or arg_5_1 == var_0_9 then
		return {
			arg_5_0
		}
	else
		return var_0_3.super.getTargets(arg_5_0, arg_5_1, arg_5_2)
	end
end

function var_0_3.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	if not arg_6_0:isPause() and var_0_1.ctx.battle.isEnergySkilling then
		arg_6_0:getFighterModel():resume()
	end

	arg_6_2 = arg_6_2 > 0 and math.max(arg_6_2, 1) or 0

	if arg_6_0:isHurtBreak(arg_6_2, arg_6_1) and not arg_6_0.isBuried and not arg_6_0:isAdBreakImmortal() then
		arg_6_0:setBreakInterval()

		if not arg_6_0:isPause() then
			arg_6_0:attacked()
		end

		if arg_6_0:isCreatingUnits() then
			arg_6_0.fighterModel:playFloatText({
				var_0_2.BattleFloatType.BREAK
			}, arg_6_0:getTeamType())
			arg_6_0:skillIsBreak(arg_6_1)
		end
	end

	local var_6_0 = arg_6_2 - arg_6_0:getHp()
	local var_6_1 = math.max(0, arg_6_0:getHp() - arg_6_2)
	local var_6_2 = var_0_0.clone(arg_6_2)

	if var_6_0 > 0 then
		arg_6_2 = arg_6_0:getLastDHarmBuff(var_6_0, arg_6_1.attackType)
		var_6_1 = arg_6_2 > 0 and 0 or 1
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_6_0:updateHp(arg_6_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][1])
		arg_6_0:updateEnergyTo(arg_6_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][2])
	else
		arg_6_0:updateHp(var_6_1)
		arg_6_0:updateEnergyByHarm(arg_6_2)
	end

	arg_6_0:hurtSkillEffect(arg_6_1)

	if arg_6_2 > 0 then
		local var_6_3 = math.max(1, var_6_2)

		arg_6_0.fighterModel:playHPDeltas({
			{
				-var_6_3,
				arg_6_4
			}
		}, nil)
	end

	arg_6_1:recordTargetState("after")

	if arg_6_0:isDeath() then
		arg_6_0:die()
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5
end

function var_0_3.updateHp(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0.isBuried and arg_7_1 < arg_7_0:getHp() then
		return
	end

	var_0_3.super.updateHp(arg_7_0, arg_7_1, arg_7_2)

	if not arg_7_0.isBuried and arg_7_1 > 0 and arg_7_1 <= arg_7_0:getHpLimit() * var_0_6 and arg_7_0.coldTime == 0 and not arg_7_0:isFear() and not arg_7_0:isAdUnable() and not arg_7_0:isAttackFriend() and not arg_7_0:isApUnable() and arg_7_0:getX() > 0 and arg_7_0:getX() < var_0_2.STAGE_WIDTH then
		arg_7_0:Buried()
	end

	if arg_7_0.isBuried and arg_7_1 >= arg_7_0:getHpLimit() then
		arg_7_0:GetOut()
	end
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

function var_0_3.Buried(arg_9_0)
	local var_9_0 = var_0_8
	local var_9_1 = var_0_5:sound(var_9_0)

	var_0_1.ctx.battle.pushSoundQueue(var_9_1)

	local var_9_2 = var_0_5:attackIndex(var_9_0)

	arg_9_0:playAttack(var_9_2)

	arg_9_0.unitSkills_ = var_0_4.new({
		fighter = arg_9_0,
		skillID = var_9_0
	})

	arg_9_0:beginAttackEnd(arg_9_0.unitSkills_)

	arg_9_0.isBuried = true
	arg_9_0.BuriedActionCount = true
end

function var_0_3.GetOut(arg_10_0)
	if arg_10_0:isHasBuffByID(var_0_10) then
		arg_10_0:removeBuffByID(var_0_10)
	end

	arg_10_0:getFighterModel():resume()

	arg_10_0.coldTime = var_0_0.clone(var_0_7)

	local var_10_0 = var_0_9
	local var_10_1 = var_0_5:sound(var_10_0)

	var_0_1.ctx.battle.pushSoundQueue(var_10_1)

	local var_10_2 = var_0_5:attackIndex(var_10_0)

	arg_10_0:playAttack(var_10_2)

	arg_10_0.unitSkills_ = var_0_4.new({
		fighter = arg_10_0,
		skillID = var_10_0
	})

	arg_10_0:beginAttackEnd(arg_10_0.unitSkills_)

	arg_10_0.isBuried = false
end

function var_0_3.addBuffs(arg_11_0, arg_11_1)
	if arg_11_0.isBuried then
		for iter_11_0, iter_11_1 in ipairs(arg_11_1) do
			if iter_11_1:isFear() or iter_11_1:isAdUnable() or iter_11_1:isAttackFriend() or iter_11_1:isApUnable() then
				arg_11_0:GetOut()

				break
			end
		end
	end

	var_0_3.super.addBuffs(arg_11_0, arg_11_1)
end

return var_0_3
