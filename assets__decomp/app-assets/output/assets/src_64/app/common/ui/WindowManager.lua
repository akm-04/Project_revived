local var_0_0 = class("WindowManager")

var_0_0.NUMBER_OF_LAYERS = 4
var_0_0.MODAL_LAYER_INDEX = 2
var_0_0.EXCEPT_WINDOW_NAME = "main_scene_top"
var_0_0.togetherNames = {
	"main_scene_top",
	"main_scene_right"
}

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	arg_2_0.layers_ = {}
	arg_2_0.windows_ = {}
	arg_2_0.windowsQueue_ = {}
	arg_2_0.windowHistory_ = {}
end

function var_0_0.isWindowOpen(arg_3_0, arg_3_1)
	return arg_3_0:getWindow(arg_3_1) ~= nil
end

function var_0_0.isWindowVisible(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:getWindow(arg_4_1)

	return var_4_0 ~= nil and var_4_0:isVisible()
end

function var_0_0.getWindow(arg_5_0, arg_5_1)
	return arg_5_0.windows_[arg_5_1]
end

function var_0_0.getWindowHistory(arg_6_0)
	return arg_6_0.windowHistory_
end

function var_0_0.addWindowHistory(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = (function(arg_8_0, arg_8_1)
		for iter_8_0 = 1, #arg_8_0 do
			if arg_8_0[iter_8_0].name == arg_8_1 then
				return iter_8_0
			end
		end

		return -1
	end)(arg_7_0.windowHistory_, arg_7_1)

	if var_7_0 > 0 then
		table.remove(arg_7_0.windowHistory_, var_7_0)
	end

	table.insert(arg_7_0.windowHistory_, {
		name = arg_7_1,
		params = arg_7_2,
		callback = arg_7_3
	})
end

function var_0_0.deleteWindowHistory(arg_9_0, arg_9_1)
	local var_9_0 = (function(arg_10_0, arg_10_1)
		for iter_10_0 = 1, #arg_10_0 do
			if arg_10_0[iter_10_0].name == arg_10_1 then
				return iter_10_0
			end
		end

		return -1
	end)(arg_9_0.windowHistory_, arg_9_1)

	if var_9_0 > 0 then
		table.remove(arg_9_0.windowHistory_, var_9_0)
	end
end

function var_0_0.openWindow(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if NO_CACHE_MODE and arg_11_1 ~= "new_loading" and arg_11_1 ~= "loading" and arg_11_1 ~= "toast" then
		cc.Director:getInstance():purgeCachedData()
		display.addSpriteFrames("windows/button/btn_plist.plist", "windows/button/btn_plist.png")
		display.addSpriteFrames("windows/main_top_window/main_top.plist", "windows/main_top_window/main_top.png")
	end

	dump(arg_11_1)

	local function var_11_0(arg_12_0)
		if arg_11_3 ~= nil then
			arg_11_3(arg_12_0)
		end

		arg_11_0:setBackground(arg_12_0, arg_11_1)
		arg_11_0:closeExceptWindow(arg_12_0, arg_11_1)
		arg_11_0:setHideWindows(arg_12_0, arg_11_1, false)
		arg_11_0:setSideWindows(arg_12_0, arg_11_1, false)
		arg_11_0:addWindowHistory(arg_11_1, arg_11_2, arg_11_3)
		arg_12_0:afterCompleteOpenWindow()

		return arg_12_0
	end

	if xyd.tables.window:hasWindow(arg_11_1) == nil then
		return var_11_0()
	end

	if arg_11_0.windows_[arg_11_1] ~= nil then
		return var_11_0(arg_11_0.windows_[arg_11_1])
	end

	local var_11_1 = import("app.windows." .. xyd.tables.window:className(arg_11_1)).new(arg_11_1, arg_11_2)

	var_11_1:retain()

	arg_11_0.windows_[arg_11_1] = var_11_1

	table.insert(arg_11_0.windowsQueue_, arg_11_1)
	xyd.AssetDownload.get():preloadWindowsByName(arg_11_1, function()
		var_11_1:loadRes()

		if not var_11_1.isLoaded then
			var_11_1:release()

			var_11_1 = nil
			arg_11_0.windows_[arg_11_1] = nil

			for iter_13_0 = 1, #arg_11_0.windowsQueue_ do
				if arg_11_0.windowsQueue_[iter_13_0] == arg_11_1 then
					table.remove(arg_11_0.windowsQueue_, iter_13_0)

					break
				end
			end

			return
		end

		var_11_1:willOpen(arg_11_2)

		local var_13_0 = var_11_1:getContentSize()

		var_13_0.width = math.min(var_13_0.width, xyd.STAGE_WIDTH)
		var_13_0.height = math.min(var_13_0.height, xyd.STAGE_HEIGHT)

		var_11_1:size(var_13_0.width, var_13_0.height)

		local var_13_1 = arg_11_0:getLayer_(var_11_1:windowType())

		if var_13_1:getParent() == nil then
			display.getRunningScene():addWindowLayer(var_13_1, var_11_1:windowType())
		end

		var_11_1:align(display.LEFT_BOTTOM, 0, 0)
		var_11_1:setPosition(arg_11_0:getWindowPosition_(var_11_1))
		var_11_1:addTo(var_13_1, var_11_1:priority())
		arg_11_0:playWindowOpenAnimations_(var_11_1, function()
			var_11_1:didOpen(arg_11_2)
			var_11_0(var_11_1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.WINDOW_DID_OPEN,
				windowName = arg_11_1
			})
		end)
		arg_11_0:checkBgEffectVisible()
		arg_11_0:checkHideTouchWindow()
	end)
	xyd.checkFirstInGuide(arg_11_1)

	return var_11_1
end

function var_0_0.openAnnotherWindow(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0
	local var_15_1 = arg_15_1

	if arg_15_2.cloneNum and arg_15_2.cloneNum ~= 0 then
		local var_15_2 = arg_15_2.cloneNum

		arg_15_1 = arg_15_1 .. var_15_2
	end

	local function var_15_3(arg_16_0)
		if arg_15_3 ~= nil then
			arg_15_3(arg_16_0)
		end

		arg_15_0:setBackground(arg_16_0, arg_15_1)
		arg_15_0:closeExceptWindow(arg_16_0, arg_15_1)
		arg_15_0:setHideWindows(arg_16_0, arg_15_1, false)
		arg_15_0:setSideWindows(arg_16_0, arg_15_1, false)
		arg_15_0:addWindowHistory(arg_15_1, arg_15_2, arg_15_3)

		return arg_16_0
	end

	if xyd.tables.window:hasWindow(arg_15_1) == nil then
		return var_15_3()
	end

	if arg_15_0.windows_[arg_15_1] ~= nil then
		return var_15_3(arg_15_0.windows_[arg_15_1])
	end

	local var_15_4 = import("app.windows." .. xyd.tables.window:className(var_15_1)).new(var_15_1, arg_15_2)

	var_15_4:retain()

	arg_15_0.windows_[arg_15_1] = var_15_4

	table.insert(arg_15_0.windowsQueue_, arg_15_1)
	xyd.AssetDownload.get():preloadWindowsByName(var_15_1, function()
		var_15_4:loadRes()

		if not var_15_4.isLoaded then
			var_15_4:release()

			var_15_4 = nil
			arg_15_0.windows_[arg_15_1] = nil

			for iter_17_0 = 1, #arg_15_0.windowsQueue_ do
				if arg_15_0.windowsQueue_[iter_17_0] == arg_15_1 then
					table.remove(arg_15_0.windowsQueue_, iter_17_0)

					break
				end
			end

			return
		end

		var_15_4:willOpen(arg_15_2)

		local var_17_0 = var_15_4:getContentSize()

		var_17_0.width = math.min(var_17_0.width, xyd.STAGE_WIDTH)
		var_17_0.height = math.min(var_17_0.height, xyd.STAGE_HEIGHT)

		var_15_4:size(var_17_0.width, var_17_0.height)

		local var_17_1 = arg_15_0:getLayer_(var_15_4:windowType())

		if var_17_1:getParent() == nil then
			display.getRunningScene():addWindowLayer(var_17_1, var_15_4:windowType())
		end

		var_15_4:align(display.LEFT_BOTTOM, 0, 0)
		var_15_4:setPosition(arg_15_0:getWindowPosition_(var_15_4))
		var_15_4:addTo(var_17_1, var_15_4:priority())
		arg_15_0:playWindowOpenAnimations_(var_15_4, function()
			var_15_4:didOpen(arg_15_2)
			var_15_3(var_15_4)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.WINDOW_DID_OPEN,
				windowName = arg_15_1
			})
		end)
		arg_15_0:checkBgEffectVisible()
		arg_15_0:checkHideTouchWindow()
	end)

	return var_15_4
end

function var_0_0.checkBgEffectVisible(arg_19_0)
	if arg_19_0.windows_ and next(arg_19_0.windows_) then
		local var_19_0 = true

		for iter_19_0, iter_19_1 in pairs(arg_19_0.windows_) do
			if xyd.tables.window:hideBgEffect(iter_19_0) == 1 then
				var_19_0 = false

				break
			end
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.BG_EFFECT_VISIBLE,
			show = var_19_0
		})
	end
