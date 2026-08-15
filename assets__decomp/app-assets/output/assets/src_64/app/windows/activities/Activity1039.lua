local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySpringFestival

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
	arg_2_0:sakuraSellLayout(arg_2_0.activity, arg_2_0.idx, var_2_0)
end

function var_0_0.sakuraSellLayout(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local function var_3_0(arg_4_0)
		arg_4_0:getChildByName("btn"):setTouchEnabled(false)
		arg_4_0:getChildByName("btn"):setBright(false)
	end

	local function var_3_1(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
		local var_5_0 = xyd.tables.activitySpringFestival:buyCount(arg_5_1)

		if var_5_0 < 0 then
			arg_5_0:getChildByName("buy_num"):setVisible(false)
			arg_5_0:getChildByName("person"):setVisible(false)
		else
			arg_5_0:getChildByName("person"):setString(var_0_1:translation("NEWYEAR_BUYLIMIT_PERSON"))

			local var_5_1 = arg_5_0:getChildByName("buy_num")

			if arg_3_0.countBuyTimes[arg_5_1] >= 0 and arg_5_2.is_open == 1 then
				var_5_1:setString(arg_3_0.countBuyTimes[arg_5_1] .. "/" .. var_5_0)

				if var_5_0 <= arg_3_0.countBuyTimes[arg_5_1] and arg_5_3 == false then
					arg_3_0:setGiftState(arg_5_1)
				elseif arg_5_3 then
					var_3_0(arg_5_0)
				end
			else
				var_5_1:setString("0/" .. var_5_0)
			end
		end
	end

	local function var_3_2(arg_6_0, arg_6_1)
		local var_6_0 = arg_6_0:getChildByName("reward"):getContentSize().height
		local var_6_1 = display.newNode()

		var_6_1:addTo(arg_6_0:getChildByName("reward"))
		var_6_1:setAnchorPoint(cc.p(0, 0))
		var_6_1:setContentSize(var_6_0, var_6_0)

		local var_6_2 = xyd.tables.activitySpringFestival:icon(arg_6_1)
		local var_6_3 = xyd.AssetLoader.get():loadSprite(var_6_2)

		if var_6_3 then
			local var_6_4 = var_6_1:getWidth()
			local var_6_5 = var_6_1:getHeight()
			local var_6_6 = var_6_3:getWidth()
			local var_6_7 = (var_6_4 - 20) / (var_6_6 - 11)

			var_6_3:setScale(var_6_7)
			var_6_3:addTo(var_6_1)
			var_6_3:setAnchorPoint(cc.p(0.5, 0.5))
			var_6_3:setPosition(var_6_4 / 2, var_6_5 / 2)

			local var_6_8 = xyd.getBorder(2, false)

			xyd.displaySpriteOnContainer(var_6_8, var_6_1, true)
		end

		local var_6_9 = {}

		var_6_9.id = -14
		var_6_9.tipsType = 1
		var_6_9.specialTips = arg_6_1

		arg_3_0:addTips(var_6_1, var_6_9)
		arg_6_0:getChildByName("itemname"):setString(var_0_2:name(arg_6_1))

		local var_6_10 = arg_6_0:getChildByName("price_frame")

		var_6_10:getChildByName("price1"):setString(var_0_1:translation("ORIGINAL_PRICE"))
		var_6_10:getChildByName("price2"):setString(var_0_1:translation("PRESENT_PRICE"))
		var_6_10:getChildByName("price_num1"):setString(var_0_2:price(arg_6_1))
		var_6_10:getChildByName("price_num2"):setString(var_0_2:discount_price(arg_6_1))
		arg_6_0:getChildByName("bg_discount"):getChildByName("txt"):setString(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_0_2:discount(arg_6_1)))
	end

	arg_3_0.playerVipLev = arg_3_0.player.vip
	arg_3_0.giftCounts = xyd.tables.activitySpringFestival:allcount()

	if not arg_3_0.countBuyTimes then
		arg_3_0.countBuyTimes = {}

		for iter_3_0 = 1, #arg_3_0.giftCounts do
			local var_3_3 = tonumber(arg_3_1.details.buy_nums[iter_3_0])

			table.insert(arg_3_0.countBuyTimes, var_3_3)
		end
	end

	local var_3_4 = arg_3_3:getChildByName("bg_desc"):getChildByName("txt")

	var_3_4:enableOutline(cc.c4b(255, 255, 255, 255), 1)
	var_3_4:setString(var_0_1:translation("SAKURASELLRULES"))

	local var_3_5 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 605, 370),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_3:getChildByName("bg_list"):getChildByName("rewardlist")):onScroll(handler(arg_3_0, arg_3_0.scrollListener2))

	arg_3_0.btn = {}
	arg_3_0.giftContainer = {}
	arg_3_0.hasBought = {}
	arg_3_0.hasBoughtIndex = {}

	for iter_3_1 = 1, #arg_3_0.giftCounts do
		local var_3_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1039/spring_gift_item.csb")
		local var_3_7 = var_3_6:getChildByName("container")

		table.insert(arg_3_0.btn, var_3_7:getChildByName("btn"))
		table.insert(arg_3_0.giftContainer, var_3_7)
		var_3_7:getChildByName("btn"):getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT6"))

		if arg_3_1.is_open == 0 then
			var_3_7:getChildByName("btn"):setBright(false)
			var_3_7:getChildByName("btn"):setTouchEnabled(false)
			var_3_2(var_3_7, iter_3_1)
			var_3_1(var_3_7, iter_3_1, arg_3_1)

			local var_3_8 = display.newNode()
			local var_3_9 = var_3_7:getWidth()
			local var_3_10 = var_3_7:getHeight()

			var_3_8:setContentSize(var_3_9, var_3_10)
			var_3_6:addTo(var_3_8)
			var_3_8:setAnchorPoint(cc.p(0, 0))

			local var_3_11 = var_3_5:newItem()

			var_3_11:addContent(var_3_8)
			var_3_11:setItemSize(var_3_9, var_3_10)
			var_3_5:addItem(var_3_11)
			var_3_5:reload()
		else
			var_3_7:getChildByName("btn"):setBright(true)
			var_3_7:getChildByName("btn"):setTouchEnabled(true)

			local var_3_12 = xyd.tables.activitySpringFestival:buyCount(iter_3_1)

			if var_3_12 > arg_3_0.countBuyTimes[iter_3_1] or var_3_12 == -1 then
				var_3_2(var_3_7, iter_3_1)
				var_3_1(var_3_7, iter_3_1, arg_3_1)

				local var_3_13 = display.newNode()
				local var_3_14 = var_3_7:getWidth()
				local var_3_15 = var_3_7:getHeight()

				var_3_13:setContentSize(var_3_14, var_3_15)
				var_3_6:addTo(var_3_13)
				var_3_13:setAnchorPoint(cc.p(0, 0))

				local var_3_16 = var_3_5:newItem()

				var_3_16:addContent(var_3_13)
				var_3_16:setItemSize(var_3_14, var_3_15)
				var_3_5:addItem(var_3_16)
				var_3_5:reload()
			else
				table.insert(arg_3_0.hasBoughtIndex, iter_3_1)
				table.insert(arg_3_0.hasBought, var_3_7)
			end
		end
	end

	local function var_3_17()
		for iter_7_0 = 1, #arg_3_0.hasBought do
			local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1039/spring_gift_item.csb")
			local var_7_1 = var_7_0:getChildByName("container")

			var_7_1:getChildByName("btn"):getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT6"))
			var_7_1:getChildByName("btn"):setBright(true)
			var_7_1:getChildByName("btn"):setTouchEnabled(true)

			local var_7_2 = display.newNode()
			local var_7_3 = var_7_1:getWidth()
			local var_7_4 = var_7_1:getHeight()

			var_3_2(var_7_1, arg_3_0.hasBoughtIndex[iter_7_0])
			var_3_1(var_7_1, arg_3_0.hasBoughtIndex[iter_7_0], arg_3_1, true)
			var_7_2:setContentSize(var_7_3, var_7_4)
			var_7_0:addTo(var_7_2)
			var_7_2:setAnchorPoint(cc.p(0, 0))

			local var_7_5 = var_3_5:newItem()

			var_7_5:addContent(var_7_2)
			var_7_5:setItemSize(var_7_3, var_7_4)
			var_3_5:addItem(var_7_5)
			var_3_5:reload()
		end
	end

	if arg_3_1.is_open == 1 then
		var_3_17()
	end

	arg_3_0:sakuraSellButtonHander(arg_3_1)
