local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = {
	Common = 1,
	HighLev = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.bagType = var_0_3.Common
end

function var_0_0.updateChangeTypeBtnState(arg_2_0)
	if not arg_2_0.container or tolua.isnull(arg_2_0.container) then
		return
	end

	if arg_2_0.bagType == var_0_3.Common then
		arg_2_0.container:getChildByName("common_bag_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_2_0.container:getChildByName("highlev_bag_btn"):setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_2_0.container:getChildByName("common_bag_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_2_0.container:getChildByName("highlev_bag_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.isShow(arg_3_0, arg_3_1)
	if arg_3_0.player.vip == 0 then
		return false
	else
		return true
	end
end

function var_0_0.release(arg_4_0, arg_4_1)
	if arg_4_0.handle then
		var_0_2.unscheduleGlobal(arg_4_0.handle)
	end
end

function var_0_0.show(arg_5_0, arg_5_1)
	var_0_0.super.show(arg_5_0, arg_5_1)

	arg_5_0.flags = clone(arg_5_0.activity.details.buy_nums)

	if not arg_5_0.res or arg_5_0.res == 0 then
		print("No res available.")

		return
	end

	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_5_0.res)

	var_5_0:addTo(arg_5_0.parent)
	var_5_0:setAnchorPoint(cc.p(0, 0))
	var_5_0:setPosition(0, 0)

	arg_5_0.container = var_5_0:getChildByName("container")

	arg_5_0:updateChangeTypeBtnState()
	arg_5_0:updateDownTimer()

	local var_5_1 = arg_5_0.container:getChildByName("desc_container")
	local var_5_2 = var_5_1:getContentSize()
	local var_5_3 = var_0_1:translation("VIP_WEEK_GIFT")
	local var_5_4 = xyd.split(var_5_3, "\n")

	for iter_5_0 = 1, #var_5_4 do
		xyd.AssetLoader.get():loadSprite("windows/activities/1044/star.png"):addTo(var_5_1):pos(10, var_5_2.height - (iter_5_0 - 1) * 40 - 20)

		local var_5_5 = xyd.createLabel(24, cc.c3b(26, 34, 60))

		var_5_5:setString(var_5_4[iter_5_0])
		var_5_5:addTo(var_5_1):pos(30, var_5_2.height - (iter_5_0 - 1) * 40 - 20)
	end

	local var_5_6 = arg_5_0.container:getChildByName("item_container")
	local var_5_7 = var_5_6:getContentSize()

	arg_5_0.newyearList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_7.width, var_5_7.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	})

	arg_5_0.newyearList:setBounceable(false)
	arg_5_0.newyearList:addTo(var_5_6):onScroll(handler(arg_5_0, arg_5_0.scrollListener2))
	arg_5_0:setButtonClick()
	arg_5_0:updateItemList()
end

function var_0_0.getResetWeek(arg_6_0, arg_6_1)
	arg_6_0.resetWeeks = arg_6_0.activity.details.reset_weeks

	for iter_6_0 = 1, xyd.tables.ActivityVipGift:allcount() do
		if xyd.tables.ActivityVipGift:type(iter_6_0) == arg_6_1 then
			return arg_6_0.resetWeeks[iter_6_0]
		end
	end
end

function var_0_0.updateDownTimer(arg_7_0)
	if arg_7_0.handler then
		var_0_2.unscheduleGlobal(arg_7_0.handler)

		arg_7_0.handler = nil
	end

	local var_7_0 = arg_7_0.container:getChildByName("fresh_time_txt")

	local function var_7_1()
		local var_8_0 = tonumber(xyd.ServerTime.get():getServerTime())

		if not var_8_0 then
			if arg_7_0 and arg_7_0.handler and not tolua.isnull(arg_7_0.handler) then
				var_0_2.unscheduleGlobal(arg_7_0.handler)

				arg_7_0.handler = nil
			end

			return
		end

		local var_8_1 = tonumber(os.date("%w", var_8_0 - 64800))

		if var_8_1 == 0 then
			var_8_1 = 7
		end

		local var_8_2 = 7 * (xyd.tables.ActivityVipGift:getWeekByType(arg_7_0.bagType) - arg_7_0:getResetWeek(arg_7_0.bagType)) - var_8_1
		local var_8_3 = 23 - tonumber(os.date("%H", var_8_0 - 64800))
		local var_8_4 = 59 - tonumber(os.date("%M", var_8_0))

		if var_8_3 >= 24 then
			var_8_3 = var_8_3 % 24
			var_8_2 = var_8_2 + 1
		end

		if var_7_0 and not tolua.isnull(var_7_0) then
			var_7_0:setString(string.format(var_0_1:translation("VIP_CHONGZHI_TIME"), var_8_2, var_8_3, var_8_4))
		end
	end

	var_7_1()

	arg_7_0.handle = var_0_2.scheduleGlobal(handler(arg_7_0, var_7_1), 1)
