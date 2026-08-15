local var_0_0 = class("StickBlessShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.activityStickerShop
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.stickBless = xyd.ModelManager.get():loadModel(xyd.ModelType.STICK_BLESS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:getShopDatas()
	arg_2_0:initListview()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.getShopDatas(arg_4_0)
	arg_4_0.datas = var_0_1:ids()
	arg_4_0.buyTimes = arg_4_0.stickBless:getBuyTimes()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("text_score_desc"):setString(var_0_2:translation("STICK_BLESS_SCORE_2"))
	xyd.imgEvent(arg_5_0:nodeByName("img_close"), function()
		xyd.WindowManager.get():closeWindow(arg_5_0)
	end)
	arg_5_0:updateNum()
end

function var_0_0.updateNum(arg_7_0)
	local var_7_0 = arg_7_0.stickBless:getBaseInfo()

	arg_7_0:nodeByName("text_score"):setString(var_7_0.point)
end

function var_0_0.initListview(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("list")
	local var_8_1 = var_8_0:getContentSize().width
	local var_8_2 = var_8_0:getContentSize().height

	arg_8_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_8_1, var_8_2),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_8_0)

	arg_8_0.list:setDelegate(handler(arg_8_0, arg_8_0.delegate))
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = #arg_9_0.datas

	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return var_9_0
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_1
		local var_9_2
		local var_9_3
		local var_9_4 = arg_9_0.list:dequeueItem()

		if not var_9_4 then
			var_9_4 = arg_9_0.list:newItem()
		else
			var_9_4:removeAllChildren()
		end

		local var_9_5 = display.newNode()

		var_9_5:setTouchSwallowEnabled(false)

		local var_9_6 = display.newNode()

		arg_9_0:initShopItem(var_9_6, arg_9_3)

		local var_9_7 = var_9_6:getContentSize().width
		local var_9_8 = var_9_6:getContentSize().height

		var_9_5:addChild(var_9_6)
		var_9_5:setContentSize(cc.size(var_9_7 + 5, arg_9_0.list.viewRect_.height))
		var_9_4:setItemSize(var_9_7 + 5, arg_9_0.list.viewRect_.height)
		var_9_4:addContent(var_9_5)

		return var_9_4
	end
end

function var_0_0.initShopItem(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_0.datas[arg_10_2]
	local var_10_1 = var_0_1:itemID(var_10_0)
	local var_10_2 = var_0_1:itemNum(var_10_0)
	local var_10_3 = var_0_1:point(var_10_0)
	local var_10_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/stick_bless_word/shop_item.csb")

	var_10_4:addTo(arg_10_1)

	local var_10_5 = var_10_4:getChildByName("container")
	local var_10_6 = var_10_5:getContentSize()

	arg_10_1:setContentSize(var_10_6)

	local var_10_7 = var_0_3:name(var_10_1)

	var_10_5:getChildByName("text_name"):enableOutline(cc.c4b(132, 37, 11, 255), 2)
	var_10_5:getChildByName("text_name"):setString(var_10_7)
	var_10_5:getChildByName("text_cost"):enableOutline(cc.c4b(132, 37, 11, 255), 1)
	var_10_5:getChildByName("text_cost"):setString(var_10_3)

	local var_10_8 = var_0_1:buyLimit(var_10_0)

	if var_10_8 > 0 then
		local var_10_9 = arg_10_0.stickBless:getBuyTimes(tostring(var_10_0))
		local var_10_10 = string.format(var_0_2:translation("STICK_BLESS_BUY_LIMIT"), var_10_9, var_10_8)

		var_10_5:getChildByName("text_buy_limit"):setString(var_10_10)
		var_10_5:getChildByName("text_buy_limit"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	else
		var_10_5:getChildByName("text_buy_limit"):setString("")
	end

	xyd.setItemBorder(var_10_5:getChildByName("icon"), var_10_1, false, false, var_10_2)

	local var_10_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_10_1)
	local var_10_12 = display.newNode()

	var_10_12:setContentSize(110, 110)
	var_10_12:addTo(var_10_5:getChildByName("icon"))
	var_10_12:setPosition(cc.p(0, 0))
	xyd.addTips(var_10_12, {
		id = var_10_1,
		hasNum = var_10_11
	})
	var_10_5:getChildByName("btn_exchange"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = arg_10_0.stickBless:getBaseInfo().point
			local var_11_1 = arg_10_0.stickBless:getBuyTimes(tostring(var_10_0))

			if var_11_0 < var_10_3 then
				local var_11_2 = var_0_2:translation("STICK_BLESS_SCORE_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_2
				})

				return
			elseif var_10_8 > 0 and var_11_1 >= var_10_8 then
				local var_11_3 = var_0_2:translation("STICK_BLESS_SELL_ALL")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_3
				})

				return
			end

			local var_11_4 = string.format(var_0_2:translation("STICK_BLESS_EXCHANGE"), var_10_3, var_10_7)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_4, function()
				arg_10_0.stickBless:getActivityReward(var_10_0, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						if arg_10_0 and not tolua.isnull(arg_10_0) then
							arg_10_0:updateNum()
						end

						xyd.WindowManager.get():getWindow("stick_bless_word"):updateNum()

						if var_10_8 > 0 then
							local var_13_0 = arg_10_0.stickBless:getBuyTimes(tostring(var_10_0))
							local var_13_1 = string.format(var_0_2:translation("STICK_BLESS_BUY_LIMIT"), var_13_0, var_10_8)

							var_10_5:getChildByName("text_buy_limit"):setString(var_13_1)
						end
					end
				end)
			end, nil, nil, arg_10_0.colorMode)
		end
	end)
end

function var_0_0.didOpen(arg_14_0, arg_14_1)
	var_0_0.super:didOpen(arg_14_1)
	arg_14_0.list:reload()
end

return var_0_0
