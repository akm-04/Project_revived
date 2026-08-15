local var_0_0 = class("NewLoadingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = {
	squat = 30,
	slip = 100,
	stand = 60
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.count_ = 0
	arg_1_0.delay = arg_1_2.delay or 1.5

	arg_1_0:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	var_2_0:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
	var_2_0:setPosition(cc.p(0, 0))
	arg_2_0:addChild(var_2_0)

	local function var_2_1(arg_3_0, arg_3_1)
		return true
	end

	local var_2_2 = cc.EventListenerTouchOneByOne:create()

	var_2_2:setSwallowTouches(true)
	var_2_2:registerScriptHandler(var_2_1, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_2_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_2_2, arg_2_0)

	arg_2_0.bgNode = display.newNode()

	arg_2_0.bgNode:addTo(var_2_0)
	arg_2_0.bgNode:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2))
	arg_2_0.bgNode:setVisible(true)
	arg_2_0.bgNode:runAction(cc.Sequence:create({
		cc.DelayTime:create(arg_2_0.delay),
		cc.CallFunc:create(function()
			arg_2_0.bgNode:setVisible(true)
		end)
	}))
	arg_2_0.bgNode:retain()

	arg_2_0.retainBg = arg_2_0.bgNode

	arg_2_0.bgNode:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2 - 130))

	local var_2_3 = xyd.AssetLoader:get():loadSprite("windows/new_loading/box_bottom.png")

	var_2_3:setAnchorPoint(0.5, 0)
	var_2_3:addTo(arg_2_0.bgNode, -3)
	var_2_3:setPosition(0, 0)

	local var_2_4 = xyd.AssetLoader:get():loadSprite("windows/new_loading/water_cliper.png")

	var_2_4:setAnchorPoint(0.5, 0)

	arg_2_0.clipper = cc.ClippingNode:create()

	arg_2_0.clipper:setStencil(var_2_4)
	arg_2_0.clipper:setInverted(false)
	arg_2_0.clipper:setAlphaThreshold(0)
	arg_2_0.bgNode:addChild(arg_2_0.clipper, -1)

	local var_2_5 = "windows/new_loading/water_after"

	arg_2_0.waterAfterEffect = var_0_1.new(var_2_5 .. ".json", var_2_5 .. ".atlas", 1)

	arg_2_0.waterAfterEffect:setAnchorPoint(cc.p(0.5, 0))
	arg_2_0.waterAfterEffect:addTo(arg_2_0.clipper)
	arg_2_0.waterAfterEffect:setPosition(0, 0)
	arg_2_0.waterAfterEffect:play(nil, true)

	local var_2_6 = "windows/new_loading/jelly_squat"

	arg_2_0.heroEffect1 = var_0_1.new(var_2_6 .. ".json", var_2_6 .. ".atlas", 1)

	arg_2_0.heroEffect1:setAnchorPoint(cc.p(0, 0))
	arg_2_0.heroEffect1:addTo(arg_2_0.clipper)
	arg_2_0.heroEffect1:setPosition(0, 0)
	arg_2_0.heroEffect1:play(nil, true)

	local var_2_7 = "windows/new_loading/jelly_stand"

	arg_2_0.heroEffect2 = var_0_1.new(var_2_7 .. ".json", var_2_7 .. ".atlas", 1)

	arg_2_0.heroEffect2:setAnchorPoint(cc.p(0, 0))
	arg_2_0.heroEffect2:addTo(arg_2_0.clipper)
	arg_2_0.heroEffect2:setPosition(0, 0)
	arg_2_0.heroEffect2:play(nil, true)
	arg_2_0.heroEffect2:setVisible(false)

	local var_2_8 = "windows/new_loading/jelly_slip"

	arg_2_0.heroEffect3 = var_0_1.new(var_2_8 .. ".json", var_2_8 .. ".atlas", 1)

	arg_2_0.heroEffect3:setAnchorPoint(cc.p(0, 0))
	arg_2_0.heroEffect3:addTo(arg_2_0.clipper)
	arg_2_0.heroEffect3:setPosition(0, 0)
	arg_2_0.heroEffect3:play(nil, true)
	arg_2_0.heroEffect3:setVisible(false)

	local var_2_9 = xyd.AssetLoader.get():loadSprite("windows/new_loading/water.png")

	arg_2_0.bar = display.newProgressTimer(var_2_9, display.PROGRESS_TIMER_BAR):addTo(arg_2_0.clipper, -1)

	arg_2_0.bar:setAnchorPoint(cc.p(0.5, 0))
	arg_2_0.bar:setMidpoint(cc.p(0.5, 0))
	arg_2_0.bar:setBarChangeRate(cc.p(0, 1))
	arg_2_0.bar:setPercentage(0)

	local var_2_10 = "windows/new_loading/water_before"

	arg_2_0.waterBeforeEffect = var_0_1.new(var_2_10 .. ".json", var_2_10 .. ".atlas", 1)

	arg_2_0.waterBeforeEffect:setAnchorPoint(cc.p(0.5, 0))
	arg_2_0.waterBeforeEffect:addTo(arg_2_0.clipper)
	arg_2_0.waterBeforeEffect:setPosition(0, 0)
	arg_2_0.waterBeforeEffect:play(nil, true)

	local var_2_11 = xyd.AssetLoader:get():loadSprite("windows/new_loading/box_back.png")

	var_2_11:setAnchorPoint(0.5, 0)
	var_2_11:addTo(arg_2_0.bgNode)
	var_2_11:setPosition(0, 0)

	local var_2_12 = xyd.AssetLoader:get():loadSprite("windows/new_loading/box.png")

	var_2_12:setAnchorPoint(0.5, 0)
	var_2_12:addTo(arg_2_0.bgNode)
	var_2_12:setPosition(-4, -3)

	local var_2_13 = {
		text = "",
		font = "windows/new_loading/blue.fnt"
	}

	arg_2_0.label = display.newBMFontLabel(var_2_13)

	arg_2_0.label:addTo(arg_2_0.bgNode)
	arg_2_0.label:setName("percent")
	arg_2_0.label:setAnchorPoint(0.5, 0.5)
	arg_2_0.label:setPosition(0, -30)
	arg_2_0.label:setString("")
	arg_2_0.label:setVisible(false)
