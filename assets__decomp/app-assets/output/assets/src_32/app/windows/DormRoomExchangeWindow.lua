local var_0_0 = class("DormRoomExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 4

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.data = xyd.mergeTable(xyd.tables.misc.houseKeyBlueId, xyd.tables.misc.housekeyGreenId)
	arg_1_0.listItems = {}

	arg_1_0:initialListItems()
end

function var_0_0.initialListItems(arg_2_0)
	arg_2_0.listItems = {}

	for iter_2_0, iter_2_1 in pairs(arg_2_0.data) do
		local var_2_0 = arg_2_0.backPack:getItemNumByID(iter_2_1)

		if var_2_0 > 0 then
			local var_2_1 = {
				itemID = iter_2_1,
				itemNum = var_2_0
			}

			table.insert(arg_2_0.listItems, var_2_1)
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.SELL_DORM_KEY_EVENT, function(arg_4_0)
		if arg_3_0 and not tolua.isnull(arg_3_0) then
			arg_3_0:initialListItems()
			arg_3_0.scollList:refreshList()
		end
	end)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("tip_text"):setString(var_0_1:translation("DORM_ROOM_EXPAND_TEXT7"))

	arg_6_0.scroll = arg_6_0:nodeByName("scroll")

	local var_6_0 = arg_6_0.scroll:getContentSize()

	arg_6_0.scollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_6_0.width, var_6_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0.scroll):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.scollList:setBounceable(false)
	arg_6_0.scollList:setDelegate(handler(arg_6_0, arg_6_0.scollListDelegate))
	arg_6_0.scollList:setTouchType(false)
	arg_6_0.scollList:reload()
end

function var_0_0.scollListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return math.ceil(#arg_7_0.listItems / var_0_2)
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.scollList:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.scollList:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		local var_7_2 = arg_7_0:createListContent(arg_7_3)
		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		var_7_1:setItemSize(var_7_3, var_7_4)
		var_7_1:addContent(var_7_2)

		return var_7_1
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = 70
	local var_8_2 = 10
	local var_8_3 = 130

	var_8_0:setContentSize(530, 120)

	for iter_8_0 = 1, var_0_2 do
		if (arg_8_1 - 1) * var_0_2 + iter_8_0 <= #arg_8_0.listItems then
			local var_8_4 = arg_8_0.listItems[(arg_8_1 - 1) * var_0_2 + iter_8_0]
			local var_8_5 = display.newNode()

			var_8_5:setContentSize(100, 100)
			var_8_5:setAnchorPoint(cc.p(0.5, 0))
			xyd.setItemBorder(var_8_5, var_8_4.itemID, nil, nil, var_8_4.itemNum, nil, true)
			var_8_5:addTo(var_8_0)
			var_8_5:setPosition(cc.p(var_8_1, var_8_2))

			var_8_1 = var_8_1 + var_8_3

			var_8_5:setTouchEnabled(true)
			var_8_5:setTouchSwallowEnabled(false)
			var_8_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" and arg_8_0.scrollViewMoved_ ~= true then
					var_8_5:setScale(0.9)

					return true
				elseif arg_9_0.name == "ended" then
					var_8_5:setScale(1)
					xyd.WindowManager.get():openWindow("sell_detail", {
						itemID = var_8_4.itemID
					})
				end
			end)
		end
	end

	return var_8_0
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 5 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
