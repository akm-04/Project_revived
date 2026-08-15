local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementBoss", var_0_1.ctx.battle.getRequire("BaseFighter"))
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
	arg_1_0.extraHpCount_ = 0
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:updateExtrHpCount()
end

function var_0_3.setBossAvatar(arg_3_0)
	if not arg_3_0.topWnd then
		return
	end

	arg_3_0.fighterModel.headerView_.hpProgress_:setVisible(false)
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

	arg_4_0.fighterModel:updateHeroHeaderView(var_0_1.ctx.battle.count, arg_4_0.showDHarmbuff_)
	arg_4_0.fighterModel.headerView_.hpProgress_:setVisible(false)
end

function var_0_3.getPartTotalHp(arg_5_0)
	return var_0_11
end

function var_0_3.isBoss(arg_6_0)
	return true
end

function var_0_3.isBreakImmortal(arg_7_0)
	return true
end

function var_0_3.avoidHeroMoveBehind(arg_8_0)
	return var_0_8:avoidHeroMoveBehind(arg_8_0:getTableID())
end

function var_0_3.getADJianShang(arg_9_0)
	return var_0_10 * var_0_3.super.getADJianShang(arg_9_0)
end

function var_0_3.getAPJianShang(arg_10_0)
	return var_0_10 * var_0_3.super.getAPJianShang(arg_10_0)
end

function var_0_3.getHpBarSp(arg_11_0)
	local var_11_0 = arg_11_0.hpIndex_ % 5 > 0 and arg_11_0.hpIndex_ % 5 or 5
	local var_11_1 = "images/battle/boss_hp_progress" .. var_11_0 .. ".png"

	return var_0_2.AssetLoader.get():loadSprite(var_11_1)
end

function var_0_3.getHpBackSp(arg_12_0)
	local var_12_0 = arg_12_0.hpIndex_ + 1
	local var_12_1

	var_12_1 = var_12_0 % 5 > 0 and var_12_0 % 5 or 5

	local var_12_2 = "images/battle/boss_hp_progress" .. var_12_1 .. ".png"

	return var_0_2.AssetLoader.get():loadSprite(var_12_2)
end

function var_0_3.setProgress(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local function var_13_0()
		local var_14_0 = arg_13_0.hpIndex_ > 1 and "x" .. tostring(arg_13_0.hpIndex_ - 1) or ""

		arg_13_0.topWnd:getBossBuffLabel():setString(var_14_0)
		arg_13_0.topWnd:getBossHpBar(1):removeAllChildren()
		arg_13_0.topWnd:getBossHpBar(2):removeAllChildren()

		arg_13_0.progressIndex_ = arg_13_0.hpIndex_

		local var_14_1 = var_0_2.AssetLoader.get():loadSprite("images/battle/boss_hp_progress6.png")

		arg_13_0.easeBar_ = display.newProgressTimer(var_14_1, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_13_0.topWnd:getBossHpBar(1))

		arg_13_0.easeBar_:setMidpoint(cc.p(0, 0))
		arg_13_0.easeBar_:setBarChangeRate(cc.p(1, 0))
		arg_13_0.easeBar_:setPercentage(100)

		local var_14_2 = arg_13_0:getHpBarSp()

		arg_13_0.hpBarBack_ = arg_13_0:getHpBackSp()
		arg_13_0.hpBar_ = display.newProgressTimer(var_14_2, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_13_0.topWnd:getBossHpBar(1))

		arg_13_0.hpBar_:setMidpoint(cc.p(0, 0))
		arg_13_0.hpBar_:setBarChangeRate(cc.p(1, 0))
		arg_13_0.hpBar_:setPercentage(100)
		arg_13_0.hpBarBack_:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_13_0.topWnd:getBossHpBar(2))
	end

	if arg_13_0.progressIndex_ == nil then
		var_13_0()

		arg_13_2 = false
	elseif arg_13_0.progressIndex_ ~= arg_13_0.hpIndex_ then
		arg_13_0.topWnd:getBossBuffIcon():show()
		var_13_0()
		arg_13_0:showDamageText()
		arg_13_0.topWnd:onUpdateBossBuff()
	end

	arg_13_0:setBarProgress_(arg_13_0.hpBar_, arg_13_1, false, arg_13_3)
	arg_13_0:setBarProgress_(arg_13_0.easeBar_, arg_13_1, arg_13_2, arg_13_3)