end

function var_0_0.checkHideTouchWindow(arg_20_0)
	if arg_20_0.windows_ and next(arg_20_0.windows_) then
		local var_20_0 = true

		for iter_20_0, iter_20_1 in pairs(arg_20_0.windows_) do
			if xyd.tables.window:hideTouch(iter_20_0) == 1 then
				var_20_0 = false

				break
			end
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.TOUCH_VISIBLE,
			show = var_20_0
		})
	end
end

function var_0_0.setBackground(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_2 ~= var_0_0.EXCEPT_WINDOW_NAME and arg_21_0:getWindow(var_0_0.EXCEPT_WINDOW_NAME) ~= nil then
		arg_21_0:getWindow(var_0_0.EXCEPT_WINDOW_NAME):setBgVisible(arg_21_0:isShowBackground())
	end
end

function var_0_0.isShowBackground(arg_22_0)
	for iter_22_0, iter_22_1 in pairs(arg_22_0.windows_) do
		if iter_22_1:showBackground() then
			return true
		end
	end

	return false
end

function var_0_0.closeExceptWindow(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = {}

	for iter_23_0 = 1, #arg_23_0.windowHistory_ do
		local var_23_1 = arg_23_0.windowHistory_[iter_23_0]

		if arg_23_1:isExcept(var_23_1.name) then
			table.insert(var_23_0, var_23_1.name)
		end
	end

	for iter_23_1 = 1, #var_23_0 do
		arg_23_0:closeWindow(var_23_0[iter_23_1])
	end
end

function var_0_0.setSideWindows(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	if not arg_24_1 then
		return
	end

	if tonumber(arg_24_1:layoutType()) ~= 4 then
		return
	end

	local var_24_0 = {}

	for iter_24_0, iter_24_1 in pairs(arg_24_0.windows_) do
		if arg_24_1:isBySided(iter_24_1.name) and iter_24_1:isVisible() and arg_24_1:windowType() == iter_24_1:windowType() and tonumber(iter_24_1:layoutType()) == 4 then
			table.insert(var_24_0, iter_24_1)
		end
	end

	if #var_24_0 < 1 then
		return
	end

	if not arg_24_3 then
		table.insert(var_24_0, arg_24_1)
	end

	local var_24_1 = 0

	for iter_24_2, iter_24_3 in ipairs(var_24_0) do
		var_24_1 = var_24_1 + iter_24_3:getWidth()
	end

	local var_24_2 = var_24_1 + 20 * (#var_24_0 - 1)
	local var_24_3 = 0.5 * (xyd.STAGE_WIDTH - var_24_2)

	for iter_24_4, iter_24_5 in ipairs(var_24_0) do
		iter_24_5:x(var_24_3)
		iter_24_5:resetBlockLayer()

		var_24_3 = var_24_3 + iter_24_5:getWidth() + 20
	end
end

function var_0_0.setHideWindows(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	if arg_25_1 then
		arg_25_1:setVisible(not arg_25_3)
	end

	for iter_25_0 = #arg_25_0.windowHistory_, 1, -1 do
		local var_25_0 = arg_25_0.windowHistory_[iter_25_0]
		local var_25_1 = arg_25_0.windows_[var_25_0.name]

		if arg_25_1 and var_25_1 and arg_25_2 ~= var_25_1.name and arg_25_1:isHide(var_25_1.name) == true then
			if arg_25_3 == false then
				var_25_1:setVisible(arg_25_3)
				var_25_1:onHide()
			else
				local var_25_2 = false

				for iter_25_1 = #arg_25_0.windowHistory_, 1, -1 do
					local var_25_3 = arg_25_0.windowHistory_[iter_25_1]
					local var_25_4 = arg_25_0.windows_[var_25_3.name]

					if var_25_4 and var_25_1.name ~= var_25_4.name and var_25_4:isHide(var_25_1.name) == true then
						var_25_2 = true

						break
					end
				end

				if not var_25_2 then
					var_25_1:setVisible(arg_25_3)
					var_25_1:onAppear()
				end
			end
		elseif arg_25_1 and var_25_1 and arg_25_2 ~= var_25_1.name and arg_25_1:isShowWnd(var_25_1.name) == true then
			if arg_25_3 == false then
				var_25_1:setVisible(not arg_25_3)
				var_25_1:onAppear()
			else
				local var_25_5 = false

				for iter_25_2, iter_25_3 in pairs(arg_25_0.windows_) do
					if var_25_1.name ~= iter_25_3.name and iter_25_3:isHide(var_25_1.name) == true then
						var_25_5 = true

						break
					end
				end

				if var_25_5 then
					var_25_1:setVisible(not arg_25_3)
					var_25_1:onHide()
				end
			end
		end
	end
end

function var_0_0.closeWindow(arg_26_0, arg_26_1, arg_26_2, arg_26_3, arg_26_4)
	if not arg_26_1 then
		return
	end

	local var_26_0

	if type(arg_26_1) == "string" then
		var_26_0 = arg_26_1
	else
		var_26_0 = arg_26_1.name
	end

	local function var_26_1(arg_27_0)
		if arg_26_2 ~= nil then
			arg_26_2(arg_27_0)
		end

		arg_26_0:setBackground(arg_27_0, var_26_0)
		arg_26_0:setHideWindows(arg_27_0, var_26_0, true)
		arg_26_0:setSideWindows(arg_27_0, var_26_0, true)
		arg_26_0:deleteWindowHistory(var_26_0)
	end

	local var_26_2 = arg_26_0.windows_[var_26_0]

	if not var_26_2 or tolua.isnull(var_26_2) then
		return var_26_1()
	end

	for iter_26_0, iter_26_1 in ipairs(var_26_2:childWindowNames()) do
		arg_26_0:closeWindow(iter_26_1, nil, true, arg_26_4)
	end

	var_26_2:willClose(arg_26_4)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.WINDOW_WILL_CLOSE,
		windowName = var_26_0
	})

	local function var_26_3()
		var_26_2:removeSelf()

		arg_26_0.windows_[var_26_0] = nil

		for iter_28_0 = 1, #arg_26_0.windowsQueue_ do
			if arg_26_0.windowsQueue_[iter_28_0] == var_26_0 then
				table.remove(arg_26_0.windowsQueue_, iter_28_0)

				break
			end
		end

		local var_28_0 = arg_26_0:getLayer_(var_26_2:windowType())

		if var_28_0:getChildrenCount() <= 0 or var_26_2:windowType() == var_0_0.MODAL_LAYER_INDEX and var_28_0:getChildrenCount() <= 1 then
			var_28_0:removeSelf()
			var_28_0:release()

			arg_26_0.layers_[var_26_2:windowType()] = false
		end

		var_26_2:didClose(arg_26_4)
		var_26_1(var_26_2)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.WINDOW_DID_CLOSE,
			windowName = var_26_0
		})
		var_26_2:release()
		arg_26_0:checkHideTouchWindow()
	end

	var_26_2:stopAllActions()

	if arg_26_3 then
		var_26_3()
	else
		arg_26_0:playWindowCloseAnimations_(var_26_2, var_26_3)
	end

	arg_26_0:checkBgEffectVisible()
end

function var_0_0.closeAllWindows(arg_29_0)
	local var_29_0 = {}

	for iter_29_0 = 1, #arg_29_0.windowsQueue_ do
		arg_29_0:closeWindow(arg_29_0.windowsQueue_[1], nil, true, {
			close_all = true
		})
	end

	arg_29_0.windowHistory_ = {}
end

function var_0_0.closeAllWindowsForGuide(arg_30_0)
	local var_30_0 = {}

	for iter_30_0, iter_30_1 in pairs(arg_30_0.windows_) do
		table.insert(var_30_0, iter_30_0)
	end

	for iter_30_2, iter_30_3 in ipairs(var_30_0) do
		if iter_30_3 ~= "main_scene_top" and iter_30_3 ~= "main_scene_middle" and iter_30_3 ~= "main_scene_left" and iter_30_3 ~= "main_scene_bottom" then
			arg_30_0:closeWindow(iter_30_3, nil, true, {
				close_all = true
			})
		end
	end
end

function var_0_0.isInMainWindow(arg_31_0)
	local var_31_0 = {}

	for iter_31_0, iter_31_1 in pairs(arg_31_0.windows_) do
		table.insert(var_31_0, iter_31_0)
	end

	for iter_31_2, iter_31_3 in ipairs(var_31_0) do
		if iter_31_3 ~= "main_scene_top" and iter_31_3 ~= "main_scene_middle" and iter_31_3 ~= "main_scene_left" and iter_31_3 ~= "main_scene_bottom" and iter_31_3 ~= "main_scene_touch" then
			return false
		end
	end

	return true
end

function var_0_0.retainHistory(arg_32_0)
	arg_32_0.retainedHistory = clone(arg_32_0.windowHistory_)
end

function var_0_0.releaseRetainedHistory(arg_33_0)
	arg_33_0.retainedHistory = {}
end

function var_0_0.getRetainedHistory(arg_34_0)
	return arg_34_0.retainedHistory
end

function var_0_0.getLayer_(arg_35_0, arg_35_1)
	if not arg_35_0.layers_[arg_35_1] or tolua.isnull(arg_35_0.layers_[arg_35_1]) then
		arg_35_0.layers_[arg_35_1] = display.newNode():size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT):align(display.CENTER, 0.5 * xyd.STAGE_WIDTH, 0.5 * xyd.STAGE_HEIGHT)

		arg_35_0.layers_[arg_35_1]:retain()
	end

	if arg_35_1 == var_0_0.MODAL_LAYER_INDEX then
		arg_35_0.layers_[arg_35_1]:setTouchEnabled(true)
		arg_35_0.layers_[arg_35_1]:setTouchSwallowEnabled(true)

		if arg_35_0.layers_[arg_35_1].innerLayer == nil then
			arg_35_0.layers_[arg_35_1].innerLayer = ccui.Layout:create()

			arg_35_0.layers_[arg_35_1].innerLayer:setContentSize(arg_35_0.layers_[arg_35_1]:getContentSize())
			arg_35_0.layers_[arg_35_1].innerLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_35_0.layers_[arg_35_1], -1)
		end

		arg_35_0.layers_[arg_35_1].innerLayer:setTouchEnabled(true)
		arg_35_0.layers_[arg_35_1].innerLayer:setTouchSwallowEnabled(true)
	end

	return arg_35_0.layers_[arg_35_1]
