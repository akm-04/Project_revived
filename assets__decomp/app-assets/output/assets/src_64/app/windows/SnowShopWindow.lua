local var_0_0 = class("SnowShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySnowShop
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super:willClose(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_ice_coin"):enableOutline(cc.c4b(54, 161, 211, 255), 2)
	arg_4_0:initShopList()
	arg_4_0:updateIceCore()
	xyd.imgEvent(arg_4_0:nodeByName("img_close"), function()
		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
end

function var_0_0.initShopList(arg_6_0)
	local var_6_0 = var_0_2:ids()
	local var_6_1 = 0

	for iter_6_0 = 1, #var_6_0 do
		local var_6_2 = var_6_0[iter_6_0]
		local var_6_3 = var_0_2:giftID(var_6_2)
		local var_6_4 = xyd.tables.gift:items(var_6_3)[1]
		local var_6_5 = var_0_2:price(var_6_2)
		local var_6_6 = var_0_2:vip(var_6_2)
		local var_6_7 = arg_6_0:createExchangeItem(var_6_2, var_6_4, var_6_5, var_6_6)
		local var_6_8 = var_6_7:getContentSize()

		var_6_7:addTo(arg_6_0:nodeByName("list"))
		var_6_7:setPosition(var_6_1, 0)

		var_6_1 = var_6_1 + var_6_8.width + 10
	end
end

function var_0_0.createExchangeItem(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_shop/item.csb")
	local var_7_2 = var_7_1:getChildByName("container")

	var_7_2:getChildByName("text_name"):setString(xyd.tables.item:name(arg_7_2))
	var_7_2:getChildByName("text_name"):enableOutline(cc.c4b(226, 71, 133, 255), 2)
	var_7_2:getChildByName("text_cost"):setString(arg_7_3)
	xyd.setItemAndAddTips(var_7_2:getChildByName("item"), arg_7_2)

	if arg_7_4 <= arg_7_0.selfPlayer.vip then
		var_7_2:getChildByName("text_tips"):setVisible(false)
	else
		local var_7_3 = string.format(var_0_1:translation("SNOW_ACTIVITY_EXCHANGE_TIPS_2"), arg_7_4)

		var_7_2:getChildByName("text_tips"):setString(var_7_3)
		var_7_2:getChildByName("btn_exchange"):setVisible(false)
	end

	xyd.imgEvent(var_7_2:getChildByName("btn_exchange"), function()
		if arg_7_0.selfPlayer.iceCore < arg_7_3 then
			local var_8_0 = var_0_1:translation("SNOW_ACTIVITY_EXCHANGE_TIPS_1")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_8_0
			})

			return
		end

		arg_7_0.snowActivity:exchangeItem(arg_7_1, function(arg_9_0, arg_9_1)
			if arg_9_0 == xyd.error.OK then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_9_1.awards)

				if arg_7_0 and not tolua.isnull(arg_7_0) then
					arg_7_0:updateIceCore()
				end

				local var_9_0 = xyd.WindowManager.get():getWindow("snow_battle")

				if var_9_0 and not tolua.isnull(var_9_0) then
					var_9_0:updateIceCore()
				end
			end
		end)
	end)
	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

function var_0_0.updateIceCore(arg_10_0)
	arg_10_0:nodeByName("text_ice_coin"):setString(arg_10_0.selfPlayer.iceCore)
end

return var_0_0
