local var_0_0 = class("ShopSellWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.items = arg_1_2.items
	arg_1_0.total_price = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_title"):setString(var_0_1:translation("SELL_TITLE"))
	arg_2_0:nodeByName("txt_canget"):setString(var_0_1:translation("SELL_WILLGET"))
	arg_2_0:nodeByName("txt_ok"):setString(var_0_1:translation("OK"))

	local var_2_0 = arg_2_0:nodeByName("list")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.itemList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_2_0):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.itemList:setDelegate(handler(arg_2_0, arg_2_0.itemDelegate))
	arg_2_0.itemList:reload()
	arg_2_0:nodeByName("txt_num"):setString(arg_2_0.total_price)
end

function var_0_0.itemDelegate(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = #arg_3_0.items
	local var_3_1 = math.ceil(var_3_0 / 2)

	if cc.ui.UIListView.COUNT_TAG == arg_3_2 then
		return var_3_1
	elseif cc.ui.UIListView.CELL_TAG == arg_3_2 then
		local var_3_2 = arg_3_0.itemList:dequeueItem()

		if var_3_2 then
			var_3_2:reomveAllChildren(true)
		else
			var_3_2 = arg_3_0.itemList:newItem()
		end

		local var_3_3 = display.newNode()
		local var_3_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/sell_item.csb")
		local var_3_5 = var_3_4:getChildByName("container")

		var_3_3:setContentSize(arg_3_0.itemList.viewRect_.width, var_3_5:getContentSize().height)
		var_3_2:setItemSize(arg_3_0.itemList.viewRect_.width, var_3_5:getContentSize().height + 10)

		local var_3_6 = 2

		if arg_3_3 == var_3_1 then
			var_3_6 = var_3_0 % 2

			if var_3_6 == 0 then
				var_3_6 = 2
			end
		end

		for iter_3_0 = 1, var_3_6 do
			local var_3_7 = var_3_4:clone()
			local var_3_8 = var_3_7:getChildByName("container")
			local var_3_9 = arg_3_0.items[(arg_3_3 - 1) * 2 + iter_3_0]
			local var_3_10 = xyd.tables.item:name(var_3_9.item_id)
			local var_3_11 = xyd.tables.item:mana(var_3_9.item_id)
			local var_3_12 = var_3_9.item_num

			arg_3_0.total_price = arg_3_0.total_price + var_3_12 * var_3_11

			xyd.setItemBorder(var_3_8:getChildByName("item"), var_3_9.item_id)
			var_3_8:getChildByName("txt_item_num"):setString("x " .. var_3_12)
			var_3_7:addTo(var_3_3)
			var_3_7:setPosition((iter_3_0 - 1) * (var_3_8:getContentSize().width + 5), 0)
			var_3_7:setAnchorPoint(0, 0)
		end

		var_3_2:addContent(var_3_3)

		return var_3_2
	end
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 < math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_ok"), nil, function(arg_6_0)
		xyd.playButtonSound()

		if arg_5_1.itemType == "MANA" then
			arg_5_0.selfPlayer:sellItems(arg_5_1, function(arg_7_0)
				if arg_7_0 == xyd.error.OK then
					arg_5_0:close()
				end
			end)
		end
	end)
end

return var_0_0
