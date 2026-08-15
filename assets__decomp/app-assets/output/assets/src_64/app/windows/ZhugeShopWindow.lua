local var_0_0 = class("ZhugeShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.zhugeShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.datas = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0.zhugeModel:updateShopType(false)
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
	arg_4_0.datas = var_0_3:ids()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("text_title"):setString(var_0_1:translation("ZHUGE_FOREST_TIPS_10"))
	arg_5_0:nodeByName("close"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_9")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
				xyd.WindowManager.get():closeWindow(arg_5_0)
			end, nil, nil, arg_5_0.colorMode)
		end
	end)
	arg_5_0:updateNum()
end

function var_0_0.updateNum(arg_8_0)
	local var_8_0 = arg_8_0.zhugeModel:getBaseInfo()
	local var_8_1 = var_8_0.cur_shop_num
	local var_8_2 = var_8_0.extra_shop_num + xyd.tables.misc.zhugeForestBagMaxNum

	arg_8_0:nodeByName("text_num"):setString("(" .. var_8_1 .. "/" .. var_8_2 .. ")")
end

function var_0_0.initListview(arg_9_0)
	local var_9_0 = arg_9_0:nodeByName("list")
	local var_9_1 = var_9_0:getContentSize().width
	local var_9_2 = var_9_0:getContentSize().height

	arg_9_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_9_1, var_9_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_9_0)

	arg_9_0.list:setDelegate(handler(arg_9_0, arg_9_0.delegate))
end

function var_0_0.delegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = #arg_10_0.datas

	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return var_10_0
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_1
		local var_10_2
		local var_10_3
		local var_10_4 = arg_10_0.list:dequeueItem()

		if not var_10_4 then
			var_10_4 = arg_10_0.list:newItem()
		else
			var_10_4:removeAllChildren()
		end

		local var_10_5 = display.newNode()

		var_10_5:setTouchSwallowEnabled(false)

		local var_10_6 = display.newNode()

		arg_10_0:initShopItem(var_10_6, arg_10_3)

		local var_10_7 = var_10_6:getContentSize().width
		local var_10_8 = var_10_6:getContentSize().height

		var_10_5:addChild(var_10_6)
		var_10_5:setContentSize(cc.size(arg_10_0.list.viewRect_.width, var_10_6:getContentSize().height + 5))
		var_10_4:setItemSize(arg_10_0.list.viewRect_.width, var_10_6:getContentSize().height + 5)
		var_10_4:addContent(var_10_5)

		return var_10_4
	end
end

function var_0_0.initShopItem(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.datas[arg_11_2]
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/backpack_and_shop/list_item_1.csb")

	var_11_1:addTo(arg_11_1)

	local var_11_2 = var_11_1:getChildByName("container")
	local var_11_3 = var_11_2:getContentSize()

	arg_11_1:setContentSize(var_11_3)

	local var_11_4 = var_0_2:name(var_11_0)
	local var_11_5 = var_0_2:desc1(var_11_0)

	var_11_2:getChildByName("text_name"):setString(var_11_4)
	var_11_2:getChildByName("text_desc"):setString(var_11_5)
	xyd.setItemBorder(var_11_2:getChildByName("item"), var_11_0)

	local var_11_6 = var_0_3:cost(var_11_0)

	var_11_2:getChildByName("btn_buy"):getChildByName("text_cost"):setString(var_11_6)
	var_11_2:getChildByName("btn_use"):setVisible(false)
	var_11_2:getChildByName("btn_buy"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			if not arg_11_0:checkCanBuy() then
				local var_12_0 = var_0_1:translation("ZHUGE_FOREST_TIPS_11")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_12_0
				})

				return
			elseif arg_11_0.selfPlayer.crystal < var_11_6 then
				local var_12_1 = var_0_1:translation("ZHUGE_FOREST_TIPS_18")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_12_1
				})

				return
			end

			local var_12_2 = string.format(var_0_1:translation("ZHUGE_FOREST_TIPS_19"), var_11_6, var_11_4)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_2, function()
				arg_11_0.zhugeModel:buyShopItems(var_11_0, function(arg_14_0, arg_14_1)
					local var_14_0 = ""

					if arg_14_0 == xyd.error.OK then
						arg_11_0.backpack:addItemsByID(var_11_0, 1)
						arg_11_0:updateNum()

						local var_14_1 = string.format(var_0_1:translation("ZHUGE_FOREST_TIPS_12"), var_11_4)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_14_1
						})
					else
						local var_14_2 = string.format(var_0_1:translation("ZHUGE_FOREST_TIPS_13"), var_11_4)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_14_2
						})
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

function var_0_0.checkCanBuy(arg_16_0)
	local var_16_0 = arg_16_0.zhugeModel:getBaseInfo()

	if var_16_0.cur_shop_num >= var_16_0.extra_shop_num + xyd.tables.misc.zhugeForestBagMaxNum then
		return false
	end

	return true
end

return var_0_0
