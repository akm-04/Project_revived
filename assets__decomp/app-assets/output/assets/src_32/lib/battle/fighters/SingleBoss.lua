local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SingleBoss", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_0.import("app.common.ui.SpineEffect")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = 1
local var_0_11 = 100000

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.hpIndex_ = 1
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
end

function var_0_3.setBossAvatar(arg_3_0)
	if not arg_3_0.topWnd then
		return
	end

	arg_3_0.topWnd:getBossBuffIcon():hide()
	arg_3_0.topWnd:getBossAvatarBackground():show()
	arg_3_0.topWnd:hideGuildLabel()

	local var_3_0 = arg_3_0.hero_
	local var_3_1 = arg_3_0.topWnd:getAvatarBossContainer()

	var_3_1:removeAllChildren()

	local var_3_2 = var_3_0:getAvatar(2)
	local var_3_3 = var_0_2.AssetLoader.get():loadSprite(var_3_2)

	var_3_3:align(display.CENTER_BOTTOM, var_3_1:getWidth() / 2, 0):addTo(var_3_1)
	var_3_3:scale(100 / var_3_3:getWidth())
end

function var_0_3.updateHpBar(arg_4_0, arg_4_1)
	if arg_4_0.topWnd then
		arg_4_0.hpIndex_ = math.floor((arg_4_0:getHpLimit() - arg_4_0:getHp()) / arg_4_0:getPartTotalHp())
		arg_4_0.hpIndex_ = arg_4_0.hpIndex_ + 1

		local var_4_0 = var_0_11 - (arg_4_0:getHpLimit() - arg_4_0:getHp()) % var_0_11

		if arg_4_0:getHpLimit() == arg_4_0:getHp() then
			var_4_0 = var_0_11
		end

		if arg_4_0:getHpLimit() == arg_4_0:getHp() then
			arg_4_0.topWnd:getDamageIcon():hide()
			arg_4_0.topWnd:getDamageLabel():hide()
		else
			arg_4_0.topWnd:getDamageLabel():setString(math.floor(arg_4_0:getHpLimit() - arg_4_0:getHp()))
			arg_4_0.topWnd:getDamageLabel():show()
			arg_4_0.topWnd:getDamageIcon():show()
		end

		arg_4_0:setProgress(var_4_0 / arg_4_0:getPartTotalHp(), true)
	end
end

function var_0_3.getPartTotalHp(arg_5_0)
	return var_0_11
end

function var_0_3.isBoss(arg_6_0)
	return true
end

function var_0_3.avoidHeroMoveBehind(arg_7_0)
	return var_0_8:avoidHeroMoveBehind(arg_7_0:getTableID())
end

function var_0_3.getADJianShang(arg_8_0)
	return var_0_10 * var_0_3.super.getADJianShang(arg_8_0)
end

function var_0_3.getAPJianShang(arg_9_0)
	return var_0_10 * var_0_3.super.getAPJianShang(arg_9_0)
end

function var_0_3.getHpBarSp(arg_10_0)
	local var_10_0 = arg_10_0.hpIndex_ % 5 > 0 and arg_10_0.hpIndex_ % 5 or 5
	local var_10_1 = "images/battle/boss_hp_progress" .. var_10_0 .. ".png"

	return var_0_2.AssetLoader.get():loadSprite(var_10_1)
end

function var_0_3.getHpBackSp(arg_11_0)
	local var_11_0 = arg_11_0.hpIndex_ + 1
	local var_11_1

	var_11_1 = var_11_0 % 5 > 0 and var_11_0 % 5 or 5

	local var_11_2 = "images/battle/boss_hp_progress" .. var_11_1 .. ".png"

	return var_0_2.AssetLoader.get():loadSprite(var_11_2)
end

