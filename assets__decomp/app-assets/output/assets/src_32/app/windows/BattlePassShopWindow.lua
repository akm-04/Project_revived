local var_0_0 = class("BattlePassShopWindow", import("app.windows.ShopWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc
local var_0_4 = var_0_3:getValue("battle_pass_shop_coin_id")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = {
		ecoCount = 1,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_4
		},
		ecoIcons = {
			"images/icon/eco/battle_pass_coin.png"
		}
	}

	arg_2_0:addTopSidebar(var_2_0)

	arg_2_0.leftTime = var_0_3:getValue("battle_pass_season_end_time") - xyd.ServerTime.get():getServerTime()

	if arg_2_0.leftTime > 0 then
		arg_2_0.battlePassHandle = var_0_1.scheduleGlobal(function()
			if arg_2_0.leftTime > 0 then
				arg_2_0.leftTime = arg_2_0.leftTime - 1

				arg_2_0:nodeByName("txt_time"):setString(arg_2_0:secondsToString(arg_2_0.leftTime))
			elseif arg_2_0.battlePassHandle then
				var_0_1.unscheduleGlobal(arg_2_0.battlePassHandle)

				arg_2_0.battlePassHandle = nil
			end
		end, 1)
	end

	arg_2_0.dialog = arg_2_0:nodeByName("dialog")
	arg_2_0.dialogBg = arg_2_0:nodeByName("dialog_img")
	arg_2_0.ItemPanel = arg_2_0:nodeByName("list")

	arg_2_0:createShopTypeList()

	arg_2_0.isRefresh = false
	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:loadOpenList()

	if not arg_2_0.shop_:isOpen(arg_2_0.shopType_) and xyd.tables.shop:isTeamShop(arg_2_0.shopType_) ~= 1 and xyd.tables.shop:isAlone(arg_2_0.shopType_) == 0 then
		print("shop type is not open!")

		arg_2_0.shopType_ = xyd.ShopType.NORMAL
	end

	arg_2_0:nodeByName("refresh_button"):setTouchSwallowEnabled(true)

	arg_2_0.can_click = true

	arg_2_0:layout()
	arg_2_0:updateLeftHeroImg()

	if not arg_2_0.player_.backpackLoaded_ then
		arg_2_0.player_:loadBackpack(function(arg_4_0)
			if arg_4_0 == xyd.error.OK then
				arg_2_0.backpack_ = arg_2_0.player_:getBackpack()

				arg_2_0:loadShopInfo()
			end
		end)
	else
		arg_2_0.backpack_ = arg_2_0.player_:getBackpack()

		arg_2_0:loadShopInfo()
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.SHOP_COST_REFRESH, function(arg_5_0)
		if arg_2_0 and arg_2_0.updateCost then
			arg_2_0:updateCost()
		end
	end)
	arg_2_0:initSubSpaceShop()
	arg_2_0:nodeByName("type_list_bg"):setVisible(false)
	arg_2_0:nodeByName("type_scroll"):setVisible(false)
end

function var_0_0.updateAssetsContainer(arg_6_0)
	return
end

function var_0_0.getOpenList(arg_7_0)
	return {
		xyd.ShopType.BATTLE_PASS_SHOP
	}
end

function var_0_0.didOpen(arg_8_0)
	var_0_0.super.didOpen(arg_8_0)
	arg_8_0:nodeByName("refresh_button"):setVisible(false)
	arg_8_0:nodeByName("img_currency"):setVisible(false)
	arg_8_0:nodeByName("cost_txt"):setVisible(false)
end

function var_0_0.loadOpenList(arg_9_0)
	arg_9_0.openList = {
		xyd.ShopType.BATTLE_PASS_SHOP
	}
end

function var_0_0.updateView_(arg_10_0, arg_10_1)
	var_0_0.super.updateView_(arg_10_0, arg_10_1)
	arg_10_0:nodeByName("txt_time"):setString(arg_10_0:secondsToString(math.max(0, arg_10_0.leftTime)))
	arg_10_0:nodeByName("refresh_button"):setVisible(false)
end

function var_0_0.upadteEco(arg_11_0)
	arg_11_0:nodeByName("eco_sidebar"):update({
		true
	})
end

function var_0_0.secondsToString(arg_12_0, arg_12_1)
	local var_12_0 = math.floor(arg_12_1 / 86400)
	local var_12_1 = math.floor(arg_12_1 % 86400 / 3600)
	local var_12_2 = math.floor(arg_12_1 % 3600 / 60)
	local var_12_3 = math.floor(arg_12_1 % 60)
	local var_12_4 = var_0_2:translation("BATTLE_PASS_TEXT_28")

	if var_12_0 > 0 then
		var_12_4 = var_12_4 .. var_12_0 .. var_0_2:translation("BATTLE_PASS_TEXT_29")
	end

	if var_12_0 > 0 or var_12_1 > 0 then
		if var_12_1 < 10 then
			var_12_4 = var_12_4 .. "0"
		end

		var_12_4 = var_12_4 .. var_12_1 .. var_0_2:translation("BATTLE_PASS_TEXT_30")
	end

	if var_12_0 > 0 or var_12_1 > 0 or var_12_2 > 0 then
		if var_12_2 < 10 then
			var_12_4 = var_12_4 .. "0"
		end

		var_12_4 = var_12_4 .. var_12_2 .. var_0_2:translation("BATTLE_PASS_TEXT_31")
	end

	if var_12_3 < 10 then
		var_12_4 = var_12_4 .. "0"
	end

	return var_12_4 .. var_12_3 .. var_0_2:translation("BATTLE_PASS_TEXT_32")
end

function var_0_0.willClose(arg_13_0)
	var_0_0.super.willClose(arg_13_0)

	if arg_13_0.battlePassHandle then
		var_0_1.unscheduleGlobal(arg_13_0.battlePassHandle)

		arg_13_0.battlePassHandle = nil
	end
end

return var_0_0
