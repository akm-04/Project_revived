local var_0_0 = class("SendFireworkNumWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.id
	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.itemNum = arg_1_2.itemNum
	arg_1_0.cancelCallback = arg_1_2.cancelCallback
	arg_1_0.okCallback = arg_1_2.okCallback
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	xyd.setItemBorder(arg_3_0:nodeByName("item_container"), arg_3_0.itemID)

	local var_3_0 = 50

	if arg_3_0.itemNum == 1 then
		var_3_0 = 100
	end

	arg_3_0.sendNum = math.ceil(arg_3_0.itemNum * var_3_0 / 100)

	arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)

	local var_3_1 = cc.ui.UISlider.new(display.LEFT_TO_RIGHT, {
		bar = "windows/firework/firework_main/scroll_bar_bg.png",
		button = "windows/firework/firework_main/scorll_point.png"
	}, {
		scale9 = true
	}):setSliderValue(var_3_0):addTo(arg_3_0:nodeByName("slider_pos")):onSliderValueChanged(function(arg_4_0)
		local var_4_0 = arg_4_0.value * arg_3_0.itemNum / 100

		if var_4_0 < 1 then
			arg_3_0.sendNum = 1
		elseif var_4_0 > arg_3_0.itemNum then
			arg_3_0.sendNum = arg_3_0.itemNum
		else
			arg_3_0.sendNum = math.ceil(var_4_0)
		end

		arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)
	end)

	arg_3_0:nodeByName("undo_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)

			if xyd.WindowManager.get():getWindow("firework_main") and arg_3_0.cancelCallback then
				arg_3_0.cancelCallback()
			end

			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)

			local var_6_1 = {
				sendNum = arg_3_0.sendNum,
				id = arg_3_0.id,
				itemID = arg_3_0.itemID,
				itemNum = arg_3_0.itemNum
			}

			if xyd.WindowManager.get():getWindow("firework_main") and arg_3_0.okCallback then
				arg_3_0.okCallback(var_6_1)
			end

			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("plus"):setTouchEnabled(true)
	arg_3_0:nodeByName("minus"):setTouchEnabled(true)
	arg_3_0:nodeByName("plus"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			arg_3_0.sendNum = math.min(arg_3_0.itemNum, arg_3_0.sendNum + 1)

			arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)
			var_3_1:setSliderValue(arg_3_0.sendNum * 100 / arg_3_0.itemNum)
		end
	end)
	arg_3_0:nodeByName("minus"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			arg_3_0.sendNum = math.max(1, arg_3_0.sendNum - 1)

			arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)
			var_3_1:setSliderValue(arg_3_0.sendNum * 100 / arg_3_0.itemNum)
		end
	end)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

function var_0_0.willClose(arg_10_0, arg_10_1)
	var_0_0.super:willClose(arg_10_1)
end

return var_0_0
