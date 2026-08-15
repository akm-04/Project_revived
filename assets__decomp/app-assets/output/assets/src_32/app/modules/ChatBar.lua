local var_0_0 = class("ChatBar", function()
	return display.newNode()
end)
local var_0_1 = xyd.AssetLoader.get()
local var_0_2 = require("framework.scheduler")
local var_0_3 = "msg-tag"
local var_0_4 = 3
local var_0_5 = "chat"
local var_0_6 = 60

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:layout(arg_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	if arg_3_1 and arg_3_1.background then
		arg_3_0.background = arg_3_1.background
	else
		arg_3_0.background = var_0_1:loadSprite("images/chat_message_background.png", cc.rect(20, 19, 1, 1))
	end

	local var_3_0 = cc.Menu:create()

	var_3_0:setAnchorPoint(0, 0)
	var_3_0:pos(0, 0):addTo(arg_3_0, 10)

	if arg_3_1 and arg_3_1.chatIcon then
		arg_3_0.chatIcon_ = arg_3_1.chatIcon
	else
		arg_3_0.chatIcon_ = var_0_1:loadSprite("images/chat_icon.png")
	end

	local var_3_1 = cc.MenuItemSprite:create(arg_3_0.chatIcon_, arg_3_0.chatIcon_)

	arg_3_0:setContentSize(arg_3_0.background:getContentSize().width + var_3_1:getContentSize().width * 0.5, arg_3_0.background:getContentSize().height)
	arg_3_0.background:setAnchorPoint(0, 0)
	arg_3_0.background:pos(var_3_1:getContentSize().width * 0.5, 0):retain()
	var_3_1:setAnchorPoint(0, 0.5)
	var_3_1:pos(0, arg_3_0:getContentSize().height * 0.5):addTo(var_3_0)
	var_3_1:registerScriptTapHandler(function(arg_4_0)
		xyd.WindowManager.get():openWindow(var_0_5)
	end)

	arg_3_0.clip = cc.ClippingNode:create()

	arg_3_0.clip:setAnchorPoint(0, 0)
	arg_3_0.clip:pos(0, 0):addTo(arg_3_0.background)

	arg_3_0.blockLayer = display.newNode()

	arg_3_0.blockLayer:setAnchorPoint(0, 0)
	arg_3_0.blockLayer:pos(0, 0):addTo(arg_3_0, 5)
	arg_3_0.blockLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		return true
	end)
	arg_3_0:setWidth(arg_3_0.background:getContentSize().width)
end

function var_0_0.registerListeners(arg_6_0)
	local var_6_0 = cc.EventProxy.new(xyd.EventDispatcher.get(), arg_6_0)

	var_6_0:addEventListener(xyd.event.WINDOW_DID_OPEN, function(arg_7_0)
		if arg_7_0.windowName == var_0_5 then
			arg_6_0.chatWindowOpen_ = true
		end
	end)
	var_6_0:addEventListener(xyd.event.WINDOW_DID_CLOSE, function(arg_8_0)
		if arg_8_0.windowName == var_0_5 then
			arg_6_0.chatWindowOpen_ = false

			if arg_6_0.hasNewMessage_ then
				arg_6_0:showMessage()

				arg_6_0.hasNewMessage_ = false
			end
		end
	end)
	var_6_0:addEventListener(xyd.event.CHAT_UPDATE, function(arg_9_0)
		if arg_6_0.chatWindowOpen_ then
			arg_6_0.hasNewMessage_ = true
		else
			arg_6_0:showMessage()

			arg_6_0.hasNewMessage_ = false
		end
	end)
end

function var_0_0.setWidth(arg_10_0, arg_10_1)
	arg_10_0:setContentSize(arg_10_1, arg_10_0:getContentSize().height)
	arg_10_0.blockLayer:setContentSize(arg_10_0:getContentSize())
	arg_10_0.background:setContentSize(arg_10_0:getContentSize().width - arg_10_0.chatIcon_:getContentSize().width * 0.5, arg_10_0:getContentSize().height)

	local var_10_0 = display.newRect(cc.rect(0, 0, arg_10_0.background:getContentSize().width, arg_10_0.background:getContentSize().height), {
		fillColor = cc.c4f(1, 1, 1, 1),
		borderColor = cc.c4f(1, 1, 1, 1)
	})

	print("charbar size", arg_10_0.background:getContentSize().width, arg_10_0.background:getContentSize().height)
	arg_10_0.clip:setStencil(var_10_0)
end

function var_0_0.showMessage(arg_11_0)
	local var_11_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.MESSAGE_MANAGER):getLatestMessage()
	local var_11_1 = arg_11_0.background:getChildByName(var_0_3)

	if var_11_1 then
		var_11_1:removeFromParent()
		var_0_2.unscheduleGlobal(arg_11_0.handle_)
	else
		arg_11_0:retain()
	end

	var_11_0:setAnchorPoint(0, 1)
	var_11_0:pos(arg_11_0.chatIcon_:getContentSize().width * 0.5, arg_11_0.background:getContentSize().height):addTo(arg_11_0.clip, 5, var_0_3)

	if arg_11_0.background:getParent() == nil then
		arg_11_0:addChild(arg_11_0.background)
	end

	arg_11_0.handle_ = var_0_2.performWithDelayGlobal(handler(arg_11_0, arg_11_0.removeMessage), var_0_4)
end

function var_0_0.removeMessage(arg_12_0, arg_12_1)
	arg_12_0.clip:removeChildByName(var_0_3, false)
	arg_12_0.background:removeFromParent(false)
	arg_12_0:release()

	arg_12_0.handle_ = nil
end

return var_0_0
