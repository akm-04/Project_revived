local var_0_0 = class("MainSceneUpWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.posX = arg_1_2.posX
	arg_1_0.posY = arg_1_2.posY
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	if arg_2_0.player.isSigned == 0 then
		arg_2_0:nodeByName("sign_point"):setVisible(true)
	else
		arg_2_0:nodeByName("sign_point"):setVisible(false)
	end

	if arg_2_0.activities.isRedMark then
		arg_2_0:nodeByName("activities_point"):setVisible(true)
	else
		arg_2_0:nodeByName("activities_point"):setVisible(false)
	end

	if arg_2_0.player.isInviteAward == 1 then
		arg_2_0:nodeByName("invite_point"):setVisible(true)
	else
		arg_2_0:nodeByName("invite_point"):setVisible(false)
	end
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:setPosition(arg_3_0.posX, arg_3_0.posY)
	arg_3_0:nodeByName("sign_button"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("sign_in")
			xyd.WindowManager.get():closeWindow(arg_3_0)

			local var_4_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

			if var_4_0 then
				var_4_0:setPanelVisible(false)

				var_4_0.isPanelVisible = false
			end
		end
	end)
	arg_3_0:nodeByName("activities_button"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0.activities:loadActivities(function(arg_6_0)
				if arg_6_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("activities")
					xyd.WindowManager.get():closeWindow(arg_3_0.name)
				end
			end)

			local var_5_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

			if var_5_0 then
				var_5_0:setPanelVisible(false)

				var_5_0.isPanelVisible = false
			end
		end
	end)
	arg_3_0:nodeByName("invite_button"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_7_0()
				if not arg_3_0.player.playerName or arg_3_0.player.playerName == "" then
					xyd.WindowManager.get():openWindow("edit_player_name")
				end
			end

			xyd.WindowManager.get():openWindow("invite_friends", nil, var_7_0)
			xyd.WindowManager.get():closeWindow(arg_3_0)

			local var_7_1 = xyd.WindowManager.get():getWindow("main_scene_bottom")

			if var_7_1 then
				var_7_1:setPanelVisible(false)

				var_7_1.isPanelVisible = false
			end
		end
	end)
	arg_3_0:nodeByName("down_button"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_3_0)

			local var_9_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

			if var_9_0 then
				var_9_0:setPanelVisible(false)

				var_9_0.isPanelVisible = false
			end
		end
	end)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.addBlockLayer(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	if arg_10_1 == nil then
		arg_10_1 = cc.c4b(0, 0, 0, 200)
	end

	arg_10_0.blockLayer_ = display.newColorLayer(arg_10_1)

	local var_10_0 = arg_10_0:convertToWorldSpace(cc.p(0, 0))

	arg_10_0.blockLayer_:pos(-var_10_0.x, -var_10_0.y):addTo(arg_10_0, -1)

	local function var_10_1(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended and not arg_10_3 then
			local var_11_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_11_0, false)
			xyd.WindowManager.get():closeWindow(arg_10_0)
		end

		return true
	end

	local function var_10_2(arg_12_0, arg_12_1)
		if not arg_10_3 then
			local var_12_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_12_0, false)
			xyd.WindowManager.get():closeWindow(arg_10_0.name)

			local var_12_1 = xyd.WindowManager.get():getWindow("main_scene_bottom")

			if var_12_1 then
				var_12_1:setPanelVisible(false)

				var_12_1.isPanelVisible = false
			end
		end

		if arg_10_4 then
			arg_10_4()
		end
	end

	if not arg_10_2 then
		arg_10_0.layerListener = cc.EventListenerTouchOneByOne:create()

		arg_10_0.layerListener:setSwallowTouches(true)
		arg_10_0.layerListener:registerScriptHandler(var_10_1, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_10_0.layerListener:registerScriptHandler(var_10_2, cc.Handler.EVENT_TOUCH_ENDED)
		arg_10_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_10_0.layerListener, arg_10_0.contentView_)
	end
end

return var_0_0
