local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityLevelChargeGift2
local var_0_3 = import("framework.scheduler")
local var_0_4
local var_0_5
local var_0_6 = {}
local var_0_7 = {
	afterDiscounting = 3,
	isDiscounting = 4,
	hasBought = 1,
	cannotBuy = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	local var_2_1 = var_2_0:getChildByName("bg")

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:updateTimeCount()

	local var_3_0 = arg_3_1:getChildByName("item_container")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0:updateListInfo()
	arg_3_0.list:reload()

	local var_3_2 = xyd.createLabel(18, cc.c3b(87, 72, 144))

	var_3_2:addTo(arg_3_1:getChildByName("label_node"))
	var_3_2:setString(var_0_1:translation("ACTIVITY_1136_TXT"))
	var_3_2:setWidth(560)
	var_3_2:setLineHeight(28)
	var_3_2:setAnchorPoint(0, 1)
	var_3_2:setPosition(0, 5)
end

function var_0_0.updateListInfo(arg_4_0)
	arg_4_0.listInfo = var_0_2:ids()

	table.sort(arg_4_0.listInfo, function(arg_5_0, arg_5_1)
		local var_5_0 = tostring(arg_5_0)
		local var_5_1 = tostring(arg_5_1)
		local var_5_2 = arg_4_0:giftBoxState(var_5_0)
		local var_5_3 = arg_4_0:giftBoxState(var_5_1)

		if var_5_2 == var_5_3 then
			return var_0_2:level(arg_5_0) < var_0_2:level(arg_5_1)
		end

		return var_5_3 < var_5_2
	end)
end

function var_0_0.giftBoxState(arg_6_0, arg_6_1)
	local var_6_0 = xyd.ServerTime.get():getServerTime()
	local var_6_1 = {
		isDiscounting = arg_6_0.details.award_infos[arg_6_1].is_awarded == 0 and arg_6_0.details.award_infos[arg_6_1].open_time > 0 and var_6_0 - arg_6_0.details.award_infos[arg_6_1].open_time <= xyd.tables.misc:getValue("activity_level_charge2_discount_time"),
		afterDiscounting = arg_6_0.details.award_infos[arg_6_1].is_awarded == 0 and arg_6_0.details.award_infos[arg_6_1].open_time > 0 and var_6_0 - arg_6_0.details.award_infos[arg_6_1].open_time > xyd.tables.misc:getValue("activity_level_charge2_discount_time"),
		cannotBuy = arg_6_0.details.award_infos[arg_6_1].is_awarded == 0 and arg_6_0.details.award_infos[arg_6_1].open_time == 0,
		hasBought = arg_6_0.details.award_infos[arg_6_1].is_awarded == 1
	}

	if var_6_1.isDiscounting then
		return var_0_7.isDiscounting
	elseif var_6_1.afterDiscounting then
		return var_0_7.afterDiscounting
	elseif var_6_1.cannotBuy then
		return var_0_7.cannotBuy
	elseif var_6_1.hasBought then
		return var_0_7.hasBought
	else
		return 0
	end
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0 = arg_7_0.list:dequeueItem()

		if not var_7_0 then
			var_7_0 = arg_7_0.list:newItem()
		else
			var_7_0:removeAllChildren(true)
		end

		local var_7_1 = 240
		local var_7_2 = 460

		var_7_0:setItemSize(var_7_1, var_7_2)

		local var_7_3 = display.newNode()

		var_7_3:setContentSize(var_7_1, 460)
		arg_7_0:initCell(var_7_3, arg_7_3)
		var_7_0:addContent(var_7_3)

		return var_7_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_7_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_2 > #arg_8_0.listInfo then
		return
	end

	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1213/level_charge_item.csb")

	var_8_0:setPosition(0, 0)
	arg_8_1:addChild(var_8_0)

	local var_8_1 = var_8_0:getChildByName("bg")
	local var_8_2 = arg_8_0:giftBoxState(tostring(arg_8_0.listInfo[arg_8_2]))

	var_8_1:getChildByName("lev_text"):setString(var_0_2:name(arg_8_0.listInfo[arg_8_2]))
	arg_8_0:rewardLayer(var_8_1:getChildByName("item_container"), var_0_2:gift(arg_8_0.listInfo[arg_8_2]))

	if var_8_2 == var_0_7.isDiscounting then
		var_8_1:getChildByName("old_price"):setVisible(true)
		var_8_1:getChildByName("btn_buy"):getChildByName("text_price"):setString(var_0_2:discountCharge(arg_8_0.listInfo[arg_8_2]) .. var_0_1:translation("ACTIVITY_CHARGE_LEVEL_TEXT1"))

		local var_8_3 = var_8_1:getChildByName("time")
		local var_8_4 = arg_8_0.details.award_infos[tostring(arg_8_0.listInfo[arg_8_2])].open_time + xyd.tables.misc:getValue("activity_level_charge2_discount_time") - xyd.ServerTime.get():getServerTime()

		var_8_3:setString(xyd.secondsToString(var_8_4, {
			toText = false
		}))

		var_0_5 = xyd.EventDispatcher.get():addEventListener(xyd.event.LEVEL_CHARGE_TIME_UPDATE, function(arg_9_0)
			if var_8_3 and not tolua.isnull(var_8_3) then
				local var_9_0 = arg_8_0.details.award_infos[tostring(arg_8_0.listInfo[arg_8_2])].open_time + xyd.tables.misc:getValue("activity_level_charge2_discount_time") - xyd.ServerTime.get():getServerTime()

				if var_9_0 <= 0 then
					var_9_0 = 0
				end

				var_8_3:setString(xyd.secondsToString(var_9_0, {
					toText = false
				}))

				if var_9_0 == 0 then
					arg_8_0:updateListInfo()
					arg_8_0.list:refreshList()
				end
			end
		end)

		table.insert(var_0_6, var_0_5)
		var_8_1:getChildByName("btn_buy"):setBright(true)
		var_8_1:getChildByName("btn_buy"):setTouchEnabled(true)
		var_8_1:getChildByName("btn_buy"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.began then
				arg_10_0:setScale(0.9)
			elseif arg_10_1 == ccui.TouchEventType.moved then
				arg_10_0:setScale(1)
			elseif arg_10_1 == ccui.TouchEventType.ended then
				arg_10_0:setScale(1)
				xyd.playButtonSound()
				arg_8_0:purchaseGiftBag(arg_8_0.listInfo[arg_8_2], true)
				xyd.WindowManager.get():closeWindow("activities")
			end
		end)
	elseif var_8_2 == var_0_7.afterDiscounting then
		var_8_1:getChildByName("old_price"):setVisible(false)
		var_8_1:getChildByName("time"):setVisible(false)
		var_8_1:getChildByName("btn_buy"):getChildByName("text_price"):setString(var_0_2:charge(arg_8_0.listInfo[arg_8_2]) .. var_0_1:translation("ACTIVITY_CHARGE_LEVEL_TEXT1"))
		var_8_1:getChildByName("btn_buy"):setBright(true)
		var_8_1:getChildByName("btn_buy"):setTouchEnabled(true)
		var_8_1:getChildByName("btn_buy"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.began then
				arg_11_0:setScale(0.9)
			elseif arg_11_1 == ccui.TouchEventType.moved then
				arg_11_0:setScale(1)
			elseif arg_11_1 == ccui.TouchEventType.ended then
				arg_11_0:setScale(1)
				xyd.playButtonSound()
				arg_8_0:purchaseGiftBag(arg_8_0.listInfo[arg_8_2], false)
				xyd.WindowManager.get():closeWindow("activities")
			end
		end)
	elseif var_8_2 == var_0_7.cannotBuy then
		var_8_1:getChildByName("old_price"):setVisible(false)
		var_8_1:getChildByName("time"):setVisible(false)
		var_8_1:getChildByName("btn_buy"):getChildByName("text_price"):setString(var_0_1:translation("ACTIVITY_CHARGE_LEVEL_TEXT2"))
		var_8_1:getChildByName("btn_buy"):getChildByName("text_price"):setColor(cc.c4b(109, 88, 73, 255))
		var_8_1:getChildByName("btn_buy"):setBright(false)
		var_8_1:getChildByName("btn_buy"):setTouchEnabled(false)
	elseif var_8_2 == var_0_7.hasBought then
		var_8_1:getChildByName("old_price"):setVisible(false)
		var_8_1:getChildByName("time"):setVisible(false)
		var_8_1:getChildByName("btn_buy"):getChildByName("text_price"):setString(var_0_1:translation("ACTIVITY_CHARGE_LEVEL_TEXT3"))
		var_8_1:getChildByName("btn_buy"):getChildByName("text_price"):setColor(cc.c4b(109, 88, 73, 255))
		var_8_1:getChildByName("btn_buy"):setBright(false)
		var_8_1:getChildByName("btn_buy"):setTouchEnabled(false)
	end
end

function var_0_0.purchaseGiftBag(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = true
	local var_12_1
	local var_12_2
	local var_12_3

	if arg_12_2 then
		var_12_1 = var_0_2:discountChargeID(arg_12_1)
		var_12_2 = var_0_2:discountCharge(arg_12_1)
		var_12_3 = var_0_2:discountProductID(arg_12_1)
	else
		var_12_1 = var_0_2:chargeID(arg_12_1)
		var_12_2 = var_0_2:charge(arg_12_1)
		var_12_3 = var_0_2:productID(arg_12_1)
	end

	if device.platform == "android" then
		xyd.androidPurchase({
			var_12_1
		}, {}, var_12_1, false, var_12_2, var_0_2:name(arg_12_1))
	elseif device.platform == "ios" then
		xyd.sdkPurchase(var_12_3, var_12_0, var_12_1, {}, {}, {
			var_12_1
		})
	end
end

function var_0_0.rewardLayer(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = xyd.tables.gift:items(arg_13_2)

	if #var_13_0 == 1 and var_13_0[1] == 0 then
		var_13_0 = {}
	end

	local var_13_1 = xyd.tables.gift:itemNum(arg_13_2)
	local var_13_2 = #var_13_1
	local var_13_3 = arg_13_1:getContentSize().width / 2 - 10
	local var_13_4 = 10
	local var_13_5 = #var_13_0

	for iter_13_0 = 1, #var_13_0 do
		local var_13_6 = display.newNode()

		var_13_6:setContentSize(var_13_3, var_13_3)

		local var_13_7 = xyd.tables.item:type(var_13_0[iter_13_0])

		xyd.setItemBorder(var_13_6, var_13_0[iter_13_0], false, false, var_13_1[iter_13_0])
		var_13_6:addTo(arg_13_1)
		var_13_6:setAnchorPoint(cc.p(0, 0))
		var_13_6:setPosition((1 - iter_13_0 % 2) * (var_13_3 + var_13_4), (3 - math.ceil(iter_13_0 / 2)) * (var_13_3 + var_13_4))

		local var_13_8 = {
			id = var_13_0[iter_13_0],
			lev = xyd.tables.item:level(var_13_0[iter_13_0])
		}

		if xyd.tables.item:type(var_13_0[iter_13_0]) == -1 then
			var_13_8.tipsType = 0
			var_13_8.desc1 = xyd.tables.hero:getDes(var_13_0[iter_13_0])
		elseif specialItem then
			var_13_8.tipsType = 1
			var_13_8.id = -3
		else
			var_13_8.tipsType = 1
			var_13_8.desc1 = xyd.tables.item:desc1(var_13_0[iter_13_0])
			var_13_8.desc2 = xyd.tables.item:desc2(var_13_0[iter_13_0])
		end

		var_13_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_13_0[iter_13_0])
		var_13_8.name = xyd.tables.item:name(var_13_0[iter_13_0])

		arg_13_0:addTips(var_13_6, var_13_8)
	end

	local var_13_9 = var_13_5 + 1
	local var_13_10 = xyd.tables.gift:crystal(arg_13_2)

	if var_13_10 and var_13_10 > 0 then
		local var_13_11 = display.newNode()

		var_13_11:setContentSize(var_13_3, var_13_3)
		xyd.setItemBorder(var_13_11, -1, false, false, var_13_10)
		var_13_11:addTo(arg_13_1)
		var_13_11:setAnchorPoint(cc.p(0, 0))
		var_13_11:setPosition((1 - var_13_9 % 2) * (var_13_3 + var_13_4), (3 - math.ceil(var_13_9 / 2)) * (var_13_3 + var_13_4))

		local var_13_12 = {}

		var_13_12.id = -1
		var_13_12.tipsType = 1

		arg_13_0:addTips(var_13_11, var_13_12)

		var_13_9 = var_13_9 + 1
	end

	local var_13_13 = xyd.tables.gift:mana(arg_13_2)

	if var_13_13 and var_13_13 > 0 then
		local var_13_14 = display.newNode()

		var_13_14:setContentSize(var_13_3, var_13_3)
		xyd.setItemBorder(var_13_14, -2, false, false, var_13_13)
		var_13_14:addTo(arg_13_1)
		var_13_14:setAnchorPoint(cc.p(0, 0))
		var_13_14:setPosition((1 - var_13_9 % 2) * (var_13_3 + var_13_4), (3 - math.ceil(var_13_9 / 2)) * (var_13_3 + var_13_4))

		local var_13_15 = {}

		var_13_15.id = -2
		var_13_15.tipsType = 1

		arg_13_0:addTips(var_13_14, var_13_15)

		var_13_9 = var_13_9 + 1
	end

	local var_13_16 = xyd.tables.gift:drops(arg_13_2)
	local var_13_17 = false

	if var_13_16 and next(var_13_16) then
		var_13_17 = #var_13_16 ~= 1 or var_13_16[1] ~= 0
	end

	if var_13_17 then
		local var_13_18 = display.newNode()

		var_13_18:addTo(arg_13_1)
		var_13_18:setAnchorPoint(cc.p(0, 0))
		var_13_18:setPosition((1 - var_13_9 % 2) * (var_13_3 + var_13_4), (3 - math.ceil(var_13_9 / 2)) * (var_13_3 + var_13_4))
		var_13_18:setContentSize(var_13_3, var_13_3)

		local var_13_19 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		if var_13_19 then
			local var_13_20 = var_13_18:getWidth()
			local var_13_21 = var_13_18:getHeight()
			local var_13_22 = var_13_20 / var_13_19:getWidth()

			var_13_19:setScale(var_13_22)
			var_13_19:addTo(var_13_18)
			var_13_19:setAnchorPoint(cc.p(0, 0))
			var_13_19:setPosition(0, 0)

			local var_13_23 = xyd.getBorder(0, false)

			xyd.displaySpriteOnContainer(var_13_23, var_13_18, true)
		end

		local var_13_24 = {}

		var_13_24.id = -13
		var_13_24.tipsType = 1

		arg_13_0:addTips(var_13_18, var_13_24)

		local var_13_25 = var_13_9 + 1
	end

	return arg_13_1
end

function var_0_0.updateTimeCount(arg_14_0)
	var_0_4 = var_0_3.scheduleGlobal(function()
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.LEVEL_CHARGE_TIME_UPDATE
		})
	end, 1)
end

function var_0_0.release(arg_16_0)
	var_0_0.super.release(arg_16_0, params)

	if var_0_4 then
		var_0_3.unscheduleGlobal(var_0_4)

		var_0_4 = nil
	end

	for iter_16_0, iter_16_1 in pairs(var_0_6) do
		if iter_16_1 then
			xyd.EventDispatcher.get():removeEventListener(iter_16_1)
		end
	end

	var_0_6 = {}
end

return var_0_0