end

function var_0_3.setBarProgress_(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	if tolua.isnull(arg_15_1) then
		return
	end

	arg_15_1:stopAllActions()

	arg_15_2 = arg_15_2 * 100

	if tonumber(arg_15_3) then
		arg_15_1:runActionOnce(cc.ProgressTo:create(tonumber(arg_15_3), arg_15_2), false, arg_15_4)
	elseif arg_15_3 then
		local var_15_0 = arg_15_1:getPercentage()
		local var_15_1 = arg_15_2 - var_15_0
		local var_15_2 = var_0_2.tables.battleConfig.hpProgressMoveBase + var_0_2.tables.battleConfig.hpProgressMoveStep * math.abs(var_15_1)
		local var_15_3 = var_0_2.tables.battleConfig.hpProgressBrakeBase
		local var_15_4 = var_15_0 + var_15_1 * (1 - var_0_2.tables.battleConfig.hpProgressBrakePercent)
		local var_15_5 = arg_15_2
		local var_15_6 = cc.Sequence:create(cc.ProgressTo:create(var_15_2, var_15_4), cc.ProgressTo:create(var_15_3, var_15_5))

		arg_15_1:runActionOnce(var_15_6, false, arg_15_4)
	else
		arg_15_1:setPercentage(arg_15_2)

		if arg_15_4 ~= nil then
			arg_15_4()
		end
	end
end

function var_0_3.getAD(arg_16_0)
	return var_0_2.tables.battleConfig.elementBossBuffRate * (arg_16_0.hpIndex_ + arg_16_0.extraHpCount_) * arg_16_0.hero_:getBattleAttr(var_0_2.AttributeType.AD) + var_0_3.super.getAD(arg_16_0) - arg_16_0.hero_:getBattleAttr(var_0_2.AttributeType.AD)
end

function var_0_3.getAP(arg_17_0)
	return var_0_2.tables.battleConfig.elementBossBuffRate * (arg_17_0.hpIndex_ + arg_17_0.extraHpCount_) * arg_17_0.hero_:getBattleAttr(var_0_2.AttributeType.AP) + var_0_3.super.getAP(arg_17_0) - arg_17_0.hero_:getBattleAttr(var_0_2.AttributeType.AP)
end

function var_0_3.showDamageText(arg_18_0)
	local var_18_0 = {}

	;(function(arg_19_0)
		local var_19_0 = display.newNode()
		local var_19_1 = var_0_2.AssetLoader.get():loadLabel({
			size = 26,
			text = var_0_2.tables.translation:translation("HARM_SUM_GET"),
			color = cc.c4b(255, 101, 101, 255)
		})

		var_19_1:enableOutline(cc.c4b(0, 0, 0, 255), 2)

		local var_19_2 = var_0_2.AssetLoader.get():loadLabel({
			size = 28,
			text = string.format("%d", arg_19_0),
			color = var_0_2.color.FONT_A
		})

		var_19_2:enableOutline(cc.c4b(0, 0, 0, 255), 2)
		var_19_2:align(display.RIGHT_BOTTOM, 95, 0)
		var_19_0:width(200)
		var_19_0:height(30)
		var_19_1:align(display.LEFT_BOTTOM, 105, 0)
		var_19_1:addTo(var_19_0)
		var_19_2:addTo(var_19_0)
		var_19_0:align(display.CENTER, var_0_2.STAGE_WIDTH / 2, -70)
		table.insert(var_18_0, var_19_0)
	end)((arg_18_0.hpIndex_ - 1) * 10)
	arg_18_0:playNumberFloat_(var_18_0, callback)
end

function var_0_3.playNumberFloat_(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local function var_20_0()
		if arg_20_2 ~= nil then
			arg_20_2()
		end
	end

	arg_20_3 = arg_20_3 or 0

	local var_20_1 = var_0_2.tables.battleConfig.floatAnimationDuration
	local var_20_2 = var_0_2.tables.battleConfig.floatAnimationDeltaY
	local var_20_3 = var_0_2.tables.battleConfig.battleFloatScaleDuration

	local function var_20_4(arg_22_0, arg_22_1)
		local var_22_0 = arg_22_0:getScale()

		arg_22_0:setAnchorPoint(cc.p(0.5, 0.5))
		arg_22_0:addTo(arg_20_0.topWnd, 1)
		var_0_2.setCascadeOpacityEnabled(arg_22_0, true)
		arg_22_0:scale(0)

		local var_22_1 = {}

		table.insert(var_22_1, cc.ScaleTo:create(var_20_3, 1.4 * var_22_0, 1.4 * var_22_0))
		table.insert(var_22_1, cc.DelayTime:create(var_20_3 * 2))

		local var_22_2 = cc.Spawn:create({
			cc.MoveBy:create(var_20_1 * 3, cc.p(0, var_20_2)),
			cc.FadeOut:create(var_20_1)
		})

		table.insert(var_22_1, var_22_2)
		arg_22_0:runActionOnce(transition.sequence(var_22_1), true, arg_22_1, arg_20_3)
	end

	local var_20_5 = {}
	local var_20_6 = var_0_2.tables.battleConfig.floatAnimationInternal

	for iter_20_0, iter_20_1 in ipairs(arg_20_1) do
		iter_20_1:retain()

		local var_20_7

		var_20_7 = iter_20_0 == #arg_20_1

		local function var_20_8()
			var_20_4(iter_20_1, function()
				iter_20_1:release()

				if iter_20_0 == #arg_20_1 then
					var_20_0()
				end
			end)
		end

		if #var_20_5 > 0 then
			table.insert(var_20_5, cc.DelayTime:create(var_20_6))
		end

		table.insert(var_20_5, cc.CallFunc:create(var_20_8))
	end

	if #var_20_5 <= 0 then
		var_20_0()
	else
		arg_20_0.topWnd:runAction(transition.sequence(var_20_5))
	end
end

function var_0_3.addBuffs(arg_25_0, arg_25_1)
	local var_25_0 = {}

	for iter_25_0, iter_25_1 in ipairs(arg_25_1) do
		if var_0_6:attr(iter_25_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_6:attr(iter_25_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_25_1:isFear() and not iter_25_1:isApUnable() and not iter_25_1:isAdUnable() and not iter_25_1:isExcuteAdCircle() and not iter_25_1:isAttackFriend() and not iter_25_1:isPugongOnly() then
			table.insert(var_25_0, iter_25_1)
		end
	end

	var_0_3.super.addBuffs(arg_25_0, var_25_0)
end

function var_0_3.applyUnitBuffs(arg_26_0, arg_26_1, arg_26_2, arg_26_3, arg_26_4, arg_26_5, arg_26_6)
	var_0_3.super.applyUnitBuffs(arg_26_0, arg_26_1, arg_26_2)
end

function var_0_3.progressAwardAction(arg_27_0)
	return
end

function var_0_3.setFormation(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	return var_0_3.super.setFormation(arg_28_0, 4, arg_28_2, arg_28_3)
end

function var_0_3.setFormationDelay(arg_29_0, arg_29_1, arg_29_2)
	var_0_3.super.setFormationDelay(arg_29_0, 0, var_0_2.tables.battleConfig.formationWalkQueue[4])
end

function var_0_3.applyBuffMoves(arg_30_0)
	arg_30_0.buffMovePath_ = {}
end

function var_0_3.checkSkillBreak(arg_31_0, arg_31_1, arg_31_2)
	return
end

function var_0_3.checkKilling(arg_32_0, arg_32_1)
	return
end

function var_0_3.updateUnitDataByFighter(arg_33_0, arg_33_1, arg_33_2, arg_33_3, arg_33_4, arg_33_5, arg_33_6, arg_33_7)
	arg_33_6 = 0
	arg_33_5 = 0

	return arg_33_2, arg_33_3, arg_33_4, arg_33_5, arg_33_6, arg_33_7
end

function var_0_3.getDCureRate(arg_34_0)
	return 0
end

function var_0_3.updateExtrHpCount(arg_35_0)
	return
end

return var_0_3
