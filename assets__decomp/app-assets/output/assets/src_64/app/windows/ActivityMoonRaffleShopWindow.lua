local var_0_0 = class("ActivityMoonRaffleShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityMoonRaffleShop
local var_0_4 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activity = arg_1_2.activity
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.buyTimes = xyd.splitToNumber(arg_1_0.details.exchange_times, "|") or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_title"):setString(var_0_2:translation("ACTIVITY_1090_TEXT4"))
	arg_2_0:nodeByName("txt_has"):setString(var_0_2:translation("ACTIVITY_1090_TEXT5"))
	arg_2_0:initData()
	arg_2_0:initListview()
	arg_2_0:updateScore()
end

function var_0_0.initData(arg_3_0)
	local var_3_0 = var_0_3:ids()
	local var_3_1 = {}

	for iter_3_0 = 1, #var_3_0 do
		if arg_3_0.selfPlayer.vip >= var_0_3:vip(var_3_0[iter_3_0]) then
			table.insert(var_3_1, var_3_0[iter_3_0])
		end
	end

	arg_3_0.listInfo = var_3_1
end

function var_0_0.initListview(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("item_container")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
		arg_5_0.prevY_ = arg_5_1.y
	elseif arg_5_1.name == "moved" then
		local var_5_0 = 3

		if var_5_0 <= math.abs(arg_5_1.y - arg_5_0.prevY_) or var_5_0 <= math.abs(arg_5_1.x - arg_5_0.prevX_) then
			arg_5_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return (math.ceil(#arg_6_0.listInfo / var_0_4))
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.list:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.list:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = 748
		local var_6_2 = 183

		var_6_0:setItemSize(var_6_1, var_6_2 + 11)

		local var_6_3 = display.newNode()

		var_6_3:setContentSize(var_6_1, var_6_2)
		arg_6_0:initItemCell(var_6_3, arg_6_3)
		var_6_0:addContent(var_6_3)

		return var_6_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_6_2 then
		-- block empty
	end
end

function var_0_0.updateScore(arg_7_0)
	arg_7_0:nodeByName("count_time_txt"):setString(arg_7_0.activity.details.lucky_star)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0.list:reload()
end

function var_0_0.initItemCell(arg_9_0, arg_9_1, arg_9_2)
	for iter_9_0 = 1, var_0_4 do
		local var_9_0 = (arg_9_2 - 1) * var_0_4 + iter_9_0

		if var_9_0 > #arg_9_0.listInfo then
			break
		end

		local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1090/new_shop/moon_item.csb")

		var_9_1:setContentSize(368, 183)
		arg_9_1:addChild(var_9_1)
		var_9_1:setPosition(380 * (iter_9_0 - 1), 0)

		local var_9_2 = var_9_1:getChildByName("bg")
		local var_9_3 = var_0_3:itemID(arg_9_0.listInfo[var_9_0])

		xyd.setItemAndAddTips(var_9_2:getChildByName("item"), var_9_3, var_0_3:itemNum(arg_9_0.listInfo[var_9_0]))
		var_9_2:getChildByName("item_name"):setString(xyd.tables.item:name(var_9_3))
		var_9_2:getChildByName("text1"):setString(var_0_2:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT1"))
		var_9_2:getChildByName("text_cost"):setString(var_0_2:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))
		var_9_2:getChildByName("cost"):setString(var_0_3:cost(arg_9_0.listInfo[var_9_0]))
		arg_9_0:updateTimes(var_9_0, var_9_2:getChildByName("text2"))

		local var_9_4 = var_0_3:times(arg_9_0.listInfo[var_9_0])
		local var_9_5 = var_9_2:getChildByName("btn_exchange")

		var_9_5:getChildByName("text_exchange"):setString(var_0_2:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT2"))
		xyd.nodeEventSample(var_9_5, nil, function()
			if xyd.ServerTime.get():getServerTime() >= arg_9_0.activity.start_time and xyd.ServerTime.get():getServerTime() < arg_9_0.activity.end_time then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("ACTIVITY_SUN_RAFFLE_SHOP_TEXT3"), var_0_3:cost(arg_9_0.listInfo[var_9_0]), xyd.tables.item:name(var_9_3)), function()
					if var_0_3:cost(arg_9_0.listInfo[var_9_0]) > arg_9_0.activity.details.lucky_star then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("SQUARE_TURNTABLE2_POINT_TIP")
						})

						return
					end

					if var_9_4 ~= -1 and (arg_9_0.buyTimes[var_9_0] or 0) >= var_9_4 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_2:translation("NUMBER_HAS_FINISH")
						})

						return
					end

					arg_9_0.activitiesModel:getActivityReward(arg_9_0.activity.table_id, arg_9_0.listInfo[var_9_0], function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							arg_9_0.buyTimes[var_9_0] = (arg_9_0.buyTimes[var_9_0] or 0) + 1
							arg_9_0.details.exchange_times = arg_9_0:getStr()
							arg_9_0.activity.details.lucky_star = arg_12_1.lucky_star

							arg_9_0:updateScore()
							arg_9_0.callback()
							arg_9_0.selfPlayer:handleRewards(arg_12_1.awards)
							arg_9_0:updateTimes(var_9_0, var_9_2:getChildByName("text2"))
						end
					end)
				end, nil, nil, arg_9_0.colorMode)
			elseif xyd.ServerTime.get():getServerTime() >= arg_9_0.activity.end_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_FINISHED")
				})
			elseif xyd.ServerTime.get():getServerTime() < arg_9_0.activity.start_time then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("ACTIVITY_NO_OPEN")
				})
			end
		end)
	end
end

function var_0_0.getStr(arg_13_0)
	local var_13_0 = #var_0_3.times_
	local var_13_1 = ""

	for iter_13_0 = 1, var_13_0 do
		if iter_13_0 ~= 1 then
			var_13_1 = var_13_1 .. "|"
		end

		var_13_1 = var_13_1 .. (arg_13_0.buyTimes[iter_13_0] or 0)
	end

	return var_13_1
end

function var_0_0.updateTimes(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = var_0_3:times(arg_14_0.listInfo[arg_14_1])

	if var_14_0 ~= -1 then
		arg_14_2:setVisible(true)
		arg_14_2:setString(string.format("(%d/%d)", arg_14_0.buyTimes[arg_14_1] or 0, var_14_0))
	else
		arg_14_2:setVisible(false)
	end
end

return var_0_0
