local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Nian", var_0_1.ctx.battle.requireFighter("SingleBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = var_0_2.tables.battleConfig
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 10000227
local var_0_11 = 10000228
local var_0_12 = 40010037

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isBuried = false
	arg_1_0.BuriedActionCount = true
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	for iter_2_0, iter_2_1 in ipairs(var_0_8.bossNianIds or {}) do
		if iter_2_1 == arg_2_0.hero_:getTableID() then
			arg_2_0.totalAttackCount_ = var_0_8.bossNianAttackCounts[iter_2_0]
		end
	end
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)

	if var_0_1.ctx.battle.count % 15 == 0 and arg_3_0.isBuried and not arg_3_0:isDeath() then
		arg_3_0:updateHp(arg_3_0:getHp() + 0.1 * arg_3_0:getHpLimit(), false)
	end

	if arg_3_0:acttionInBlack() and arg_3_0:isHasBuffByID(var_0_12) and arg_3_0.BuriedActionCount then
		arg_3_0:getFighterModel():playAnimation_("gongji06", true)

		arg_3_0.BuriedActionCount = false
	end
end

function var_0_3.canAttack(arg_4_0)
	if arg_4_0.isBuried then
		return false
	end

	return var_0_3.super.canAttack(arg_4_0)
end

function var_0_3.Buried(arg_5_0)
	local var_5_0 = var_0_10
	local var_5_1 = var_0_5:sound(var_5_0)

	var_0_1.ctx.battle.pushSoundQueue(var_5_1)

	local var_5_2 = var_0_5:attackIndex(var_5_0)

	arg_5_0:playAttack(var_5_2)

	arg_5_0.unitSkills_ = var_0_4.new({
		fighter = arg_5_0,
		skillID = var_5_0
	})

	arg_5_0:beginAttackEnd(arg_5_0.unitSkills_)

	arg_5_0.isBuried = true
	arg_5_0.BuriedActionCount = true
	arg_5_0.attackCount_ = arg_5_0.totalAttackCount_

	if arg_5_0.rebornBar_ then
		arg_5_0.rebornBar_:show()
	end

	arg_5_0:rebornProgress(1, false)
end

function var_0_3.GetOut(arg_6_0)
	arg_6_0:removeBuffByID(var_0_12)
	arg_6_0:getFighterModel():resume()

	local var_6_0 = var_0_11
	local var_6_1 = var_0_5:sound(var_6_0)

	var_0_1.ctx.battle.pushSoundQueue(var_6_1)

	local var_6_2 = var_0_5:attackIndex(var_6_0)

	arg_6_0:playAttack(var_6_2)

	arg_6_0.unitSkills_ = var_0_4.new({
		fighter = arg_6_0,
		skillID = var_6_0
	})

	arg_6_0:beginAttackEnd(arg_6_0.unitSkills_)

	arg_6_0.isBuried = false

	if arg_6_0.rebornBar_ then
		arg_6_0.rebornBar_:hide()
	end
end

function var_0_3.applyBuffHarm(arg_7_0)
	local var_7_0 = 0
	local var_7_1 = 0
	local var_7_2 = 0
	local var_7_3

	for iter_7_0 = #arg_7_0.buffs_, 1, -1 do
		local var_7_4 = arg_7_0.buffs_[iter_7_0]

		if var_7_4:getType() == var_0_2.BuffType.CONTINUE_HARM then
			var_7_0 = var_7_0 + var_7_4:getHarm()
			var_7_3 = var_7_4.fighter

			if var_7_4:getHarm() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				var_7_3.harms = var_7_3.harms + var_7_4:getHarm()
			end

			var_7_2 = var_7_2 + var_7_4:getMana()
		elseif var_7_4:getType() == var_0_2.BuffType.GAIN then
			var_7_1 = var_7_1 + var_7_4:getHarm()
		end
	end

	if var_7_1 == 0 and var_7_0 == 0 and var_7_2 == 0 then
		return
	end

	local var_7_5 = math.max(0, arg_7_0:getHp() - var_7_0 + var_7_1)

	if not arg_7_0.isBuried then
		if var_7_1 - var_7_0 > 0 then
			var_7_5 = math.min(arg_7_0:getHp() - var_7_0 + var_7_1, arg_7_0:getHpLimit())
		end
	else
		var_7_5 = math.min(arg_7_0:getHp() + var_7_1, arg_7_0:getHpLimit())
	end

	if var_7_1 ~= 0 then
		arg_7_0.cureHp = arg_7_0.cureHp + var_7_1
	end

	local var_7_6 = -var_7_2

	arg_7_0:updateHp(var_7_5)
	arg_7_0:updateEnergyBy(var_7_6)
	arg_7_0:setOriHurt(var_7_0)

	return var_7_3
end

function var_0_3.checkMove(arg_8_0)
	if arg_8_0.isBuried then
		return
	end

	var_0_3.super.checkMove(arg_8_0)
end

function var_0_3.addBuffs(arg_9_0, arg_9_1)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_1) do
		if var_0_9:attr(iter_9_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_9:attr(iter_9_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_9_1:isFear() and not iter_9_1:isApUnable() and not iter_9_1:isAdUnable() and not iter_9_1:isExcuteAdCircle() and not iter_9_1:isAttackFriend() then
			table.insert(var_9_0, iter_9_1)
		end
	end

	var_0_3.super.addBuffs(arg_9_0, var_9_0)
end

function var_0_3.applyUnitBuffs(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6)
	var_0_3.super.applyUnitBuffs(arg_10_0, arg_10_1, arg_10_2)
end

function var_0_3.checkSkillBreak(arg_11_0, arg_11_1)
	return
end

function var_0_3.checkKilling(arg_12_0, arg_12_1)
	return
end

function var_0_3.setBossAvatar(arg_13_0)
	var_0_3.super.setBossAvatar(arg_13_0)
end

function var_0_3.rebornProgress(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local function var_14_0()
		arg_14_0.topWnd:getBossHpBar(2):removeAllChildren()
		arg_14_0.topWnd:getBossHpBar(2):y(arg_14_0.topWnd:getBossHpBar(2):getY() - arg_14_0.topWnd:getBossHpBar(2):getHeight())

		arg_14_0.progressIndex_ = arg_14_0.hpIndex_

		local var_15_0 = var_0_2.AssetLoader.get():loadSprite("images/battle/boss_hp_progress7.png")

		arg_14_0.rebornBar_ = display.newProgressTimer(var_15_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_14_0.topWnd:getBossHpBar(2))

		arg_14_0.rebornBar_:setMidpoint(cc.p(0, 0))
		arg_14_0.rebornBar_:setBarChangeRate(cc.p(1, 0))
		arg_14_0.rebornBar_:setPercentage(100)
	end

	if arg_14_0.rebornBar_ == nil then
		var_14_0()

		arg_14_2 = false
	end

	arg_14_0:setBarProgress_(arg_14_0.rebornBar_, arg_14_1, arg_14_2, arg_14_3)
end

function var_0_3.applyHurtFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5)
	if not arg_16_5 and arg_16_2 > 0 and arg_16_0.isBuried then
		arg_16_2 = 0
		arg_16_0.attackCount_ = arg_16_0.attackCount_ - 1

		local var_16_0 = arg_16_0.attackCount_ / arg_16_0.totalAttackCount_

		arg_16_0:rebornProgress(var_16_0, false)

		if arg_16_0.attackCount_ < 1 then
			arg_16_0:updateHp(0)
			arg_16_0:die()
		end
	end

	return var_0_3.super.applyHurtFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5)
end

function var_0_3.isAdBreakImmortal(arg_17_0)
	return true
end

return var_0_3
