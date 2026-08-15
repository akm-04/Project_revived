local var_0_0 = class("WishCandleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.wishInfo = arg_1_2.wish_info
	arg_1_0.actInfo = arg_1_2.act_info
	arg_1_0.idx = arg_1_2.idx
	arg_1_0.activityID = arg_1_2.activity_id
	arg_1_0.tableID = arg_1_2.table_id
	arg_1_0.candleNum = arg_1_0.wishInfo.wish_times
	arg_1_0.serverTime = arg_1_2.server_time
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.startTime = arg_1_2.start_time
	arg_1_0.endTime = arg_1_2.end_time
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.initScrollView(arg_4_0)
	arg_4_0.descContainer = arg_4_0:nodeByName("desc_container")

	local var_4_0 = arg_4_0.descContainer:getContentSize()

	arg_4_0.scrollView = cc.ui.UIScrollView.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height)
	}):onScroll(handler(arg_4_0, arg_4_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0):addTo(arg_4_0.descContainer)
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" and 5 <= math.abs(arg_5_1.y - arg_5_0.prevY_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:initScrollView()
	arg_6_0:nodeByName("title"):setString(xyd.tables.activityCandle:name(arg_6_0.idx))

	local var_6_0 = xyd.tables.misc.candleCost

	arg_6_0:nodeByName("text_bottom_2"):setString(string.format(var_0_2:translation("WISH_CANDLE_TIPS_1"), var_6_0))
	arg_6_0:nodeByName("text_bottom_3"):setString(var_0_2:translation("WISH_CANDLE_TIPS_2"))
	arg_6_0:nodeByName("text_mid_3"):setString(var_0_2:translation("WISH_CANDLE_TIPS_4"))

	local var_6_1 = xyd.tables.activities:desc(arg_6_0.activityID)
	local var_6_2 = cc.Node:create()

	arg_6_0.scrollView:addScrollNode(var_6_2)
	var_6_2:setPosition(0, 140)

	local var_6_3 = arg_6_0:nodeByName("text_act_des")

	var_6_3:setString(var_0_2:translation("WISH_CANDLE_TIPS_5"))
	arg_6_0.descContainer:removeChild(var_6_3)
	var_6_3:addTo(var_6_2)
	var_6_3:setPosition(cc.p(0, 0))
	var_6_3:setAnchorPoint(cc.p(0, 0))

	local var_6_4 = {
		y = 0,
		size = 24,
		x = 0,
		color = cc.c3b(220, 220, 200),
		dimensions = cc.size(680, 0),
		text = var_6_1
	}
	local var_6_5 = xyd.AssetLoader.get():loadLabel(var_6_4)

	var_6_5:addTo(var_6_2)
	var_6_5:setAnchorPoint(cc.p(0, 1))
	arg_6_0:updateLoadingBar()
	arg_6_0:updateCandleNum()
	arg_6_0:UpdateWaitingTime()
	arg_6_0:nodeByName("btn_wish_normal"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = xyd.ServerTime.get():getServerTime()

			if var_7_0 < arg_6_0.startTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_NO_OPEN")
				})
			elseif var_7_0 > arg_6_0.endTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_11")
				})
			elseif arg_6_0.actInfo and arg_6_0.actInfo.end_time - arg_6_0.serverTime < 0 and arg_6_0.candleNum >= arg_6_0.maxCandleNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_11")
				})
			elseif arg_6_0.candleNum == arg_6_0.maxCandleNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_8")
				})
			elseif arg_6_0.backpackCandleNum <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_9")
				})
			else
				arg_6_0:makeRequestWish(xyd.WishCandleType.candle)
			end
		end
	end)
	arg_6_0:nodeByName("btn_wish_diamond"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_8_0 = xyd.ServerTime.get():getServerTime()

			if var_8_0 < arg_6_0.startTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_NO_OPEN")
				})
			elseif var_8_0 > arg_6_0.endTime then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_11")
				})
			elseif arg_6_0.actInfo and arg_6_0.actInfo.end_time - arg_6_0.serverTime < 0 and arg_6_0.candleNum >= arg_6_0.maxCandleNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_11")
				})
			elseif arg_6_0.candleNum == arg_6_0.maxCandleNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("WISH_CANDLE_TIPS_8")
				})
			elseif var_6_0 > arg_6_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					local var_9_0 = {}

					var_9_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
				end, nil, nil, arg_6_0.colorMode)
			else
				local var_8_1 = string.format(var_0_2:translation("WISH_DIAMOND_TIPS"), var_6_0)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_1, function()
					local var_10_0 = {}

					arg_6_0:makeRequestWish(xyd.WishCandleType.yuanbao)
				end, nil, nil, arg_6_0.colorMode)
			end
		end
	end)
end

