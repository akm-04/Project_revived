local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Nian", var_0_1.ctx.battle.requireFighter("ProphesyBoss"))
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

function var_0_3.updateHp(arg_5_0, arg_5_1, arg_5_2)
	if not arg_5_0.isBuried and arg_5_1 <= 1 then
		arg_5_0:Buried()

		arg_5_1 = 1
	end

	var_0_3.super.updateHp(arg_5_0, arg_5_1, arg_5_2)

	if arg_5_0.isBuried and arg_5_1 >= arg_5_0:getHpLimit() then
		arg_5_0:GetOut()
	end
end

function var_0_3.Buried(arg_6_0)
	local var_6_0 = var_0_10
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
	arg_6_0.BuriedActionCount = true
	arg_6_0.attackCount_ = arg_6_0.totalAttackCount_

	if arg_6_0.rebornBar_ then
		arg_6_0.rebornBar_:show()
	end

	arg_6_0:rebornProgress(1, false)
end

function var_0_3.GetOut(arg_7_0)
	arg_7_0:removeBuffByID(var_0_12)
	arg_7_0:getFighterModel():resume()

	local var_7_0 = var_0_11
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

	if arg_7_0.rebornBar_ then
		arg_7_0.rebornBar_:hide()
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

function var_0_3.checkMove(arg_9_0)
	if arg_9_0.isBuried then
		return
	end

	var_0_3.super.checkMove(arg_9_0)
end

function var_0_3.addBuffs(arg_10_0, arg_10_1)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		if var_0_9:attr(iter_10_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_9:attr(iter_10_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_10_1:isFear() and not iter_10_1:isApUnable() and not iter_10_1:isAdUnable() and not iter_10_1:isExcuteAdCircle() and not iter_10_1:isAttackFriend() then
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

function var_0_3.checkKilling(arg_13_0, arg_13_1)
	return
end

function var_0_3.setBossAvatar(arg_14_0)
	var_0_3.super.setBossAvatar(arg_14_0)
end

function var_0_3.rebornProgress(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local function var_15_0()
		arg_15_0.topWnd:getBossHpBar(2):removeAllChildren()
		arg_15_0.topWnd:getBossHpBar(2):y(arg_15_0.topWnd:getBossHpBar(2):getY() - arg_15_0.topWnd:getBossHpBar(2):getHeight())

		arg_15_0.progressIndex_ = arg_15_0.hpIndex_

		local var_16_0 = var_0_2.AssetLoader.get():loadSprite("images/battle/boss_hp_progress7.png")

		arg_15_0.rebornBar_ = display.newProgressTimer(var_16_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_15_0.topWnd:getBossHpBar(2))

		arg_15_0.rebornBar_:setMidpoint(cc.p(0, 0))
		arg_15_0.rebornBar_:setBarChangeRate(cc.p(1, 0))
		arg_15_0.rebornBar_:setPercentage(100)
	end

	if arg_15_0.rebornBar_ == nil then
		var_15_0()

		arg_15_2 = false
	end

	arg_15_0:setBarProgress_(arg_15_0.rebornBar_, arg_15_1, arg_15_2, arg_15_3)
end

function var_0_3.applyHurtFighter(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5)
	if not arg_17_5 and arg_17_2 > 0 and arg_17_0.isBuried then
		arg_17_2 = 0
		arg_17_0.attackCount_ = arg_17_0.attackCount_ - 1

		local var_17_0 = arg_17_0.attackCount_ / arg_17_0.totalAttackCount_

		arg_17_0:rebornProgress(var_17_0, false)

		if arg_17_0.attackCount_ < 1 then
			arg_17_0:updateHp(0)
			arg_17_0:die()
		end
	end

	return var_0_3.super.applyHurtFighter(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5)
end

function var_0_3.isAdBreakImmortal(arg_18_0)
	return true
end

return var_0_3
