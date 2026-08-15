local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
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
	var_2_0:setPosition(0, 0)
	arg_2_0:petGiftLayout(arg_2_0.activity, arg_2_0.idx, var_2_0)
end

function var_0_0.petGiftLayout(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local function var_3_0(arg_4_0)
		arg_4_0:getChildByName("btn"):setTouchEnabled(false)
		arg_4_0:getChildByName("btn"):setBright(false)
		arg_4_0:getChildByName("not_begin"):hide()
		arg_4_0:getChildByName("already_buy_gray"):hide()
		arg_4_0:getChildByName("goumai_fund_txt"):hide()
		arg_4_0:getChildByName("bought"):show()
	end

	local function var_3_1(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
		local var_5_0 = xyd.tables.activityPetGiftTable:buyCount(arg_5_1)

		if var_5_0 < 0 then
			arg_5_0:getChildByName("hasBougntNum"):hide()
			arg_5_0:getChildByName("canBuyNum"):hide()
			arg_5_0:getChildByName("separatorLine"):hide()
			arg_5_0:getChildByName("person"):hide()
		else
			local var_5_1 = arg_5_0:getChildByName("hasBougntNum")
			local var_5_2 = arg_5_0:getChildByName("canBuyNum")

			if arg_3_0.countBuyTimes[arg_5_1] >= 0 and arg_5_2.is_open == 1 then
				var_5_1:setString(arg_3_0.countBuyTimes[arg_5_1])
				var_5_2:setString(var_5_0)

				if var_5_0 <= arg_3_0.countBuyTimes[arg_5_1] and arg_5_3 == false then
					arg_3_0:setGiftState(arg_5_1)
				elseif arg_5_3 then
					var_3_0(arg_5_0)
				end
			else
				var_5_1:setString(0)
				var_5_2:setString(var_5_0)
			end
		end
	end

	local function var_3_2(arg_6_0, arg_6_1)
		local var_6_0 = arg_6_0:getChildByName("reward"):getContentSize().height
		local var_6_1 = display.newNode()

		var_6_1:addTo(arg_6_0:getChildByName("reward"))
		var_6_1:setAnchorPoint(cc.p(0, 0))
		var_6_1:setContentSize(var_6_0, var_6_0)

		local var_6_2 = xyd.tables.activityPetGiftTable:icon(arg_6_1)
		local var_6_3 = xyd.SpriteLoader.new(var_6_2, nil, nil, xyd.DefaultImageType.ITEM_ICON, var_6_1)

		var_6_3:setAnchorPoint(cc.p(0, 0))
		var_6_3:addTo(var_6_1)

		local var_6_4 = xyd.getBorder(2, false)

		xyd.displaySpriteOnContainer(var_6_4, var_6_1, true)

		local var_6_5 = {}

		var_6_5.id = -12
		var_6_5.tipsType = 1
		var_6_5.specialTips = arg_6_1

		arg_3_0:addTips(var_6_1, var_6_5)

		local var_6_6 = arg_6_0:getChildByName("itemname")
		local var_6_7 = arg_6_0:getChildByName("price_frame"):getChildByName("price_num1")
		local var_6_8 = arg_6_0:getChildByName("price_frame"):getChildByName("price_num2")

		var_6_6:setString(xyd.tables.activityPetGiftTable:name(arg_6_1))
		arg_6_0:getChildByName("bg_check"):setVisible(false)

		local var_6_9 = xyd.tables.activityPetGiftTable:detailText(arg_6_1)
		local var_6_10 = xyd.tables.activityPetGiftTable:detailIcon(arg_6_1)

		if var_6_9 and var_6_9 ~= 0 and next(var_6_10) then
			arg_6_0:getChildByName("bg_check"):setVisible(true)
			xyd.imgEvent(arg_6_0:getChildByName("bg_check"), function()
				local var_7_0 = {
					title = var_6_9,
					data = var_6_10
				}

				xyd.WindowManager.get():openWindow("pet_gift_item_show", var_7_0)
			end)
		end

		var_6_7:setString(xyd.tables.activityPetGiftTable:price(arg_6_1))
		var_6_8:setString(xyd.tables.activityPetGiftTable:discount_price(arg_6_1))

		local var_6_11 = arg_6_0:getChildByName("Image_1")
		local var_6_12 = arg_6_0:getChildByName("txt_discount")

		var_6_11:setVisible(false)
		var_6_12:setVisible(false)

		local var_6_13 = xyd.tables.activityPetGiftTable:discount(arg_6_1)

		if var_6_13 <= 10 then
			var_6_11:setVisible(true)
			var_6_12:setVisible(true)
			var_6_12:setString(tostring((10 - var_6_13) * 10) .. "%off")
		end
	end

	arg_3_0.playerVipLev = arg_3_0.player.vip
	arg_3_0.giftCounts = xyd.tables.activityPetGiftTable:allcount()

	if not arg_3_0.countBuyTimes then
		arg_3_0.countBuyTimes = {}

		for iter_3_0 = 1, #arg_3_0.giftCounts do
			local var_3_3 = tonumber(arg_3_1.details.buy_nums[iter_3_0])

			table.insert(arg_3_0.countBuyTimes, var_3_3)
		end
	end

	local var_3_4 = arg_3_3:getChildByName("container")

	var_3_4:getChildByName("topItemList"):getChildByName("title"):setString(var_0_1:translation("PET_GIFT_RULE"))

	local var_3_5 = var_3_4:getChildByName("rewardlist"):getContentSize()
	local var_3_6 = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_3_5.width, var_3_5.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_4:getChildByName("rewardlist")):onScroll(handler(arg_3_0, arg_3_0.scrollListener2))

	arg_3_0.btn = {}
	arg_3_0.giftContainer = {}
	arg_3_0.hasBought = {}
	arg_3_0.hasBoughtIndex = {}

	for iter_3_1 = 1, #arg_3_0.giftCounts do
		local var_3_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1057/pet_gift_item.csb")
		local var_3_8 = var_3_7:getChildByName("container")

		table.insert(arg_3_0.btn, var_3_8:getChildByName("btn"))
		table.insert(arg_3_0.giftContainer, var_3_8)

		if arg_3_1.is_open == 0 then
			var_3_8:getChildByName("not_begin"):show()
			var_3_8:getChildByName("btn"):setBright(false)
			var_3_8:getChildByName("btn"):setTouchEnabled(false)
			var_3_8:getChildByName("already_buy_gray"):hide()
			var_3_8:getChildByName("goumai_fund_txt"):hide()
			var_3_8:getChildByName("bought"):hide()
			var_3_2(var_3_8, iter_3_1)
			var_3_1(var_3_8, iter_3_1, arg_3_1)

			local var_3_9 = display.newNode()
			local var_3_10 = var_3_8:getWidth()
			local var_3_11 = var_3_8:getHeight()

			var_3_9:setContentSize(var_3_10, var_3_11)
			var_3_7:addTo(var_3_9)
			var_3_9:setAnchorPoint(cc.p(0, 0))

			local var_3_12 = var_3_6:newItem()

			var_3_12:addContent(var_3_9)
			var_3_12:setItemSize(var_3_10, var_3_11)
			var_3_6:addItem(var_3_12)
			var_3_6:reload()
		else
			var_3_8:getChildByName("not_begin"):hide()
			var_3_8:getChildByName("btn"):setBright(true)
			var_3_8:getChildByName("btn"):setTouchEnabled(true)
			var_3_8:getChildByName("goumai_fund_txt"):show()
			var_3_8:getChildByName("already_buy_gray"):hide()
			var_3_8:getChildByName("bought"):hide()

			local var_3_13 = xyd.tables.activityPetGiftTable:buyCount(iter_3_1)

			if var_3_13 > arg_3_0.countBuyTimes[iter_3_1] or var_3_13 == -1 then
				var_3_2(var_3_8, iter_3_1)
				var_3_1(var_3_8, iter_3_1, arg_3_1)

				local var_3_14 = display.newNode()
				local var_3_15 = var_3_8:getWidth()
				local var_3_16 = var_3_8:getHeight()

				var_3_14:setContentSize(var_3_15, var_3_16)
				var_3_7:addTo(var_3_14)
				var_3_14:setAnchorPoint(cc.p(0, 0))

				local var_3_17 = var_3_6:newItem()

				var_3_17:addContent(var_3_14)
				var_3_17:setItemSize(var_3_15, var_3_16)
				var_3_6:addItem(var_3_17)
				var_3_6:reload()
			else
				table.insert(arg_3_0.hasBoughtIndex, iter_3_1)
				table.insert(arg_3_0.hasBought, var_3_8)
			end
		end
	end

	local function var_3_18()
		for iter_8_0 = 1, #arg_3_0.hasBought do
			local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1057/pet_gift_item.csb")
			local var_8_1 = var_8_0:getChildByName("container")

			var_8_1:getChildByName("not_begin"):hide()
			var_8_1:getChildByName("btn"):setBright(true)
			var_8_1:getChildByName("btn"):setTouchEnabled(true)
			var_8_1:getChildByName("goumai_fund_txt"):show()
			var_8_1:getChildByName("already_buy_gray"):hide()
			var_8_1:getChildByName("bought"):hide()

			local var_8_2 = display.newNode()
			local var_8_3 = var_8_1:getWidth()
			local var_8_4 = var_8_1:getHeight()

			var_3_2(var_8_1, arg_3_0.hasBoughtIndex[iter_8_0])
			var_3_1(var_8_1, arg_3_0.hasBoughtIndex[iter_8_0], arg_3_1, true)
			var_8_2:setContentSize(var_8_3, var_8_4)
			var_8_0:addTo(var_8_2)
			var_8_2:setAnchorPoint(cc.p(0, 0))

			local var_8_5 = var_3_6:newItem()

			var_8_5:addContent(var_8_2)
			var_8_5:setItemSize(var_8_3, var_8_4)
			var_3_6:addItem(var_8_5)
			var_3_6:reload()
		end
	end

	if arg_3_1.is_open == 1 then
		var_3_18()
	end

	arg_3_0:petButtonHander(arg_3_1)
end

function var_0_0.petButtonHander(arg_9_0, arg_9_1)
	for iter_9_0 = 1, #arg_9_0.giftCounts do
		arg_9_0.btn[iter_9_0]:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended and arg_9_0.scrollViewMoved2_ ~= true then
				xyd.playButtonSound()

				local var_10_0 = xyd.tables.activityPetGiftTable:vip(iter_9_0)

				if var_10_0 > arg_9_0.playerVipLev then
					local var_10_1 = var_0_1:translation("VIP_CAN_BUY_GIFT_" .. var_10_0)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_10_1
					})
				elseif arg_9_0.player.crystal < xyd.tables.activityPetGiftTable:discount_price(iter_9_0) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_11_0 = {}

						var_11_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)

					return
				else
					local var_10_2 = string.format(var_0_1:translation("SURE_TO_BY_GIFTS"), xyd.tables.activityPetGiftTable:discount_price(iter_9_0))

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_2, function()
						arg_9_0.activitiesModel:getActivityReward(arg_9_1.table_id, iter_9_0, function(arg_13_0, arg_13_1)
							if arg_13_0 == xyd.error.OK then
								arg_9_0.player:handleRewards(arg_13_1.awards)
								arg_9_0.activitiesModel:clearRedMarkState(arg_9_1.table_id, 2)

								if xyd.tables.activityPetGiftTable:buyCount(iter_9_0) ~= -1 then
									arg_9_0.countBuyTimes[iter_9_0] = arg_9_0.countBuyTimes[iter_9_0] + 1

									arg_9_0.giftContainer[iter_9_0]:getChildByName("hasBougntNum"):setString(arg_9_0.countBuyTimes[iter_9_0])

									local var_13_0 = transition.sequence({
										cc.ScaleTo:create(0.2, 1.5),
										cc.ScaleTo:create(0.2, 1)
									})
									local var_13_1 = cc.Spawn:create(var_13_0)

									arg_9_0.giftContainer[iter_9_0]:getChildByName("hasBougntNum"):runAction(var_13_1)

									if arg_9_0.countBuyTimes[iter_9_0] >= xyd.tables.activityPetGiftTable:buyCount(iter_9_0) then
										arg_9_0:setGiftState(iter_9_0)
									end
								end
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				end
			end
		end)
	end