end

function var_0_0.setButtonClick(arg_9_0)
	if arg_9_0.container and not tolua.isnull(arg_9_0.container) then
		local var_9_0 = arg_9_0.container:getChildByName("common_bag_btn")

		var_9_0:getChildByName("common_bag_text"):setString(var_0_1:translation("ACTIVITY_1044_TEXT1"))
		var_9_0:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				arg_9_0.bagType = var_0_3.Common

				arg_9_0:updateChangeTypeBtnState()
				arg_9_0:updateItemList()
				arg_9_0:updateDownTimer()
			end
		end)

		local var_9_1 = arg_9_0.container:getChildByName("highlev_bag_btn")

		var_9_1:getChildByName("hignlev_bag_text"):setString(var_0_1:translation("ACTIVITY_1044_TEXT2"))
		var_9_1:addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				arg_9_0.bagType = var_0_3.HighLev

				arg_9_0:updateChangeTypeBtnState()
				arg_9_0:updateItemList()
				arg_9_0:updateDownTimer()
			end
		end)
	end
end

function var_0_0.updateItemList(arg_12_0)
	local var_12_0 = {
		list = arg_12_0.newyearList,
		activity = arg_12_0.activity
	}

	arg_12_0:createItemList(var_12_0)
end

function var_0_0.createItemList(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_1.list
	local var_13_1 = arg_13_1.activity
	local var_13_2 = arg_13_1.listNum

	var_13_0:removeAllItems()

	local var_13_3 = {}
	local var_13_4 = arg_13_0.player.vip
	local var_13_5 = xyd.tables.ActivityVipGift:allcount()
	local var_13_6 = {}

	for iter_13_0 = 1, var_13_5 do
		table.insert(var_13_6, xyd.tables.ActivityVipGift:buylimit(iter_13_0))
	end

	for iter_13_1 = 1, var_13_5 do
		if arg_13_0:checkInitItem(iter_13_1, arg_13_1) then
			local var_13_7 = var_13_0:newItem()
			local var_13_8 = display.newNode()
			local var_13_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1044/vip_week_item.csb")
			local var_13_10 = var_13_9:getChildByName("container")

			var_13_10:getChildByName("orgprice_text"):setString(var_0_1:translation("ORIGINAL_PRICE"))
			var_13_10:getChildByName("currentprice_text"):setString(var_0_1:translation("PRESENT_PRICE"))
			var_13_10:getChildByName("gift_name_txt"):setString(xyd.tables.ActivityVipGift:name(iter_13_1))

			local var_13_11 = var_13_10:getChildByName("orgprice_txt")
			local var_13_12 = var_13_10:getChildByName("currentprice_txt")

			var_13_11:setString(tonumber(xyd.tables.ActivityVipGift:price(iter_13_1)))
			var_13_12:setString(xyd.tables.ActivityVipGift:discount_price(iter_13_1))

			local var_13_13 = var_13_10:getChildByName("reward_container")
			local var_13_14 = xyd.tables.ActivityVipGift:giftid(iter_13_1)
			local var_13_15 = var_13_10:getContentSize().height
			local var_13_16 = xyd.tables.gift:items(var_13_14)

			if #var_13_16 == 1 and var_13_16[1] == 0 then
				local var_13_17 = {}
			end

			local var_13_18 = xyd.tables.gift:itemNum(var_13_14)

			if arg_13_0:isHaveBagIcon(iter_13_1) then
				arg_13_0:rewardFormatWithBagIcon(var_13_13, var_13_14, iter_13_1)
			else
				arg_13_0:rewardFormat(var_13_13, var_13_14, var_13_1)
			end

			local var_13_19 = var_13_10:getChildByName("buy_btn"):getChildByName("buy_text")

			var_13_19:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT6"))

			local var_13_20 = var_13_10:getChildByName("buy_btn")
			local var_13_21 = var_13_10:getChildByName("buy_gray_btn"):getChildByName("buy_gray_text")

			var_13_21:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT6"))

			local var_13_22 = var_13_10:getChildByName("buy_gray_btn")

			if tonumber(arg_13_0.flags[iter_13_1]) == 0 and arg_13_0.player.vip >= xyd.tables.ActivityVipGift:level_limit(iter_13_1) then
				var_13_19:setVisible(true)
				var_13_20:setVisible(true)
				var_13_20:setTouchEnabled(true)
				var_13_22:setVisible(false)
				var_13_21:setVisible(false)
			else
				var_13_19:setVisible(false)
				var_13_20:setTouchEnabled(false)
				var_13_20:setVisible(false)
				var_13_22:setVisible(true)
				var_13_21:setVisible(true)
			end

			var_13_20:addTouchEventListener(function(arg_14_0, arg_14_1)
				local function var_14_0()
					arg_13_0.flags[iter_13_1] = "1"
					arg_13_0.activity.details.buy_nums = arg_13_0.flags

					if tonumber(arg_13_0.flags[iter_13_1]) > 0 then
						var_13_19:setVisible(false)
						var_13_20:setTouchEnabled(false)
						var_13_20:setVisible(false)
						var_13_22:setVisible(true)
						var_13_21:setVisible(true)
					end
				end

				if arg_14_1 == ccui.TouchEventType.began then
					var_13_20:setScale(0.9)
				elseif arg_14_1 == ccui.TouchEventType.moved then
					var_13_20:setScale(1)
				elseif arg_14_1 == ccui.TouchEventType.ended then
					var_13_20:setScale(1)

					if arg_13_0.scrollViewMoved2_ == true then
						return
					end

					if arg_13_0.player.crystal < xyd.tables.ActivityVipGift:discount_price(iter_13_1) then
						message = var_0_1:translation("ZUANSHI_ABSENCE")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, message, function()
							local var_16_0 = {}

							var_16_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					elseif xyd.tables.ActivityVipGift:giftChoiceNum(iter_13_1) and xyd.tables.ActivityVipGift:giftChoiceNum(iter_13_1) > 0 then
						local var_14_1 = {
							count = iter_13_1,
							table_id = var_13_1.table_id,
							callback = var_14_0
						}

						xyd.WindowManager.get():openWindow("vipgift_choice", var_14_1)
					else
						str = string.format(var_0_1:translation("VIP_CONFIRM_TIP"), xyd.tables.ActivityVipGift:name(iter_13_1), xyd.tables.ActivityVipGift:discount_price(iter_13_1))

						local var_14_2 = xyd.CommonAlertType.TWO_BTN
						local var_14_3 = xyd.luaStringSplit(str, "\n")

						xyd.CommonAlertWindow.open(var_14_2, var_14_3, function()
							if var_14_2 == xyd.CommonAlertType.TWO_BTN then
								arg_13_0.activitiesModel:getActivityReward(var_13_1.table_id, iter_13_1, function(arg_18_0, arg_18_1)
									if arg_18_0 == xyd.error.OK then
										arg_13_0.player:handleRewards(arg_18_1.awards)
										arg_13_0.activitiesModel:clearRedMarkState(var_13_1.table_id, 2)
										var_14_0()
									end
								end)
							end
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					end
				end
			end)
			var_13_9:addTo(var_13_8)
			var_13_9:setTouchEnabled(true)
			var_13_9:setAnchorPoint(cc.p(0, 0))
			var_13_9:setPosition(0, 0)
			var_13_9:setTouchSwallowEnabled(false)
			var_13_8:setContentSize(667, 166)
			var_13_7:addContent(var_13_8)
			var_13_7:setItemSize(667, 176)
			var_13_0:addItem(var_13_7)
		end
	end

	var_13_0:reload()
end

function var_0_0.rewardFormatWithBagIcon(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local var_19_0 = arg_19_1:getContentSize().height
	local var_19_1 = var_19_0 / 4
	local var_19_2 = xyd.tables.gift:items(arg_19_2)

	if #var_19_2 == 1 and var_19_2[1] == 0 then
		var_19_2 = {}
	end

	local var_19_3 = xyd.tables.gift:itemNum(arg_19_2)
	local var_19_4 = xyd.tables.ActivityVipGift:dropDesc(arg_19_3)
	local var_19_5 = #var_19_4 + #var_19_2

	for iter_19_0 = 1, #var_19_4 do
		local var_19_6 = display.newNode()

		var_19_6:setContentSize(arg_19_1:getHeight(), arg_19_1:getHeight())
		xyd.setSpriteBorder(var_19_6, xyd.tables.ActivityVipGift:dropIcon(arg_19_3), 1)
		var_19_6:addTo(arg_19_1)
		var_19_6:setPosition((iter_19_0 - 1) * (var_19_0 + var_19_1), 0)
		var_19_6:setAnchorPoint(cc.p(0, 0))

		local var_19_7 = {}

		var_19_7.id = -100000
		var_19_7.tipsType = 1
		var_19_7.desc1 = var_19_4[iter_19_0]

		arg_19_0:addTips(var_19_6, var_19_7)
	end

	local var_19_8 = #var_19_2

	for iter_19_1 = 1, #var_19_2 do
		local var_19_9 = display.newNode()

		var_19_9:setContentSize(var_19_0, var_19_0)

		if xyd.tables.item:type(var_19_2[iter_19_1]) == -1 then
			xyd.setAvatarBorder(var_19_2[iter_19_1], var_19_9, 1, xyd.tables.hero:initialStar(var_19_2[iter_19_1]))
		else
			xyd.setItemBorder(var_19_9, var_19_2[iter_19_1], false, false, var_19_3[iter_19_1])
		end

		var_19_9:addTo(arg_19_1)
		var_19_9:setAnchorPoint(cc.p(0, 0))
		var_19_9:setPosition((iter_19_1 - 1 + #var_19_4) * (var_19_0 + var_19_1), 0)

		local var_19_10 = {
			id = var_19_2[iter_19_1],
			lev = xyd.tables.item:level(var_19_2[iter_19_1])
		}

		if xyd.tables.item:type(var_19_2[iter_19_1]) == -1 then
			var_19_10.tipsType = 0
			var_19_10.desc1 = xyd.tables.hero:getDes(var_19_2[iter_19_1])
		elseif specialItem then
			var_19_10.tipsType = 1
			var_19_10.id = -3
		else
			var_19_10.tipsType = 1
			var_19_10.desc1 = xyd.tables.item:desc1(var_19_2[iter_19_1])
			var_19_10.desc2 = xyd.tables.item:desc2(var_19_2[iter_19_1])
		end

		var_19_10.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_19_2[iter_19_1])
		var_19_10.name = xyd.tables.item:name(var_19_2[iter_19_1])

		arg_19_0:addTips(var_19_9, var_19_10)
	end

	local var_19_11 = xyd.tables.gift:crystal(arg_19_2)

	if var_19_11 and var_19_11 > 0 then
		local var_19_12 = display.newNode()

		var_19_12:setContentSize(var_19_0, var_19_0)
		xyd.setItemBorder(var_19_12, -1, false, false, var_19_11)
		var_19_12:addTo(arg_19_1)
		var_19_12:setAnchorPoint(cc.p(0, 0))
		var_19_12:setPosition(var_19_8 * (var_19_0 + var_19_1), 0)

		local var_19_13 = {}

		var_19_13.id = -1
		var_19_13.tipsType = 1

		arg_19_0:addTips(var_19_12, var_19_13)

		var_19_8 = var_19_8 + 1
	end

	local var_19_14 = xyd.tables.gift:mana(arg_19_2)

	if var_19_14 and var_19_14 > 0 then
		local var_19_15 = display.newNode()

		var_19_15:setContentSize(var_19_0, var_19_0)
		xyd.setItemBorder(var_19_15, -2, false, false, var_19_14)
		var_19_15:addTo(arg_19_1)
		var_19_15:setAnchorPoint(cc.p(0, 0))
		var_19_15:setPosition(var_19_8 * (var_19_0 + var_19_1), 0)

		local var_19_16 = {}

		var_19_16.id = -2
		var_19_16.tipsType = 1

		arg_19_0:addTips(var_19_15, var_19_16)

		local var_19_17 = var_19_8 + 1
	end
end

function var_0_0.scrollListener2(arg_20_0, arg_20_1)
	if arg_20_1.name == "began" then
		arg_20_0.scrollViewMoved2_ = false
		arg_20_0.prevY_ = arg_20_1.y
	elseif arg_20_1.name == "moved" and 20 <= math.abs(arg_20_1.y - arg_20_0.prevY_) then
		arg_20_0.scrollViewMoved2_ = true
	end
end

function var_0_0.checkInitItem(arg_21_0, arg_21_1, arg_21_2)
	if xyd.tables.ActivityVipGift:type(arg_21_1) == arg_21_0.bagType then
		return true
	else
		return false
	end
end

function var_0_0.isHaveBagIcon(arg_22_0, arg_22_1)
	if xyd.tables.ActivityVipGift:dropIcon(arg_22_1) ~= "" then
		return true
	else
		return false
	end
end

return var_0_0