function var_0_0.updateLoadingBar(arg_11_0)
	arg_11_0.maxCandleNum = xyd.tables.misc.candleTotal

	local var_11_0 = 0
	local var_11_1 = arg_11_0.candleNum >= arg_11_0.maxCandleNum and 100 or math.floor(100 * arg_11_0.candleNum / arg_11_0.maxCandleNum)

	arg_11_0:nodeByName("loading_bar"):setPercent(var_11_1)
	arg_11_0:nodeByName("text_loading_bar"):setString(arg_11_0.candleNum .. "/" .. arg_11_0.maxCandleNum)
end

function var_0_0.willClose(arg_12_0)
	return
end

function var_0_0.didClose(arg_13_0)
	if arg_13_0.handler then
		var_0_1.unscheduleGlobal(arg_13_0.handler)

		arg_13_0.handler = nil
	end
end

function var_0_0.UpdateWaitingTime(arg_14_0)
	if arg_14_0.wishInfo.open_flag ~= 1 then
		arg_14_0:nodeByName("text_time"):setVisible(false)

		return
	elseif arg_14_0.actInfo.end_time - arg_14_0.serverTime < 0 and arg_14_0.candleNum >= arg_14_0.maxCandleNum then
		arg_14_0:nodeByName("text_time"):setString(var_0_2:translation("WISH_CANDLE_TIPS_11"))

		return
	end

	local function var_14_0(arg_15_0)
		local var_15_0

		if arg_15_0 < 86400 then
			var_15_0 = xyd.secondsToString(arg_15_0)
		else
			var_15_0 = xyd.secondsToString1(arg_15_0)
		end

		return var_15_0
	end

	if arg_14_0.handler then
		var_0_1.unscheduleGlobal(arg_14_0.handler)

		arg_14_0.handler = nil
	end

	local var_14_1 = arg_14_0.actInfo.start_time - arg_14_0.serverTime

	if var_14_1 > 0 then
		arg_14_0:nodeByName("text_time"):setString(string.format(var_0_2:translation("WISH_CANDLE_TIPS_6"), var_14_0(var_14_1)))

		arg_14_0.handler = var_0_1.scheduleGlobal(function()
			var_14_1 = var_14_1 - 1

			if not tolua.isnull(arg_14_0) then
				arg_14_0:nodeByName("text_time"):setString(string.format(var_0_2:translation("WISH_CANDLE_TIPS_6"), var_14_0(var_14_1)))
			end

			if var_14_1 <= 0 and arg_14_0.handler then
				var_0_1.unscheduleGlobal(arg_14_0.handler)

				arg_14_0.handler = nil

				if not tolua.isnull(arg_14_0) then
					arg_14_0:nodeByName("text_time"):setString(var_0_2:translation("WISH_CANDLE_TIPS_10"))
				end
			end
		end, 1)
	else
		arg_14_0:nodeByName("text_time"):setString(var_0_2:translation("WISH_CANDLE_TIPS_10"))
	end
end

function var_0_0.makeRequestWish(arg_17_0, arg_17_1)
	local var_17_0 = {
		wish_type = arg_17_1,
		id = arg_17_0.idx
	}

	xyd.Backend.get():request(xyd.mid.CANDLE_WISH, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			local var_18_0 = arg_18_1.wish_info[arg_17_0.idx].wish_times

			if arg_17_0.callback then
				arg_17_0.callback(arg_18_1)
			end

			arg_17_0.backpackCandleNum = arg_17_0.backpackCandleNum - 1

			if arg_17_1 == xyd.WishCandleType.candle then
				arg_17_0.backpack_:setItemNumByID(xyd.tables.misc.candleItem, arg_17_0.backpackCandleNum)
			end

			arg_17_0.candleNum = var_18_0
			arg_17_0.actInfo = arg_18_1.act_info[arg_17_0.idx]
			arg_17_0.wishInfo = arg_18_1.wish_info[arg_17_0.idx]

			arg_17_0:updateLoadingBar()
			arg_17_0:updateCandleNum()
			arg_17_0:UpdateWaitingTime()
		end
	end)
end

function var_0_0.updateCandleNum(arg_19_0)
	if not arg_19_0.selfPlayer.backpackLoaded_ then
		arg_19_0.selfPlayer:loadBackpack(function(arg_20_0)
			if arg_20_0 == xyd.error.OK then
				arg_19_0.backpack_ = arg_19_0.selfPlayer:getBackpack()
			end
		end)
	else
		arg_19_0.backpack_ = arg_19_0.selfPlayer:getBackpack()
	end

	arg_19_0.backpackCandleNum = arg_19_0.backpack_:getItemNumByID(xyd.tables.misc.candleItem) or 0

	arg_19_0:nodeByName("text_bottom_1"):setString(string.format(var_0_2:translation("WISH_CANDLE_TIPS_3"), arg_19_0.backpackCandleNum))
end

return var_0_0