end

function var_0_0.isAnimated(arg_5_0)
	return arg_5_0.bgNode:isVisible() and arg_5_0.waterBeforeEffect
end

function var_0_0.setPercent(arg_6_0, arg_6_1)
	if arg_6_0.lastPer and math.abs(arg_6_0.lastPer - arg_6_1) <= 2 then
		return
	end

	arg_6_0.lastPer = arg_6_1

	if arg_6_0.bar and not tolua.isnull(arg_6_0.bar) and math.abs(arg_6_0.bar:getPercentage() - arg_6_1) <= 2 then
		return
	end

	arg_6_0.label:setVisible(true)
	arg_6_0.label:setString(string.format(var_0_3:translation("LOADING_PERCENT_TEXT"), arg_6_1))

	if arg_6_1 <= var_0_4.squat then
		arg_6_0.heroEffect1:setVisible(true)
		arg_6_0.heroEffect2:setVisible(false)
		arg_6_0.heroEffect3:setVisible(false)
	elseif arg_6_1 <= var_0_4.stand then
		arg_6_0.heroEffect1:setVisible(false)
		arg_6_0.heroEffect2:setVisible(true)
		arg_6_0.heroEffect3:setVisible(false)
	elseif arg_6_1 <= var_0_4.slip then
		arg_6_0.heroEffect1:setVisible(false)
		arg_6_0.heroEffect2:setVisible(false)
		arg_6_0.heroEffect3:setVisible(true)
	end

	if arg_6_0.bar and not tolua.isnull(arg_6_0.bar) then
		arg_6_0.bar:stopAllActions()
		arg_6_0.bar:runActionOnce(cc.ProgressTo:create(0.05, arg_6_1), false)
	end

	arg_6_0.waterAfterEffect:stopAllActions()
	arg_6_0.waterBeforeEffect:stopAllActions()

	local var_6_0 = cc.Sequence:create({
		cc.Spawn:create({
			cc.MoveTo:create(0.05, cc.p(0, arg_6_1 / 100 * 150))
		})
	})
	local var_6_1 = cc.Sequence:create({
		cc.Spawn:create({
			cc.MoveTo:create(0.05, cc.p(0, arg_6_1 / 100 * 150))
		})
	})

	arg_6_0.waterAfterEffect:runActionOnce(var_6_0)
	arg_6_0.waterBeforeEffect:runActionOnce(var_6_1)
end

function var_0_0.willClose(arg_7_0)
	arg_7_0.retainBg:release()
end

function var_0_0.closeWindow(arg_8_0)
	xyd.WindowManager.get():closeWindow(arg_8_0.name)
end

return var_0_0