function var_0_3.setProgress(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local function var_12_0()
		local var_13_0 = arg_12_0.hpIndex_ > 1 and "x" .. tostring(arg_12_0.hpIndex_ - 1) or ""

		arg_12_0.topWnd:getBossBuffLabel():setString(var_13_0)
		arg_12_0.topWnd:getBossHpBar(1):removeAllChildren()
		arg_12_0.topWnd:getBossHpBar(2):removeAllChildren()

		arg_12_0.progressIndex_ = arg_12_0.hpIndex_

		local var_13_1 = var_0_2.AssetLoader.get():loadSprite("images/battle/boss_hp_progress6.png")

		arg_12_0.easeBar_ = display.newProgressTimer(var_13_1, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_12_0.topWnd:getBossHpBar(1))

		arg_12_0.easeBar_:setMidpoint(cc.p(0, 0))
		arg_12_0.easeBar_:setBarChangeRate(cc.p(1, 0))
		arg_12_0.easeBar_:setPercentage(100)

		local var_13_2 = arg_12_0:getHpBarSp()

		arg_12_0.hpBarBack_ = arg_12_0:getHpBackSp()
		arg_12_0.hpBar_ = display.newProgressTimer(var_13_2, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_12_0.topWnd:getBossHpBar(1))

		arg_12_0.hpBar_:setMidpoint(cc.p(0, 0))
		arg_12_0.hpBar_:setBarChangeRate(cc.p(1, 0))
		arg_12_0.hpBar_:setPercentage(100)
		arg_12_0.hpBarBack_:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_12_0.topWnd:getBossHpBar(2))
	end

	if arg_12_0.progressIndex_ == nil then
		var_12_0()

		arg_12_2 = false
	elseif arg_12_0.progressIndex_ ~= arg_12_0.hpIndex_ then
		arg_12_0.topWnd:getBossBuffIcon():show()
		var_12_0()
		arg_12_0:showDamageText()
		arg_12_0.topWnd:onUpdateBossBuff()
	end

	arg_12_0:setBarProgress_(arg_12_0.hpBar_, arg_12_1, false, arg_12_3)
	arg_12_0:setBarProgress_(arg_12_0.easeBar_, arg_12_1, arg_12_2, arg_12_3)
end

function var_0_3.setBarProgress_(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4)
	if tolua.isnull(arg_14_1) then
		return
	end

	arg_14_1:stopAllActions()

	arg_14_2 = arg_14_2 * 100

	if tonumber(arg_14_3) then
		arg_14_1:runActionOnce(cc.ProgressTo:create(tonumber(arg_14_3), arg_14_2), false, arg_14_4)
	elseif arg_14_3 then
		local var_14_0 = arg_14_1:getPercentage()
		local var_14_1 = arg_14_2 - var_14_0
		local var_14_2 = var_0_2.tables.battleConfig.hpProgressMoveBase + var_0_2.tables.battleConfig.hpProgressMoveStep * math.abs(var_14_1)
		local var_14_3 = var_0_2.tables.battleConfig.hpProgressBrakeBase
		local var_14_4 = var_14_0 + var_14_1 * (1 - var_0_2.tables.battleConfig.hpProgressBrakePercent)
		local var_14_5 = arg_14_2
		local var_14_6 = cc.Sequence:create(cc.ProgressTo:create(var_14_2, var_14_4), cc.ProgressTo:create(var_14_3, var_14_5))

		arg_14_1:runActionOnce(var_14_6, false, arg_14_4)
	else
		arg_14_1:setPercentage(arg_14_2)

		if arg_14_4 ~= nil then
			arg_14_4()
		end
	end
end

function var_0_3.getAD(arg_15_0)
	return math.pow(var_0_2.tables.battleConfig.singleBossBuffRate, arg_15_0.hpIndex_) * arg_15_0.hero_:getBattleAttr(var_0_2.AttributeType.AD) + var_0_3.super.getAD(arg_15_0) - arg_15_0.hero_:getBattleAttr(var_0_2.AttributeType.AD)
end

function var_0_3.getAP(arg_16_0)
	return math.pow(var_0_2.tables.battleConfig.singleBossBuffRate, arg_16_0.hpIndex_) * arg_16_0.hero_:getBattleAttr(var_0_2.AttributeType.AP) + var_0_3.super.getAP(arg_16_0) - arg_16_0.hero_:getBattleAttr(var_0_2.AttributeType.AP)
end

function var_0_3.showDamageText(arg_17_0)
	local var_17_0 = {}

	;(function(arg_18_0)
		local var_18_0 = display.newNode()
		local var_18_1 = var_0_2.AssetLoader.get():loadLabel({
			size = 20,
			text = var_0_2.tables.translation:translation("HARM_SUM_GET"),
			color = cc.c4b(255, 101, 101, 255)
		})

		var_18_1:enableOutline(cc.c4b(0, 0, 0, 255), 2)

		local var_18_2 = var_0_2.AssetLoader.get():loadLabel({
			size = 22,
			text = string.format("%d", arg_18_0),
			color = var_0_2.color.FONT_A
		})

		var_18_2:enableOutline(cc.c4b(0, 0, 0, 255), 2)
		var_18_2:align(display.RIGHT_BOTTOM, 95, 0)
		var_18_0:width(200)
		var_18_0:height(30)
		var_18_1:align(display.LEFT_BOTTOM, 105, 0)
		var_18_1:addTo(var_18_0)
		var_18_2:addTo(var_18_0)
		var_18_0:align(display.CENTER, var_0_2.STAGE_WIDTH / 2, -70)
		table.insert(var_17_0, var_18_0)
	end)((arg_17_0.hpIndex_ - 1) * 10)
	arg_17_0:playNumberFloat_(var_17_0, callback)
