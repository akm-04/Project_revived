local var_0_0 = class("GuideOnlyDialogWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.callback = arg_1_2.callback
	arg_1_0.text = arg_1_2.text
	arg_1_0.tipPosition = arg_1_2.tipPosition
	arg_1_0.right = arg_1_2.right
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setOnlyDialogGuide(arg_4_0.text, arg_4_0.tipPosition, arg_4_0.right)

	arg_4_0.blockLayer_ = display.newNode()

	local var_4_0 = arg_4_0:convertToWorldSpace(cc.p(0, 0))

	arg_4_0.blockLayer_:pos(-var_4_0.x, -var_4_0.y):addTo(arg_4_0)
	arg_4_0.blockLayer_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_4_0.blockLayer_:setTouchEnabled(true)
	arg_4_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.setOnlyDialogGuide(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = arg_6_1
	local var_6_1 = xyd.StoryData.get():getGuideID()

	if not var_6_0 then
		var_6_0 = xyd.tables.guide:desc(var_6_1)

		if not var_6_0 then
			return
		end
	end

	local var_6_2 = xyd.AssetLoader:get():loadSprite("windows/guide_window/guide_clip.png")

	var_6_2:setAnchorPoint(0.5, 1)
	var_6_2:setPosition(0, -120)

	local var_6_3 = cc.ClippingNode:create()

	var_6_3:setStencil(var_6_2)
	var_6_3:setInverted(true)
	var_6_3:setAlphaThreshold(0)
	arg_6_0:nodeByName("card_pos"):addChild(var_6_3)

	local var_6_4 = 10001001
	local var_6_5 = xyd.tables.skinDynamic:path(var_6_4)
	local var_6_6 = xyd.tables.misc:getValue("guide_scailing")
	local var_6_7 = xyd.tables.misc:getValue("guide_location")

	xyd.EffectLoader.new(var_6_5, 5, var_6_6, {
		x = var_6_7[1],
		y = var_6_7[2]
	}):addTo(var_6_3)
	arg_6_0:nodeByName("tip_txt"):setString(var_6_0)
	arg_6_0:nodeByName("txt_bg1"):removeAllChildren()

	local var_6_8 = xyd.createMultiLineMultiColorTxt(var_6_0, cc.c3b(187, 93, 41), 20, false)

	var_6_8:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_8:addTo(arg_6_0:nodeByName("txt_bg1"))
	var_6_8:setPosition(cc.p(173, 51.5))
	arg_6_0:nodeByName("txt_bg"):setVisible(false)
	arg_6_0:nodeByName("txt_bg1"):setVisible(true)
	arg_6_0:nodeByName("guide_tip"):setVisible(false)
	arg_6_0:nodeByName("not_tip_bg"):setVisible(false)

	if arg_6_3 then
		arg_6_0:nodeByName("tip_bg"):setFlippedX(false)
		arg_6_0:nodeByName("txt_bg1"):setFlippedX(true)
	else
		arg_6_0:nodeByName("txt_bg1"):setFlippedX(true)
		arg_6_0:nodeByName("tip_bg"):setFlippedX(false)
	end

	if arg_6_2 then
		arg_6_0:nodeByName("tip_bg"):setPosition(cc.p(arg_6_2.x + 380, arg_6_2.y + 62))
	else
		arg_6_0:nodeByName("tip_bg"):setPosition(cc.p(580, 262))
	end
end

function var_0_0.didClose(arg_7_0, arg_7_1)
	var_0_0.super.didClose(arg_7_0, arg_7_1)

	if arg_7_0.callback then
		arg_7_0.callback()
	end
end

return var_0_0
