local var_0_0 = class("FireworkWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityFireworkType
local var_0_4 = xyd.tables.item
local var_0_5 = 85
local var_0_6 = 150
local var_0_7 = 10
local var_0_8 = 49

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemList = arg_1_2.list
	arg_1_0.fireworkModel = xyd.ModelManager.get():loadModel(xyd.ModelType.FIREWORK)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.goToSendNextWin = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevX_ = arg_4_1.x
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 5 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("detail_container")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		}
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0:initItemList()
end

function var_0_0.initItemList(arg_6_0)
	local var_6_0 = var_0_3:ids()

	for iter_6_0 = 1, #var_6_0 do
		local var_6_1 = var_6_0[iter_6_0]
		local var_6_2 = arg_6_0.list:newItem()
		local var_6_3 = display.newNode()
		local var_6_4 = arg_6_0:nodeByName("detail_container"):getContentSize()

		var_6_3:setContentSize(var_6_4.width, var_0_6)
		arg_6_0:initItemCell(var_6_3, var_6_1)
		var_6_2:setItemSize(var_6_4.width, var_0_6)
		var_6_2:addContent(var_6_3)
		arg_6_0.list:addItem(var_6_2)
	end

	arg_6_0.list:reload()
end

function var_0_0.getItemNum(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in pairs(arg_7_0.itemList) do
		if iter_7_1.itemID == arg_7_1 then
			return iter_7_1.itemNum
		end
	end

	return 0
end

function var_0_0.initItemCell(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = var_0_3:itemID(arg_8_2)
	local var_8_1 = arg_8_0:getItemNum(var_8_0)
	local var_8_2 = var_0_3:num(arg_8_2)
	local var_8_3 = var_0_3:sendTicket(arg_8_2)
	local var_8_4 = var_0_3:recharge(arg_8_2)
	local var_8_5 = var_0_3:desc(arg_8_2)
	local var_8_6 = var_0_3:name(arg_8_2)
	local var_8_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/firework/firework/firework_item.csb")
	local var_8_8 = var_8_7:getChildByName("container")
	local var_8_9 = cc.p(var_8_8:getChildByName("node_item"):getPosition())
	local var_8_10 = display.newNode()

	var_8_10:setContentSize(var_0_5, var_0_5)
	var_8_10:setAnchorPoint(cc.p(0.5, 0.5))
	xyd.setItemBorder(var_8_10, var_8_0, false, false, var_8_1, false, true)
	var_8_10:setPosition(cc.p(var_8_9))
	var_8_10:addTo(var_8_8)
	var_8_8:getChildByName("text_name"):setString(var_8_6)
	var_8_8:getChildByName("text_coin_num"):setString("x" .. var_8_3 .. "）")
	var_8_8:getChildByName("text_get"):setString("（" .. var_0_2:translation("FIREWORK_TEXT_18"))
	var_8_8:getChildByName("text_desc1"):setString(var_8_5)
	var_8_8:getChildByName("text_desc2"):setString(var_0_2:translation("VIP_RECHARGE"))
	var_8_8:getChildByName("text_desc3"):setString(string.format(var_0_2:translation("FIREWORK_TEXT_1"), var_8_2))
	var_8_8:getChildByName("text_charge_num"):setString(var_8_4)

	if var_8_1 > 0 then
		var_8_8:getChildByName("btn_exchange"):getChildByName("btn_text_charge"):setVisible(false)
	else
		var_8_8:getChildByName("btn_exchange"):getChildByName("text_exchange"):setVisible(false)
	end

	var_8_7:setPosition(cc.p(0, 12))
	arg_8_1:addChild(var_8_7)

	local var_8_11 = var_8_8:getChildByName("splitline"):getContentSize()
	local var_8_12 = {
		size = var_8_11.width,
		align = xyd.SplitLineAlign.LEFT
	}

	var_0_1.new(var_8_12):addTo(var_8_8:getChildByName("splitline"))
	var_8_8:getChildByName("btn_exchange"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			var_8_8:getChildByName("btn_exchange"):setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.ended then
			var_8_8:getChildByName("btn_exchange"):setScale(1)

			arg_8_0.goToSendNextWin = true

			if var_8_1 > 0 then
				local var_9_0 = xyd.WindowManager.get():getWindow("firework_main")

				if var_9_0 then
					local var_9_1 = {
						id = arg_8_2,
						itemID = var_8_0,
						itemNum = var_8_1,
						okCallback = function(arg_10_0)
							var_9_0:sendFirework(arg_10_0)
						end,
						cancelCallback = function()
							var_9_0:updateWindow()
						end
					}

					xyd.WindowManager.get():openWindow("send_firework_num", var_9_1)
				end
			else
				local var_9_2 = {}

				var_9_2.windowState = true

				xyd.WindowManager.get():openWindow("vip_recharge", var_9_2)
			end

			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
end

function var_0_0.willClose(arg_12_0)
	if xyd.WindowManager.get():getWindow("firework_main") and not arg_12_0.goToSendNextWin and arg_12_0.callback then
		arg_12_0.callback()
	end
end

return var_0_0
