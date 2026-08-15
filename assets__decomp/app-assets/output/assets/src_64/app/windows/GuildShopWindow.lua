local var_0_0 = class("GuildShopWindow", import("app.windows.ShopWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = var_0_1:translation("TEAM_DUNGEON_SHOP_REFRESH")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	xyd.AssetLoader.get():loadSprite("team_dungeon_coin.png")

	if not arg_2_0.shopType_ then
		arg_2_0.shopType_ = arg_2_0.openList[1]
	end

	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.getOpenList(arg_3_0)
	return arg_3_0.shop_:getGuildOpenList()
end

function var_0_0.didOpen(arg_4_0)
	var_0_0.super.didOpen(arg_4_0)
	arg_4_0:nodeByName(arg_4_0.REFRESH_BUTTON):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.can_click = true

			xyd.playButtonSound()

			local var_5_0 = arg_4_0.shop_.refreshTimes_[arg_4_0.shopType_]
			local var_5_1 = xyd.tables.refreshCost:shopRefreshCost(var_5_0 + 1, arg_4_0.shopType_)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_2, var_5_1),
				string.format(var_0_1:translation("SHOP_REFRESH_CONTINUE"), var_5_0)
			}, function()
				arg_4_0:nodeByName(arg_4_0.REFRESH_BUTTON):setVisible(true)

				if (arg_4_0.shopType_ == xyd.ShopType.NORMAL or arg_4_0.shopType_ == xyd.ShopType.GMONE or arg_4_0.shopType_ == xyd.ShopType.BLACK or arg_4_0.shopType_ == xyd.ShopType.SPACE or arg_4_0.shopType_ == xyd.ShopType.MAGIC) and arg_4_0.player_.crystal < var_5_1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_7_0 = {}

						var_7_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
					end, nil, nil, arg_4_0.colorMode)
				elseif xyd.tables.shop:isTeamShop(arg_4_0.shopType_) == 1 and arg_4_0.player_.teamDungeonCoin < var_5_1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("TEAM_DUNGEON_COIN_REFRESH_ABSENCE")
					})
				else
					arg_4_0.shop_:refreshShop({
						shop_type = arg_4_0.shopType_
					}, function(arg_8_0)
						if arg_8_0 == xyd.error.OK then
							local var_8_0 = xyd.WindowManager.get():getWindow("guild_shop")

							if var_8_0 then
								var_8_0:resetScrollNode()
								var_8_0:updateItems()
								var_8_0:updateCost()
							end
						end
					end)
				end
			end, nil, 0, arg_4_0.colorMode)
		elseif arg_5_1 == ccui.TouchEventType.began then
			arg_4_0.can_click = false
		elseif arg_5_1 == ccui.TouchEventType.canceled then
			arg_4_0.can_click = true
		end
	end)
end

function var_0_0.loadOpenList(arg_9_0)
	arg_9_0.openList = arg_9_0.shop_:getGuildOpenList()
	arg_9_0.shopIndex_ = 1
	arg_9_0.countDowns_ = {}

	local var_9_0 = false

	for iter_9_0, iter_9_1 in pairs(arg_9_0.openList) do
		if iter_9_1 == arg_9_0.shopType_ then
			arg_9_0.shopIndex_ = iter_9_0
			var_9_0 = true

			break
		end
	end

	if var_9_0 == false then
		arg_9_0.shopType_ = xyd.ShopType.NORMAL
	end
end

function var_0_0.updateView_(arg_10_0, arg_10_1)
	var_0_0.super.updateView_(arg_10_0, arg_10_1)
	arg_10_0.timeLabel:setString(var_0_1:translation("SHOP_AUTO_REFRESH_TIP"))
end

return var_0_0
