local var_0_0 = class("BaseScene", function(arg_1_0)
	return display.newScene(arg_1_0)
end)
local var_0_1 = 10000

function var_0_0.ctor(arg_2_0)
	local var_2_0 = cc.Director:getInstance():getVisibleSize()
	local var_2_1 = cc.rect(0, 0, xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)

	arg_2_0.clippingNode_ = display.newClippingRegionNode(var_2_1):size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT):pos(0.5 * (var_2_0.width - xyd.STAGE_WIDTH), 0.5 * (var_2_0.height - xyd.STAGE_HEIGHT))

	arg_2_0:trueAddChild_(arg_2_0.clippingNode_, 0)

	if var_2_0.width > xyd.STAGE_WIDTH then
		local var_2_2 = xyd.AssetLoader.get():loadSprite("images/deco_left.png")

		var_2_2:setAnchorPoint(1, 0)
		var_2_2:pos(0.5 * (var_2_0.width - xyd.STAGE_WIDTH) + 1, 0)

		local var_2_3 = xyd.AssetLoader.get():loadSprite("images/deco_right.png")

		var_2_3:setAnchorPoint(0, 0)
		var_2_3:pos(0.5 * (var_2_0.width + xyd.STAGE_WIDTH) - 1, 0)
		arg_2_0:trueAddChild_(var_2_2, 1)
		arg_2_0:trueAddChild_(var_2_3, 1)
	end

	if var_2_0.height > xyd.STAGE_HEIGHT then
		local var_2_4 = xyd.AssetLoader.get():loadSprite("images/deco_top.png")

		var_2_4:setAnchorPoint(0, 0)
		var_2_4:pos(0, 0.5 * (var_2_0.height + xyd.STAGE_HEIGHT) - 1)

		local var_2_5 = xyd.AssetLoader.get():loadSprite("images/deco_bottom.png")

		var_2_5:setAnchorPoint(0, 1)
		var_2_5:pos(0, 0.5 * (var_2_0.height - xyd.STAGE_HEIGHT) + 1)
		arg_2_0:trueAddChild_(var_2_4, 1)
		arg_2_0:trueAddChild_(var_2_5, 1)
	end
end

function var_0_0.onEnterTransitionFinish(arg_3_0)
	arg_3_0:registerAndroidBackButton_()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.SHOW_BROADCAST, function(arg_4_0)
		local var_4_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.mainSceneTopWnd)

		if var_4_0 then
			var_4_0:showBroadcast(arg_4_0.params)
		end
	end)
end

function var_0_0.onExit(arg_5_0)
	xyd.WindowManager.get():closeAllWindows()

	for iter_5_0, iter_5_1 in pairs(xyd.WindowManager.get().layers_) do
		if iter_5_1 and not tolua.isnull(iter_5_1) then
			iter_5_1:release()

			iter_5_1 = false
		end
	end

	xyd.WindowManager.get().layers_ = {}
end

function var_0_0.getContentSize(arg_6_0)
	return arg_6_0.clippingNode_:getContentSize()
end

function var_0_0.addChild(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	arg_7_0.clippingNode_:addChild(arg_7_1, arg_7_2, arg_7_3)
end

function var_0_0.addWindowLayer(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1 == nil then
		return
	end

	arg_8_1:addTo(arg_8_0, var_0_1 + arg_8_2)
end

function var_0_0.trueAddChild_(arg_9_0, arg_9_1, arg_9_2)
	getmetatable(arg_9_0).addChild(arg_9_0, arg_9_1, arg_9_2)
end

function var_0_0.registerAndroidBackButton_(arg_10_0)
	if device.platform == "android" then
		arg_10_0:setKeypadEnabled(true)
		arg_10_0:addNodeEventListener(cc.KEYPAD_EVENT, function(arg_11_0)
			if arg_11_0.key == "back" then
				local var_11_0 = xyd.tables.translation:translation("EXIT_GAME_PROMPT")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_0, function()
					xyd.exitProgram()
				end)
			end
		end)
	end
end

function var_0_0.unregisterAndroidBackButton_(arg_13_0)
	if device.platform == "android" then
		arg_13_0:setKeypadEnabled(false)
		arg_13_0:removeNodeEventListenersByEvent(cc.KEYPAD_EVENT)
	end
end

return var_0_0
