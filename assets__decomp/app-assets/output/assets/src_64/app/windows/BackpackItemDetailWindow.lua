local var_0_0 = class("BackpackItemDetailWindow", import("app.common.ui.BaseWindow"))

var_0_0.ITEM_ICON = "item_icon"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.imgIcon = arg_2_0:nodeByName(var_0_0.ITEM_ICON)

	arg_2_0.imgIcon:removeAllChildren()

	arg_2_0.detailList_ = arg_2_0:nodeByName("list")
	arg_2_0.items = {}
	arg_2_0.heightOfList = 0

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()
	arg_3_0:addBlockLayer()
	arg_3_0.listView_:reload()
end

function var_0_0.layout(arg_4_0)
	xyd.setItemBorder(arg_4_0.imgIcon, arg_4_0.itemID)
	arg_4_0:initData()

	local var_4_0 = {
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list"):getContentSize().width, arg_4_0:nodeByName("list"):getContentSize().height + 10),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}

	arg_4_0.listView_ = cc.ui.UIListView.new(var_4_0):addTo(arg_4_0.detailList_)

	arg_4_0.listView_:setDelegate(handler(arg_4_0, arg_4_0.listDelegate))
end

function var_0_0.initData(arg_5_0)
	if #xyd.tables.item:canCompose(arg_5_0.itemID) > 0 then
		table.insert(arg_5_0.items, {
			DetailType = xyd.ItemDetailType.TITLE,
			str = var_0_1:translation("ITEM_DETAIL_CAN_COMPOSE")
		})
		table.insert(arg_5_0.items, {
			str = "",
			DetailType = xyd.ItemDetailType.EQUIPMENT
		})
	end

	local var_5_0 = xyd.tables.item:hero(arg_5_0.itemID)

	if #var_5_0 > 0 and var_5_0[1] ~= 0 then
		table.insert(arg_5_0.items, {
			DetailType = xyd.ItemDetailType.TITLE,
			str = var_0_1:translation("ITEM_DETAIL_CAN_EQUIP")
		})
		table.insert(arg_5_0.items, {
			str = "",
			DetailType = xyd.ItemDetailType.HERO
		})
	end

	table.insert(arg_5_0.items, {
		DetailType = xyd.ItemDetailType.TITLE,
		str = var_0_1:translation("ITEM_DETAIL_GAIN_WAY")
	})

	if xyd.tables.item:type(arg_5_0.itemID) == xyd.ItemType.INSCRIPTION then
		table.insert(arg_5_0.items, {
			str = "",
			DetailType = xyd.ItemDetailType.MAKE
		})
	end

	local var_5_1 = xyd.tables.item:map(arg_5_0.itemID)

	table.insert(arg_5_0.items, {
		str = "",
		DetailType = xyd.ItemDetailType.CAMPAIGN
	})
end

function var_0_0.listDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return #arg_6_0.items
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0
		local var_6_1 = arg_6_0.listView_:dequeueItem()

		if not var_6_1 then
			var_6_1 = arg_6_0.listView_:newItem()
		else
			var_6_1:removeAllChildren(true)
		end

		local var_6_2 = display.newNode()

		var_6_2:setAnchorPoint(cc.p(0, 1))

		local var_6_3
		local var_6_4 = 0
		local var_6_5 = 0

		if arg_6_0.items[arg_6_3].DetailType == xyd.ItemDetailType.TITLE then
			var_6_3 = import("app.windows.ItemDetailTitle").new()

			var_6_3:setParams({
				titleName = arg_6_0.items[arg_6_3].str
			})

			var_6_4 = var_6_3.contentView_:nodeByName("detail_title_node"):getWidth() + 10
			var_6_5 = var_6_3.contentView_:nodeByName("detail_title_node"):getHeight() + 10
		else
			var_6_3 = import("app.windows.ItemDetailItemBg").new()

			var_6_3:setParams({
				itemID = arg_6_0.itemID,
				detailType = arg_6_0.items[arg_6_3].DetailType
			})

			var_6_4 = var_6_3.contentView_:nodeByName("bg"):getWidth() + 50
			var_6_5 = var_6_3.contentView_:nodeByName("bg"):getHeight()
		end

		var_6_2:setContentSize(cc.size(var_6_4, var_6_5))
		var_6_1:setItemSize(var_6_4, var_6_5)
		var_6_3:ignoreAnchorPointForPosition(false)
		var_6_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_3:setPositionX((arg_6_0.detailList_:getWidth() - var_6_4) * 0.5)
		var_6_3:setTouchEnabled(true)
		var_6_3:setTouchSwallowEnabled(false)
		var_6_2:addChild(var_6_3)
		var_6_1:addContent(var_6_2)

		return var_6_1
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		-- block empty
	end
end

function var_0_0.willClose(arg_7_0, arg_7_1)
	var_0_0.super:willClose(arg_7_1)

	local var_7_0 = xyd.WindowManager.get():getWindow("furniture_factory")

	if var_7_0 and not tolua.isnull(var_7_0) then
		var_7_0:updateBottomContainer()
	end
end

return var_0_0