end

function var_0_0.getWindowPosition_(arg_36_0, arg_36_1)
	local var_36_0 = arg_36_1:layoutType() % 3
	local var_36_1 = math.floor(arg_36_1:layoutType() / 3)
	local var_36_2 = 0
	local var_36_3 = 0

	if var_36_0 == 0 then
		var_36_2 = 0
	elseif var_36_0 == 1 then
		var_36_2 = 0.5 * (xyd.STAGE_WIDTH - arg_36_1:getContentSize().width)
	else
		var_36_2 = xyd.STAGE_WIDTH - arg_36_1:getContentSize().width
	end

	if var_36_1 == 0 then
		var_36_3 = xyd.STAGE_HEIGHT - arg_36_1:getContentSize().height
	elseif var_36_1 == 1 then
		var_36_3 = 0.5 * (xyd.STAGE_HEIGHT - arg_36_1:getContentSize().height)
	else
		var_36_3 = 0
	end

	return cc.pAdd(cc.p(var_36_2, var_36_3), arg_36_1:offset())
end

function var_0_0.playWindowOpenAnimations_(arg_37_0, arg_37_1, arg_37_2)
	arg_37_0:playWindowAnimations_(arg_37_1, xyd.tables.window:openAnimations(arg_37_1.name), arg_37_2)
