local var_0_0 = class("GuildShopChangeWindow", import("app.windows.ShopChangeWindow"))
local var_0_1 = xyd.tables.shop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.initShopList(arg_2_0)
	arg_2_0.shopOpenList = arg_2_0.shop:getGuildOpenList()
end

function var_0_0.initShopItemCell(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_0.shopOpenList[arg_3_2]
	local var_3_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/shop_change/shop_change_item.csb")
	local var_3_2 = var_3_1:getChildByName("container")
	local var_3_3 = var_3_2:getContentSize()

	arg_3_1:setContentSize(var_3_3.width, var_3_3.height)
	arg_3_1:addChild(var_3_1)

	local var_3_4 = var_3_2:getChildByName("text_name")

	var_3_4:setString(var_0_1:shopChangeName(var_3_0))
	var_3_4:enableOutline(cc.c4b(69, 133, 192, 255), 1)

	local var_3_5 = cc.p(var_3_2:getChildByName("img_node"):getPosition())
	local var_3_6 = var_0_1:shopChangePath(var_3_0)
	local var_3_7 = xyd.AssetLoader.get():loadSprite(var_3_6)

	if var_3_7 then
		var_3_7:addTo(var_3_2)
		var_3_7:setAnchorPoint(cc.p(0.5, 0.5))

		local var_3_8 = arg_3_0:changeImg(var_3_0, var_3_7, var_3_5)

		var_3_7:setLocalZOrder(-1)
		var_3_7:setTouchSwallowEnabled(false)
		var_3_7:setTouchEnabled(true)
		var_3_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				arg_3_0.startClick = true

				var_3_7:setScale(var_3_8 - 0.1)

				arg_3_0.beginX = arg_4_0.x
				arg_3_0.beginY = arg_4_0.y

				return true
			elseif arg_4_0.name == "moved" then
				local var_4_0 = 20

				if var_4_0 <= math.abs(arg_4_0.x - arg_3_0.beginX) or var_4_0 <= math.abs(arg_4_0.y - arg_3_0.beginY) then
					arg_3_0.startClick = false

					var_3_7:setScale(var_3_8)
				end

				return true
			elseif arg_4_0.name == "ended" and arg_3_0.startClick then
				arg_3_0.startClick = false

				var_3_7:setScale(var_3_8)

				local var_4_1 = xyd.WindowManager.get():getWindow("guild_shop")

				if var_4_1 then
					var_4_1.shopType_ = var_3_0
					var_4_1.shopIndex_ = 1

					local var_4_2 = arg_3_0.shop:getGuildOpenList()
					local var_4_3 = false

					for iter_4_0, iter_4_1 in pairs(var_4_2) do
						if iter_4_1 == var_3_0 then
							var_4_1.shopIndex_ = iter_4_0
							var_4_3 = true

							break
						end
					end

					if var_4_3 == false then
						var_4_1.shopType_ = xyd.ShopType.NORMAL
					end

					var_4_1:updateItemVisible(true)
					var_4_1:updateNewShop(var_4_1.shopIndex_, var_4_1.shopType_)
				end

				xyd.WindowManager.get():closeWindow(arg_3_0)
			end
		end)
	end
end

function var_0_0.changeImg(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = 0.85

	arg_5_2:setPosition(cc.p(arg_5_3.x, arg_5_3.y - 20))
	arg_5_2:setScale(var_5_0)

	return var_5_0
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super.didOpen(arg_6_0, arg_6_1)

	local var_6_0, var_6_1 = arg_6_0:nodeByName("title"):getPosition()

	arg_6_0:nodeByName("title"):removeSelf()

	local var_6_2 = xyd.AssetLoader.get():loadSprite("windows/shop_window/shop_change/chapter_change_txt.png")

	var_6_2:setPosition(var_6_0, var_6_1)
	arg_6_0:nodeByName("container"):addChild(var_6_2)
end

return var_0_0