end

function var_0_0.sakuraSellButtonHander(arg_8_0, arg_8_1)
	for iter_8_0 = 1, #arg_8_0.giftCounts do
		arg_8_0.btn[iter_8_0]:addTouchEventListener(function(arg_9_0, arg_9_1)
			xyd.buttonScaleAnim(arg_8_0.btn[iter_8_0], arg_9_1)

			if arg_9_1 == ccui.TouchEventType.ended and arg_8_0.scrollViewMoved2_ ~= true then
				xyd.playButtonSound()

				local var_9_0 = xyd.tables.activitySpringFestival:vip(iter_8_0)

				if var_9_0 > arg_8_0.playerVipLev then
					local var_9_1 = var_0_1:translation("VIP_CAN_BUY_GIFT_" .. var_9_0)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_9_1
					})
				elseif arg_8_0.player.crystal < xyd.tables.activitySpringFestival:discount_price(iter_8_0) then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_10_0 = {}

						var_10_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)

					return
				else
					arg_8_0.activitiesModel:getActivityReward(arg_8_1.table_id, iter_8_0, function(arg_11_0, arg_11_1)
						if arg_11_0 == xyd.error.OK then
							arg_8_0.player:handleRewards(arg_11_1.awards)
							arg_8_0.activitiesModel:clearRedMarkState(arg_8_1.table_id, 2)

							if xyd.tables.activitySpringFestival:buyCount(iter_8_0) ~= -1 then
								arg_8_0.countBuyTimes[iter_8_0] = arg_8_0.countBuyTimes[iter_8_0] + 1

								arg_8_0.giftContainer[iter_8_0]:getChildByName("buy_num"):setString(arg_8_0.countBuyTimes[iter_8_0] .. "/" .. var_0_2:buyCount(iter_8_0))

								local var_11_0 = transition.sequence({
									cc.ScaleTo:create(0.2, 1.5),
									cc.ScaleTo:create(0.2, 1)
								})
								local var_11_1 = cc.Spawn:create(var_11_0)

								arg_8_0.giftContainer[iter_8_0]:getChildByName("buy_num"):runAction(var_11_1)

								if arg_8_0.countBuyTimes[iter_8_0] >= xyd.tables.activitySpringFestival:buyCount(iter_8_0) then
									arg_8_0:setGiftState(iter_8_0)
								end
							end
						end
					end)
				end
			end
		end)
	end
end

function var_0_0.setGiftState(arg_12_0, arg_12_1)
	for iter_12_0 = 1, #arg_12_0.giftCounts do
		if iter_12_0 == arg_12_1 then
			arg_12_0.giftContainer[iter_12_0]:getChildByName("btn"):setTouchEnabled(false)
			arg_12_0.giftContainer[iter_12_0]:getChildByName("btn"):setBright(false)
		end
	end
end

function var_0_0.scrollListener2(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved2_ = false
		arg_13_0.prevY_ = arg_13_1.y
	elseif arg_13_1.name == "moved" and 20 <= math.abs(arg_13_1.y - arg_13_0.prevY_) then
		arg_13_0.scrollViewMoved2_ = true
	end
end

return var_0_0
