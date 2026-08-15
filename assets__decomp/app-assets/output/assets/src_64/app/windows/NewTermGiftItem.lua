local var_0_0 = class("NewTermGiftItem", function()
	return cc.Node:create()
end)
local var_0_1 = require("framework.scheduler")
local var_0_2 = 3

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.longTouch = false
	arg_2_0.longTouchTime = 0
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/fumo_window/fumo_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setContentSize(111, 86)
		arg_3_0:setContentSize(111, 86)
		arg_3_0.contentView_:setPosition(55.5, 43)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.updateItem(arg_4_0, arg_4_1)
	if arg_4_1 then
		if not arg_4_0.move and not arg_4_0.decreaseOnTouch then
			arg_4_0:updateNums(arg_4_0.item_.nowNum + 1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.NEW_TERM_GIFT_REFRESH,
				params = {
					item = arg_4_0.item_
				}
			})
		end
	elseif not arg_4_0.moved and arg_4_0.item_.nowNum - 1 >= 0 then
		arg_4_0:updateNums(arg_4_0.item_.nowNum - 1)

		arg_4_0.decreaseOnTouch = true

		arg_4_0.contentView_:setScale(1)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.NEW_TERM_GIFT_REFRESH,
			params = {
				item = arg_4_0.item_
			}
		})
	end
end

function var_0_0.setParams(arg_5_0, arg_5_1)
	if arg_5_1 == nil then
		return true
	end

	arg_5_0:setAnchorPoint(0.5, 0.5)

	arg_5_0.item_ = arg_5_1

	arg_5_0:contentView():nodeByName("item"):setContentSize(76, 76)
	arg_5_0:contentView():nodeByName("txt_num"):setAnchorPoint(0.5, 0)
	arg_5_0:contentView():nodeByName("txt_num"):setPosition(cc.p(38, 3.5))
	arg_5_0:contentView():nodeByName("txt_num"):setAnchorPoint(0.5, 0.5)
	arg_5_0:contentView():nodeByName("decrease"):setPosition(cc.p(70, 70))
	arg_5_0:contentView():nodeByName("decrease"):setLocalZOrder(20)
	arg_5_0:contentView():nodeByName("decrease"):setScale(0.8)
	xyd.setItemBorder(arg_5_0:contentView():nodeByName("item"), arg_5_1.itemID, false)
	arg_5_0:updateNums(arg_5_1.nowNum)
	arg_5_0.contentView_:setTouchEnabled(true)
	arg_5_0.contentView_:nodeByName("item"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		local function var_6_0()
			arg_5_0.longTouchTime = arg_5_0.longTouchTime + 1

			if arg_5_0.longTouchTime > var_0_2 then
				arg_5_0:updateItem(true)

				arg_5_0.longTouch = true
			end
		end

		if arg_6_0.name == "began" then
			arg_5_0.move = false
			arg_5_0.prevX_ = arg_6_0.x
			arg_5_0.prevY_ = arg_6_0.y

			arg_5_0.contentView_:setScale(0.9)

			if not arg_5_0.decreaseOnTouch then
				arg_5_0.longTouchHandler = var_0_1.scheduleGlobal(var_6_0, 0.2)
			end

			return true
		elseif arg_6_0.name == "ended" then
			if not arg_5_0.move and not arg_5_0.decreaseOnTouch and not arg_5_0.longTouch then
				arg_5_0:updateItem(true)
			end

			arg_5_0.contentView_:setScale(1)

			if arg_5_0.longTouchHandler then
				var_0_1.unscheduleGlobal(arg_5_0.longTouchHandler)

				arg_5_0.longTouchHandler = nil
			end

			arg_5_0.longTouch = false
			arg_5_0.longTouchTime = 0

			return
		elseif arg_6_0.name == "moved" then
			local var_6_1 = 5

			if var_6_1 <= math.abs(arg_6_0.y - arg_5_0.prevY_) or var_6_1 <= math.abs(arg_6_0.x - arg_5_0.prevX_) then
				arg_5_0.contentView_:setScale(1)

				arg_5_0.move = true

				if arg_5_0.longTouchHandler then
					var_0_1.unscheduleGlobal(arg_5_0.longTouchHandler)

					arg_5_0.longTouchHandler = nil
				end

				arg_5_0.longTouch = false
				arg_5_0.longTouchTime = 0
			end

			return true
		end
	end)
	arg_5_0.contentView_:nodeByName("decrease"):setTouchSwallowEnabled(true)
	arg_5_0.contentView_:nodeByName("decrease"):addTouchEventListener(function(arg_8_0, arg_8_1)
		local function var_8_0()
			arg_5_0.longTouchTime = arg_5_0.longTouchTime + 1

			if arg_5_0.longTouchTime > var_0_2 then
				arg_5_0:updateItem(false)

				arg_5_0.longTouch = true
			end
		end

		if arg_8_1 == ccui.TouchEventType.began then
			arg_5_0.decreaseOnTouch = true
			arg_5_0.moved = false

			arg_5_0.contentView_:setScale(1)

			arg_5_0.longTouchDecreaseHandler = var_0_1.scheduleGlobal(var_8_0, 0.2)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			if not arg_5_0.moved and not arg_5_0.longTouch then
				arg_5_0:updateItem(false)
			end

			if arg_5_0.longTouchDecreaseHandler then
				var_0_1.unscheduleGlobal(arg_5_0.longTouchDecreaseHandler)

				arg_5_0.longTouchDecreaseHandler = nil
			end

			arg_5_0.longTouch = false
			arg_5_0.longTouchTime = 0
			arg_5_0.decreaseOnTouch = false

			return false
		elseif arg_8_1 == ccui.TouchEventType.moved then
			arg_5_0.moved = true

			if arg_5_0.longTouchDecreaseHandler then
				var_0_1.unscheduleGlobal(arg_5_0.longTouchDecreaseHandler)

				arg_5_0.longTouchDecreaseHandler = nil
			end

			arg_5_0.longTouch = false
			arg_5_0.longTouchTime = 0

			arg_5_0.contentView_:setScale(1)
		end

		return false
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.NEW_TERM_GIFT_SELECT_ALL, function(arg_10_0)
		if arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:updateNums(arg_5_0.item_.itemNum)
		end
	end)
end

function var_0_0.updateNums(arg_11_0, arg_11_1)
	arg_11_0.item_.nowNum = arg_11_1

	if arg_11_0.item_.nowNum >= arg_11_0.item_.itemNum then
		arg_11_0.item_.nowNum = arg_11_0.item_.itemNum
	end

	arg_11_0:contentView():nodeByName("txt_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	if arg_11_0.item_.nowNum > 0 then
		arg_11_0:contentView():nodeByName("txt_num"):setString(arg_11_0.item_.nowNum .. "/" .. arg_11_0.item_.itemNum)
		arg_11_0:contentView():nodeByName("decrease"):setVisible(true)
	else
		arg_11_0:contentView():nodeByName("txt_num"):setString(arg_11_0.item_.itemNum)
		arg_11_0:contentView():nodeByName("decrease"):setVisible(false)
	end
end

function var_0_0.getNewTermGiftItem(arg_12_0, arg_12_1)
	return arg_12_0.item_
end

return var_0_0
