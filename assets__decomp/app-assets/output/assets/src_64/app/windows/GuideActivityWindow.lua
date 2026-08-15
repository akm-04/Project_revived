local var_0_0 = class("GuideActivityWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")

var_0_0.TIPS_TIME = 1.5
var_0_0.FADEOUT_DELAY = 0.5

local var_0_2 = 10001001

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setContentSize(3000, 3000)

	arg_2_0.tipsSchedulerHandlers_ = {}

	local function var_2_0(arg_3_0, arg_3_1)
		xyd.WindowManager.get():closeWindow(arg_2_0)
	end

	local var_2_1 = cc.EventListenerTouchOneByOne:create()

	var_2_1:setSwallowTouches(true)
	var_2_1:registerScriptHandler(var_2_0, cc.Handler.EVENT_TOUCH_BEGAN)
	cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(var_2_1, arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.arrow_ = arg_4_0:nodeByName("arrow")
	arg_4_0.arrow1_ = arg_4_0:nodeByName("arrow1")

	arg_4_0.arrow_:setVisible(false)
	arg_4_0.arrow1_:setVisible(false)

	arg_4_0.content_ = arg_4_0:nodeByName("container")
end

function var_0_0.addNode(arg_5_0)
	arg_5_0:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(arg_6_0)
		if not arg_5_0:isTouchInContent(arg_6_0.x, arg_6_0.y) then
			return true
		end
	end)
end

