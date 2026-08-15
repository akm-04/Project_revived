local var_0_0 = class("ToastWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "toast"
local var_0_2 = import("framework.scheduler")

function var_0_0.open(arg_1_0, arg_1_1)
	arg_1_1 = arg_1_1 or {}
	arg_1_1.message = arg_1_0

	return xyd.WindowManager.get():openWindow(var_0_1, arg_1_1)
end

function var_0_0.close(arg_2_0)
	xyd.WindowManager.get():closeWindow(var_0_1, arg_2_0)
end

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2)
	var_0_0.super.ctor(arg_3_0, arg_3_1, arg_3_2)

	arg_3_0.message = arg_3_2.message
	arg_3_0.winPos = arg_3_2.pos
	arg_3_0.anchor = arg_3_2.anchor
	arg_3_0.delay = arg_3_2.delay or 1.5
	arg_3_0.txtSize = arg_3_2.txtSize or 28
	arg_3_0.isOutLine = arg_3_2.isOutLine or 1
	arg_3_0.isAutoClose = arg_3_2.isAutoClose or 1
	arg_3_0.callback = arg_3_2.callback
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)

	local var_4_0 = {
		color = cc.c3b(255, 255, 255),
		size = arg_4_0.txtSize
	}

	arg_4_0.messageLabel = xyd.AssetLoader.get():loadLabel(var_4_0)

	arg_4_0.messageLabel:setAnchorPoint(0.5, 0.5)
	arg_4_0.messageLabel:setMaxLineWidth(700)
	arg_4_0.messageLabel:addTo(arg_4_0)
	arg_4_0.messageLabel:setPosition(arg_4_0:nodeByName("container"):getPosition())
	arg_4_0.messageLabel:setString(arg_4_0.message)

	if arg_4_0.isOutLine == 1 then
		arg_4_0.messageLabel:enableOutline(cc.c4b(11, 11, 11, 255), 1)
	end

	local var_4_1 = arg_4_0.messageLabel:getContentSize().width
	local var_4_2 = arg_4_0.messageLabel:getContentSize().height

	arg_4_0:nodeByName("container"):setContentSize(var_4_1 + 60, var_4_2 + 30)
end

function var_0_0.getWndWidth(arg_5_0)
	return arg_5_0:nodeByName("container"):getContentSize().width
end

function var_0_0.getWndHeight(arg_6_0)
	return arg_6_0:nodeByName("container"):getContentSize().height
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super.didOpen(arg_7_0, arg_7_1)

	if arg_7_0.winPos and next(arg_7_0.winPos) then
		arg_7_0:setPosition(arg_7_0.winPos)
	else
		arg_7_0:setAnchorPoint(cc.p(0.5, 0.5))

		local var_7_0 = cc.Director:getInstance():getWinSize()

		arg_7_0:setPosition(xyd.convertWorldPos(var_7_0.width / 2, var_7_0.height / 2))
	end

	if arg_7_0.anchor and next(arg_7_0.anchor) then
		arg_7_0:setAnchorPoint(arg_7_0.anchor.x, arg_7_0.anchor.y)
	end

	if arg_7_0.isAutoClose == 1 then
		arg_7_0.schedulerHandler = var_0_2.performWithDelayGlobal(function()
			xyd.WindowManager.get():closeWindow(var_0_1)
		end, arg_7_0.delay)
	end
end

function var_0_0.didClose(arg_9_0)
	var_0_0.super.didClose()

	if arg_9_0.schedulerHandler ~= nil then
		var_0_2.unscheduleGlobal(arg_9_0.schedulerHandler)
	end

	if arg_9_0.callback then
		arg_9_0.callback()
	end
end

return var_0_0
