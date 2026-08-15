local var_0_0 = class("SelectKiteNumWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.idx
	arg_1_0.kiteTotalNum = arg_1_2.total_num
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = {
		50001091,
		50001092,
		50001093
	}

	xyd.setItemBorder(arg_3_0:nodeByName("item_container"), var_3_0[arg_3_0.id])

	local var_3_1 = 50

	if arg_3_0.kiteTotalNum == 1 then
		var_3_1 = 100
	end

	arg_3_0.sendNum = math.ceil(arg_3_0.kiteTotalNum * var_3_1 / 100)

	arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)

	local var_3_2 = cc.ui.UISlider.new(display.LEFT_TO_RIGHT, {
		bar = "windows/kite/scroll_bar_bg.png",
		button = "windows/kite/scorll_point.png"
	}, {
		scale9 = true
	}):setSliderValue(var_3_1):addTo(arg_3_0:nodeByName("slider_pos")):onSliderValueChanged(function(arg_4_0)
		local var_4_0 = arg_4_0.value * arg_3_0.kiteTotalNum / 100

		if var_4_0 < 1 then
			arg_3_0.sendNum = 1
		elseif var_4_0 > arg_3_0.kiteTotalNum then
			arg_3_0.sendNum = arg_3_0.kiteTotalNum
		else
			arg_3_0.sendNum = math.ceil(var_4_0)
		end

		arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)
	end)

	arg_3_0:nodeByName("undo_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {
				idx = arg_3_0.id,
				num = arg_3_0.sendNum
			}

			xyd.WindowManager.get():openWindow("send_kite", var_6_0)
		end
	end)
	arg_3_0:nodeByName("plus"):setTouchEnabled(true)
	arg_3_0:nodeByName("minus"):setTouchEnabled(true)
	arg_3_0:nodeByName("plus"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			arg_3_0.sendNum = math.min(arg_3_0.kiteTotalNum, arg_3_0.sendNum + 1)

			arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)
			var_3_2:setSliderValue(arg_3_0.sendNum * 100 / arg_3_0.kiteTotalNum)
		end
	end)
	arg_3_0:nodeByName("minus"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			arg_3_0.sendNum = math.max(1, arg_3_0.sendNum - 1)

			arg_3_0:nodeByName("num_txt"):setString(arg_3_0.sendNum)
			var_3_2:setSliderValue(arg_3_0.sendNum * 100 / arg_3_0.kiteTotalNum)
		end
	end)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

return var_0_0