function var_0_0.isTouchInContent(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = cc.Director:getInstance():getVisibleSize()
	local var_7_1 = (var_7_0.width - xyd.STAGE_WIDTH) / 2
	local var_7_2 = (var_7_0.height - xyd.STAGE_HEIGHT) / 2

	arg_7_1 = arg_7_1 - var_7_1
	arg_7_2 = arg_7_2 - var_7_2

	local var_7_3 = arg_7_0.content_:getPositionX() - arg_7_0.content_:getContentSize().width / 2
	local var_7_4 = arg_7_0.content_:getPositionX() + arg_7_0.content_:getContentSize().width / 2
	local var_7_5 = arg_7_0.content_:getPositionY() + arg_7_0.content_:getContentSize().height / 2
	local var_7_6 = arg_7_0.content_:getPositionY() - arg_7_0.content_:getContentSize().height / 2

	if arg_7_1 < var_7_4 and var_7_3 < arg_7_1 and var_7_6 < arg_7_2 and arg_7_2 < var_7_5 then
		return true
	end

	return false
end

function var_0_0.setStencil(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7, arg_8_8)
	dump(guideId)
	dump(arg_8_1)

	if arg_8_1 then
		local var_8_0 = false
		local var_8_1 = {
			600,
			300
		}

		if arg_8_7 then
			var_8_1 = arg_8_7.position or var_8_1
			var_8_0 = arg_8_7.right or var_8_0
		end

		if arg_8_0.tipWindow then
			arg_8_0.tipWindow:setVisible(true)
		else
			arg_8_0.tipWindow = import("app.common.ui.BaseWindow"):new()

			arg_8_0.tipWindow:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_tip.csb"))
			arg_8_0.tipWindow:addTo(arg_8_0)

			local var_8_2 = xyd.AssetLoader:get():loadSprite("windows/guide_window/guide_clip.png")

			var_8_2:setAnchorPoint(0.5, 1)
			var_8_2:setPosition(0, -120)

			local var_8_3 = cc.ClippingNode:create()

			var_8_3:setStencil(var_8_2)
			var_8_3:setInverted(true)
			var_8_3:setAlphaThreshold(0)
			arg_8_0.tipWindow:nodeByName("card_pos"):addChild(var_8_3)

			local var_8_4 = xyd.tables.skinDynamic:path(var_0_2)
			local var_8_5 = xyd.tables.misc:getValue("guide_scailing")
			local var_8_6 = xyd.tables.misc:getValue("guide_location")

			xyd.EffectLoader.new(var_8_4, 3, var_8_5, {
				x = var_8_6[1],
				y = var_8_6[2]
			}):addTo(var_8_3)
		end

		arg_8_0.tipWindow:nodeByName("guide_tip"):setVisible(false)
		arg_8_0.tipWindow:setPosition(cc.p(var_8_1[1], var_8_1[2]))
		arg_8_0.tipWindow:nodeByName("tip_txt"):setString(arg_8_1)
		arg_8_0.tipWindow:nodeByName("tip_txt"):setPositionX(arg_8_0.tipWindow:nodeByName("tip_txt"):getPositionX() - 50)

		local var_8_7 = xyd.createMultiLineMultiColorTxt(arg_8_1, cc.c3b(105, 64, 28), 24, false)

		var_8_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_7:addTo(arg_8_0.tipWindow)
		var_8_7:setPosition(arg_8_0.tipWindow:nodeByName("tip_txt"):getPosition())
		arg_8_0.tipWindow:nodeByName("tip_txt"):setVisible(false)

		if var_8_0 then
			arg_8_0.tipWindow:nodeByName("tip_bg"):setFlippedX(true)
			arg_8_0.tipWindow:nodeByName("guide_tip"):setFlippedX(true)
			var_8_7:setPositionX(var_8_7:getPositionX() + 50)
		else
			arg_8_0.tipWindow:nodeByName("tip_bg"):setFlippedX(false)
			arg_8_0.tipWindow:nodeByName("guide_tip"):setFlippedX(false)
			var_8_7:setPositionX(var_8_7:getPositionX() + 5)
		end
	elseif arg_8_0.tipWindow then
		arg_8_0.tipWindow:setVisible(false)
	end

	arg_8_0.scale_ = true

	arg_8_0.content_:setContentSize(arg_8_2, arg_8_3)
	arg_8_0.content_:setPosition(cc.p(arg_8_4, arg_8_5))

	if arg_8_7 and arg_8_7.main_scene then
		local var_8_8 = xyd.AssetLoader:get():loadSprite("windows/guide_window/main_clip.png")
		local var_8_9 = var_8_8:getContentSize()

		var_8_8:setScale(arg_8_2 / var_8_9.width, arg_8_3 / var_8_9.height)
		var_8_8:setAnchorPoint(0.5, 0.5)
		var_8_8:setPosition(arg_8_4, arg_8_5)

		local var_8_10 = cc.ClippingNode:create()

		var_8_10:setStencil(var_8_8)
		var_8_10:setInverted(true)
		var_8_10:setAlphaThreshold(0.5)
		var_8_10:addTo(arg_8_0, -1)

		arg_8_0.layer = display.newColorLayer(cc.c4b(0, 0, 0, 150))

		arg_8_0.layer:addTo(var_8_10)
		arg_8_0.layer:setPosition(0, 0)
		arg_8_0.layer:setContentSize(1280, 720)

		local var_8_11 = xyd.createEffect("skeletons/ui_effect/guide/guide_click")

		var_8_11:play(nil, true)
		var_8_11:addTo(arg_8_0)
		var_8_11:setPosition(arg_8_4, arg_8_5)
		var_8_11:setRotation(arg_8_6)

		if arg_8_7.effect_pos then
			var_8_11:runAction(cc.MoveBy:create(0, arg_8_7.effect_pos))
		end

		return
	end

	if arg_8_7 and arg_8_7.rect then
		arg_8_0.border = arg_8_0:nodeByName("guide_rect")
	elseif arg_8_7 and arg_8_7.machine1 then
		arg_8_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine1.png")

		arg_8_0.border:addTo(arg_8_0:nodeByName("container"))
		arg_8_0.border:setAnchorPoint(0.5, 0.5)
	elseif arg_8_7 and arg_8_7.machine2 then
		arg_8_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine2.png")

		arg_8_0.border:addTo(arg_8_0:nodeByName("container"))
		arg_8_0.border:setAnchorPoint(0.5, 0.5)
	else
		arg_8_0.border = arg_8_0:nodeByName("guide_circle")
	end

	arg_8_0.border:setContentSize(arg_8_2, arg_8_3)
	arg_8_0.border:setPosition(arg_8_2 / 2, arg_8_3 / 2)
	arg_8_0.border:setVisible(true)

	local var_8_12 = transition.sequence({
		cc.ScaleTo:create(1, (arg_8_2 + 50) / arg_8_2, (arg_8_3 + 50) / arg_8_3),
		cc.ScaleTo:create(1, 1)
	})
	local var_8_13 = cc.RepeatForever:create(var_8_12)

	arg_8_0.border:runAction(var_8_13)

	if arg_8_6 == 0 then
		arg_8_0.arrow_:setVisible(true)
		arg_8_0.arrow1_:setVisible(false)
		arg_8_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow_:setPosition(cc.p(arg_8_4, arg_8_5 + arg_8_3 / 2 + 10))
		arg_8_0.arrow_:setFlippedY(false)
	elseif arg_8_6 == 1 then
		arg_8_0.arrow_:setVisible(true)
		arg_8_0.arrow1_:setVisible(false)
		arg_8_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow_:setPosition(cc.p(arg_8_4, arg_8_5 - arg_8_3 / 2 - 10))
		arg_8_0.arrow_:setFlippedY(true)
	elseif arg_8_6 == 2 then
		arg_8_0.arrow1_:setVisible(true)
		arg_8_0.arrow_:setFlippedY(false)
		arg_8_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow1_:setPosition(cc.p(arg_8_4 - arg_8_2 / 2 - 10, arg_8_5))
	elseif arg_8_6 == 3 then
		arg_8_0.arrow_:setVisible(false)
		arg_8_0.arrow1_:setVisible(true)
		arg_8_0.arrow1_:setFlippedY(true)
		arg_8_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow1_:setPosition(cc.p(arg_8_4 + arg_8_2 / 2 + 10, arg_8_5))
	end

	if arg_8_8 then
		arg_8_0.arrow_:setPositionY(arg_8_0.arrow_:getPositionY() + arg_8_8)
	end

	arg_8_0:arrowAnimation(arg_8_6)
end

function var_0_0.arrowAnimation(arg_9_0, arg_9_1)
	if arg_9_0.scale_ then
		if arg_9_1 == 0 or arg_9_1 == 1 then
			local var_9_0 = cc.p(0, 20)
			local var_9_1 = cc.MoveBy:create(0.5, var_9_0)

			arg_9_0.arrow_:runAction(cc.RepeatForever:create(cc.Sequence:create(var_9_1, var_9_1:reverse(), nil)))
		elseif arg_9_1 == 2 or arg_9_1 == 3 then
			local var_9_2 = cc.p(-20, 0)
			local var_9_3 = cc.MoveBy:create(0.5, var_9_2)

			arg_9_0.arrow1_:runAction(cc.RepeatForever:create(cc.Sequence:create(var_9_3, var_9_3:reverse(), nil)))
		end
	end
end

function var_0_0.didClose(arg_10_0)
	var_0_0.super.didClose(arg_10_0, params)
end

return var_0_0
