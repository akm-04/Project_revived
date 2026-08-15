local var_0_0 = class("ThirdDiglettShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityDiglettShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.shopIds = var_0_3:ids()
	arg_1_0.diglettInfo = arg_1_0.thirdAnniversary.diglettInfo
end

function var_0_0.updateAsset(arg_2_0)
	arg_2_0:nodeByName("star_txt"):setString(arg_2_0.diglettInfo.point)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("scroll")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.list:reload()
	arg_5_0:nodeByName("star_txt"):enableOutline(cc.c4b(151, 51, 51, 255), 2)
	arg_5_0:updateAsset()
end

function var_0_0.willClose(arg_6_0)
	var_0_0.super.willClose()
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" then
		local var_7_0 = 3

		if var_7_0 <= math.abs(arg_7_1.y - arg_7_0.prevY_) or var_7_0 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
			arg_7_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.shopIds
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.list:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.list:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = 269
		local var_8_2 = 429

		var_8_0:setItemSize(var_8_1, var_8_2)

		local var_8_3 = display.newNode()

		var_8_3:setContentSize(var_8_1, var_8_2)
		arg_8_0:createExchangeItem(var_8_3, arg_8_3)
		var_8_0:addContent(var_8_3)

		return var_8_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		-- block empty
	end
end

function var_0_0.createExchangeItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0.shopIds[arg_9_2]
	local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd_diglett/shop/exchange_item.csb")
	local var_9_2 = var_9_1:getChildByName("container")
	local var_9_3 = var_0_3:itemId(var_9_0)
	local var_9_4 = var_0_3:itemNum(var_9_0)
	local var_9_5 = var_0_3:buyLimit(var_9_0)

	var_9_2:getChildByName("name_txt"):setString(xyd.tables.item:name(var_9_3))
	var_9_2:getChildByName("price_txt"):setString(var_0_3:sellPrice(var_9_0))
	var_9_2:getChildByName("exchange_btn"):getChildByName("echange_txt"):setString(var_0_1:translation("BACKPACK_TEXT_3"))
	var_9_2:getChildByName("limit_txt"):enableOutline(cc.c4b(181, 62, 62, 255), 0)

	local function var_9_6()
		arg_9_0:updateAsset()
		var_9_2:getChildByName("limit_txt"):setString("(" .. (arg_9_0.diglettInfo.exchange_times[var_9_0] or 0) .. "/" .. var_9_5 .. ")")
	end

	if var_9_5 > 0 then
		var_9_2:getChildByName("limit_txt"):setString("(" .. (arg_9_0.diglettInfo.exchange_times[var_9_0] or 0) .. "/" .. var_9_5 .. ")")
	else
		var_9_2:getChildByName("limit_txt"):setVisible(false)
	end

	xyd.setItemAndAddTips(var_9_2:getChildByName("icon_container"), var_9_3, var_9_4)
	var_9_2:getChildByName("exchange_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				idx = arg_9_2,
				callback = var_9_6
			}

			xyd.WindowManager.get():openWindow("third_diglett_sure_exchange", var_11_0)
		end
	end)
	var_9_1:addTo(arg_9_1)
	var_9_1:setAnchorPoint(cc.p(0, 0))
	arg_9_1:setContentSize(var_9_2:getContentSize())
	var_9_1:setName("source")

	return arg_9_1
end

return var_0_0