end

function var_0_0.setGiftState(arg_14_0, arg_14_1)
	for iter_14_0 = 1, #arg_14_0.giftCounts do
		if iter_14_0 == arg_14_1 then
			arg_14_0.giftContainer[iter_14_0]:getChildByName("btn"):setTouchEnabled(false)
			arg_14_0.giftContainer[iter_14_0]:getChildByName("btn"):setBright(false)
			arg_14_0.giftContainer[iter_14_0]:getChildByName("not_begin"):hide()
			arg_14_0.giftContainer[iter_14_0]:getChildByName("already_buy_gray"):hide()
			arg_14_0.giftContainer[iter_14_0]:getChildByName("goumai_fund_txt"):hide()
			arg_14_0.giftContainer[iter_14_0]:getChildByName("bought"):show()
			arg_14_0.giftContainer[iter_14_0]:getChildByName("hasBougntNum"):setColor(cc.c4b(179, 179, 179, 0))
			arg_14_0.giftContainer[iter_14_0]:getChildByName("canBuyNum"):setColor(cc.c4b(179, 179, 179, 0))
			arg_14_0.giftContainer[iter_14_0]:getChildByName("separatorLine"):setColor(cc.c4b(179, 179, 179, 0))
		end
	end
end

function var_0_0.scrollListener2(arg_15_0, arg_15_1)
	if arg_15_1.name == "began" then
		arg_15_0.scrollViewMoved2_ = false
		arg_15_0.prevY_ = arg_15_1.y
	elseif arg_15_1.name == "moved" and 20 <= math.abs(arg_15_1.y - arg_15_0.prevY_) then
		arg_15_0.scrollViewMoved2_ = true
	end
end

return var_0_0
