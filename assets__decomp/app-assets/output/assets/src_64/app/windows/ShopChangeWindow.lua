local var_0_0 = class("ShopChangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.shop
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.shop = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.shopOpenList = {}
	arg_1_0.startClick = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initShopList()
	arg_2_0:layout()
end

function var_0_0.initShopList(arg_3_0)
	arg_3_0.shopOpenList = arg_3_0.shop:getOpenList()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("detail_container"):getContentSize()

	arg_4_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_4_0:nodeByName("detail_container")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.listView_:setDelegate(handler(arg_4_0, arg_4_0.delegate))
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" then
		local var_5_0 = 20

		if var_5_0 <= math.abs(arg_5_1.x - arg_5_0.prevX_) or var_5_0 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
			arg_5_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = #arg_6_0.shopOpenList

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_1
		local var_6_2
		local var_6_3 = arg_6_0.listView_:dequeueItem()

		if not var_6_3 then
			var_6_3 = arg_6_0.listView_:newItem()
		else
			var_6_3:removeAllChildren()
		end

		local var_6_4 = display.newNode()
		local var_6_5 = display.newNode()

		arg_6_0:initShopItemCell(var_6_5, arg_6_3)
		var_6_5:addTo(var_6_4)
		var_6_4:setContentSize(var_6_5:getContentSize().width, var_6_5:getContentSize().height)
		var_6_3:setItemSize(var_6_4:getContentSize().width, var_6_4:getContentSize().height)
		var_6_3:addContent(var_6_4)

		return var_6_3
	end
end

function var_0_0.initShopItemCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0.shopOpenList[arg_7_2]
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/shop_change/shop_change_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_7_2:getContentSize()

	arg_7_1:setContentSize(var_7_3.width, var_7_3.height)
	arg_7_1:addChild(var_7_1)

	local var_7_4 = var_7_2:getChildByName("text_name")

	var_7_4:setString(var_0_1:shopChangeName(var_7_0))
	var_7_4:enableOutline(cc.c4b(69, 133, 192, 255), 1)

	local var_7_5 = cc.p(var_7_2:getChildByName("img_node"):getPosition())

	if xyd.tables.shop:isDynamic(var_7_0) == 1 then
		local var_7_6 = var_0_1:dynamicImagePath(var_7_0)
		local var_7_7 = cc.p(var_7_2:getPosition())
		local var_7_8 = xyd.EffectLoader.new(var_7_6, 3, 0.55, {
			x = var_7_7.x + 150,
			y = var_7_7.y + 55
		})

		var_7_8:addTo(var_7_2)
		var_7_8:setLocalZOrder(-1)

		local var_7_9 = var_0_1:shopChangePath(var_7_0)
		local var_7_10 = xyd.AssetLoader.get():loadSprite(var_7_9)

		if var_7_10 then
			var_7_10:addTo(var_7_2)
			var_7_10:setOpacity(0)
			var_7_10:setAnchorPoint(cc.p(0.5, 0.5))

			local var_7_11 = arg_7_0:changeImg(var_7_0, var_7_10, var_7_5)

			var_7_10:setLocalZOrder(-1)
			var_7_10:setTouchSwallowEnabled(false)
			var_7_10:setTouchEnabled(true)
			var_7_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
				if arg_8_0.name == "began" then
					arg_7_0.startClick = true

					var_7_8:setScale(var_7_11 - 0.1)

					arg_7_0.beginX = arg_8_0.x
					arg_7_0.beginY = arg_8_0.y

					return true
				elseif arg_8_0.name == "moved" then
					local var_8_0 = 20

					if var_8_0 <= math.abs(arg_8_0.x - arg_7_0.beginX) or var_8_0 <= math.abs(arg_8_0.y - arg_7_0.beginY) then
						arg_7_0.startClick = false

						var_7_8:setScale(var_7_11)
					end

					return true
				elseif arg_8_0.name == "ended" and arg_7_0.startClick then
					arg_7_0.startClick = false

					var_7_8:setScale(var_7_11)

					local var_8_1 = xyd.WindowManager.get():getWindow("shop")

					if var_8_1 then
						var_8_1.shopType_ = var_7_0
						var_8_1.shopIndex_ = 1

						local var_8_2 = arg_7_0.shop:getOpenList()
						local var_8_3 = false

						for iter_8_0, iter_8_1 in pairs(var_8_2) do
							if iter_8_1 == var_7_0 then
								var_8_1.shopIndex_ = iter_8_0
								var_8_3 = true

								break
							end
						end

						if var_8_3 == false then
							var_8_1.shopType_ = xyd.ShopType.NORMAL
						end

						var_8_1:updateItemVisible(true)
						var_8_1:updateNewShop(var_8_1.shopIndex_, var_8_1.shopType_)
					end

					xyd.WindowManager.get():closeWindow(arg_7_0)
				end
			end)
		end
	else
		local var_7_12 = var_0_1:shopChangePath(var_7_0)
		local var_7_13 = xyd.AssetLoader.get():loadSprite(var_7_12)

		if var_7_13 then
			var_7_13:addTo(var_7_2)
			var_7_13:setAnchorPoint(cc.p(0.5, 0.5))

			local var_7_14 = arg_7_0:changeImg(var_7_0, var_7_13, var_7_5)

			var_7_13:setLocalZOrder(-1)
			var_7_13:setTouchSwallowEnabled(false)
			var_7_13:setTouchEnabled(true)
			var_7_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
				if arg_9_0.name == "began" then
					arg_7_0.startClick = true

					var_7_13:setScale(var_7_14 - 0.1)

					arg_7_0.beginX = arg_9_0.x
					arg_7_0.beginY = arg_9_0.y

					return true
				elseif arg_9_0.name == "moved" then
					local var_9_0 = 20

					if var_9_0 <= math.abs(arg_9_0.x - arg_7_0.beginX) or var_9_0 <= math.abs(arg_9_0.y - arg_7_0.beginY) then
						arg_7_0.startClick = false

						var_7_13:setScale(var_7_14)
					end

					return true
				elseif arg_9_0.name == "ended" and arg_7_0.startClick then
					arg_7_0.startClick = false

					var_7_13:setScale(var_7_14)

					local var_9_1 = xyd.WindowManager.get():getWindow("shop")

					if var_9_1 then
						var_9_1.shopType_ = var_7_0
						var_9_1.shopIndex_ = 1

						local var_9_2 = arg_7_0.shop:getOpenList()
						local var_9_3 = false

						for iter_9_0, iter_9_1 in pairs(var_9_2) do
							if iter_9_1 == var_7_0 then
								var_9_1.shopIndex_ = iter_9_0
								var_9_3 = true

								break
							end
						end

						if var_9_3 == false then
							var_9_1.shopType_ = xyd.ShopType.NORMAL
						end

						var_9_1:updateItemVisible(true)
						var_9_1:updateNewShop(var_9_1.shopIndex_, var_9_1.shopType_)
					end

					xyd.WindowManager.get():closeWindow(arg_7_0)
				end
			end)
		end
	end
end

function var_0_0.changeImg(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = 1

	arg_10_2:setPosition(cc.p(arg_10_3.x, arg_10_3.y - 20))

	if arg_10_1 == xyd.ShopType.TOP then
		var_10_0 = 0.9
	elseif arg_10_1 == xyd.ShopType.BLACK then
		var_10_0 = 0.85

		arg_10_2:setPositionY(arg_10_3.y)
	elseif arg_10_1 == xyd.ShopType.GUILD then
		var_10_0 = 0.9
	elseif arg_10_1 == xyd.ShopType.HONOR then
		var_10_0 = 0.9

		arg_10_2:setPositionY(arg_10_3.y - 24)
	elseif arg_10_1 == xyd.ShopType.SKIN then
		var_10_0 = 0.9

		arg_10_2:setPositionY(arg_10_3.y - 5)
	end

	arg_10_2:setScale(var_10_0)

	return var_10_0
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super.didOpen(arg_11_0, arg_11_1)
	arg_11_0:addBlockLayer()
	arg_11_0.listView_:reload()
end

return var_0_0
