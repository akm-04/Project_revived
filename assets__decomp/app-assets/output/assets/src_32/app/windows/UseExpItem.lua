local var_0_0 = class("UseExpItem", function()
	return display.newNode()
end)
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = require("framework.scheduler")

var_0_0.IMG_TOUXIANG = "img_touxiang"
var_0_0.IMG_TYPE = "img_type"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_LEV = "txt_lev"
var_0_0.FULL_BAR = "full_bar"
var_0_0.EXP_BAR = "exp_bar"
var_0_0.events = {
	{
		to = "disabled",
		name = "disable",
		from = {
			"normal",
			"pressed"
		}
	},
	{
		to = "normal",
		name = "enable",
		from = {
			"disabled"
		}
	},
	{
		to = "pressed",
		name = "press",
		from = "normal"
	},
	{
		to = "normal",
		name = "release",
		from = "pressed"
	}
}
var_0_0.LONG_TOUCH_EVENT = "LONG_TOUCH_EVENT"
var_0_0.LONG_TOUCH_INTERVAL = 0.2
var_0_0.LONG_TOUCH_THRESHOLD = 10
var_0_0.CLICKED_EVENT = "CLICKED_EVENT"
var_0_0.PRESSED_EVENT = "PRESSED_EVENT"
var_0_0.RELEASE_EVENT = "RELEASE_EVENT"
var_0_0.STATE_CHANGED_EVENT = "STATE_CHANGED_EVENT"

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.touxiangIcon = arg_2_0.contentView_:nodeByName(var_0_0.IMG_TOUXIANG)

	arg_2_0.touxiangIcon:removeAllChildren()

	arg_2_0.typeIcon = arg_2_0.contentView_:nodeByName(var_0_0.IMG_TYPE)

	arg_2_0.typeIcon:removeAllChildren()

	arg_2_0.nameLabel = arg_2_0.contentView_:nodeByName(var_0_0.TXT_NAME)
	arg_2_0.levLabel = arg_2_0.contentView_:nodeByName(var_0_0.TXT_LEV)
	arg_2_0.fullBar = arg_2_0.contentView_:nodeByName(var_0_0.FULL_BAR)
	arg_2_0.expBar = arg_2_0.contentView_:nodeByName(var_0_0.EXP_BAR)
	arg_2_0.fullTxt = arg_2_0.contentView_:nodeByName("txt_full")

	arg_2_0.fullTxt:setString(var_0_3:translation("EXP_FULL"))
	arg_2_0.expBar:setVisible(false)

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.maxLev = xyd.tables.player:heroMaxLev(arg_2_0.player_.lev)
	arg_2_0.container = arg_2_0.contentView_:nodeByName("container")
	arg_2_0.fsm_ = {}

	cc(arg_2_0.fsm_):addComponent("components.behavior.StateMachine"):exportMethods()
	arg_2_0.fsm_:setupState({
		initial = {
			event = "startup",
			defer = false,
			state = "normal"
		},
		events = var_0_0.events,
		callbacks = {
			onchangestate = handler(arg_2_0, arg_2_0.onChangeState_)
		}
	})
	arg_2_0:setLongTouchEnabled(true)

	arg_2_0.isTouchHold_ = false
	arg_2_0.isLongTouched_ = false
end

function var_0_0.onChangeState_(arg_3_0, arg_3_1)
	return
end

function var_0_0.contentView(arg_4_0)
	if arg_4_0.contentView_ == nil then
		arg_4_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_4_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/use_exp_window/hero_item.csb"))
		arg_4_0.contentView_:addTo(arg_4_0):setAnchorPoint(0.5, 0.5)
		arg_4_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_4_0.contentView_
end

