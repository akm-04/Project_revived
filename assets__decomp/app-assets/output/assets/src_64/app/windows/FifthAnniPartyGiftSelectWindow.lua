local var_0_0 = class("GiftItem", function()
	return xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1232/party/gift_select_item.csb")
end)
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.fifthAnniPartyGift

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.id = arg_2_1.id
	arg_2_0.itemID = arg_2_1.item_id
	arg_2_0.num = arg_2_1.num
	arg_2_0.point = var_0_2:point(arg_2_0.id)
	arg_2_0.selectNum = 0

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:getChildByName("container")

	arg_3_0.numLabel = arg_3_0:getChildByName("txt_num")

	xyd.setItemBorder(var_3_0, arg_3_0.itemID)
	arg_3_0.numLabel:setString(arg_3_0.num)
	arg_3_0.numLabel:enableOutline(cc.c4b(86, 86, 92, 255), 2)
	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0:createAddHandle()
		elseif arg_4_1 == ccui.TouchEventType.ended or arg_4_1 == ccui.TouchEventType.canceled then
			arg_3_0:removeAddHandle()

			if not arg_3_0.isLongTouch and not arg_3_0.window.scrollViewMoved_ then
				arg_3_0:addSelectNum()
			end
		end
	end)

	arg_3_0.sub = arg_3_0:getChildByName("sub")

	arg_3_0.sub:setVisible(false)
	arg_3_0.sub:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_3_0:createSubHandle()
		elseif arg_5_1 == ccui.TouchEventType.ended or arg_5_1 == ccui.TouchEventType.canceled then
			arg_3_0:removeSubHandle()

			if not arg_3_0.isLongTouch and not arg_3_0.window.scrollViewMoved_ then
				arg_3_0:decreaseSelectNum()
			end
		end
	end)
end

function var_0_0.setWindow(arg_6_0, arg_6_1)
	arg_6_0.window = arg_6_1
end

function var_0_0.createAddHandle(arg_7_0)
	arg_7_0:removeAddHandle()

	local var_7_0 = 0

	local function var_7_1()
		var_7_0 = var_7_0 + 0.03

		arg_7_0:addSelectNum()
	end

	local function var_7_2()
		var_7_0 = var_7_0 + 0.1

		if var_7_0 > 0.5 and var_7_0 <= 4 then
			arg_7_0.isLongTouch = true

			arg_7_0:addSelectNum()
		elseif var_7_0 > 4 then
			arg_7_0:removeAddHandle()

			arg_7_0.addHandle = var_0_1.scheduleGlobal(var_7_1, 0.03)
		else
			arg_7_0.isLongTouch = false
		end
	end

	arg_7_0.isLongTouch = false
	arg_7_0.addHandle = var_0_1.scheduleGlobal(var_7_2, 0.1)
end

function var_0_0.removeAddHandle(arg_10_0)
	if arg_10_0.addHandle then
		var_0_1.unscheduleGlobal(arg_10_0.addHandle)

		arg_10_0.addHandle = nil
	end
end

function var_0_0.createSubHandle(arg_11_0)
	arg_11_0:removeSubHandle()

	local var_11_0 = 0

	local function var_11_1()
		var_11_0 = var_11_0 + 0.03

		arg_11_0:decreaseSelectNum()
	end

	local function var_11_2()
		var_11_0 = var_11_0 + 0.1

		if var_11_0 > 0.5 and var_11_0 <= 4 then
			arg_11_0.isLongTouch = true

			arg_11_0:decreaseSelectNum()
		elseif var_11_0 > 4 then
			arg_11_0:removeSubHandle()

			arg_11_0.subHandle = var_0_1.scheduleGlobal(var_11_1, 0.03)
		else
			arg_11_0.isLongTouch = false
		end
	end

	arg_11_0.isLongTouch = false
	arg_11_0.subHandle = var_0_1.scheduleGlobal(var_11_2, 0.1)
end

function var_0_0.removeSubHandle(arg_14_0)
	if arg_14_0.subHandle then
		var_0_1.unscheduleGlobal(arg_14_0.subHandle)

		arg_14_0.subHandle = nil
	end
end

function var_0_0.addSelectNum(arg_15_0)
	if arg_15_0.selectNum >= arg_15_0.num then
		return
	else
		arg_15_0.selectNum = arg_15_0.selectNum + 1

		arg_15_0.numLabel:setString(arg_15_0.selectNum .. "/" .. arg_15_0.num)
		arg_15_0.window:addPoint(arg_15_0.point)
	end

	arg_15_0.sub:setVisible(true)
