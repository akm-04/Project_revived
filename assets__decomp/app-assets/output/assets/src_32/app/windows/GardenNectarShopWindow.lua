local var_0_0 = class("GardenNectarShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityGardenShop
local var_0_4 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.shopIds = var_0_3:ids()
	arg_1_0.selfDetails = arg_1_0.garden.selfDetails
	arg_1_0.activity = arg_1_0.garden.activity
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_GARDEN_INFO, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:updateAsset()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.ECONOMY, handler(arg_2_0, arg_2_0.updateAsset))
	arg_2_0:layout()
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
	arg_5_0:updateAsset()
	arg_5_0:showMainTop(false)
	arg_5_0:createScheduler()
end

function var_0_0.createScheduler(arg_6_0)
	if arg_6_0.handle then
		var_0_4.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	local var_6_0 = arg_6_0.activity.start_time + 604800 - xyd.ServerTime.get():getServerTime()

	arg_6_0.handle = var_0_4.scheduleGlobal(function()
		var_6_0 = var_6_0 - 1

		if arg_6_0.list and not tolua.isnull(arg_6_0.list) then
			arg_6_0.list:refreshList()
		end

		if not arg_6_0 or var_6_0 < 0 then
			if arg_6_0.handle then
				var_0_4.unscheduleGlobal(arg_6_0.handle)

				arg_6_0.handle = nil
			end

			return
		end
	end, 1)
end

function var_0_0.willClose(arg_8_0)
	var_0_0.super.willClose()
	arg_8_0:showMainTop(true)

	if arg_8_0.handle then
		var_0_4.unscheduleGlobal(arg_8_0.handle)

		arg_8_0.handle = nil
	end
end

function var_0_0.showMainTop(arg_9_0, arg_9_1)
	local var_9_0 = xyd.WindowManager.get():getWindow("garden")

	if var_9_0 and not tolua.isnull(var_9_0) then
		var_9_0:nodeByName("top_container"):setVisible(arg_9_1)
	end
end

function var_0_0.updateAsset(arg_10_0)
	arg_10_0:nodeByName("nectar_num_txt"):setString(arg_10_0.selfDetails.nectar)
	arg_10_0:nodeByName("crystal_num_txt"):setString(arg_10_0.selfPlayer.crystal)
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevX_ = arg_11_1.x
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" then
		local var_11_0 = 3

		if var_11_0 <= math.abs(arg_11_1.y - arg_11_0.prevY_) or var_11_0 <= math.abs(arg_11_1.x - arg_11_0.prevX_) then
			arg_11_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.shopIds
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0 = arg_12_0.list:dequeueItem()

		if not var_12_0 then
			var_12_0 = arg_12_0.list:newItem()
		else
			var_12_0:removeAllChildren(true)
		end

		local var_12_1 = 260
		local var_12_2 = 403

		var_12_0:setItemSize(var_12_1, var_12_2)

		local var_12_3 = display.newNode()

		var_12_3:setContentSize(var_12_1, var_12_2)
		arg_12_0:createExchangeItem(var_12_3, arg_12_3)
		var_12_0:addContent(var_12_3)

		return var_12_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_12_2 then
		-- block empty
	end
end

function var_0_0.isHaveLvbu5star(arg_13_0)
	for iter_13_0, iter_13_1 in pairs(arg_13_0.selfPlayer.heros_) do
		local var_13_0 = iter_13_1:getTableID()

		if iter_13_1:isAwaken() then
			var_13_0 = xyd.tables.hero:beforeAwaken(var_13_0)
		end

		if var_13_0 == xyd.tables.misc.lvbuTableID and iter_13_1:getStar() >= 5 then
			return true
		end
	end

	return false
end

function var_0_0.createExchangeItem(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0.shopIds[arg_14_2]
	local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/garden/shop/nectar_item.csb")
	local var_14_2 = var_14_1:getChildByName("container")
	local var_14_3 = var_14_1:getChildByName("container_not_open")
	local var_14_4 = var_0_3:itemId(var_14_0)
	local var_14_5 = var_0_3:itemNum(var_14_0)
	local var_14_6 = var_0_3:buyLimit(var_14_0)
	local var_14_7 = var_0_3:isHide(var_14_0)
	local var_14_8 = arg_14_0.activity.start_time + 604800 - xyd.ServerTime.get():getServerTime()

	if var_14_7 == 1 and var_14_8 > 0 then
		var_14_2:setVisible(false)

		local var_14_9 = string.format(var_0_1:translation("GARDEN_SHOP_ITEM_OPEN_TIME"), xyd.secondsToString1(var_14_8, 2))

		var_14_3:getChildByName("down_time_txt"):setString(var_14_9)
	else
		var_14_3:setVisible(false)
	end

	var_14_2:getChildByName("name_txt"):setString(xyd.tables.item:name(var_14_4))
	var_14_2:getChildByName("price_txt"):setString(var_0_3:sellPrice(var_14_0))
	var_14_2:getChildByName("price_text"):setString(var_0_1:translation("PRICE_TEXT"))

	local var_14_10 = xyd.tables.asset:getIdByBackendName("nectar")

	var_14_2:getChildByName("cost_icon"):loadTexture(xyd.tables.asset:transparentIcon(var_14_10))

	if var_14_6 > 0 then
		var_14_2:getChildByName("time_bg"):setVisible(true)
		var_14_2:getChildByName("limit_txt"):setVisible(true)
	else
		var_14_2:getChildByName("time_bg"):setVisible(false)
		var_14_2:getChildByName("limit_txt"):setVisible(false)
	end

	local function var_14_11()
		if var_14_2 and not tolua.isnull(var_14_2) then
			var_14_2:getChildByName("limit_txt"):setString(string.format(var_0_1:translation("STICK_BLESS_BUY_LIMIT"), arg_14_0.garden.selfDetails.exchange_times[var_14_0] or 0, var_0_3:buyLimit(var_14_0)))
		end
	end

	var_14_11()
	xyd.setItemAndAddTips(var_14_2:getChildByName("icon_container"), var_14_4, var_14_5)
	var_14_2:getChildByName("sure_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			local var_16_0 = {
				id = var_14_0,
				itemID = var_14_4,
				callback = var_14_11
			}

			xyd.WindowManager.get():openWindow("garden_nectar_sure_exchange", var_16_0)
		end
	end)
	var_14_1:addTo(arg_14_1)
	var_14_1:setAnchorPoint(cc.p(0, 0))
	arg_14_1:setContentSize(var_14_2:getContentSize())
	var_14_1:setName("source")

	return arg_14_1
end

return var_0_0
