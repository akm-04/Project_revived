local var_0_0 = class("SubShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addThemeBG()
	arg_2_0:addTopSidebar()
	xyd.nodeEventSample(arg_2_0:nodeByName("shop_node"), {}, function()
		xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
			xyd.WindowManager.get():openWindow("shop", {
				shop_type = 1
			})
		end)
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("skin_node"), {}, function()
		local var_5_0 = xyd.FunctionID.ID_SKIN_SHOP

		if arg_2_0.selfPlayer:isFuncOpen(var_5_0) == false then
			local var_5_1 = xyd.tables.functionOpen:level(var_5_0)
			local var_5_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_5_1)

			xyd.WindowManager.get():openWindow("toast", {
				message = var_5_2
			})

			return
		end

		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(3)
		xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadSkinShopInfo({}, function()
			xyd.WindowManager.get():openWindow("skin_shop", {})
		end)
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("auction_node"), {}, function()
		local var_7_0 = xyd.FunctionID.ID_AUCTION

		if arg_2_0.selfPlayer:isFuncOpen(var_7_0) == false then
			local var_7_1 = xyd.tables.functionOpen:level(var_7_0)
			local var_7_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_7_1)

			xyd.WindowManager.get():openWindow("toast", {
				message = var_7_2
			})

			return
		end

		xyd.ModelManager.get():loadModel(xyd.ModelType.AUCTION):getAuctionInfoByType({
			auction_type = 2
		}, function(arg_8_0, arg_8_1)
			if arg_8_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("auction_room", {
					loaded = true
				})
			end
		end)
	end)
	arg_2_0:nodeByName("shop_tip_text"):enableOutline(cc.c4b(138, 26, 31, 255), 2)
	arg_2_0:nodeByName("skin_tip_text"):enableOutline(cc.c4b(105, 6, 186, 255), 2)
	arg_2_0:nodeByName("shop_tip_text"):setString(var_0_1:translation("SHOP_TIP_TEXT"))
	arg_2_0:nodeByName("skin_tip_text"):setString(var_0_1:translation("SHOP_SKIN_TIP_TEXT"))
	arg_2_0:nodeByName("auction_tip_text"):setString(var_0_1:translation("AUCTION_TIP_TEXT1"))
	arg_2_0:nodeByName("auction_tip_txt"):setString(var_0_1:translation("AUCTION_TIP_TEXT2"))
end

function var_0_0.didClose(arg_9_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