end

function var_0_0.playWindowCloseAnimations_(arg_38_0, arg_38_1, arg_38_2)
	arg_38_0:playWindowAnimations_(arg_38_1, xyd.tables.window:closeAnimations(arg_38_1.name), arg_38_2)
end

function var_0_0.playWindowAnimations_(arg_39_0, arg_39_1, arg_39_2, arg_39_3)
	arg_39_1 = arg_39_1.contentView_

	local var_39_0 = 0.15
	local var_39_1 = {}

	for iter_39_0, iter_39_1 in ipairs(arg_39_2) do
		if iter_39_1 == xyd.WindowAnimation.FADE_IN then
			arg_39_1:setOpacity(0)
			table.insert(var_39_1, cc.FadeIn:create(var_39_0))
		elseif iter_39_1 == xyd.WindowAnimation.FADE_OUT then
			table.insert(var_39_1, cc.FadeOut:create(var_39_0))
		elseif iter_39_1 == xyd.WindowAnimation.BOX_IN then
			arg_39_1:setScale(0)
			table.insert(var_39_1, cc.EaseBackOut:create(cc.Spawn:create({
				cc.ScaleTo:create(var_39_0, 1)
			})))
		elseif iter_39_1 == xyd.WindowAnimation.BOX_OUT then
			table.insert(var_39_1, cc.EaseBackIn:create(cc.Spawn:create({
				cc.ScaleTo:create(var_39_0, 0)
			})))
		end
	end

	if #var_39_1 <= 0 then
		if arg_39_3 then
			arg_39_3()
		end
	elseif #var_39_1 == 1 then
		arg_39_1:runActionOnce(var_39_1[1], false, arg_39_3)
	else
		arg_39_1:runActionOnce(cc.Spawn:create(var_39_1), false, arg_39_3)
	end
end

function var_0_0.hasMajorWindow(arg_40_0)
	for iter_40_0, iter_40_1 in pairs(arg_40_0.windows_) do
		if iter_40_0 ~= "main_scene_top" and iter_40_0 ~= "main_scene_right" then
			return true
		end
	end

	return false
end

function var_0_0.hideAllWindows(arg_41_0)
	for iter_41_0, iter_41_1 in pairs(arg_41_0.windows_) do
		if not tolua.isnull(iter_41_1) then
			iter_41_1:hide()
		end
	end
end

return var_0_0
