local var_0_0 = class("FishGamblingShopWindow", import("app.windows.ShopWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc:getValue("activity_fish_gambling_gold_coin")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0)
	local var_2_0 = {
		ecoCount = 3,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_3,
			2,
			1
		},
		ecoScale = {
			0.5,
			1,
			1
		},
		ecoIcons = {
			"windows/fish_gambling/fish_gold_coin.png",
			-1,
			-1
		}
	}

	arg_2_0:addTopSidebar(var_2_0)

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
		arg_2_0.player_:loadBackpack(function(arg_3_0)
			if arg_3_0 == xyd.error.OK then
				arg_2_0.backpack_ = arg_2_0.player_:getBackpack()

				arg_2_0:loadShopInfo()
			end
		end)
	else
		arg_2_0.backpack_ = arg_2_0.player_:getBackpack()

		arg_2_0:loadShopInfo()
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.SHOP_COST_REFRESH, function(arg_4_0)
		if arg_2_0 and arg_2_0.updateCost then
			arg_2_0:updateCost()
		end
	end)
	arg_2_0:initSubSpaceShop()
	arg_2_0:nodeByName("type_list_bg"):setVisible(false)
	arg_2_0:nodeByName("type_scroll"):setVisible(false)
end

function var_0_0.updateAssetsContainer(arg_5_0)
	return
end

function var_0_0.getOpenList(arg_6_0)
	return {
		xyd.ShopType.FISH_GAMBLING
	}
end

function var_0_0.didOpen(arg_7_0)
	var_0_0.super.didOpen(arg_7_0)
	arg_7_0:nodeByName("refresh_button"):setVisible(false)
	arg_7_0:nodeByName("img_currency"):setVisible(false)
	arg_7_0:nodeByName("cost_txt"):setVisible(false)
end

function var_0_0.loadOpenList(arg_8_0)
	arg_8_0.openList = {
		xyd.ShopType.FISH_GAMBLING
	}
end

function var_0_0.updateView_(arg_9_0, arg_9_1)
	var_0_0.super.updateView_(arg_9_0, arg_9_1)
	arg_9_0:nodeByName("txt_time"):setString(var_0_2:translation("FISH_FIGHT_SHOP_TEXT"))
	arg_9_0:nodeByName("refresh_button"):setVisible(false)
end

function var_0_0.upadteEco(arg_10_0)
	arg_10_0:nodeByName("eco_sidebar"):update({
		true
	})
end

function var_0_0.willClose(arg_11_0)
	var_0_0.super.willClose(arg_11_0)
end

return var_0_0
