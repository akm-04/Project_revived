local var_0_0 = class("GardenFlowerShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityGardenSeedShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.shopIds = var_0_3:ids()
	arg_1_0.selfDetails = arg_1_0.garden.selfDetails
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
end

function var_0_0.willClose(arg_6_0)
	var_0_0.super.willClose()
	arg_6_0:showMainTop(true)
end

function var_0_0.showMainTop(arg_7_0, arg_7_1)
	local var_7_0 = xyd.WindowManager.get():getWindow("garden")

	if var_7_0 and not tolua.isnull(var_7_0) then
		var_7_0:nodeByName("top_container"):setVisible(arg_7_1)
	end
end

function var_0_0.updateAsset(arg_8_0)
	arg_8_0:nodeByName("gold_seed_num_txt"):setString(arg_8_0.selfDetails.gold_seed)
	arg_8_0:nodeByName("crystal_num_txt"):setString(arg_8_0.selfPlayer.crystal)
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevX_ = arg_9_1.x
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" then
		local var_9_0 = 3

		if var_9_0 <= math.abs(arg_9_1.y - arg_9_0.prevY_) or var_9_0 <= math.abs(arg_9_1.x - arg_9_0.prevX_) then
			arg_9_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.shopIds
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0 = arg_10_0.list:dequeueItem()

		if not var_10_0 then
			var_10_0 = arg_10_0.list:newItem()
		else
			var_10_0:removeAllChildren(true)
		end

		local var_10_1 = 260
		local var_10_2 = 403

		var_10_0:setItemSize(var_10_1, var_10_2)

		local var_10_3 = display.newNode()

		var_10_3:setContentSize(var_10_1, var_10_2)
		arg_10_0:createExchangeItem(var_10_3, arg_10_3)
		var_10_0:addContent(var_10_3)

		return var_10_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_10_2 then
		-- block empty
	end
end

function var_0_0.isHaveLvbu5star(arg_11_0)
	for iter_11_0, iter_11_1 in pairs(arg_11_0.selfPlayer.heros_) do
		local var_11_0 = iter_11_1:getTableID()

		if iter_11_1:isAwaken() then
			var_11_0 = xyd.tables.hero:beforeAwaken(var_11_0)
		end

		if var_11_0 == xyd.tables.misc.lvbuTableID and iter_11_1:getStar() >= 5 then
			return true
		end
	end

	return false
end

function var_0_0.createExchangeItem(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_0.shopIds[arg_12_2]
	local var_12_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/garden/shop/flower_item.csb")
	local var_12_2 = var_12_1:getChildByName("container")
	local var_12_3 = var_0_3:itemId(var_12_0)
	local var_12_4 = var_0_3:sellType(var_12_0)

	var_12_2:getChildByName("name_txt"):setString(xyd.tables.item:name(var_12_3))
	var_12_2:getChildByName("price_txt"):setString(var_0_3:sellPrice(var_12_0))
	var_12_2:getChildByName("price_text"):setString(var_0_1:translation("PRICE_TEXT"))

	if var_12_4 == 1 then
		local var_12_5 = xyd.tables.asset:getIdByBackendName("crystal")

		var_12_2:getChildByName("cost_icon"):loadTexture(xyd.tables.asset:transparentIcon(var_12_5))
	else
		local var_12_6 = xyd.tables.asset:getIdByBackendName("gold_seed")

		var_12_2:getChildByName("cost_icon"):loadTexture(xyd.tables.asset:transparentIcon(var_12_6))
	end

	xyd.setItemAndAddTips(var_12_2:getChildByName("icon_container"), var_12_3)
	var_12_2:getChildByName("sure_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			local var_13_0 = {
				id = var_12_0,
				itemID = var_12_3,
				callback = updateBuyLimit
			}

			xyd.WindowManager.get():openWindow("garden_flower_sure_buy", var_13_0)
		end
	end)
	var_12_1:addTo(arg_12_1)
	var_12_1:setAnchorPoint(cc.p(0, 0))
	arg_12_1:setContentSize(var_12_2:getContentSize())
	var_12_1:setName("source")

	return arg_12_1
end

return var_0_0
