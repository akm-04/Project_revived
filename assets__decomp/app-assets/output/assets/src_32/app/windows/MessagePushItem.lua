local var_0_0 = class("MessagePushItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.messagePush
local var_0_2 = math.floor(#var_0_1.titles_ / 2)
local var_0_3 = 750
local var_0_4 = 70

function var_0_0.ctor(arg_2_0)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.messagePush = arg_2_0.selfPlayer:getMessagePush()

	arg_2_0:size(var_0_3, var_0_4 * var_0_2)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.messagePush:getState()) do
		local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/playerwindow/pushmessageitem.csb")

		arg_3_0.btns_ = {}
		arg_3_0.btns_[iter_3_0] = var_3_0

		var_3_0:getChildByName("txt_push_message"):setString(arg_3_0.messagePush:title(iter_3_0))

		local var_3_1 = iter_3_1 > 0 and cc.c4b(81, 123, 149, 255) or cc.c4b(52, 54, 55, 255)

		var_3_0:getChildByName("txt_push_message"):setColor(var_3_1)

		local var_3_2 = iter_3_0 % 2 < 1 and 30 or 400
		local var_3_3 = math.floor(var_0_2 - iter_3_0 / 2) * 70

		var_3_0:pos(var_3_2, var_3_3)

		var_3_0.messageID = iter_3_0

		var_3_0:addTo(arg_3_0)
		var_3_0:getChildByName("bg_open"):setVisible(false)
		var_3_0:getChildByName("bg_close"):setVisible(false)
		arg_3_0:setupButton(var_3_0)
	end
end

function var_0_0.setupButton(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.messageID
	local var_4_1 = arg_4_0.messagePush:getState()[var_4_0] > 0 and arg_4_1:getChildByName("bg_open") or arg_4_1:getChildByName("bg_close")

	var_4_1:setVisible(true)

	local var_4_2 = cc.p(var_4_1:getPosition())
	local var_4_3 = var_4_1:getContentSize()
	local var_4_4 = display.newNode()

	var_4_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_4:setContentSize(var_4_3)
	var_4_4:addTo(arg_4_1)
	var_4_4:setPosition(var_4_2)
	var_4_4:setTouchEnabled(true)
	var_4_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			local var_5_0 = arg_4_0.messagePush:getState()[var_4_0] > 0 and 0 or 1

			arg_4_0.messagePush:setState(var_4_0, var_5_0, function(arg_6_0)
				if arg_6_0 == xyd.error.OK then
					local var_6_0 = var_5_0 > 0 and cc.c4b(81, 123, 149, 255) or cc.c4b(52, 54, 55)

					arg_4_1:getChildByName("txt_push_message"):setColor(var_6_0)

					local var_6_1 = var_5_0 > 0 and arg_4_1:getChildByName("bg_open") or arg_4_1:getChildByName("bg_close")

					arg_4_1:getChildByName("bg_open"):setVisible(false)
					arg_4_1:getChildByName("bg_close"):setVisible(false)
					var_6_1:setVisible(true)
				end
			end)
		end
	end)
end

return var_0_0
