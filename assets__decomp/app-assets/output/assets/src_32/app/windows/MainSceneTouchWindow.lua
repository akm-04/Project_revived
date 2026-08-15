local var_0_0 = class("MainSceneTouchWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("app.common.ui.SpriteNodeButton")
local var_0_4 = xyd.tables.translation
local var_0_5 = 60
local var_0_6 = {
	HIDE = false,
	SHOW = true
}
local var_0_7 = {
	HIDE = false,
	SHOW = true
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	arg_1_0.isAnimation = false
	arg_1_0.windowStyle = var_0_7.SHOW
	arg_1_0.touchPoints = {}
	arg_1_0.touchPoints[1] = {}
	arg_1_0.touchPoints[2] = {}
	arg_1_0.autoCount = 0
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:initMainSceneTouch()
	arg_2_0:autoPlayHide()
	xyd.EventDispatcher.get():addEventListener(xyd.event.TOUCH_VISIBLE, function(arg_3_0)
		if tolua.isnull(arg_2_0) then
			return
		end

		arg_2_0:hideTouch(arg_3_0.show)
		arg_2_0:autoPlayHide()
	end)
end

function var_0_0.didOpen(arg_4_0)
	var_0_1.performWithDelayGlobal(function()
		if arg_4_0 and not tolua.isnull(arg_4_0) then
			arg_4_0:hidewindow(false)
		end
	end, 0.2)
end

function var_0_0.hidewindow(arg_6_0, arg_6_1)
	local var_6_0 = xyd.WindowManager.get():getWindow("main_scene_touch")

	if var_6_0 and not tolua.isnull(var_6_0) then
		var_6_0:setVisible(arg_6_1)
	end
end

function var_0_0.hideTouch(arg_7_0, arg_7_1)
	arg_7_0:nodeByName("container"):setVisible(arg_7_1)
end

function var_0_0.layout(arg_8_0)
	arg_8_0:nodeByName("container"):setTouchEnabled(true)
	arg_8_0:nodeByName("container"):setTouchSwallowEnabled(false)
	arg_8_0:nodeByName("btn_close"):setVisible(false)

	local var_8_0 = var_0_3.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_8_0:addTo(arg_8_0:nodeByName("btn_close"))
	var_8_0:setAnchorPoint(0.5, 0.5)
	var_8_0:setPosition(41, 28)
	var_8_0:setName("return_btn")

	arg_8_0.children_.return_btn = var_8_0

	var_8_0:addTouchEvent(function(arg_9_0)
		if arg_9_0.name == "ended" and not arg_8_0.isAnimation then
			arg_8_0:playHide()
		end
	end)
end

function var_0_0.initMainSceneTouch(arg_10_0)
	arg_10_0.blockLayer_ = display.newNode()

	local var_10_0 = arg_10_0:convertToWorldSpace(cc.p(0, 0))

	arg_10_0.blockLayer_:pos(0, 0):addTo(arg_10_0:nodeByName("container"), 100)
	arg_10_0.blockLayer_:setContentSize(cc.size(400, 400))
	arg_10_0.blockLayer_:setAllAtOnceTouchEnabled(true)
	arg_10_0.blockLayer_:setLocalZOrder(99)
	arg_10_0.blockLayer_:setTouchSwallowEnabled(false)
	arg_10_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" or arg_11_0.name == "added" then
			for iter_11_0, iter_11_1 in pairs(arg_11_0.points) do
				table.insert(arg_10_0.touchPoints[1], iter_11_1)
			end

			return true
		elseif arg_11_0.name == "removed" then
			for iter_11_2, iter_11_3 in pairs(arg_11_0.points) do
				table.insert(arg_10_0.touchPoints[2], iter_11_3)
			end

			return true
		elseif arg_11_0.name == "ended" and not arg_10_0.isAnimation then
			for iter_11_4, iter_11_5 in pairs(arg_11_0.points) do
				table.insert(arg_10_0.touchPoints[2], iter_11_5)
			end

			local var_11_0, var_11_1 = arg_10_0:checkGestures()

			arg_10_0.touchPoints[1] = {}
			arg_10_0.touchPoints[2] = {}

			if var_11_0 and var_11_1 == arg_10_0.windowStyle then
				if arg_10_0.windowStyle == var_0_7.HIDE and arg_10_0.selfPlayer.firstMainTouch and arg_10_0.selfPlayer.firstMainTouch == 0 then
					xyd.Backend.get():request(xyd.mid.FIRST_MAIN_TOUCH, {}, function(arg_12_0, arg_12_1, arg_12_2)
						if arg_12_0 == xyd.error.OK then
							arg_10_0.selfPlayer.firstMainTouch = 1
						end

						arg_10_0:playHide()
					end)
				else
					arg_10_0:playHide()
				end
			end

			return true
		end
	end)
end

function var_0_0.playHide(arg_13_0)
	arg_13_0:playWindowMove(arg_13_0.windowStyle)

	arg_13_0.windowStyle = not arg_13_0.windowStyle

	var_0_1.performWithDelayGlobal(function()
		arg_13_0.isAnimation = false
		arg_13_0.autoCount = 0

		arg_13_0:updateBlockLayer()

		if arg_13_0.windowStyle == var_0_7.SHOW then
			arg_13_0:autoPlayHide()
		else
			arg_13_0:nodeByName("btn_close"):setVisible(true)
			arg_13_0:hidewindow(true)
		end

		arg_13_0:playGuide()
	end, 1.5)

	if arg_13_0.guideEffect then
		arg_13_0.guideEffect:removeSelf()

		arg_13_0.guideEffect = nil
	end

	if arg_13_0.textLabel then
		arg_13_0.textLabel:removeSelf()

		arg_13_0.textLabel = nil
	end

	arg_13_0:nodeByName("btn_close"):setVisible(false)
	arg_13_0:hidewindow(false)
end

function var_0_0.autoPlayHide(arg_15_0)
	if arg_15_0.autoHandle ~= nil then
		var_0_1.unscheduleGlobal(arg_15_0.autoHandle)

		arg_15_0.autoHandle = nil
	end

	if xyd.db.settings:getAutoStandby() == 0 then
		return
	end

	arg_15_0.autoHandle = var_0_1.scheduleGlobal(function()
		if arg_15_0 and not tolua.isnull(arg_15_0) and arg_15_0:nodeByName("container"):isVisible() then
			arg_15_0.autoCount = arg_15_0.autoCount + 1

			if arg_15_0.autoCount == var_0_5 and not arg_15_0.isAnimation then
				if arg_15_0.autoHandle ~= nil then
					var_0_1.unscheduleGlobal(arg_15_0.autoHandle)

					arg_15_0.autoHandle = nil
				end

				arg_15_0:playHide()
			end
		else
			arg_15_0.autoCount = 0

			if arg_15_0.autoHandle ~= nil then
				var_0_1.unscheduleGlobal(arg_15_0.autoHandle)

				arg_15_0.autoHandle = nil
			end
		end
	end, 1)
end

function var_0_0.updateBlockLayer(arg_17_0)
	if not arg_17_0.blockLayer_ then
		return
	end

	if arg_17_0.windowStyle == var_0_7.HIDE then
		arg_17_0:nodeByName("container"):setContentSize(1000, 500)
		arg_17_0.blockLayer_:setContentSize(1000, 500)
	else
		arg_17_0:nodeByName("container"):setContentSize(400, 400)
		arg_17_0.blockLayer_:setContentSize(400, 400)
	end
end

function var_0_0.checkGestures(arg_18_0)
	local function var_18_0(arg_19_0)
		local var_19_0 = 0

		for iter_19_0, iter_19_1 in pairs(arg_19_0) do
			var_19_0 = var_19_0 + 1
		end

		return var_19_0
	end

	if var_18_0(arg_18_0.touchPoints) ~= 2 or arg_18_0.isAnimation then
		arg_18_0.touchPoints = {}

		return false
	elseif var_18_0(arg_18_0.touchPoints[1]) ~= 2 or var_18_0(arg_18_0.touchPoints[2]) ~= 2 then
		arg_18_0.touchPoints = {}

		return false
	end

	local var_18_1 = arg_18_0.touchPoints[1]
	local var_18_2 = arg_18_0.touchPoints[2]

	local function var_18_3(arg_20_0)
		for iter_20_0, iter_20_1 in pairs(var_18_2) do
			if iter_20_1.id == arg_20_0 then
				return iter_20_1
			end
		end

		return nil
	end

	local var_18_4 = {}
	local var_18_5 = {}
	local var_18_6 = {}

	for iter_18_0, iter_18_1 in pairs(var_18_1) do
		local var_18_7 = var_18_3(iter_18_1.id)

		if var_18_7 then
			local var_18_8 = var_18_7.x - iter_18_1.x
			local var_18_9 = var_18_7.y - iter_18_1.y

			table.insert(var_18_5, {
				x = var_18_8,
				y = var_18_9
			})

			local var_18_10 = math.sqrt(var_18_8 * var_18_8 + var_18_9 * var_18_9)

			table.insert(var_18_4, var_18_10)
			table.insert(var_18_6, {
				beganPoint = iter_18_1,
				endPoint = var_18_7
			})
		end
	end

	if #var_18_5 ~= 2 then
		return false
	elseif var_18_5[1].x <= 0 and var_18_5[2].x <= 0 or var_18_5[1].y <= 0 and var_18_5[2].y <= 0 then
		return false
	elseif var_18_5[1].x >= 0 and var_18_5[2].x >= 0 or var_18_5[1].y >= 0 and var_18_5[2].y >= 0 then
		return false
	end

	local var_18_11 = math.abs(var_18_6[1].beganPoint.x - var_18_6[2].beganPoint.x)
	local var_18_12 = math.abs(var_18_6[1].endPoint.x - var_18_6[2].endPoint.x)
	local var_18_13 = var_0_6.HIDE

	if var_18_12 < var_18_11 then
		var_18_13 = var_0_6.HIDE
	else
		var_18_13 = var_0_6.SHOW
	end

	local var_18_14 = 0

	for iter_18_2 = 1, #var_18_4 do
		var_18_14 = var_18_14 + var_18_4[iter_18_2]
	end

	if var_18_14 >= 200 then
		return true, var_18_13
	end

	return false
end

function var_0_0.checkMoveStyle(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_1 < 0 and arg_21_2 < 0 then
		-- block empty
	elseif arg_21_1 < 0 and arg_21_2 > 0 then
		-- block empty
	end
end

function var_0_0.playWindowMove(arg_22_0, arg_22_1)
	arg_22_0.isAnimation = true

	local var_22_0 = xyd.WindowManager.get():getWindow("main_scene_middle")
	local var_22_1 = xyd.WindowManager.get():getWindow("main_scene_top")
	local var_22_2 = xyd.WindowManager.get():getWindow("main_scene_bottom")
	local var_22_3 = xyd.WindowManager.get():getWindow("main_scene_left")

	if not var_22_0 or not var_22_1 or not var_22_2 or not var_22_3 then
		return
	end

	if arg_22_1 then
		var_22_0:playWindowMove(arg_22_1)
		var_22_1:playWindowMove(arg_22_1)
		var_22_2:playWindowMove(arg_22_1)
		var_0_1.performWithDelayGlobal(function()
			var_22_0:hide()
			var_22_1:hide()
			var_22_2:hide()
			var_22_3:playWindowMove(arg_22_1)
		end, 0.5)
	else
		var_22_3:playWindowMove(arg_22_1)
		var_0_1.performWithDelayGlobal(function()
			var_22_0:show()
			var_22_1:show()
			var_22_2:show()
			var_22_0:playWindowMove(arg_22_1)
			var_22_1:playWindowMove(arg_22_1)
			var_22_2:playWindowMove(arg_22_1)
		end, 1)
	end
end

function var_0_0.playGuide(arg_25_0)
	if arg_25_0.selfPlayer.firstMainTouch == 0 and arg_25_0.windowStyle == var_0_7.HIDE then
		if not arg_25_0.guideEffect then
			local var_25_0 = "skeletons/ui_effect/interface_guide_point/interface_guide_point"
			local var_25_1 = var_25_0 .. ".json"
			local var_25_2 = var_25_0 .. ".atlas"

			arg_25_0.guideEffect = var_0_2.new(var_25_1, var_25_2, 1)

			arg_25_0.guideEffect:setAnchorPoint(cc.p(0.5, 0.5))
			arg_25_0.guideEffect:setPosition(400, 300)
			arg_25_0.guideEffect:addTo(arg_25_0:nodeByName("container"))
			arg_25_0.guideEffect:setLocalZOrder(1)
			arg_25_0.guideEffect:setTouchEnabled(true)
			arg_25_0.guideEffect:setTouchSwallowEnabled(false)

			local var_25_3 = {
				size = 24,
				text = var_0_4:translation("DOUBLE_FINGER_TIPS"),
				align = cc.ui.TEXT_ALIGN_CENTER,
				color = cc.c4b(255, 255, 255, 255)
			}

			arg_25_0.textLabel = xyd.AssetLoader.get():loadLabel(var_25_3)

			arg_25_0.textLabel:enableOutline(cc.c4b(255, 204, 204, 255), 1)
			arg_25_0.textLabel:addTo(arg_25_0:nodeByName("container"))
			arg_25_0.textLabel:setAnchorPoint(cc.p(0.5, 0.5))
			arg_25_0.textLabel:setPosition(cc.p(400, 200))
			arg_25_0.textLabel:setLocalZOrder(1)
			arg_25_0.textLabel:setTouchEnabled(true)
			arg_25_0.textLabel:setTouchSwallowEnabled(false)
		end

		arg_25_0.guideEffect:play(nil, true)
	end
end

return var_0_0
