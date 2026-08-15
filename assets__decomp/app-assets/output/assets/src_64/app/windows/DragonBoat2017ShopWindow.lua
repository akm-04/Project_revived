local var_0_0 = class("DragonBoat2017ShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.activityDragonshipShop
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.misc.activityDragonBoatReward

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT2017)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
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
	arg_4_0.buyTimes = arg_4_0.dragonBoatModel:getBuyTimes()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("text_score_desc"):setString(var_0_2:translation("DRAGON_BOAT2017_SCORE_2"))
	xyd.imgEvent(arg_5_0:nodeByName("img_close"), function()
		xyd.WindowManager.get():closeWindow(arg_5_0)
	end)
	arg_5_0:updateNum()
end

function var_0_0.updateNum(arg_7_0)
	local var_7_0 = arg_7_0.backpack:getItemNumByID(var_0_4)

	arg_7_0:nodeByName("text_score"):setString(var_7_0)
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
	arg_9_0.showDatas = arg_9_0:filteredIds()

	local var_9_0 = #arg_9_0.showDatas

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
		var_9_4:setItemSize(var_9_7 + 25, arg_9_0.list.viewRect_.height)
		var_9_4:addContent(var_9_5)

		return var_9_4
	end
end

function var_0_0.filteredIds(arg_10_0)
	local var_10_0 = {}
	local var_10_1 = {}
	local var_10_2 = arg_10_0.selfPlayer:getHeroIgnoreAwaken(10001192)

	if not var_10_2 or var_10_2:getStar() < 3 then
		table.insert(var_10_1, 2)
	end

	for iter_10_0, iter_10_1 in pairs(arg_10_0.datas) do
		if not xyd.isInTable(var_10_1, iter_10_1) then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

function var_0_0.initShopItem(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.showDatas[arg_11_2]
	local var_11_1 = var_0_1:itemId(var_11_0)
	local var_11_2 = var_0_1:itemNum(var_11_0)
	local var_11_3 = var_0_1:cost(var_11_0)
	local var_11_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1104/shop/shop_item.csb")

	var_11_4:addTo(arg_11_1)

	local var_11_5 = var_11_4:getChildByName("container")
	local var_11_6 = var_11_5:getContentSize()

	arg_11_1:setContentSize(var_11_6)

	local var_11_7 = var_0_3:name(var_11_1)

	var_11_5:getChildByName("text_name"):setString(var_11_7)
	var_11_5:getChildByName("text_cost"):setString(var_11_3)

	local var_11_8 = var_0_1:buyLimit(var_11_0)

	if var_11_8 > 0 then
		local var_11_9 = arg_11_0.dragonBoatModel:getBuyTimes()[tostring(var_11_0)] or 0

		var_11_5:getChildByName("text_buy_limit"):setVisible(true)

		local var_11_10 = string.format(var_0_2:translation("ZHUGE_ADVENTURE_TIPS_12"), var_11_9, var_11_8)

		var_11_5:getChildByName("num_buy_limit"):setString(var_11_10)
	else
		var_11_5:getChildByName("num_buy_limit"):setString("")
		var_11_5:getChildByName("text_buy_limit"):setVisible(false)
	end

	xyd.setItemBorder(var_11_5:getChildByName("icon"), var_11_1, false, false, var_11_2)

	local var_11_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_11_1)
	local var_11_12 = display.newNode()

	var_11_12:setContentSize(110, 110)
	var_11_12:addTo(var_11_5:getChildByName("icon"))
	var_11_12:setPosition(cc.p(0, 0))
	xyd.addTips(var_11_12, {
		id = var_11_1,
		hasNum = var_11_11
	})
	var_11_5:getChildByName("btn_exchange"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			var_11_5:getChildByName("btn_exchange"):setScale(0.9)
		elseif arg_12_1 == ccui.TouchEventType.ended then
			var_11_5:getChildByName("btn_exchange"):setScale(1)

			local var_12_0 = arg_11_0.backpack:getItemNumByID(var_0_4)
			local var_12_1 = arg_11_0.dragonBoatModel:getBuyTimes()[tostring(var_11_0)] or 0

			if var_12_0 < var_11_3 then
				local var_12_2 = var_0_2:translation("DRAGON_BOAT2017_SCORE_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_12_2
				})

				return
			elseif var_11_8 > 0 and var_12_1 >= var_11_8 then
				local var_12_3 = var_0_2:translation("DRAGON_BOAT2017_SELL_ALL")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_12_3
				})

				return
			end

			local var_12_4 = string.format(var_0_2:translation("DRAGON_BOAT2017_EXCHANGE_TIP"), var_11_3, var_11_7)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_4, function()
				local var_13_0 = {
					id = var_11_0
				}

				arg_11_0.dragonBoatModel:exchange(var_13_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						local var_14_0 = {
							itemID = var_0_4,
							itemNum = var_11_3
						}

						arg_11_0.selfPlayer:getBackpack():removeItem(var_14_0)
						arg_11_0:updateNum()
						arg_11_0.list:refreshList()
					end
				end)
			end, nil, nil, arg_11_0.colorMode)
		end
	end)
end

function var_0_0.didOpen(arg_15_0, arg_15_1)
	var_0_0.super:didOpen(arg_15_1)
	arg_15_0.list:reload()
end

return var_0_0
