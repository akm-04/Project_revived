local var_0_0 = class("FifthAnniStoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "fifth_anni_story"
local var_0_2 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.message = arg_1_2.message
	arg_1_0.delay = arg_1_2.delay or 1.5
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.canTouch = false
	arg_2_0.schedulerHandler = var_0_2.performWithDelayGlobal(function()
		arg_2_0.canTouch = true
	end, arg_2_0.delay)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = display.newNode()

	var_5_0:size(arg_5_0:getContentSize())
	var_5_0:setAnchorPoint(cc.p(0, 0))
	var_5_0:setPosition(cc.p(0, 0))
	var_5_0:addTo(arg_5_0, 1)
	var_5_0:setTouchEnabled(true)
	var_5_0:setTouchSwallowEnabled(false)
	var_5_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "ended" and arg_5_0.canTouch then
			xyd.WindowManager.get():closeWindow(var_0_1)
		end

		return true
	end)

	local var_5_1 = {
		color = cc.c3b(255, 255, 255),
		size = arg_5_0.txtSize or 28
	}

	arg_5_0.messageLabel = xyd.AssetLoader.get():loadLabel(var_5_1)

	arg_5_0.messageLabel:setAnchorPoint(0.5, 0.5)
	arg_5_0.messageLabel:setMaxLineWidth(700)
	arg_5_0.messageLabel:addTo(arg_5_0:nodeByName("text"))

	local var_5_2 = arg_5_0:nodeByName("text"):getContentSize()

	arg_5_0.messageLabel:setPosition(var_5_2.width / 2, var_5_2.height / 2)
	arg_5_0.messageLabel:setString(arg_5_0.message)
	arg_5_0:nodeByName("name_box1"):setVisible(false)
	arg_5_0:nodeByName("name_box2"):setVisible(false)
	arg_5_0:nodeByName("label_name1"):setVisible(false)
	arg_5_0:nodeByName("label_name2"):setVisible(false)
end

function var_0_0.didClose(arg_7_0)
	var_0_0.super.didClose()

	if arg_7_0.schedulerHandler ~= nil then
		var_0_2.unscheduleGlobal(arg_7_0.schedulerHandler)
	end

	if arg_7_0.callback then
		arg_7_0.callback()
	end
end

return var_0_0
