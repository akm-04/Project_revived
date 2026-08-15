local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ProphesyBoss", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_0.import("app.common.ui.SpineEffect")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = 1

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

	arg_3_0.topWnd:getDamageIcon():hide()
	arg_3_0.topWnd:getDamageLabel():hide()
	arg_3_0.topWnd:getBossBuffIcon():hide()
	arg_3_0.topWnd:getBossBuffLabel():hide()
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
		arg_4_0:setProgress(arg_4_0:getHp() / arg_4_0:getHpLimit(), true)
	end
end

function var_0_3.isBoss(arg_5_0)
	return true
end

function var_0_3.avoidHeroMoveBehind(arg_6_0)
	return var_0_8:avoidHeroMoveBehind(arg_6_0:getTableID())
end

function var_0_3.getADJianShang(arg_7_0)
	return var_0_10 * var_0_3.super.getADJianShang(arg_7_0)
end

function var_0_3.getAPJianShang(arg_8_0)
	return var_0_10 * var_0_3.super.getAPJianShang(arg_8_0)
end

function var_0_3.getHpBarSp(arg_9_0)
	local var_9_0 = "images/battle/boss_hp_progress5.png"

	return var_0_2.AssetLoader.get():loadSprite(var_9_0)
end

function var_0_3.setProgress(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local function var_10_0()
		arg_10_0.topWnd:getBossHpBar(1):removeAllChildren()
		arg_10_0.topWnd:getBossHpBar(2):removeAllChildren()

		arg_10_0.progressIndex_ = arg_10_0.hpIndex_

		local var_11_0 = var_0_2.AssetLoader.get():loadSprite("images/battle/boss_hp_progress6.png")

		arg_10_0.easeBar_ = display.newProgressTimer(var_11_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_10_0.topWnd:getBossHpBar(1))

		arg_10_0.easeBar_:setMidpoint(cc.p(0, 0))
		arg_10_0.easeBar_:setBarChangeRate(cc.p(1, 0))
		arg_10_0.easeBar_:setPercentage(100)

		local var_11_1 = arg_10_0:getHpBarSp()

		arg_10_0.hpBar_ = display.newProgressTimer(var_11_1, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_10_0.topWnd:getBossHpBar(1))

		arg_10_0.hpBar_:setMidpoint(cc.p(0, 0))
		arg_10_0.hpBar_:setBarChangeRate(cc.p(1, 0))
		arg_10_0.hpBar_:setPercentage(100)
	end

	if arg_10_0.progressIndex_ == nil then
		var_10_0()

		arg_10_2 = false
	end

	arg_10_0:setBarProgress_(arg_10_0.hpBar_, arg_10_1, false, arg_10_3)
	arg_10_0:setBarProgress_(arg_10_0.easeBar_, arg_10_1, arg_10_2, arg_10_3)
end

function var_0_3.setBarProgress_(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	if tolua.isnull(arg_12_1) then
		return
	end

	arg_12_1:stopAllActions()

	arg_12_2 = arg_12_2 * 100

	if tonumber(arg_12_3) then
		arg_12_1:runActionOnce(cc.ProgressTo:create(tonumber(arg_12_3), arg_12_2), false, arg_12_4)
	elseif arg_12_3 then
		local var_12_0 = arg_12_1:getPercentage()
		local var_12_1 = arg_12_2 - var_12_0
		local var_12_2 = var_0_2.tables.battleConfig.hpProgressMoveBase + var_0_2.tables.battleConfig.hpProgressMoveStep * math.abs(var_12_1)
		local var_12_3 = var_0_2.tables.battleConfig.hpProgressBrakeBase
		local var_12_4 = var_12_0 + var_12_1 * (1 - var_0_2.tables.battleConfig.hpProgressBrakePercent)
		local var_12_5 = arg_12_2
		local var_12_6 = cc.Sequence:create(cc.ProgressTo:create(var_12_2, var_12_4), cc.ProgressTo:create(var_12_3, var_12_5))

		arg_12_1:runActionOnce(var_12_6, false, arg_12_4)
	else
		arg_12_1:setPercentage(arg_12_2)

		if arg_12_4 ~= nil then
			arg_12_4()
		end
	end
end

function var_0_3.playNumberFloat_(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local function var_13_0()
		if arg_13_2 ~= nil then
			arg_13_2()
		end
	end

	arg_13_3 = arg_13_3 or 0

	local var_13_1 = var_0_2.tables.battleConfig.floatAnimationDuration
	local var_13_2 = var_0_2.tables.battleConfig.floatAnimationDeltaY
	local var_13_3 = var_0_2.tables.battleConfig.battleFloatScaleDuration

	local function var_13_4(arg_15_0, arg_15_1)
		local var_15_0 = arg_15_0:getScale()

		arg_15_0:setAnchorPoint(cc.p(0.5, 0.5))
		arg_15_0:addTo(arg_13_0.topWnd, 1)
		var_0_2.setCascadeOpacityEnabled(arg_15_0, true)
		arg_15_0:scale(0)

		local var_15_1 = {}

		table.insert(var_15_1, cc.ScaleTo:create(var_13_3, 1.4 * var_15_0, 1.4 * var_15_0))
		table.insert(var_15_1, cc.DelayTime:create(var_13_3 * 2))

		local var_15_2 = cc.Spawn:create({
			cc.MoveBy:create(var_13_1 * 3, cc.p(0, var_13_2)),
			cc.FadeOut:create(var_13_1)
		})

		table.insert(var_15_1, var_15_2)
		arg_15_0:runActionOnce(transition.sequence(var_15_1), true, arg_15_1, arg_13_3)
	end

	local var_13_5 = {}
	local var_13_6 = var_0_2.tables.battleConfig.floatAnimationInternal

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		iter_13_1:retain()

		local var_13_7

		var_13_7 = iter_13_0 == #arg_13_1

		local function var_13_8()
			var_13_4(iter_13_1, function()
				iter_13_1:release()

				if iter_13_0 == #arg_13_1 then
					var_13_0()
				end
			end)
		end

		if #var_13_5 > 0 then
			table.insert(var_13_5, cc.DelayTime:create(var_13_6))
		end

		table.insert(var_13_5, cc.CallFunc:create(var_13_8))
	end

	if #var_13_5 <= 0 then
		var_13_0()
	else
		arg_13_0.topWnd:runAction(transition.sequence(var_13_5))
	end
end

function var_0_3.progressAwardAction(arg_18_0)
	return
end

function var_0_3.setFormation(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	return var_0_3.super.setFormation(arg_19_0, 4, arg_19_2, arg_19_3)
end

function var_0_3.setFormationDelay(arg_20_0, arg_20_1, arg_20_2)
	var_0_3.super.setFormationDelay(arg_20_0, 0, var_0_2.tables.battleConfig.formationWalkQueue[4])
end

function var_0_3.applyBuffMoves(arg_21_0)
	arg_21_0.buffMovePath_ = {}
end

function var_0_3.checkKilling(arg_22_0, arg_22_1)
	return
end

return var_0_3