function var_0_0.setParams(arg_5_0, arg_5_1)
	if arg_5_1 == nil then
		return
	end

	arg_5_0.hero = arg_5_1

	local var_5_0 = xyd.AssetLoader.get():loadSprite("images/herotype_" .. arg_5_0.hero:getHeroType() .. ".png")

	xyd.displaySpriteOnContainer(var_5_0, arg_5_0.typeIcon)
	xyd.setAvatarBorder(arg_5_0.hero, arg_5_0.touxiangIcon)
	xyd.setNameLabel(arg_5_0.nameLabel, arg_5_0.hero, true)

	local var_5_1 = xyd.AssetLoader.get():loadSprite("windows/use_exp_window/exp.png")

	arg_5_0.expProgress_ = display.newProgressTimer(var_5_1, display.PROGRESS_TIMER_BAR)

	arg_5_0.expProgress_:setMidpoint(cc.p(0, 0))
	arg_5_0.expProgress_:setBarChangeRate(cc.p(1, 0))
	arg_5_0.expProgress_:setPercentage(0)
	arg_5_0.container:addChild(arg_5_0.expProgress_)
	arg_5_0.expProgress_:setPosition(arg_5_0.expBar:getPosition())
	arg_5_0:contentView():nodeByName("txt_num"):setVisible(false)
	arg_5_0:contentView():nodeByName("txt_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	arg_5_0.oldLev = arg_5_0.hero:getLevel()

	arg_5_0:initExp()
end

function var_0_0.initExp(arg_6_0)
	arg_6_0.lev = arg_6_0.hero:getLevel()
	arg_6_0.exp = arg_6_0.hero:getExp()

	arg_6_0.levLabel:setString(arg_6_0.hero:getLevel())
	arg_6_0.levLabel:enableOutline(cc.c4b(255, 255, 255, 255), 2)

	if arg_6_0.exp >= xyd.tables.partnerExp:totalExp(arg_6_0.maxLev) then
		arg_6_0.fullBar:setVisible(true)
		arg_6_0.fullTxt:setVisible(true)
		arg_6_0.expProgress_:setVisible(false)
	else
		arg_6_0.fullBar:setVisible(false)
		arg_6_0.fullTxt:setVisible(false)

		local var_6_0 = xyd.tables.partnerExp:exp(arg_6_0.lev)
		local var_6_1 = xyd.tables.partnerExp:totalExp(arg_6_0.lev)
		local var_6_2 = arg_6_0.exp + var_6_0 - var_6_1
		local var_6_3 = math.min(var_6_2 / var_6_0 * 100, 100)

		arg_6_0.expProgress_:setPercentage(var_6_3)
	end
end

function var_0_0.updateExp(arg_7_0, arg_7_1)
	arg_7_0.lev = arg_7_0.hero:getLevel()
	arg_7_0.exp = arg_7_0.hero:getExp()

	arg_7_0.levLabel:setString(arg_7_0.hero:getLevel())
	arg_7_0.levLabel:enableOutline(cc.c4b(255, 255, 255, 255), 2)

	if arg_7_0.exp >= xyd.tables.partnerExp:totalExp(arg_7_0.maxLev) then
		arg_7_0.fullBar:setVisible(true)
		arg_7_0.fullTxt:setVisible(true)
		arg_7_0.expProgress_:setVisible(false)

		local var_7_0 = xyd.tables.sound:getSound("train_exp_max")

		audio.playSound(var_7_0, false)
	else
		arg_7_0.fullBar:setVisible(false)
		arg_7_0.fullTxt:setVisible(false)

		local var_7_1 = xyd.tables.partnerExp:exp(arg_7_0.lev)
		local var_7_2 = xyd.tables.partnerExp:totalExp(arg_7_0.lev)
		local var_7_3 = arg_7_0.exp + var_7_1 - var_7_2
		local var_7_4 = math.min(var_7_3 / var_7_1 * 100, 100)

		if arg_7_0.oldLev == arg_7_0.lev then
			arg_7_0.expProgress_:runAction(cc.ProgressTo:create(0.1, var_7_4))
		else
			arg_7_0.expProgress_:runActionOnce(cc.ProgressTo:create(0.05, 100), false, function()
				arg_7_0.expProgress_:setPercentage(0)

				local var_8_0 = xyd.tables.sound:getSound("train_lv_up")

				audio.playSound(var_8_0, false)

				if arg_7_0.levelUpEffect == nil then
					local var_8_1 = "skeletons/ui_effect/common_effect_exp_lv_up/common_effect_exp_lv_up"
					local var_8_2 = var_8_1 .. ".json"
					local var_8_3 = var_8_1 .. ".atlas"

					arg_7_0.levelUpEffect = var_0_2.new(var_8_2, var_8_3, 1)

					arg_7_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
					arg_7_0.levelUpEffect:setPosition(69, 60)
					arg_7_0.container:addChild(arg_7_0.levelUpEffect)
				end

				arg_7_0.levelUpEffect:play(nil, false)

				if arg_7_0.levelUpSprite == nil then
					arg_7_0.levelUpSprite = xyd.AssetLoader.get():loadSprite("images/text/txt_levelup.png")

					arg_7_0.levelUpSprite:setAnchorPoint(cc.p(0.5, 0.5))
					arg_7_0.levelUpSprite:setPosition(69, 60)
					arg_7_0.container:addChild(arg_7_0.levelUpSprite)
				end

				arg_7_0.levelUpSprite:setPosition(69, 60)
				arg_7_0.levelUpSprite:setVisible(true)
				arg_7_0.levelUpSprite:runActionOnce(cc.MoveTo:create(1, cc.p(69, 100)), false, function()
					arg_7_0.levelUpSprite:setVisible(false)
				end)
				arg_7_0.expProgress_:runAction(cc.ProgressTo:create(0.05, var_7_4))
			end)
		end
	end

	if arg_7_0.clickEffect == nil then
		local var_7_5 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
		local var_7_6 = var_7_5 .. ".json"
		local var_7_7 = var_7_5 .. ".atlas"

		arg_7_0.clickEffect = var_0_2.new(var_7_6, var_7_7, 1)

		arg_7_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_7_0.clickEffect:setPosition(69, 60)
		arg_7_0.container:addChild(arg_7_0.clickEffect)
	end

	arg_7_0.clickEffect:play(nil, false)

	arg_7_0.oldLev = arg_7_0.lev

	arg_7_0:contentView():nodeByName("txt_num"):setVisible(true)
	arg_7_0:contentView():nodeByName("txt_num"):setString("X" .. arg_7_1)

	if arg_7_0.visibleHandler ~= nil then
		var_0_4.unscheduleGlobal(arg_7_0.visibleHandler)
	end

	arg_7_0.visibleHandler = var_0_4.performWithDelayGlobal(function()
		if not tolua.isnull(arg_7_0.contentView) then
			arg_7_0:contentView():nodeByName("txt_num"):setVisible(false)
		end
	end, 0.5)
end

function var_0_0.setLongTouchEnabled(arg_11_0, arg_11_1)
	arg_11_0.longTouchEnabled_ = arg_11_1
end

function var_0_0.isLongTouchEnabled(arg_12_0)
	return arg_12_0.longTouchEnabled_
end

function var_0_0.onLongTouch(arg_13_0, arg_13_1)
	arg_13_0:addLongTouchEventListener(arg_13_1)

	return arg_13_0
end

function var_0_0.onButtonPressed(arg_14_0, arg_14_1)
	arg_14_0:addButtonPressedEventListener(arg_14_1)

	return arg_14_0
end

function var_0_0.addButtonReleaseEventListener(arg_15_0, arg_15_1)
	return arg_15_0:addEventListener(UIButton.RELEASE_EVENT, arg_15_1)
end

function var_0_0.addButtonPressedEventListener(arg_16_0, arg_16_1)
	return arg_16_0:addEventListener(UIButton.PRESSED_EVENT, arg_16_1)
end

function var_0_0.addButtonReleaseEventListener(arg_17_0, arg_17_1)
	return arg_17_0:addEventListener(UIButton.RELEASE_EVENT, arg_17_1)
end

function var_0_0.addLongTouchEventListener(arg_18_0, arg_18_1)
	return arg_18_0:addEventListener(var_0_0.LONG_TOUCH_EVENT, arg_18_1)
end

function var_0_0.onTouch_(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_1.name
	local var_19_1 = arg_19_1.x
	local var_19_2 = arg_19_1.y

	if var_19_0 == "began" then
		arg_19_0.touchBeganX = var_19_1
		arg_19_0.touchBeganY = var_19_2

		if not arg_19_0:checkTouchInSprite_(var_19_1, var_19_2) then
			return false
		end

		arg_19_0.fsm_:doEvent("press")
		arg_19_0:dispatchEvent({
			touchInTarget = true,
			name = var_0_0.PRESSED_EVENT,
			x = var_19_1,
			y = var_19_2
		})

		if arg_19_0.longTouchEnabled_ then
			arg_19_0.isTouchHold_ = true
			arg_19_0.isLongTouched_ = false
			arg_19_0.longTouchHandle_ = var_0_4.performWithDelayGlobal(function()
				if arg_19_0.isTouchHold_ then
					arg_19_0.isLongTouched_ = true

					arg_19_0:dispatchEvent({
						touchInTarget = true,
						name = var_0_0.LONG_TOUCH_EVENT,
						x = var_19_1,
						y = var_19_2
					})
				end
			end, var_0_0.LONG_TOUCH_INTERVAL)
		end

		return true
	end

	local var_19_3 = arg_19_0:checkTouchInSprite_(arg_19_0.touchBeganX, arg_19_0.touchBeganY) and arg_19_0:checkTouchInSprite_(var_19_1, var_19_2)

	if var_19_0 == "moved" then
		if var_19_3 and arg_19_0.fsm_:canDoEvent("press") then
			arg_19_0.fsm_:doEvent("press")
			arg_19_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_0.PRESSED_EVENT,
				x = var_19_1,
				y = var_19_2
			})
		elseif not var_19_3 and arg_19_0.fsm_:canDoEvent("release") then
			arg_19_0.fsm_:doEvent("release")
			arg_19_0:dispatchEvent({
				touchInTarget = false,
				name = var_0_0.RELEASE_EVENT,
				x = var_19_1,
				y = var_19_2
			})
		end

		if arg_19_0.longTouchEnabled_ and (math.abs(var_19_1 - arg_19_0.touchBeganX) > var_0_0.LONG_TOUCH_THRESHOLD or math.abs(var_19_2 - arg_19_0.touchBeganY) > var_0_0.LONG_TOUCH_THRESHOLD) then
			arg_19_0.isTouchHold_ = false

			if arg_19_0.longTouchHandle_ then
				var_0_4.unscheduleGlobal(arg_19_0.longTouchHandle_)
			end
		end
	else
		if arg_19_0.fsm_:canDoEvent("release") then
			arg_19_0.fsm_:doEvent("release")
			arg_19_0:dispatchEvent({
				name = var_0_0.RELEASE_EVENT,
				x = var_19_1,
				y = var_19_2,
				touchInTarget = var_19_3
			})
		end

		if var_19_0 == "ended" and var_19_3 then
			arg_19_0:dispatchEvent({
				touchInTarget = true,
				name = var_0_0.CLICKED_EVENT,
				x = var_19_1,
				y = var_19_2
			})
		end

		if arg_19_0.longTouchEnabled_ then
			arg_19_0.isTouchHold_ = false

			if arg_19_0.longTouchHandle_ then
				var_0_4.unscheduleGlobal(arg_19_0.longTouchHandle_)
			end
		end
	end
end

function var_0_0.checkTouchInSprite_(arg_21_0, arg_21_1, arg_21_2)
	return arg_21_0:getCascadeBoundingBox():containsPoint(cc.p(arg_21_1, arg_21_2))
end

return var_0_0