end

function var_0_3.playNumberFloat_(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local function var_19_0()
		if arg_19_2 ~= nil then
			arg_19_2()
		end
	end

	arg_19_3 = arg_19_3 or 0

	local var_19_1 = var_0_2.tables.battleConfig.floatAnimationDuration
	local var_19_2 = var_0_2.tables.battleConfig.floatAnimationDeltaY
	local var_19_3 = var_0_2.tables.battleConfig.battleFloatScaleDuration

	local function var_19_4(arg_21_0, arg_21_1)
		local var_21_0 = arg_21_0:getScale()

		arg_21_0:setAnchorPoint(cc.p(0.5, 0.5))
		arg_21_0:addTo(arg_19_0.topWnd, 1)
		var_0_2.setCascadeOpacityEnabled(arg_21_0, true)
		arg_21_0:scale(0)

		local var_21_1 = {}

		table.insert(var_21_1, cc.ScaleTo:create(var_19_3, 1.4 * var_21_0, 1.4 * var_21_0))
		table.insert(var_21_1, cc.DelayTime:create(var_19_3 * 2))

		local var_21_2 = cc.Spawn:create({
			cc.MoveBy:create(var_19_1 * 3, cc.p(0, var_19_2)),
			cc.FadeOut:create(var_19_1)
		})

		table.insert(var_21_1, var_21_2)
		arg_21_0:runActionOnce(transition.sequence(var_21_1), true, arg_21_1, arg_19_3)
	end

	local var_19_5 = {}
	local var_19_6 = var_0_2.tables.battleConfig.floatAnimationInternal

	for iter_19_0, iter_19_1 in ipairs(arg_19_1) do
		iter_19_1:retain()

		local var_19_7

		var_19_7 = iter_19_0 == #arg_19_1

		local function var_19_8()
			var_19_4(iter_19_1, function()
				iter_19_1:release()

				if iter_19_0 == #arg_19_1 then
					var_19_0()
				end
			end)
		end

		if #var_19_5 > 0 then
			table.insert(var_19_5, cc.DelayTime:create(var_19_6))
		end

		table.insert(var_19_5, cc.CallFunc:create(var_19_8))
	end

	if #var_19_5 <= 0 then
		var_19_0()
	else
		arg_19_0.topWnd:runAction(transition.sequence(var_19_5))
	end
end

function var_0_3.addBuffs(arg_24_0, arg_24_1)
	local var_24_0 = {}

	for iter_24_0, iter_24_1 in ipairs(arg_24_1) do
		if var_0_6:attr(iter_24_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_6:attr(iter_24_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_24_1:isFear() and not iter_24_1:isApUnable() and not iter_24_1:isAdUnable() and not iter_24_1:isExcuteAdCircle() and not iter_24_1:isAttackFriend() then
			table.insert(var_24_0, iter_24_1)
		end
	end

	var_0_3.super.addBuffs(arg_24_0, var_24_0)
end

function var_0_3.applyUnitBuffs(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4, arg_25_5, arg_25_6)
	var_0_3.super.applyUnitBuffs(arg_25_0, arg_25_1, arg_25_2)
end

function var_0_3.progressAwardAction(arg_26_0)
	return
end

function var_0_3.setFormation(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	return var_0_3.super.setFormation(arg_27_0, 4, arg_27_2, arg_27_3)
end

function var_0_3.setFormationDelay(arg_28_0, arg_28_1, arg_28_2)
	var_0_3.super.setFormationDelay(arg_28_0, 0, var_0_2.tables.battleConfig.formationWalkQueue[4])
end

function var_0_3.applyBuffMoves(arg_29_0)
	arg_29_0.buffMovePath_ = {}
end

function var_0_3.checkSkillBreak(arg_30_0, arg_30_1)
	return
end

function var_0_3.checkKilling(arg_31_0, arg_31_1)
	return
end

function var_0_3.updateUnitDataByFighter(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4, arg_32_5, arg_32_6, arg_32_7)
	arg_32_6 = 0
	arg_32_5 = 0

	return arg_32_2, arg_32_3, arg_32_4, arg_32_5, arg_32_6, arg_32_7
end

return var_0_3
