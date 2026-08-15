local var_0_0 = class("ActivityNewCandleWishWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activity = arg_1_2.activity
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.idx = arg_1_2.idx
	arg_1_0.wishInfo = arg_1_0.details.wish_info[arg_1_0.idx]
	arg_1_0.candleNum = arg_1_0.wishInfo.wish_times
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.startTime = arg_1_0.activity.start_time
	arg_1_0.endTime = arg_1_0.activity.end_time
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_time"):setVisible(false)
	arg_4_0:rewardFormat(arg_4_0:nodeByName("desc_container"), 20)
	arg_4_0:nodeByName("title"):setString(xyd.tables.activityServerCandle:name(arg_4_0.idx))

	local var_4_0 = xyd.tables.misc.activityServerCandleCost

	arg_4_0:nodeByName("text_bottom_2"):setString(string.format(var_0_2:translation("WISH_CANDLE_TIPS_1"), var_4_0))
	arg_4_0:nodeByName("text_bottom_3"):setString(var_0_2:translation("ACTIVITY_NEW_CANDLE_COST_TEXT"))
	arg_4_0:nodeByName("text_mid_3"):setString(var_0_2:translation("WISH_CANDLE_TIPS_4"))
	arg_4_0:nodeByName("text_act_des"):setString(var_0_2:translation("ACTIVITY_NEW_CANDLE_AWARD_TIP"))
	arg_4_0:updateLoadingBar()
	arg_4_0:updateCandleNum()
	arg_4_0:nodeByName("btn_wish_normal"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = xyd.ServerTime.get():getServerTime()

			if var_5_0 < arg_4_0.startTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_NO_OPEN")
				})
			elseif var_5_0 > arg_4_0.endTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_11")
				})
			elseif arg_4_0.candleNum >= arg_4_0.maxCandleNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_8")
				})
			elseif arg_4_0.backpackCandleNum <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_9")
				})
			else
				arg_4_0:makeRequestWish(xyd.WishCandleType.candle)
			end
		end
	end)
	arg_4_0:nodeByName("btn_wish_diamond"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = xyd.ServerTime.get():getServerTime()

			if var_6_0 < arg_4_0.startTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_NO_OPEN")
				})
			elseif var_6_0 > arg_4_0.endTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_11")
				})
			elseif arg_4_0.candleNum == arg_4_0.maxCandleNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_8")
				})
			elseif var_4_0 > arg_4_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					local var_7_0 = {}

					var_7_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
				end, nil, nil, arg_4_0.colorMode)
			else
				local var_6_1 = string.format(var_0_2:translation("ACTIVITY_NEW_CANDLE_WISH_DIAMOND_TIPS"), var_4_0)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_1, function()
					local var_8_0 = {}

					arg_4_0:makeRequestWish(xyd.WishCandleType.yuanbao)
				end, nil, nil, arg_4_0.colorMode)
			end
		end
	end)
end

function var_0_0.updateLoadingBar(arg_9_0)
	arg_9_0.maxCandleNum = xyd.tables.misc.activityServerCandleTotal

	local var_9_0 = 0
	local var_9_1 = arg_9_0.candleNum >= arg_9_0.maxCandleNum and 100 or math.floor(100 * arg_9_0.candleNum / arg_9_0.maxCandleNum)

	arg_9_0:nodeByName("loading_bar"):setPercent(var_9_1)
	arg_9_0:nodeByName("text_loading_bar"):setString(arg_9_0.candleNum .. "/" .. arg_9_0.maxCandleNum)
end

function var_0_0.didClose(arg_10_0)
	if arg_10_0.handler then
		var_0_1.unscheduleGlobal(arg_10_0.handler)

		arg_10_0.handler = nil
	end
end

function var_0_0.makeRequestWish(arg_11_0, arg_11_1)
	local var_11_0 = {
		wish_type = arg_11_1,
		id = arg_11_0.idx
	}

	xyd.Backend.get():request(xyd.mid.ACTIVITY_NEW_CANDLE_WISH, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			if arg_12_1.awards then
				arg_11_0.selfPlayer:handleRewards(arg_12_1.awards)
			end

			if arg_11_1 == xyd.WishCandleType.candle then
				arg_11_0.backpackCandleNum = arg_11_0.backpackCandleNum - 1

				arg_11_0.backpack_:setItemNumByID(xyd.tables.misc.activityServerCandleItem, arg_11_0.backpackCandleNum)
			end

			if arg_12_1.wish_info then
				arg_11_0.wishInfo.wish_times = arg_12_1.wish_info.wish_times
			end

			arg_11_0.candleNum = arg_11_0.wishInfo.wish_times
			arg_11_0.details.base_info.wish_times = arg_11_0.details.base_info.wish_times + 1

			arg_11_0:updateLoadingBar()
			arg_11_0:updateCandleNum()

			if arg_11_0.callback then
				arg_11_0.callback()
			end
		end
	end)
end

function var_0_0.updateCandleNum(arg_13_0)
	arg_13_0.backpack_ = arg_13_0.selfPlayer:getBackpack()
	arg_13_0.backpackCandleNum = arg_13_0.backpack_:getItemNumByID(xyd.tables.misc.activityServerCandleItem) or 0

	arg_13_0:nodeByName("text_bottom_1"):setString(string.format(var_0_2:translation("WISH_CANDLE_TIPS_3"), arg_13_0.backpackCandleNum))
end

function var_0_0.rewardFormat(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1:getContentSize().height
	local var_14_1 = margin or var_14_0 / 4
	local var_14_2 = xyd.tables.activityServerCandle:itemIds(arg_14_0.idx)

	if #var_14_2 == 1 and var_14_2[1] == 0 then
		var_14_2 = {}
	end

	local var_14_3 = xyd.tables.activityServerCandle:itemNums(arg_14_0.idx)

	for iter_14_0 = 1, #var_14_2 do
		local var_14_4 = display.newNode()

		var_14_4:setContentSize(var_14_0, var_14_0)

		if xyd.tables.item:type(var_14_2[iter_14_0]) == -1 then
			xyd.setAvatarBorder(var_14_2[iter_14_0], var_14_4, 1, xyd.tables.hero:initialStar(var_14_2[iter_14_0]))
		else
			xyd.setItemBorder(var_14_4, var_14_2[iter_14_0], false, false, var_14_3[iter_14_0])
		end

		var_14_4:addTo(arg_14_1)
		var_14_4:setAnchorPoint(cc.p(0, 0))
		var_14_4:setPosition((iter_14_0 - 1) * (var_14_0 + var_14_1), 0)

		local var_14_5 = {
			id = var_14_2[iter_14_0],
			lev = xyd.tables.item:level(var_14_2[iter_14_0])
		}

		if xyd.tables.item:type(var_14_2[iter_14_0]) == -1 then
			var_14_5.tipsType = 0
			var_14_5.desc1 = xyd.tables.hero:getDes(var_14_2[iter_14_0])
		elseif specialItem then
			var_14_5.tipsType = 1
			var_14_5.id = -3
		else
			var_14_5.tipsType = 1
			var_14_5.desc1 = xyd.tables.item:desc1(var_14_2[iter_14_0])
			var_14_5.desc2 = xyd.tables.item:desc2(var_14_2[iter_14_0])
		end

		var_14_5.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_14_2[iter_14_0])
		var_14_5.name = xyd.tables.item:name(var_14_2[iter_14_0])

		arg_14_0:addTips(var_14_4, var_14_5)
	end

	return arg_14_1
end

return var_0_0