end

function var_0_0.decreaseSelectNum(arg_16_0)
	if arg_16_0.selectNum <= 0 then
		return
	else
		arg_16_0.selectNum = arg_16_0.selectNum - 1

		arg_16_0.numLabel:setString(arg_16_0.selectNum .. "/" .. arg_16_0.num)
		arg_16_0.window:addPoint(-arg_16_0.point)
	end

	if arg_16_0.selectNum == 0 then
		arg_16_0.numLabel:setString(arg_16_0.num)
		arg_16_0.sub:setVisible(false)
		arg_16_0:removeSubHandle()
	end
end

function var_0_0.selectAll(arg_17_0)
	if arg_17_0.num == 0 then
		return
	end

	local var_17_0 = arg_17_0.num - arg_17_0.selectNum

	arg_17_0.selectNum = arg_17_0.num

	arg_17_0.numLabel:setString(arg_17_0.selectNum .. "/" .. arg_17_0.num)
	arg_17_0.sub:setVisible(true)
	arg_17_0.window:addPoint(var_17_0 * arg_17_0.point)
end

function var_0_0.getIdAndSelectNum(arg_18_0)
	return arg_18_0.id, arg_18_0.selectNum or 0
end

local var_0_3 = class("FifthAnniPartyGiftSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_4 = import("app.common.ui.SplitLine")
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.misc
local var_0_7 = var_0_6:getValue("fifth_anni_party_receive_point_extra_num")
local var_0_8 = var_0_6:getValue("fifth_anni_party_receive_point_extra_rate")
local var_0_9 = 4
local var_0_10 = 77

function var_0_3.ctor(arg_19_0, arg_19_1, arg_19_2)
	var_0_3.super.ctor(arg_19_0, arg_19_1, arg_19_2)

	arg_19_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_19_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_19_0.backpack = arg_19_0.selfPlayer:getBackpack()
	arg_19_0.playerName = arg_19_2.player_name
	arg_19_0.playerID = arg_19_2.player_id
	arg_19_0.playerExtraPoint = var_0_7 - arg_19_2.player_send_point
	arg_19_0.items = {}
	arg_19_0.giftItems = {}
	arg_19_0.sendPoint = 0
	arg_19_0.receivePoint = 0

	for iter_19_0 = 1, var_0_2:all() do
		local var_19_0 = {
			id = iter_19_0,
			item_id = var_0_2:itemId(iter_19_0),
			num = arg_19_0.backpack:getItemNumByID(var_0_2:itemId(iter_19_0))
		}

		table.insert(arg_19_0.items, var_19_0)
	end
end

function var_0_3.willOpen(arg_20_0)
	arg_20_0:layout()
end

function var_0_3.didOpen(arg_21_0)
	arg_21_0:addBlockLayer()
end

function var_0_3.layout(arg_22_0)
	arg_22_0:nodeByName("txt_title"):setString(var_0_5:translation("FIFTH_ANNI_PARTY_TEXT_29"))
	arg_22_0:nodeByName("txt_send"):setString(var_0_5:translation("FIFTH_ANNI_PARTY_TEXT_30"))
	arg_22_0:nodeByName("txt_receive_point"):setString(var_0_5:translation("FIFTH_ANNI_PARTY_TEXT_31"))
	arg_22_0:nodeByName("txt_send_point"):setString(var_0_5:translation("FIFTH_ANNI_PARTY_TEXT_32"))
	arg_22_0:nodeByName("txt_btn_send"):setString(var_0_5:translation("FIFTH_ANNI_PARTY_TEXT_33"))
	arg_22_0:nodeByName("txt_btn_all"):setString(var_0_5:translation("FIFTH_ANNI_PARTY_TEXT_34"))
	arg_22_0:nodeByName("txt_title"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_22_0:nodeByName("txt_name"):setString(arg_22_0.playerName)

	local var_22_0 = var_0_4.new({
		size = 400
	})

	arg_22_0:nodeByName("pos_line"):addChild(var_22_0)

	local var_22_1 = arg_22_0:nodeByName("item_container")
	local var_22_2 = var_22_1:getContentSize()

	arg_22_0.list = cc.ui.UITableView.new({
		itemGap = 2,
		size = var_22_2,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL
	}):addTo(var_22_1):onScroll(handler(arg_22_0, arg_22_0.scrollListener))

	for iter_22_0 = 1, math.ceil(#arg_22_0.items / var_0_9) do
		local var_22_3 = arg_22_0.list:newItem()
		local var_22_4 = arg_22_0:createContent(iter_22_0)

		var_22_3:addContent(var_22_4)
		var_22_3:setItemSize(var_22_2.width, var_0_10 + 8)
		arg_22_0.list:addItem(var_22_3)
	end

	arg_22_0.list:reload()
	xyd.nodeEventSample(arg_22_0:nodeByName("btn_all"), nil, function()
		for iter_23_0, iter_23_1 in ipairs(arg_22_0.giftItems) do
			iter_23_1:selectAll()
		end
	end)
	xyd.nodeEventSample(arg_22_0:nodeByName("btn_send"), nil, function()
		arg_22_0:send()
	end)
end

function var_0_3.createContent(arg_25_0, arg_25_1)
	local var_25_0 = display.newNode()
	local var_25_1 = 1
	local var_25_2 = 0
	local var_25_3 = 34

	for iter_25_0 = 1, var_0_9 do
		local var_25_4 = (arg_25_1 - 1) * var_0_9 + iter_25_0

		if not arg_25_0.items[var_25_4] then
			break
		end

		local var_25_5 = var_0_0.new(arg_25_0.items[var_25_4])

		table.insert(arg_25_0.giftItems, var_25_5)
		var_25_5:setWindow(arg_25_0)
		var_25_5:setPosition(var_25_1, var_25_2)
		var_25_0:addChild(var_25_5)

		var_25_1 = var_25_1 + var_0_10 + var_25_3
	end

	return var_25_0
end

function var_0_3.addPoint(arg_26_0, arg_26_1)
	arg_26_0.sendPoint = arg_26_0.sendPoint + arg_26_1
	arg_26_0.receivePoint = arg_26_0.receivePoint + arg_26_1
	arg_26_0.extraSendPoint = 0

	if arg_26_0.playerExtraPoint > 0 then
		arg_26_0.extraSendPoint = math.ceil(var_0_8 * math.min(arg_26_0.playerExtraPoint, arg_26_0.sendPoint))
	end

	arg_26_0:nodeByName("send_point"):setString(arg_26_0.sendPoint + arg_26_0.extraSendPoint)
	arg_26_0:nodeByName("receive_point"):setString(arg_26_0.receivePoint)
end

function var_0_3.send(arg_27_0)
	local var_27_0 = {}
	local var_27_1 = {}

	for iter_27_0, iter_27_1 in ipairs(arg_27_0.giftItems) do
		local var_27_2, var_27_3 = iter_27_1:getIdAndSelectNum()

		if var_27_3 > 0 then
			table.insert(var_27_0, var_27_2)
			table.insert(var_27_1, var_27_3)
		end
	end

	if #var_27_0 == 0 then
		return
	end

	local var_27_4 = {
		to_player = arg_27_0.playerID,
		ids = table.concat(var_27_0, "|"),
		nums = table.concat(var_27_1, "|"),
		show_point = arg_27_0.sendPoint + arg_27_0.extraSendPoint
	}

	arg_27_0.model:partySendGift(var_27_4, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			for iter_28_0 = 1, #var_27_0 do
				arg_27_0.backpack:addItemsByID(var_0_2:itemId(var_27_0[iter_28_0]), -var_27_1[iter_28_0])
			end

			arg_27_0:close()
		else
			arg_27_0.model:partyGetPlayerInfo({
				player_id = arg_27_0.playerID
			}, function(arg_29_0, arg_29_1)
				if arg_29_0 == xyd.error.OK then
					local var_29_0 = var_0_5:translation("FIFTH_ANNI_PARTY_TEXT_41")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_29_0
					})

					arg_27_0.playerExtraPoint = var_0_7 - arg_29_1.point

					arg_27_0:addPoint(0)
				end
			end)
		end
	end)
end

function var_0_3.didClose(arg_30_0)
	for iter_30_0, iter_30_1 in ipairs(arg_30_0.giftItems) do
		iter_30_1:removeAddHandle()
		iter_30_1:removeSubHandle()
	end
end

function var_0_3.scrollListener(arg_31_0, arg_31_1)
	if arg_31_1.name == "began" then
		arg_31_0.scrollViewMoved_ = false
		arg_31_0.prevY_ = arg_31_1.y
	elseif arg_31_1.name == "moved" and 10 <= math.abs(arg_31_1.y - arg_31_0.prevY_) then
		arg_31_0.scrollViewMoved_ = true
	end
end

return var_0_3
