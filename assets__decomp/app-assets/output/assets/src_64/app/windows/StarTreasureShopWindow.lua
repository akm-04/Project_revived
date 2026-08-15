local var_0_0 = class("StarTreasureShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.starTreasureShop
local var_0_3 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.starTreasure = xyd.ModelManager.get():loadModel(xyd.ModelType.STAR_TREASURE)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list"):getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = var_0_2:getTableIds()

	for iter_4_0, iter_4_1 in pairs(var_4_0) do
		local var_4_1 = var_0_2:getName(iter_4_1)
		local var_4_2 = var_0_2:getDesc(iter_4_1)
		local var_4_3 = var_0_2:getItem(iter_4_1)
		local var_4_4 = var_0_2:getItemNum(iter_4_1)
		local var_4_5 = var_0_2:getSellPrice(iter_4_1)
		local var_4_6 = var_0_3:name(var_4_3)
		local var_4_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/star_treasure/star_treasure_shop/shop_cell.csb")
		local var_4_8 = var_4_7:getChildByName("container")

		var_4_8:getChildByName("item_title"):setString(var_4_6 .. " * " .. tostring(var_4_4))
		var_4_8:getChildByName("item_title"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_4_8:getChildByName("price"):setString(tostring(var_4_5))
		var_4_8:getChildByName("price"):enableOutline(cc.c4b(0, 0, 0, 240), 1)
		xyd.setItemBorder(var_4_8:getChildByName("icon"), var_4_3)

		local var_4_9 = {
			size = 20,
			color = xyd.color.BLACK
		}
		local var_4_10 = xyd.AssetLoader.get():loadLabel(var_4_9)

		var_4_10:setLineBreakWithoutSpace(true)
		var_4_10:setDimensions(370, 0)
		var_4_10:setString(var_4_2)
		var_4_10:addTo(var_4_8)
		var_4_10:setAnchorPoint(cc.p(0, 1))
		var_4_10:setPosition(var_4_8:getChildByName("desc_pos"):getPosition())
		var_4_8:getChildByName("buy_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				if var_4_5 > var_5_0.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_6_0 = {}

						var_6_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
					end, nil, nil, arg_4_0.colorMode)
				end

				local var_5_1 = string.format(var_0_1:translation("STAR_TREASURE_TIP1"), var_4_5)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
					local var_7_0 = {
						id = iter_4_1
					}

					arg_4_0.starTreasure:buyGameTool(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							var_5_0:handleRewards(arg_8_1.awards)
							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.REFRESH_STAR_TREASURE_ITEM
							})
						end
					end)
				end, nil, nil, arg_4_0.colorMode)
			end
		end)

		local var_4_11 = arg_4_0.list:newItem()

		var_4_7:setContentSize(var_4_8:getWidth(), var_4_8:getHeight())
		var_4_11:addContent(var_4_7)
		var_4_11:setItemSize(var_4_8:getWidth(), var_4_8:getHeight() + 5)
		arg_4_0.list:addItem(var_4_11)
	end

	arg_4_0.list:reload()
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 20 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

function var_0_0.willClose(arg_10_0)
	return
end

return var_0_0
